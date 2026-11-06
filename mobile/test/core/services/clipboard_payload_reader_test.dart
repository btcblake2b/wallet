import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/clipboard_payload_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reader = ClipboardPayloadReader();

  void stubClipboard(String? text) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return text == null ? null : <String, dynamic>{'text': text};
      }
      return null;
    });
  }

  void stubClipboardThrows() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        throw PlatformException(code: 'permission_denied');
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ClipboardPayloadReader (ADR 02/11-27 §3)', () {
    test('indirizzo bech32 → bitcoinAddress', () async {
      stubClipboard('bc1qshopaddress0000000000000000000000');

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.ok);
      expect(sut.kind, ClipboardPayloadKind.bitcoinAddress);
      expect(sut.isUsable, isTrue);
    });

    test('indirizzo legacy → bitcoinAddress', () async {
      stubClipboard('1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2');

      final sut = await reader.read();

      expect(sut.kind, ClipboardPayloadKind.bitcoinAddress);
    });

    test('BOLT11 e BOLT12 riconosciuti, con prefisso lightning:', () async {
      stubClipboard(
        'lightning:lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4js',
      );
      final bolt11 = await reader.read();
      expect(bolt11.kind, ClipboardPayloadKind.bolt11);
      // Il prefisso URI non resta nel valore.
      expect(bolt11.value.startsWith('lnbc'), isTrue);

      stubClipboard(
        'lno1pqps7sjqpgtyzm3qv4uxzmtsd3jjqer9wd3hy6tsw35k7msjzfpy7nz5yqcnygrf'
        'dej82um5wf5k2uckyypwa3eyt44h6txtxquqh7lz5djge4afgfjn7k4rgrkuag0jsd5xvxg',
      );
      final bolt12 = await reader.read();
      expect(bolt12.kind, ClipboardPayloadKind.bolt12);
    });

    test('LNURL (lnurl1…) → recognizedUnsupported, non "sconosciuto"',
        () async {
      // PERCHÉ (ADR 02/11-28 §3): formato legittimo che l'app conosce ma non
      // paga in questa build. «Non riconosciuto» sarebbe falso.
      stubClipboard(
        'lnurl1dp68gurn8ghj7ampd3kx2ar0veekzar0wd5xjtnrdakj7tnhv4kxctttdehhwm30d3h82unvwqhkwetvv9kk2um5d3skgetnvdkx2cm0daks6ct5v9mrs',
      );

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.recognizedUnsupported);
      expect(sut.kind, ClipboardPayloadKind.lnurl);
      expect(sut.isUsable, isFalse);
      expect(sut.isRecognizedButUnsupported, isTrue);
    });

    test('lightning address (nome@dominio) → recognizedUnsupported', () async {
      stubClipboard('caffe@getalby.com');

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.recognizedUnsupported);
      expect(sut.kind, ClipboardPayloadKind.lightningAddress);
      expect(sut.isRecognizedButUnsupported, isTrue);
    });

    test('email valida → recognizedUnsupported (falso positivo DICHIARATO)',
        () async {
      // PERCHÉ (ADR 02/11-29 §3): `nome@dominio.tld` è anche la forma di
      // un'email. Senza risolvere il DNS (A3a, bloccata dalla CSP) non si può
      // distinguere: si accetta il falso positivo e la UI dice «formato
      // riconosciuto, non disponibile qui», senza nominare «lightning address».
      stubClipboard('mario@azienda.it');

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.recognizedUnsupported);
      expect(sut.kind, ClipboardPayloadKind.lightningAddress);
    });

    test('BIP21 con lightning= → hasLightningFallback true', () async {
      // PERCHÉ (ADR 02/11-29 §4): il merchant ha offerto LN come alternativa.
      // On-chain-first resta la scelta, ma il fallback non va ignorato in
      // silenzio.
      stubClipboard(
        'bitcoin:bc1qshop?amount=0.0001&lightning=lnbc2500u1pvjluezpp5qqqsyqcy',
      );

      final sut = await reader.read();

      expect(sut.kind, ClipboardPayloadKind.bip21);
      expect(sut.hasLightningFallback, isTrue);
    });

    test('BIP21 senza lightning= → hasLightningFallback false', () async {
      stubClipboard('bitcoin:bc1qshop?amount=0.0001');

      final sut = await reader.read();

      expect(sut.hasLightningFallback, isFalse);
    });

    test('URI BIP21 → uri', () async {
      stubClipboard('bitcoin:bc1qshop?amount=0.0001');

      final sut = await reader.read();

      expect(sut.kind, ClipboardPayloadKind.bip21);
    });

    test('appunti vuoti → empty', () async {
      stubClipboard('   ');

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.empty);
      expect(sut.isUsable, isFalse);
    });

    test('testo qualsiasi → unsupported, senza eccezioni', () async {
      stubClipboard('ciao, come stai?');

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.unsupported);
      expect(sut.isUsable, isFalse);
    });

    test('permesso negato → unavailable, non un crash', () async {
      // PERCHÉ (ADR 02/11-27 §3): su web readText() può fallire per permesso o
      // contesto non sicuro. Deve diventare un esito gestibile dalla UI.
      stubClipboardThrows();

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.unavailable);
      expect(sut.isUsable, isFalse);
    });

    test('appunti assenti (null) → empty', () async {
      stubClipboard(null);

      final sut = await reader.read();

      expect(sut.status, ClipboardPayloadStatus.empty);
    });
  });
}
