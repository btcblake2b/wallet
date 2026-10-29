/// Costruzione di un URI BIP21 (`bitcoin:<address>?amount=…&label=…`).
///
/// // PERCHÉ (26/10): un esercente deve poter chiedere un IMPORTO, non solo
/// // mostrare un indirizzo vuoto. BIP21 è letto da tutti i wallet e non
/// // richiede backend: l'importo viaggia dentro il QR.
library;

/// Importo BTC come stringa decimale ESATTA (max 8 decimali, zeri finali
/// rimossi).
///
/// // PERCHÉ: mai `double` — in virgola mobile 0.00012345 non è rappresentabile
/// // e un arrotondamento sbagliato su un incasso è una perdita reale. Qui si
/// // lavora solo su interi di satoshi.
String satsToBtcAmount(int sats) {
  if (sats <= 0) return '0';
  const satsPerBtc = 100000000;
  final whole = sats ~/ satsPerBtc;
  final fraction = (sats % satsPerBtc)
      .toString()
      .padLeft(8, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole.$fraction';
}

/// URI BIP21 per chiedere [amountSats] all'indirizzo [address].
///
/// [label] e [message] sono opzionali e vengono codificati (spazi, `&`, `#`…):
/// un'etichetta non codificata romperebbe il QR in modo silenzioso.
///
/// Lancia [ArgumentError] se [address] è vuoto: meglio un errore esplicito che
/// un QR che punta a `bitcoin:?amount=…` (fondi inviati a nessuno).
String buildBip21Uri({
  required String address,
  int? amountSats,
  String? label,
  String? message,
}) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(address, 'address', 'indirizzo vuoto');
  }
  final params = <String>[];
  // PERCHÉ `Uri.encodeComponent` e NON `encodeQueryComponent`: quest'ultimo
  // codifica lo spazio come `+` (form-encoding), che in un URI BIP21 resta un
  // `+` letterale → etichetta sbagliata nel wallet del cliente.
  if (amountSats != null && amountSats > 0) {
    params.add('amount=${Uri.encodeComponent(satsToBtcAmount(amountSats))}');
  }
  final cleanLabel = label?.trim();
  if (cleanLabel != null && cleanLabel.isNotEmpty) {
    params.add('label=${Uri.encodeComponent(cleanLabel)}');
  }
  final cleanMessage = message?.trim();
  if (cleanMessage != null && cleanMessage.isNotEmpty) {
    params.add('message=${Uri.encodeComponent(cleanMessage)}');
  }
  final query = params.isEmpty ? '' : '?${params.join('&')}';
  return 'bitcoin:$trimmed$query';
}
