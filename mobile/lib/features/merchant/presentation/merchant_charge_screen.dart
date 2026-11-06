import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/lightning_invoice.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/services/receive_address_presenter.dart';
import '../../../core/services/receive_address_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bip21.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/wallet_indices_notice.dart';
import '../../../l10n/app_localizations.dart';

/// Modalità di incasso.
enum ChargeMode {
  /// Fattura Lightning: accredito immediato, richiede un nodo collegato.
  lightning,

  /// URI BIP21: il cliente paga on-chain con l'importo già dentro il QR.
  onchain,
}

/// «Incassa»: richiesta di pagamento con IMPORTO, pensata per un esercente.
///
/// // PERCHÉ (leva 4, 27/10): finora l'app sapeva mostrare un indirizzo vuoto
/// // (Ricevi). Un esercente ha bisogno del gesto opposto: «dammi 12.000 sat»,
/// // con l'importo dentro il QR e la conferma a schermo appena il cliente
/// // paga. È il primo passo dell'adozione commerciale: senza questo,
/// // accettare XBT significa dettare un importo a voce e sperare.
///
/// // PERCHÉ nessuna chiave privata: incassare è LEGGERE (indirizzo) o
/// // CHIEDERE al nodo (fattura). Niente seed, niente password — coerente con
/// // il modello «chiavi solo per firmare» del 26/10.
class MerchantChargeScreen extends StatefulWidget {
  const MerchantChargeScreen({
    super.key,
    required this.wallet,
    required this.bitcoinService,
    this.lightningService,
    this.receiveAddressService,
    this.pollInterval = const Duration(seconds: 5),
  });

  final WalletRecord wallet;
  final BitcoinService bitcoinService;

  /// Nodo Lightning collegato (NWC/NCC). `null` = solo on-chain.
  final LightningService? lightningService;

  /// Rotazione degli indirizzi (A2). `null` = comportamento storico:
  /// `publicAddress` unico. Presente = ogni incasso usa `/0/N`.
  final ReceiveAddressService? receiveAddressService;

  /// Ogni quanto verificare il pagamento.
  final Duration pollInterval;

  /// Dopo N errori consecutivi il polling si ferma (nodo/explorer giù).
  static const int maxPollFailures = 3;

  @override
  State<MerchantChargeScreen> createState() => _MerchantChargeScreenState();
}

