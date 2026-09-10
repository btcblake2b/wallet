// FLOW: Invio Transazione Wallet

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/wallet_record.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/password_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/config/bitcoin_network_config.dart';
import 'scan_qr_screen.dart';

const int _kDustLimitSats = 546;

class SendScreen extends StatefulWidget {
  const SendScreen({
    super.key,
    required this.wallet,
    required this.walletRepository,
    required this.bitcoinService,
    required this.biometricService,
    required this.balanceSats,
    this.initialUtxos, // UTXO già caricati dalla pagina wallet detail
  });

  final WalletRecord wallet;
  final WalletRepository walletRepository;
  final BitcoinService bitcoinService;

  /// PERCHÉ (audit A1): autenticazione (biometria nativa / password web)
  /// prima di decifrare il seed e firmare.
  final BiometricService biometricService;
  final int balanceSats;
  final List<UtxoInfo>? initialUtxos;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customFeeCtrl = TextEditingController();

  FeeEstimates? _feeEstimates;
  List<UtxoInfo>? _utxos;
  final Set<String> _selectedUtxoKeys = {};
  bool _utxoSelectorExpanded = false;
  bool _loadingInit = true;
  String? _initError;

  // Fee selection: 0=low 1=normal 2=high 3=custom
  int _feeChoice = 1;
  bool _sending = false;
  String? _sendError;
  String? _successTxid;
  String? _sendStep;

  /// Restituisce una stima del tempo di conferma basata sul fee rate.
  /// Mapping approssimativo (1 block ≈ 10 min):
  ///   ≤1 sat/vB → ~2 ore, ≤3 → ~1 ora, ≤5 → ~30 min,
  ///   ≤10 → ~15 min, ≤20 → ~10 min, >20 → ~5 min
  String _feeTimeLabel(int satVb, AppLocalizations loc) {
    if (satVb <= 1) return loc.sendScreenFeeTime2h;
    if (satVb <= 3) return loc.sendScreenFeeTime1h;
    if (satVb <= 5) return loc.sendScreenFeeTime30m;
    if (satVb <= 10) return loc.sendScreenFeeTime15m;
    if (satVb <= 20) return loc.sendScreenFeeTime10m;
    return loc.sendScreenFeeTime5m;
  }

  List<UtxoInfo> get _selectedUtxos => (_utxos ?? const <UtxoInfo>[])
      .where((u) => _selectedUtxoKeys.contains(_utxoKey(u)))
      .toList();

  int get _availableBalanceSats =>
      _selectedUtxos.fold<int>(0, (s, u) => s + u.valueSat);

  String _utxoKey(UtxoInfo utxo) => '${utxo.txid}:${utxo.vout}';

  void _selectAllUtxos() {
    _selectedUtxoKeys
      ..clear()
      ..addAll((_utxos ?? const <UtxoInfo>[]).map(_utxoKey));
  }

  bool get _allUtxosSelected =>
      _utxos != null &&
      _utxos!.isNotEmpty &&
      _selectedUtxoKeys.length == _utxos!.length;

  @override
  void initState() {
    super.initState();
    // PERCHÉ (audit A7/A6): schermata che gestisce importi, indirizzi e firma
    // → protezione screenshot (reference-counted in SecurityService).
    SecurityService().protectScreen(true);
    _utxos = widget.initialUtxos;
    _selectAllUtxos();
    if (_utxos != null && _utxos!.isNotEmpty) {
      // UTXO già disponibili da wallet detail: carica solo fee estimates
      _loadingInit = true;
      _loadFeeEstimatesOnly();
    } else {
      // Nessun UTXO pre-caricato: mostra prompt caricamento manuale
      _loadingInit = false;
    }
  }

  Future<void> _loadFeeEstimatesOnly() async {
    try {
      final feeEstimates = await widget.bitcoinService.fetchFeeEstimates();
      if (!mounted) return;
      setState(() {
        _feeEstimates = feeEstimates;
        _loadingInit = false;
      });
    } catch (e) {
      if (!mounted) return;
      // PERCHÉ (fee blake2b): fallback dalla config di rete (mainnet 1/2/3),
      // non hardcoded testnet — unica fonte BitcoinNetworkConfig.
      final fb = BitcoinNetworkConfig.fallbackFeeEstimates;
      setState(() {
        _feeEstimates = FeeEstimates(
          lowSatVb: fb.low,
          normalSatVb: fb.normal,
          highSatVb: fb.high,
        );
        _loadingInit = false;
      });
    }
  }

