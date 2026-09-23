import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';

/// Equivalenza e "laziness" del percorso snapshot dopo P8-b/opzione B.
///
/// // PERCHÉ: il rischio di questa ottimizzazione non è il costo ma il
/// // COMPORTAMENTO (stesse tx, stesso saldo). Qui si verifica che:
/// // 1. un UTXO dentro il range utile venga trovato, con saldo corretto;
/// // 2. un indirizzo oltre il gap-limit resti invisibile — COME PRIMA;
/// // 3. il numero di indirizzi interrogati sia quello del gap (≈20 per ramo),
/// //    non 100+100: è la prova che la derivazione è lazy.
/// Indirizzo che il mock considera finanziato (impostato in ciascun test,
/// perché dipende dalla derivazione). Top-level: non è una variabile locale.
String fundedAddress = '';

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  setUp(() {
    ExplorerMirrors.resetForTest();
  });

  // Impostato in ciascun test (dipende dalla derivazione).

  Future<String> addressAt(int index) async {
    final derived = await BitcoinService().deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: index + 2,
    );
    return derived.addresses[index];
  }

  test('UTXO dentro il range utile: trovato, saldo corretto, derive lazy',
      () async {
    fundedAddress = await addressAt(1); // /0/1

    var utxoCalls = 0;
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('100000', 200);
      }
      if (path.endsWith('/utxo')) {
        utxoCalls++;
        final addr = path.split('/address/').last.replaceAll('/utxo', '');
        if (addr == fundedAddress) {
          return http.Response(
            jsonEncode([
              {'txid': 'a' * 64, 'vout': 0, 'value': 21000},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }
      if (path.endsWith('/txs')) return http.Response('[]', 200);
      if (path.contains('/tx/')) {
        return http.Response(
          jsonEncode({
            'vout': [
              {
                'scriptpubkey': '0014abcd',
                'scriptpubkey_type': 'v0_p2wpkh',
                'scriptpubkey_address': fundedAddress,
              },
            ],
            'status': {'confirmed': true, 'block_height': 99000},
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });
    final service = BitcoinService(client: mock);

    final snapshot = await service.fetchWalletSnapshot(
      mnemonic,
      includeHistory: false,
    );

    expect(snapshot.balanceSats, 21000);
    expect(snapshot.utxos, hasLength(1));
    expect(snapshot.utxos!.first.ownerDerivationPath, contains('/0/1'));
    // Lazy: 2 blocchi da 20 derivati per il ramo attivo + 1 per il change = 40
    // indirizzi (non 200). Chiamate: 20 + 20 (il blocco si interroga comunque
    // tutto) + 20 = 60.
    expect(utxoCalls, 60);
  });

  test('indirizzo oltre il gap-limit: NON trovato (comportamento di prima)',
      () async {
    fundedAddress = await addressAt(21);

    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('100000', 200);
      }
      if (path.endsWith('/utxo')) {
        final addr = path.split('/address/').last.replaceAll('/utxo', '');
        if (addr == fundedAddress) {
          return http.Response(
            jsonEncode([
              {'txid': 'a' * 64, 'vout': 0, 'value': 21000},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }
      if (path.endsWith('/txs')) return http.Response('[]', 200);
      return http.Response('not found', 404);
    });
    final service = BitcoinService(client: mock);

    final snapshot = await service.fetchWalletSnapshot(
      mnemonic,
      includeHistory: false,
    );

    // Il gap-limit chiude il ramo prima dell'indice 21 — esattamente come
    // nella versione precedente (dove però si derivavano 100 indirizzi).
    expect(snapshot.balanceSats, 0);
    expect(snapshot.utxos, isEmpty);
  });

  test('watch-only: stesso percorso lazy dallo xpub', () async {
    final derived = await BitcoinService().deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: 3,
    );
    fundedAddress = derived.addresses[0];

    var utxoCalls = 0;
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('100000', 200);
      }
      if (path.endsWith('/utxo')) {
        utxoCalls++;
        final addr = path.split('/address/').last.replaceAll('/utxo', '');
        if (addr == fundedAddress) {
          return http.Response(
            jsonEncode([
              {'txid': 'b' * 64, 'vout': 1, 'value': 5000},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }
      if (path.endsWith('/txs')) return http.Response('[]', 200);
      if (path.contains('/tx/')) {
        return http.Response(
          jsonEncode({
            'vout': [
              {'scriptpubkey': '0014abcd', 'scriptpubkey_type': 'v0_p2wpkh'},
              {
                'scriptpubkey': '0014abcd',
                'scriptpubkey_type': 'v0_p2wpkh',
                'scriptpubkey_address': fundedAddress,
              },
            ],
            'status': {'confirmed': true, 'block_height': 99000},
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });
    final service = BitcoinService(client: mock);

    final snapshot = await service.fetchWatchOnlySnapshot(
      accountXpub: derived.xpub,
      includeHistory: false,
    );

    expect(snapshot.balanceSats, 5000);
    // Stesso profilo del percorso hot: 60 chiamate, 40 indirizzi derivati.
    expect(utxoCalls, 60);
  });
}
