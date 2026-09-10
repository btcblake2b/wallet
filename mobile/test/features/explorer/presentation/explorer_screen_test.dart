import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/services/explorer_api.dart';
import 'package:btc_blake2b_wallet/features/explorer/presentation/explorer_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('ExplorerScreen', () {
    testWidgets('mostra saldo, tx count e tip height dopo il load',
        (tester) async {
      final mock = MockClient((request) async {
        if (request.url.path.contains('/address/')) {
          return http.Response(
            jsonEncode({
              'chain_stats': {
                'funded_txo_sum': 99999856,
                'spent_txo_sum': 0,
                'tx_count': 1,
              },
              'mempool_stats': {
                'funded_txo_sum': 0,
                'spent_txo_sum': 0,
                'tx_count': 0,
              },
            }),
            200,
          );
        }
        if (request.url.path.contains('/blocks/tip/height')) {
          return http.Response('172048', 200);
        }
        return http.Response('{}', 404);
      });
      final api = ExplorerApi(client: mock);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorerScreen(api: api),
        ),
      );
      // PERCHÉ: attende il completamento delle future avviate in initState.
      await tester.pumpAndSettle();

      expect(find.text('0.99999856 BTC'), findsOneWidget);
      expect(find.text('172048'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // tx count
    });

    testWidgets(
        'indirizzo non valido → errore localizzato senza nuove chiamate',
        (tester) async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });
      final api = ExplorerApi(client: mock);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorerScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      // initState carica l'indirizzo di test valido → 2 chiamate (address + tip).
      final callsAfterInit = calls;

      await tester.enterText(find.byType(TextField), 'not-an-address');
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid address. Check the format for this network.'),
        findsOneWidget,
      );
      // PERCHÉ: nessuna chiamata API con indirizzo non valido (validazione
      // prima della richiesta).
      expect(calls, equals(callsAfterInit));
    });

    testWidgets('ApiException rate_limited → messaggio amichevole + retry',
        (tester) async {
      final mock = MockClient(
        (_) async => http.Response('{"error":"rate_limited"}', 429),
      );
      final api = ExplorerApi(client: mock);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorerScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Rate limit exceeded. Try again in a minute.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tap su Ricarica effettua una nuova fetch', (tester) async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (request.url.path.contains('/address/')) {
          return http.Response(
            jsonEncode({
              'chain_stats': {
                'funded_txo_sum': 99999856,
                'spent_txo_sum': 0,
                'tx_count': 1,
              },
              'mempool_stats': {
                'funded_txo_sum': 0,
                'spent_txo_sum': 0,
                'tx_count': 0,
              },
            }),
            200,
          );
        }
        return http.Response('172048', 200);
      });
      final api = ExplorerApi(client: mock);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorerScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      final callsAfterInit = calls;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // PERCHÉ: il refresh deve ricaricare saldo + tip height (2 nuove chiamate).
      expect(calls, greaterThan(callsAfterInit));
    });
  });
}
