import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/swap_claim_row.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// La riga del claim deve rendere VERIFICABILE il txid: prima del 18/09/2026
/// l'utente vedeva solo "claim in corso" e non poteva controllare nulla.
void main() {
  const txid =
      '4f9978280af97b1c3551e396c47856e396193795c6f50925dbf6d098d3f4fd40';
  const label = 'Claim txid';
  const hint = 'Confirming with the next block.';
  const explorerUrl = 'https://mempool.guide/tx/$txid';

  Widget wrap({String? url}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SwapClaimRow(
            txid: txid,
            label: label,
            hint: hint,
            explorerUrl: url,
          ),
        ),
      );

  testWidgets('mostra etichetta, txid abbreviato e spiegazione dei tempi',
      (tester) async {
    await tester.pumpWidget(wrap(url: explorerUrl));

    expect(find.text(label), findsOneWidget);
    // Abbreviato: 12 caratteri di testa + 8 di coda (mai il txid intero).
    expect(find.text('4f9978280af9…d3f4fd40'), findsOneWidget);
    expect(find.text(txid), findsNothing);
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('senza URL explorer non mostra il link ma resta la copia',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byIcon(Icons.open_in_new), findsNothing);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('con URL explorer mostra il link di verifica', (tester) async {
    await tester.pumpWidget(wrap(url: explorerUrl));

    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('il tap su copia scrive il TXID INTERO negli appunti',
      (tester) async {
    // PERCHÉ: si copia il txid completo, non la versione abbreviata mostrata.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(wrap(url: explorerUrl));
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();

    expect(copied, txid);
    expect(find.text('Copied'), findsOneWidget); // snackbar l10n
  });
}
