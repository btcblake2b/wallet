import 'package:bech32/bech32.dart';
import 'package:btc_blake2b_wallet/core/utils/bolt12_offer_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// Importo scritto dentro un'offerta BOLT12.
///
/// // PERCHÉ: la UI deve sapere se l'importo è già fissato dal destinatario —
/// // se lo è, chiederlo sarebbe una domanda senza effetto sul pagamento.
void main() {
  /// Offerta sintetica con i TLV indicati (type → valore già codificato).
  String offerWith(Map<int, List<int>> tlvs) {
    final bytes = <int>[];
    for (final entry in tlvs.entries) {
      bytes
        ..add(entry.key)
        ..add(entry.value.length)
        ..addAll(entry.value);
    }
    return bech32.encode(Bech32('lno', _toGroups(bytes)), 2048);
  }

  /// Importo 21.000 msat codificato come BigSize (`0xfd` + 2 byte: 0x5208).
  final amount21000 = <int>[0xfd, 0x52, 0x08];

  test('offerta con importo → msat dichiarati', () {
    expect(bolt12OfferAmountMsat(offerWith({8: amount21000})), 21000);
  });

  test('offerta con descrizione e importo → importo letto', () {
    final offer = offerWith({
      8: amount21000,
      10: 'caffè'.codeUnits,
    });
    expect(bolt12OfferAmountMsat(offer), 21000);
  });

  test('offerta senza importo → null (lo sceglie chi paga)', () {
    expect(bolt12OfferAmountMsat(offerWith({10: 'caffè'.codeUnits})), isNull);
  });

  test('offerta in valuta fiat → null (non è un numero di sat)', () {
    final offer = offerWith({
      6: 'EUR'.codeUnits,
      8: amount21000,
    });
    expect(bolt12OfferAmountMsat(offer), isNull);
  });

  test('codice legacy o troncato → null, nessuna eccezione', () {
    // Offerta usata dai test BOLT12 precedenti: bech32 non integro.
    const legacyOffer =
        'lno1qgsqvgnwgcg35z6ee2h3yczraddm72xrfua9uve2rlrm9deu7xyfzrc';
    expect(bolt12OfferAmountMsat(legacyOffer), isNull);
  });

  test('testo qualsiasi, fattura o stringa vuota → null', () {
    expect(bolt12OfferAmountMsat(''), isNull);
    expect(bolt12OfferAmountMsat('lnbc1test'), isNull);
    expect(bolt12OfferAmountMsat('lno1corrotta'), isNull);
  });

  test('URI lightning: e maiuscole accettati', () {
    final offer = offerWith({8: amount21000});
    expect(bolt12OfferAmountMsat('lightning:$offer'), 21000);
    expect(bolt12OfferAmountMsat(offer.toUpperCase()), 21000);
  });
}

/// Byte → gruppi da 5 bit con padding (inverso della decodifica dell'offerta).
List<int> _toGroups(List<int> bytes) {
  final groups = <int>[];
  var acc = 0;
  var bits = 0;
  for (final byte in bytes) {
    acc = (acc << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      groups.add((acc >> bits) & 31);
    }
  }
  if (bits > 0) groups.add((acc << (5 - bits)) & 31);
  return groups;
}
