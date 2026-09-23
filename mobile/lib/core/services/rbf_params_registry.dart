import 'package:flutter/foundation.dart';

import '../models/send_output.dart';
import '../models/utxo_info.dart';

/// Tipo di transazione tracciata per il bump fee RBF.
enum RbfTxKind { send, sweep }

/// Parametri di una transazione inviata da questa app, necessari per
/// ricostruirla con una fee maggiore (RBF BIP125, bump fee).
///
/// MAI contiene il seed o chiavi private: solo ciò che serve a ri-firmare
/// (il mnemonic arriva dal chiamante autenticato al momento del bump).
class RbfTxParams {
  const RbfTxParams({
    required this.kind,
    this.toAddress = '',
    this.amountSats = 0,
    this.outputs = const <SendOutput>[],
    required this.derivationPath,
    required this.originalFeeRateSatVb,
    required this.utxos,
  });

  final RbfTxKind kind;

  /// Destinatario singolo (percorso storico). Per le tx batch si usa [outputs].
  /// Non più `required`: la sostitutiva di un batch non ha un solo indirizzo.
  final String toAddress;

  /// Importo al destinatario singolo (usato solo per [RbfTxKind.send] legacy).
  final int amountSats;

  /// // PERCHÉ (P3): la sostitutiva RBF deve ripagare TUTTI i destinatari —
  /// // con il solo `toAddress` un bump su un batch pagherebbe un indirizzo e
  /// // riporterebbe gli altri importi nel change (pagamenti che falliscono in
  /// // silenzio, pur con fondi recuperati).
  final List<SendOutput> outputs;

  /// Destinatari effettivi: la lista se presente, altrimenti il singolo.
  List<SendOutput> get effectiveOutputs => outputs.isNotEmpty
      ? outputs
      : <SendOutput>[SendOutput(address: toAddress, amountSats: amountSats)];

  final String derivationPath;

  /// Fee rate originale: il bump deve essere STRETTAMENTE maggiore (BIP125).
  final int originalFeeRateSatVb;

  /// Stessi input della tx originale (con ownerDerivationPath per ri-firmare).
  final List<UtxoInfo> utxos;
}

/// Registro IN-MEMORIA (solo sessione) dei parametri delle tx inviate,
/// per il bump fee RBF.
///
/// PERCHÉ (S8 RBF, incremento B): senza i parametri originali non si può
/// ricostruire una transazione sostitutiva con fee maggiore. Pattern statico
/// coerente con [PendingSendRegistry]/[BalanceCache]: MAI persistito, MAI
/// dati sensibili (niente seed/chiavi). Scope v1: si perde al riavvio.
class RbfParamsRegistry {
  RbfParamsRegistry._();

  static final Map<String, RbfTxParams> _params = {};

  @visibleForTesting
  static void resetForTest() => _params.clear();

  static void register(String txid, RbfTxParams params) {
    if (txid.isEmpty) return;
    _params[txid] = params;
  }

  static RbfTxParams? of(String txid) => _params[txid];

  static bool contains(String txid) => _params.containsKey(txid);

  static void remove(String txid) => _params.remove(txid);
}