  @override
  void dispose() {
    SecurityService().protectScreen(false);
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    _customFeeCtrl.dispose();
    super.dispose();
  }

  int get _selectedFeeRate {
    final f = _feeEstimates;
    // PERCHÉ (fee blake2b): default dalla config di rete, non 3 hardcoded.
    if (f == null) return BitcoinNetworkConfig.fallbackFeeEstimates.normal;
    switch (_feeChoice) {
      case 0:
        return f.lowSatVb;
      case 1:
        return f.normalSatVb;
      case 2:
        return f.highSatVb;
      case 3:
        final parsed = int.tryParse(_customFeeCtrl.text);
        return (parsed != null && parsed > 0) ? parsed : f.normalSatVb;
      default:
        return f.normalSatVb;
    }
  }

  int? get _parsedAmountSats {
    final text = _amountCtrl.text.trim().replaceAll(',', '.');
    final btc = double.tryParse(text);
    if (btc == null) return null;
    return (btc * 100000000).round();
  }

  int _estimateFee(int numInputs, {int outputCount = 2}) {
    // PERCHÉ (BIP49): la stima è tipo-consapevole (nested P2SH pesa più del
    // native) così l'anteprima fee coincide con la tx reale costruita in
    // bitcoin_service. Per i wallet BIP84 il risultato è invariato.
    final pool = _utxos ?? const <UtxoInfo>[];
    final take = numInputs < pool.length ? numInputs : pool.length;
    var size = estimateTxVbytes(pool.take(take), outputCount);
    size += 41 * (numInputs - take); // fallback: input oltre il pool
    return size * _selectedFeeRate;
  }

  /// Stima il numero di input necessari per un dato importo,
  /// considerando se serve un output di change o meno.
  int _estimateInputCountForAmount(int amountSats) {
    final utxos = _utxos ?? const <UtxoInfo>[];
    if (utxos.isEmpty) return 1;

    var total = 0;
    final totalUtxo = _availableBalanceSats;
    for (var i = 0; i < utxos.length; i++) {
      total += utxos[i].valueSat;
      // Prova con 2 output (con change)
      var fee = _estimateFee(i + 1);
      var change = totalUtxo - amountSats - fee;
      // Se change sotto dust, usa 1 output (senza change)
      if (change < _kDustLimitSats) {
        fee = _estimateFee(i + 1, outputCount: 1);
      }
      if (total >= amountSats + fee) return i + 1;
    }
    return utxos.length;
  }

  int _estimateFeeForAmount(int amountSats) {
    final inputs = _estimateInputCountForAmount(amountSats);
    // Determina se serve output di change
    final change = _availableBalanceSats - amountSats - _estimateFee(inputs);
    final outputCount = change < _kDustLimitSats ? 1 : 2;
    return _estimateFee(inputs, outputCount: outputCount);
  }

