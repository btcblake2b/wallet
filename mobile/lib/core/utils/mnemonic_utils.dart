import 'package:bip39/bip39.dart' as bip39;

/// Lunghezze mnemoniche valide BIP39 (entropia 128-256 bit): 12/15/18/21/24
/// parole. PERCHÉ: il package bip39 1.0.6 accetta queste lunghezze (entropia
/// 16-32 byte) — import e scan QR non devono restringere a 12.
const kBip39WordCounts = <int>[12, 15, 18, 21, 24];

/// Normalizza una frase mnemonica proveniente da input manuale, appunti o QR:
/// minuscole, nessuno spazio ai bordi e separatori singoli.
/// PERCHÉ: un QR di backup seed contiene spesso a-capo o tabulazioni, e senza
/// normalizzazione il checksum BIP39 fallirebbe su una frase corretta.
String normalizeMnemonic(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Numero di parole di [raw] dopo la normalizzazione (0 se vuota).
int mnemonicWordCount(String raw) {
  final clean = normalizeMnemonic(raw);
  return clean.isEmpty ? 0 : clean.split(' ').length;
}

/// `true` se [raw] è una frase mnemonica BIP39 valida: lunghezza ammessa
/// (12/15/18/21/24 parole) e checksum corretto.
bool isValidMnemonic(String raw) {
  final clean = normalizeMnemonic(raw);
  if (!kBip39WordCounts.contains(mnemonicWordCount(clean))) return false;
  return bip39.validateMnemonic(clean);
}
