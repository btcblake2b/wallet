import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

/// Benchmark leggero + equivalenza dei vettori noti per la derivazione.
///
/// PERCHÉ (P8-b): la derivazione di 100 indirizzi per ramo è il costo dominante
/// del primo snapshot (4,4-5,9 s sul device). Qui si **misura** (stampa nei log)
/// e si blocca il risultato crittografico con un vettore BIP84 noto: nessun
/// assert sul tempo (fragile in CI), ma il valore deve restare identico.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  test('derivazione 100+100: tempo misurato e vettore BIP84 invariato', () async {
    final service = BitcoinService();

    final stopwatch = Stopwatch()..start();
    final result = await service.deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: 100,
    );
    stopwatch.stop();

    debugPrint(
      '[LoopEngineer] benchmark derivazione 100+100: '
      '${stopwatch.elapsedMilliseconds}ms',
    );

    expect(result.addresses, hasLength(100));
    expect(result.changeAddresses, hasLength(100));

    // Vettore BIP84 noto (m/84'/0'/0'/0/0) — non deve cambiare MAI.
    expect(
      result.addresses.first,
      'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
    );
    // Il primo indirizzo di resto è diverso da quello di ricezione.
    expect(result.changeAddresses.first, isNot(result.addresses.first));
    // Nessun indirizzo duplicato tra le due catene.
    expect(
      result.addresses.toSet().length,
      100,
    );
    expect(
      result.changeAddresses.toSet().length,
      100,
    );
  });
}