  String _formatBtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} ${BitcoinNetworkConfig.ticker}';

  // Validate destination address
  String? _validateAddress(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return loc.sendScreenValidateAddress;
    }
    final v = value.trim();
    if (!BitcoinNetworkConfig.isValidAddressPrefix(v)) {
      return loc.sendScreenValidateInvalidAddress(
        BitcoinNetworkConfig.networkName,
        BitcoinNetworkConfig.addressPrefixDescription,
      );
    }
    if (v.length < 25 || v.length > 90) {
      return loc.sendScreenValidateLength;
    }
    // PERCHÉ (UX-002): Validazione checksum Bech32m/Bech32/Base58.
    // La sola verifica del prefisso non basta — un typo di 1 char
    // può creare un indirizzo con checksum rotto ma prefisso valido.
    if (!BitcoinNetworkConfig.isValidAddress(v)) {
      return loc.sendScreenValidateInvalidAddress(
        BitcoinNetworkConfig.networkName,
        BitcoinNetworkConfig.addressPrefixDescription,
      );
    }
    if (v == widget.wallet.publicAddress) {
      return loc.sendScreenValidateSelf;
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return loc.sendScreenValidateAmount;
    }
    final text = value.trim().replaceAll(',', '.');
    final btc = double.tryParse(text);
    if (btc == null || btc <= 0) return loc.sendScreenValidateInvalidAmount;
    final sats = (btc * 100000000).round();
    if (sats < _kDustLimitSats) {
      return loc.sendScreenValidateDust(
        _kDustLimitSats,
        _formatBtc(_kDustLimitSats),
      );
    }
    final fee = _estimateFeeForAmount(sats);
    final available = _availableBalanceSats;
    if (sats + fee > available) {
      return loc.sendScreenValidateInsufficient(
        _formatBtc(available),
        fee,
      );
    }
    return null;
  }

  /// PERCHÉ (audit A1): autenticazione prima di un'azione sensibile — il
  /// dialog di riepilogo è solo UX; firmare richiede identità verificata.
  /// Nativo: biometria (o credenziale device). Web: password del vault.
  Future<bool> _authorizeSpending() async {
    final loc = AppLocalizations.of(context);
    if (kIsWeb) {
      final entered = await PasswordDialog.showEnterPasswordDialog(
        context,
        reason: loc.sendScreenPasswordReason,
      );
      if (!mounted || entered == null || entered.isEmpty) return false;
      final ok = await widget.biometricService.verifyPassword(entered);
      if (ok) {
        await widget.walletRepository.unlockWebStorage(entered);
      }
      return ok;
    }
    final available = await widget.biometricService.canAuthenticate();
    if (!mounted) return false;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.sendScreenBiometricRequired)),
      );
      return false;
    }
    return widget.biometricService.authenticateForSensitiveAction(
      reason: loc.sendScreenBiometricReason,
    );
  }

  Future<void> _loadUtxosManually() async {
    // PERCHÉ (P1/C9): i watch-only non hanno seed — nessun decrypt.
    if (widget.wallet.kind == WalletKind.watchOnly) return;
    // PERCHÉ (audit A1): decifrare il seed per scansionare gli UTXO
    // spendibili è sensibile: richiede autenticazione.
    if (!await _authorizeSpending()) return;
    if (!mounted) return;
    setState(() {
      _loadingInit = true;
      _initError = null;
    });

    try {
      final feeEstimatesFuture = widget.bitcoinService.fetchFeeEstimates();
      final mnemonic = await widget.walletRepository.decryptSeed(widget.wallet);
      // PERCHÉ: gap-limit su entrambe le catene (external + change) — gli UTXO
      // di change diventano spendibili (fix saldo/trasferimenti vs BlueWallet).
      final utxos = await widget.bitcoinService.fetchSpendableWalletUtxos(
        mnemonic,
        derivationPath: widget.wallet.derivationPath,
      );
      final feeEstimates = await feeEstimatesFuture;
      if (!mounted) return;
      setState(() {
        _feeEstimates = feeEstimates;
        _utxos = utxos;
        _selectAllUtxos();
        _loadingInit = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _loadingInit = false;
      });
    }
  }

  /// Apre lo scanner QR reale e, se il codice è un indirizzo BTC valido,
  /// lo inserisce nel campo destinatario.
  Future<void> _scanAddress() async {
    final loc = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (result == null || !mounted) return;

    final candidate = result.trim();
    if (BitcoinNetworkConfig.isValidAddress(candidate)) {
      _addressCtrl.text = candidate;
      setState(() {});
    } else {
      // PERCHÉ: la validazione completa (self/checksum) resta al form.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.scanQrInvalid)),
      );
    }
  }

  /// Dialog di conferma con riepilogo prima dell'invio (irreversibile).
  Future<bool> _confirmSend({
    required String toAddress,
    required int amountSats,
    required int feeSats,
    required int totalSats,
  }) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.sendConfirmTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.sendConfirmWarning,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _confirmRow(loc.sendScreenAddressLabel, toAddress),
              const SizedBox(height: 8),
              _confirmRow(
                loc.sendScreenAmountLabel,
                _formatBtc(amountSats),
              ),
              const SizedBox(height: 8),
              _confirmRow(loc.sendScreenFeeLabel, '$feeSats sat'),
              const Divider(height: 16),
              _confirmRow(
                loc.sendScreenTotal(
                  _formatBtc(totalSats),
                  BitcoinNetworkConfig.ticker,
                ),
                _formatBtc(totalSats),
                bold: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.passwordDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.sendConfirmSend),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Widget _confirmRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontFamily: bold ? null : 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    // PERCHÉ (P1/C9): i watch-only non hanno chiavi per firmare — guardia
    // difensiva (in UI il pulsante è già nascosto).
    if (widget.wallet.kind == WalletKind.watchOnly) return;
    final loc = AppLocalizations.of(context);
    if (_utxos == null) {
      setState(
        () => _sendError = loc.sendScreenUtxoError(''),
      );
      return;
    }
    if (_utxos!.isEmpty) {
      setState(() => _sendError = loc.sendScreenUtxoError(''));
      return;
    }
    if (_selectedUtxos.isEmpty) {
      setState(() => _sendError = loc.sendScreenUtxoNoneSelected);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amountSats = _parsedAmountSats!;
    final toAddress = _addressCtrl.text.trim();
    final feeRate = _selectedFeeRate;

    // PERCHÉ (UX-2): conferma finale prima di firmare/broadcastare — una
    // transazione BTC è irreversibile, serve un riepilogo esplicito.
    final feeSats = _estimateFeeForAmount(amountSats);
    final confirmed = await _confirmSend(
      toAddress: toAddress,
      amountSats: amountSats,
      feeSats: feeSats,
      totalSats: amountSats + feeSats,
    );
    if (!confirmed || !mounted) return;

    // PERCHÉ (audit A1): il dialog di conferma è solo UX. Firmare e
    // trasmettere una transazione richiede autenticazione reale (biometria o
    // password web). Se non autenticato, nessuna firma/broadcast.
    // STEP: 1 — autenticazione spesa (biometria nativa / password web)
    final authorized = await _authorizeSpending();
    if (!authorized || !mounted) return;

    setState(() {
      _sending = true;
      _sendError = null;
      _sendStep = loc.sendScreenSigning;
    });

    try {
      // STEP: 2 — decrypt seed (mai in chiaro: solo per la firma)
      final mnemonic = await widget.walletRepository.decryptSeed(widget.wallet);
      if (!mounted) return;

      setState(() => _sendStep = loc.sendScreenBroadcasting);

      // STEP: 3 — build + firma UNIFIED (replay protection) + broadcast
      final result = await widget.bitcoinService.buildSignAndSend(
        mnemonic: mnemonic,
        toAddress: toAddress,
        amountSats: amountSats,
        feeRateSatVb: feeRate,
        utxos: _selectedUtxos,
        derivationPath: widget.wallet.derivationPath ?? "m/84'/1'/0'",
      );

      if (!mounted) return;
      setState(() {
        _successTxid = result.txid;
        _sending = false;
        _sendStep = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendError = e.toString();
        _sending = false;
        _sendStep = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).sendScreenTitle),
          centerTitle: true,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _loadingInit
            ? const Center(child: CircularProgressIndicator())
            : _initError != null
                ? _buildError()
                : _successTxid != null
                    ? _buildSuccess()
                    : _utxos == null
                        ? _buildLoadPrompt()
                        : _buildForm(colorScheme, theme),
      ),
    );
  }

  Widget _buildError() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              loc.sendScreenUtxoError(_initError!),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _initError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loadingInit = true;
                  _initError = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text(loc.walletDetailRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 20,
          child: Semantics(
            header: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.sendScreenSuccess,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  BitcoinNetworkConfig.broadcastConfirmationMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sendScreenSuccessTxid(_successTxid!),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _successTxid!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _successTxid!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.walletDetailAddressCopied),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(loc.walletDetailCopy),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(loc.walletDetailClose),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadPrompt() {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          borderRadius: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_download, size: 64, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                loc.sendScreenLoadingUtxos,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.sendScreenUtxoError(
                  '',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadUtxosManually,
                  icon: const Icon(Icons.search),
                  label: Text(loc.walletDetailRefresh),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.passwordDialogCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme, ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final utxos = _utxos ?? [];
    final totalUtxoSats = _availableBalanceSats;
    final feeEst = _feeEstimates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Progress indicator during send ──
            if (_sending && _sendStep != null) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _sendStep!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Balance summary
            // Balance summary + coin control
            _buildBalanceAndUtxoCard(
              utxos: utxos,
              totalUtxoSats: totalUtxoSats,
              colorScheme: colorScheme,
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Destination address
            Text(loc.sendScreenAddressLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                hintText: BitcoinNetworkConfig.addressPrefixHint,
                prefixIcon: const Icon(Icons.send),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: loc.scanQrTitle,
                  onPressed: _scanAddress,
                ),
              ),
              validator: _validateAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 16),

            // Amount
            Text(
              loc.sendScreenAmountLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                hintText: BitcoinNetworkConfig.amountHint,
                prefixIcon: const Icon(Icons.currency_bitcoin),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: BitcoinNetworkConfig.amountSuffix,
                helperText: totalUtxoSats > 0
                    ? loc.sendScreenMaxHelper(_formatBtc(totalUtxoSats))
                    : null,
              ),
              validator: _validateAmount,
              textInputAction: TextInputAction.done,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) {
                if (!_sending) _send();
              },
            ),

            const SizedBox(height: 4),
            // Quick "max" button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final maxSats =
                      totalUtxoSats - _estimateFeeForAmount(totalUtxoSats);
                  if (maxSats > _kDustLimitSats) {
                    _amountCtrl.text = (maxSats / 100000000).toStringAsFixed(8);
                    setState(() {});
                  }
                },
                // PERCHÉ (A4): prima usava loc.sendScreenSend → il pulsante
                // diceva "Invia" ed era identico al vero invio.
                child: Text(loc.sendScreenMax),
              ),
            ),

            const SizedBox(height: 8),

            // Fee selector
            Text(loc.sendScreenFeeLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (feeEst == null)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              _buildFeeSelector(feeEst, colorScheme, theme),

            const SizedBox(height: 8),

            // Fee summary row
            if (feeEst != null) ...[
              _buildFeeSummary(colorScheme, theme),
              const SizedBox(height: 20),
            ],

            // Error banner
            if (_sendError != null) ...[
              Semantics(
                container: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _sendError!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Send button
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _sending ? loc.sendScreenSending : loc.sendScreenSend,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      BitcoinNetworkConfig.networkDisclaimer,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceAndUtxoCard({
    required List<UtxoInfo> utxos,
    required int totalUtxoSats,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final loc = AppLocalizations.of(context);
    final selectedCount = _selectedUtxos.length;
    final allSelected = _allUtxosSelected;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        children: [
          InkWell(
            onTap: utxos.isEmpty
                ? null
                : () => setState(
                      () => _utxoSelectorExpanded = !_utxoSelectorExpanded,
                    ),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sendScreenBalance(
                          (totalUtxoSats / 100000000).toStringAsFixed(8),
                          BitcoinNetworkConfig.ticker,
                        ),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        _formatBtc(totalUtxoSats),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.sendScreenUtxoSummary(totalUtxoSats, selectedCount),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (utxos.isNotEmpty)
                  Icon(
                    _utxoSelectorExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (_utxoSelectorExpanded && utxos.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.sendScreenUtxoControl,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Checkbox(
                  value: allSelected
                      ? true
                      : selectedCount == 0
                          ? false
                          : null,
                  tristate: true,
                  onChanged: (_) => setState(() {
                    if (allSelected) {
                      _selectedUtxoKeys.clear();
                    } else {
                      _selectAllUtxos();
                    }
                  }),
                  activeColor: colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  loc.sendScreenUtxoSelectAll,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: utxos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final utxo = utxos[index];
                  final selected = _selectedUtxoKeys.contains(_utxoKey(utxo));
                  final txid = utxo.txid;
                  final shortTxid = txid.length > 16
                      ? '${txid.substring(0, 8)}…${txid.substring(txid.length - 8)}'
                      : txid;
                  final label =
                      widget.wallet.utxoLabels[_utxoKey(utxo)]?.trim();
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => setState(() {
                      final key = _utxoKey(utxo);
                      if (selected) {
                        _selectedUtxoKeys.remove(key);
                      } else {
                        _selectedUtxoKeys.add(key);
                      }
                    }),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    activeColor: colorScheme.primary,
                    title: Text(
                      label == null || label.isEmpty
                          ? '$shortTxid:${utxo.vout}'
                          : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      label == null || label.isEmpty
                          ? _formatBtc(utxo.valueSat)
                          : '${_formatBtc(utxo.valueSat)} · $shortTxid:${utxo.vout}',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeSelector(
    FeeEstimates feeEst,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context);
    final options = [
      _FeeOption(
        label: loc.sendScreenFeeLow,
        satVb: feeEst.lowSatVb,
        icon: Icons.hourglass_bottom,
      ),
      _FeeOption(
        label: loc.sendScreenFeeNormal,
        satVb: feeEst.normalSatVb,
        icon: Icons.schedule,
      ),
      _FeeOption(
        label: loc.sendScreenFeeHigh,
        satVb: feeEst.highSatVb,
        icon: Icons.flash_on,
      ),
      _FeeOption(label: loc.sendScreenFeeCustom, satVb: null, icon: Icons.tune),
    ];

    return Column(
      children: [
        Row(
          children: options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final selected = _feeChoice == i;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                child: SizedBox(
                  height: 112,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _feeChoice = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          // Un fondo tenue evita che la card selezionata
                          // diventi un blocco arancio e mantiene il testo
                          // leggibile in entrambi i temi.
                          color: selected
                              ? colorScheme.primary.withValues(alpha: 0.16)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              opt.icon,
                              size: 18,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 28,
                              child: Text(
                                opt.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (opt.satVb != null) ...[
                              Text(
                                '${opt.satVb} sat/vB',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _feeTimeLabel(opt.satVb!, loc),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_feeChoice == 3) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customFeeCtrl,
            decoration: InputDecoration(
              labelText: loc.sendScreenFeeCustomHint,
              suffixText: loc.sendScreenFeeCustomHint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (_feeChoice != 3) return null;
              final n = int.tryParse(v ?? '');
              if (n == null || n <= 0) {
                return loc.sendScreenFeeCustomHint;
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildFeeSummary(ColorScheme colorScheme, ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final amtSats = _parsedAmountSats;
    final inputs = amtSats != null ? _estimateInputCountForAmount(amtSats) : 1;
    var fee = amtSats != null ? _estimateFee(inputs) : _estimateFee(1);
    final totalUtxo = _availableBalanceSats;
    final change = amtSats != null ? totalUtxo - amtSats - fee : 0;
    if (change < _kDustLimitSats && amtSats != null) {
      fee = _estimateFee(inputs, outputCount: 1);
    }
    final totalNeeded = amtSats != null ? amtSats + fee : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // PERCHÉ (audit 2026-09-07): la rete blake2b non ha prezzo di
          // mercato → niente controvalore fiat (prima mostrava il prezzo BTC).
          _feeLine(
            theme,
            loc.sendScreenFeeEstimated(fee),
            // PERCHÉ: totale fee + tasso — rende esplicito che la fee è
            // tasso (sat/vB) × dimensione tx (vB), non il tasso stesso.
            '$fee sat · $_selectedFeeRate sat/vB',
          ),
          if (amtSats != null) ...[
            _feeLine(theme, loc.sendScreenAmountLabel, _formatBtc(amtSats)),
            const Divider(height: 16),
            _feeLine(
              theme,
              loc.sendScreenTotal(
                _formatBtc(totalNeeded!),
                BitcoinNetworkConfig.ticker,
              ),
              _formatBtc(totalNeeded),
              bold: true,
              color: totalNeeded > _availableBalanceSats
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _feeLine(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeOption {
  final String label;
  final int? satVb;
  final IconData icon;
  const _FeeOption({
    required this.label,
    required this.satVb,
    required this.icon,
  });
}