class _MerchantChargeScreenState extends State<MerchantChargeScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _labelCtrl = TextEditingController();

  ChargeMode _mode = ChargeMode.onchain;
  bool _creating = false;
  String? _error;

  /// Stato degli indici che impedisce l'incasso (corrotto/anomalo/adozione).
  ReceiveAddressView? _view;

  /// Richiesta corrente: fattura LN oppure URI/indirizzo on-chain.
  LightningInvoice? _invoice;
  String? _onchainAddress;
  String? _onchainUri;

  Timer? _pollTimer;
  int _pollFailures = 0;
  bool _paid = false;

  /// Stato dell'indirizzo PRIMA della richiesta: serve a distinguere un
  /// incasso nuovo da un saldo già presente.
  int _baselineTxCount = 0;
  int _baselineBalanceSats = 0;

  bool get _hasLightning =>
      widget.lightningService != null && widget.lightningService!.isConnected;

  @override
  void initState() {
    super.initState();
    _mode = _hasLightning ? ChargeMode.lightning : ChargeMode.onchain;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    _pollTimer?.cancel();
    setState(() {
      _invoice = null;
      _onchainAddress = null;
      _onchainUri = null;
      _paid = false;
      _error = null;
      _pollFailures = 0;
    });
  }

  Future<void> _create() async {
    final loc = AppLocalizations.of(context);
    final sats = int.tryParse(_amountCtrl.text.trim());
    if (sats == null || sats <= 0) {
      setState(() => _error = loc.merchantChargeAmountInvalid);
      return;
    }
    final label = _labelCtrl.text.trim();
    setState(() {
      _creating = true;
      _error = null;
      _invoice = null;
      _onchainAddress = null;
      _onchainUri = null;
      _paid = false;
    });
    try {
      if (_mode == ChargeMode.lightning) {
        final invoice = await widget.lightningService!.makeInvoice(
          amountMsat: sats * 1000,
          description: label,
        );
        if (!mounted) return;
        setState(() {
          _invoice = invoice;
          _creating = false;
        });
        _startLightningPolling(invoice.paymentHash);
      } else {
        final service = widget.receiveAddressService;
        String address;
        if (service == null) {
          address = widget.wallet.publicAddress;
        } else {
          // PERCHÉ (ADR 31/10-23): con la rotazione attiva ogni incasso usa un
          // indirizzo nuovo (privacy dell'esercente); senza, resta il
          // comportamento storico su `publicAddress`.
          final resolution = await service.next(widget.wallet);
          final resolved = resolution.address;
          if (resolved == null) {
            if (!mounted) return;
            setState(() {
              _creating = false;
              _view = resolution.view;
            });
            return;
          }
          address = resolved;
        }
        final info = await widget.bitcoinService.fetchAddressInfo(address);
        if (!mounted) return;
        _baselineBalanceSats = (info['balance'] as num?)?.toInt() ?? 0;
        _baselineTxCount = (info['tx_count'] as num?)?.toInt() ?? 0;
        setState(() {
          _onchainAddress = address;
          _onchainUri = buildBip21Uri(
            address: address,
            amountSats: sats,
            label: label.isEmpty ? null : label,
          );
          _creating = false;
        });
        _startOnchainPolling(address);
      }
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = loc.lightningErrorGeneric(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = '$e';
      });
    }
  }

  void _startLightningPolling(String paymentHash) {
    _pollTimer?.cancel();
    _pollFailures = 0;
    _pollTimer = Timer.periodic(
      widget.pollInterval,
      (_) => _checkInvoice(paymentHash),
    );
  }

  Future<void> _checkInvoice(String paymentHash) async {
    try {
      final invoice = await widget.lightningService!.lookupInvoice(
        paymentHash: paymentHash,
      );
      if (!mounted) return;
      _pollFailures = 0;
      if (!invoice.isPaid) return;
      _pollTimer?.cancel();
      setState(() => _paid = true);
      debugPrint('[LoopEngineer] incasso: fattura pagata');
    } on LightningException catch (e) {
      _handlePollFailure('lookup ${e.code}');
    }
  }

  void _startOnchainPolling(String address) {
    _pollTimer?.cancel();
    _pollFailures = 0;
    _pollTimer = Timer.periodic(
      widget.pollInterval,
      (_) => _checkOnchain(address),
    );
  }

  Future<void> _checkOnchain(String address) async {
    try {
      final info = await widget.bitcoinService.fetchAddressInfo(address);
      if (!mounted) return;
      _pollFailures = 0;
      final balance = (info['balance'] as num?)?.toInt() ?? 0;
      final txCount = (info['tx_count'] as num?)?.toInt() ?? 0;
      // PERCHÉ il confronto col BASELINE: l'indirizzo può avere già un saldo
      // (esercente che lo usa da tempo). Senza baseline l'app direbbe
      // «pagato» appena aperta.
      if (balance <= _baselineBalanceSats && txCount <= _baselineTxCount) {
        return;
      }
      _pollTimer?.cancel();
      setState(() => _paid = true);
      debugPrint('[LoopEngineer] incasso: movimento on-chain rilevato');
    } catch (e) {
      _handlePollFailure('address info: $e');
    }
  }

  void _handlePollFailure(String reason) {
    _pollFailures++;
    debugPrint('[LoopEngineer] incasso: verifica fallita ($reason)');
    if (_pollFailures >= MerchantChargeScreen.maxPollFailures) {
      _pollTimer?.cancel();
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasRequest = _invoice != null || _onchainUri != null;
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.merchantChargeTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_hasLightning && !hasRequest)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SegmentedButton<ChargeMode>(
                  segments: [
                    ButtonSegment(
                      value: ChargeMode.lightning,
                      label: Text(loc.merchantChargeModeLightning),
                      icon: const Icon(Icons.bolt, size: 16),
                    ),
                    ButtonSegment(
                      value: ChargeMode.onchain,
                      label: Text(loc.merchantChargeModeOnchain),
                      icon: const Icon(Icons.link, size: 16),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
              )
            else if (!hasRequest)
              // PERCHÉ: senza nodo l'incasso è solo on-chain — dirlo prima,
              // non far scoprire all'esercente che manca qualcosa a metà.
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  loc.merchantChargeLightningUnavailable,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.merchantChargeAmount,
                suffixText: 'sat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.merchantChargeLabel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _mode == ChargeMode.lightning
                  ? loc.merchantChargeLightningHint
                  : loc.merchantChargeOnchainHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_view != null)
              // Indici non utilizzabili: senza indirizzo valido non si incassa.
              WalletIndicesNotice(view: _view!),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: _creating || _paid ? null : _create,
              icon: _creating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(loc.merchantChargeCreate),
            ),
            if (_paid) ...[
              const SizedBox(height: 16),
              _paidBanner(loc),
            ],
            if (hasRequest) ...[
              const SizedBox(height: 24),
              if (_invoice != null && _invoice!.bolt11.isNotEmpty)
                _requestCard(
                  title: loc.merchantChargeInvoiceTitle,
                  data: _invoice!.bolt11,
                  loc: loc,
                ),
              if (_onchainUri != null) ...[
                _requestCard(
                  title: loc.merchantChargeUriTitle,
                  data: _onchainUri!,
                  loc: loc,
                ),
                if (_onchainAddress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText(
                      _onchainAddress!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(loc.merchantChargeNew),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paidBanner(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.merchantChargePaid,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );

  Widget _requestCard({
    required String title,
    required String data,
    required AppLocalizations loc,
  }) =>
      GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (!_paid)
              Container(
                // PERCHÉ: il QR deve restare leggibile in dark mode.
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
            if (!_paid) const SizedBox(height: 12),
            SelectableText(
              data,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _copy(data),
              icon: const Icon(Icons.copy, size: 18),
              label: Text(loc.lightningCopied),
            ),
            if (!_paid)
              Text(
                loc.merchantChargeWaiting,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
}
