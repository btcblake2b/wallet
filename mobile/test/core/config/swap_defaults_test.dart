import 'package:btc_blake2b_wallet/core/config/swap_defaults.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider predefinito (P9): la URI REALE deve essere valida e il merge con le
/// URI salvate non deve duplicare nulla.
void main() {
  group('SwapDefaults.providerUri', () {
    test('è una URI provider valida (pubkey, relay, rete)', () {
      final provider = SwapProvider.fromUri(SwapDefaults.providerUri);
      expect(
        provider.providerPubkey,
        '91d1fca1a250bfd426b3276fa1a40018d4a0bf3fb46b8e748c5892066d18b296',
      );
      // PERCHÉ: nella URI il relay è percent-encoded — deve arrivare decodificato.
      expect(provider.relays, const ['wss://relay.primal.net']);
      expect(provider.network, 'blake2b');
    });
  });

  group('SwapDefaults.withDefault', () {
    test('appende il default in coda alle URI salvate', () {
      final uris = SwapDefaults.withDefault(const ['nostr+swap://aa']);
      expect(uris.length, 2);
      expect(uris.first, 'nostr+swap://aa');
      expect(uris.last, SwapDefaults.providerUri);
    });

    test('non duplica il default se è già nell elenco', () {
      final uris = SwapDefaults.withDefault(const [SwapDefaults.providerUri]);
      expect(uris.length, 1);
      expect(uris.single, SwapDefaults.providerUri);
    });
  });
}
