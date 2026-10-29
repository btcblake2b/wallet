import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/psbt/psbt_qr.dart';

/// Trasporto PSBT su QR multipli (P4, 26/10).
///
/// // PERCHÉ: un frame letto male o un ordine sbagliato devono produrre un
/// // "manca ancora qualcosa", MAI una PSBT sbagliata da firmare. I test
/// // coprono i due lati: ricomposizione fedele e scarto dei frame invalidi.
void main() {
  const psbt = 'cHNidP8BAH0CAAAAA'; // finto ma con lo stesso alfabeto base64

  group('encodePsbtFrames', () {
    test('payload corto → un solo frame completo', () {
      final frames = encodePsbtFrames(psbt);
      expect(frames, hasLength(1));
      expect(frames.first, 'PSBT1/1/1/$psbt');
    });

    test('payload lungo → frame numerati 1..n con totali coerenti', () {
      final payload = 'A' * 900;
      final frames = encodePsbtFrames(payload, chunkLength: 180);
      expect(frames, hasLength(5));
      expect(frames.first.startsWith('PSBT1/1/5/'), isTrue);
      expect(frames.last.startsWith('PSBT1/5/5/'), isTrue);
      // Nessun carattere perso o duplicato nella somma dei pezzi.
      final joined = frames
          .map((f) => f.split('/').last)
          .fold<String>('', (acc, chunk) => acc + chunk);
      expect(joined, payload);
    });

    test('spazi e newline vengono rimossi prima di spezzare', () {
      final frames = encodePsbtFrames('  $psbt\n ');
      expect(frames.single, 'PSBT1/1/1/$psbt');
    });

    test('payload vuoto → ArgumentError', () {
      expect(() => encodePsbtFrames('   '), throwsArgumentError);
    });

    test('chunkLength non valido → ArgumentError', () {
      expect(() => encodePsbtFrames(psbt, chunkLength: 0), throwsArgumentError);
    });
  });

  group('isPsbtFrame', () {
    test('riconosce solo i frame del nostro protocollo', () {
      expect(isPsbtFrame('PSBT1/1/2/AAAA'), isTrue);
      expect(isPsbtFrame('  PSBT1/1/1/x'), isTrue);
      expect(isPsbtFrame('bitcoin:bc1q...'), isFalse);
      expect(isPsbtFrame('cHNidP8BAH0CAAAAA'), isFalse);
    });
  });

  group('PsbtFrameAssembler', () {
    test('frame in ordine → PSBT completa', () {
      final payload = 'B' * 400;
      final frames = encodePsbtFrames(payload, chunkLength: 100);
      final assembler = PsbtFrameAssembler();

      String? complete;
      for (final frame in frames) {
        complete = assembler.add(frame);
      }
      expect(complete, payload);
      expect(assembler.isComplete, isTrue);
      expect(assembler.received, 4);
      expect(assembler.total, 4);
    });

    test('frame fuori ordine e ripetuti → ricompone lo stesso payload', () {
      final payload = 'C' * 300;
      final frames = encodePsbtFrames(payload, chunkLength: 100);
      final assembler = PsbtFrameAssembler();

      expect(assembler.add(frames[2]), isNull);
      expect(assembler.add(frames[0]), isNull);
      expect(assembler.add(frames[2]), isNull); // ripetizione tollerata
      expect(assembler.received, 2);
      expect(assembler.add(frames[1]), payload);
    });

    test('frame malformato o di altra versione → ignorato, nessuna eccezione',
        () {
      final assembler = PsbtFrameAssembler();
      expect(assembler.add('PSBT2/1/2/AAAA'), isNull);
      expect(assembler.add('PSBT1/0/2/AAAA'), isNull); // indice 1-based
      expect(assembler.add('PSBT1/3/2/AAAA'), isNull); // indice > totale
      expect(assembler.add('PSBT1/1/2/'), isNull); // pezzo vuoto
      expect(assembler.add('PSBT1/x/2/AAAA'), isNull);
      expect(assembler.add('PSBT1/1/2'), isNull); // manca il pezzo
      expect(assembler.received, 0);
    });

    test('un set diverso azzera la raccolta', () {
      final assembler = PsbtFrameAssembler();
      assembler.add('PSBT1/1/3/AAA');
      expect(assembler.total, 3);
      // Nuovo giro con totale diverso → si riparte dal frame nuovo.
      assembler.add('PSBT1/1/2/BBB');
      expect(assembler.received, 1);
      expect(assembler.total, 2);
      expect(assembler.add('PSBT1/2/2/CCC'), 'BBBCCC');
    });

    test('reset esplicito svuota tutto', () {
      final assembler = PsbtFrameAssembler();
      assembler.add('PSBT1/1/2/AAA');
      assembler.reset();
      expect(assembler.received, 0);
      expect(assembler.total, isNull);
      expect(assembler.isComplete, isFalse);
    });
  });
}
