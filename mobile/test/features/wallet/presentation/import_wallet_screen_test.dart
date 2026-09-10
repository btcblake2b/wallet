import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/import_wallet_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  setUpAll(() {
    // PERCHÉ: mocktail richiede un fallback per any() su enum non nullable.
    registerFallbackValue(WalletScriptType.p2wpkh);
  });

  group('ImportWalletScreen', () {
    testWidgets('should render', (tester) async {
      final walletRepository = MockWalletRepository();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ImportWalletScreen(
            walletRepository: walletRepository,
          ),
        ),
      );

      expect(find.byType(ImportWalletScreen), findsOneWidget);
    });

    testWidgets('mostra il selettore tipo account (default native BIP84)',
        (tester) async {
      final walletRepository = MockWalletRepository();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ImportWalletScreen(
            walletRepository: walletRepository,
          ),
        ),
      );

      // Il selettore esiste ed è su Native SegWit (BIP84) di default.
      expect(
        find.byType(SegmentedButton<WalletScriptType>),
        findsOneWidget,
      );
      var seg = tester.widget<SegmentedButton<WalletScriptType>>(
        find.byType(SegmentedButton<WalletScriptType>),
      );
      expect(seg.selected, {WalletScriptType.p2wpkh});

      // Selezione Nested SegWit (BIP49) → cambia il valore selezionato.
      await tester.tap(find.text('Nested SegWit (BIP49)'));
      await tester.pumpAndSettle();
      seg = tester.widget<SegmentedButton<WalletScriptType>>(
        find.byType(SegmentedButton<WalletScriptType>),
      );
      expect(seg.selected, {WalletScriptType.p2shP2wpkh});

      // Selezione Legacy (BIP44) → cambia il valore selezionato.
      await tester.tap(find.text('Legacy (BIP44)'));
      await tester.pumpAndSettle();
      seg = tester.widget<SegmentedButton<WalletScriptType>>(
        find.byType(SegmentedButton<WalletScriptType>),
      );
      expect(seg.selected, {WalletScriptType.p2pkh});
    });

    group('modalità watch-only (P1)', () {
      testWidgets('switch mostra il campo xpub e nasconde la mnemonic',
          (tester) async {
        final walletRepository = MockWalletRepository();

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ImportWalletScreen(
              walletRepository: walletRepository,
            ),
          ),
        );

        // Default: modalità seed → campo mnemonic visibile.
        expect(find.text('word1 word2 word3 ...'), findsOneWidget);

        // Switch su Watch-only (l'etichetta è unica finché non si cambia).
        await tester.tap(find.text('Watch-only (xpub)'));
        await tester.pumpAndSettle();

        // Campo xpub visibile (hint), campo mnemonic rimosso.
        expect(find.textContaining('Paste the account xpub'), findsOneWidget);
        expect(find.text('word1 word2 word3 ...'), findsNothing);
      });

      testWidgets('validazione: rifiuta un xpub senza prefisso mainnet',
          (tester) async {
        final walletRepository = MockWalletRepository();

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ImportWalletScreen(
              walletRepository: walletRepository,
            ),
          ),
        );

        await tester.tap(find.text('Watch-only (xpub)'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'non-un-xpub',
        );
        await tester.ensureVisible(find.text('Import'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import'));
        await tester.pumpAndSettle();

        // PERCHÉ: la validazione UI (prefisso) avviene PRIMA di ogni rete.
        expect(
          find.text('The xpub must start with "xpub" (mainnet).'),
          findsOneWidget,
        );
        // Nessun import tentato (validazione fallita).
        verifyNever(
          () => walletRepository.importWatchOnly(
            accountXpub: any(named: 'accountXpub'),
            scriptType: any(named: 'scriptType'),
          ),
        );
      });
    });
  });
}
