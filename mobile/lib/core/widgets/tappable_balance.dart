import 'package:flutter/material.dart';

import '../services/balance_display.dart';
import '../services/fiat_price.dart';
import '../services/fx_rates.dart';
import '../../l10n/app_localizations.dart';

/// Saldo che, al tocco, cambia unità: XBT → sats → dollari (e ritorno).
///
/// // PERCHÉ esiste (29/10): su BlueWallet il valore si tocca per cambiare
/// // unità invece di cercare un'impostazione. Qui la preferenza è PER WALLET
/// // ([unitKey] = `walletId`), così cambiarla su un wallet non tocca gli
/// // altri; home e dettaglio passano la stessa chiave, quindi la scelta resta
/// // identica fra le due schermate.
///
/// // PERCHÉ il tocco si attiva SOLO col controvalore acceso: senza prezzo il
/// // ciclo a tre unità non ha senso (il dollaro non avrebbe un numero), e il
/// // comportamento storico — saldo in BTC non toccabile — resta intatto.
class TappableBalance extends StatelessWidget {
  const TappableBalance({
    super.key,
    required this.unitKey,
    required this.sats,
    this.style,
    this.maxWidth,
    this.fitted = false,
  });

  /// Chiave dell'unità: `walletId` oppure [BalanceDisplay.totalKey].
  final String unitKey;

  /// Saldo in satoshi.
  final int sats;

  final TextStyle? style;

  /// Larghezza massima del testo (righe strette della lista wallet).
  final double? maxWidth;

  /// True = il testo si rimpicciolisce per stare nella riga (card del saldo).
  final bool fitted;

  @override
  Widget build(BuildContext context) {
    // PERCHÉ si ascolta anche FiatPrice: se il prezzo cambia (o viene tolto) il
    // valore in dollari e la disponibilità del ciclo devono aggiornarsi senza
    // riaprire la schermata.
    return ListenableBuilder(
      listenable: Listenable.merge([
        BalanceDisplay.instance,
        FiatPrice.instance,
        // PERCHÉ anche i cambi: la valuta scelta può non avere ancora un
        // cambio (prima richiesta) e arrivare dopo il primo frame.
        FxRates.instance,
      ]),
      builder: (context, _) {
        final fiatAvailable = FiatPrice.instance.enabled;
        final label = Text(
          formatBalanceValue(
            BalanceDisplay.instance.unitFor(unitKey),
            sats,
            fiatCents: FiatPrice.instance.centsFor(sats),
          ),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        Widget content = maxWidth == null
            ? label
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: label,
              );
        if (fitted) {
          content = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: content,
          );
        }
        if (!fiatAvailable) return content;

        return Semantics(
          button: true,
          hint: AppLocalizations.of(context).balanceChangeUnitHint,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                BalanceDisplay.instance.cycle(unitKey, fiatAvailable: true),
            child: content,
          ),
        );
      },
    );
  }
}
