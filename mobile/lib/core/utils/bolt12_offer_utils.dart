import 'package:bech32/bech32.dart';

import 'lightning_invoice_utils.dart';

/// Importo fisso dichiarato in un'offerta BOLT12, in msat.
///
/// // PERCHÉ (BOLT12): un'offerta può portare l'importo al suo interno. In quel
/// // caso chi paga non deve sceglierlo — chiederglielo mostrerebbe un campo che
/// // il nodo poi ignora, o farebbe credere di poter pagare un'altra cifra.
/// // Ritorna `null` quando l'offerta è a importo libero, illeggibile o
/// // denominata in valuta fiat (`offer_currency`: non convertibile qui).
int? bolt12OfferAmountMsat(String raw) {
  final value = normalizeLightningInvoice(raw).toLowerCase();
  if (!value.startsWith('lno1')) return null;

  final bytes = _offerBytes(value);
  if (bytes == null) return null;

  int? amountMsat;
  var hasCurrency = false;
  var offset = 0;
  while (offset < bytes.length) {
    final type = _readBigSize(bytes, offset);
    if (type == null) return null;
    final length = _readBigSize(bytes, type.next);
    if (length == null) return null;
    final start = length.next;
    final end = start + length.value;
    if (end > bytes.length) return null;

    if (type.value == _offerCurrencyType) hasCurrency = true;
    if (type.value == _offerAmountType) {
      final amount = _readBigSize(bytes, start);
      if (amount == null || amount.next != end) return null;
      amountMsat = amount.value;
    }
    offset = end;
  }

  // Con `offer_currency` l'importo è in valuta: non è un numero di sat.
  if (hasCurrency) return null;
  return amountMsat;
}

/// Tipi TLV dell'offerta (BOLT 12).
const int _offerCurrencyType = 6;
const int _offerAmountType = 8;

/// Corpo TLV dell'offerta, oppure null se il codice non è un bech32 valido.
List<int>? _offerBytes(String offer) {
  try {
    // PERCHÉ: un'offerta è lunga centinaia di caratteri, oltre il limite di
    // default del codec (90) pensato per gli indirizzi.
    final decoded = bech32.decode(offer, offer.length);
    return _groupsToBytes(decoded.data);
  } catch (_) {
    return null;
  }
}

/// Converte i gruppi da 5 bit del bech32 in byte (padding finale a zero).
List<int>? _groupsToBytes(List<int> groups) {
  final bytes = <int>[];
  var acc = 0;
  var bits = 0;
  for (final group in groups) {
    if (group < 0 || group > 31) return null;
    // Si tengono solo i bit ancora da consumare (bits < 8 prima del ciclo).
    acc = ((acc << 5) | group) & 0x1fff;
    bits += 5;
    while (bits >= 8) {
      bits -= 8;
      bytes.add((acc >> bits) & 0xff);
    }
  }
  // Un padding non nullo o più lungo di 4 bit è un'offerta corrotta.
  if (bits >= 5 || (acc & ((1 << bits) - 1)) != 0) return null;
  return bytes;
}

/// BigSize (BOLT 1): valore e offset del byte successivo.
class _BigSize {
  const _BigSize(this.value, this.next);

  final int value;
  final int next;
}

_BigSize? _readBigSize(List<int> bytes, int offset) {
  if (offset < 0 || offset >= bytes.length) return null;
  final first = bytes[offset];
  if (first < 0xfd) return _BigSize(first, offset + 1);

  final size = first == 0xfd ? 2 : (first == 0xfe ? 4 : 8);
  final end = offset + 1 + size;
  if (end > bytes.length) return null;
  var value = 0;
  for (var i = offset + 1; i < end; i++) {
    value = (value << 8) | bytes[i];
  }
  return _BigSize(value, end);
}
