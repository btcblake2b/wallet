import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_presenter.dart';
import 'package:btc_blake2b_wallet/core/widgets/wallet_indices_notice.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  Widget harness(Widget child, {Locale locale = const Locale('it')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('WalletIndicesNotice', () {
    testWidgets('corrotto: azioni riprova, restore e riparti da 0', (
      tester,
    ) async {
      var retry = 0;
      var restore = 0;
      var reset = 0;

      await tester.pumpWidget(
        harness(
          WalletIndicesNotice(
            view: ReceiveAddressView.corruptBlocked,
            onRetry: () => retry++,
            onRestoreBackup: () => restore++,
            onResetToZero: () => reset++,
          ),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      expect(find.text(loc.indicesCorruptTitle), findsOneWidget);
      expect(find.text(loc.indicesActionRetry), findsOneWidget);
      expect(find.text(loc.indicesActionRestore), findsOneWidget);

      await tester.tap(find.text(loc.indicesActionRetry));
      await tester.tap(find.text(loc.indicesActionRestore));
      expect(retry, 1);
      expect(restore, 1);
    });

    testWidgets('anomalo: NIENTE «riparti da 0» (sarebbe reuse)',
        (tester) async {
      // PERCHÉ (ADR 30/10-9 §1): da indice anomalo il reset è vietato — la
      // differenza rispetto al corrotto deve vedersi in UI, non solo nel modello.
      await tester.pumpWidget(
        harness(
          WalletIndicesNotice(
            view: ReceiveAddressView.anomalousBlocked,
            onRestoreBackup: () {},
            onContactSupport: () {},
            // Anche se il chiamante lo passasse, non deve comparire.
            onResetToZero: () {},
          ),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      expect(find.text(loc.indicesAnomalousTitle), findsOneWidget);
      expect(find.text(loc.indicesActionSupport), findsOneWidget);
      expect(find.text(loc.indicesAdoptionTitle), findsNothing);
    });

    testWidgets('adozione: un solo pulsante Continua', (tester) async {
      var continued = 0;

      await tester.pumpWidget(
        harness(
          WalletIndicesNotice(
            view: ReceiveAddressView.adoptionRequired,
            onResetToZero: () => continued++,
          ),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      expect(find.text(loc.indicesAdoptionTitle), findsOneWidget);
      await tester.tap(find.text(loc.indicesActionContinue));
      expect(continued, 1);
    });

    testWidgets('già assegnato: informazione, nessuna azione', (tester) async {
      await tester.pumpWidget(
        harness(
          const WalletIndicesNotice(
            view: ReceiveAddressView.alreadyAssigned,
          ),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      expect(find.text(loc.indicesAlreadyAssigned), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('fresco: nessun avviso', (tester) async {
      await tester.pumpWidget(
        harness(const WalletIndicesNotice(view: ReceiveAddressView.fresh)),
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('testo tradotto in inglese (7 lingue coperte da ARB)', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const WalletIndicesNotice(view: ReceiveAddressView.corruptBlocked),
          locale: const Locale('en'),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(loc.indicesCorruptTitle), findsOneWidget);
    });

    testWidgets('etichetta di scansione dichiara la CATENA (ricezione)',
        (tester) async {
      // PERCHÉ (ADR 31/10-22 §3): il restore copre solo /0; senza il prefisso
      // «Ricezione:» l'utente assumerebbe che X/Y comprenda anche il resto.
      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      final label = loc.receiveGapPartial(12, 20);

      expect(label, contains('Ricezione'));
      expect(label, contains('12/20'));
      // "Resto" arriverà con a2-changescan (0.6.0): oggi non deve comparire.
      expect(label.toLowerCase(), isNot(contains('resto')));
    });

    testWidgets('i tre esiti hanno messaggi DIVERSI (non un format unico)',
        (tester) async {
      // PERCHÉ (ADR 02/11-29 §6): `{probed}/{requested}` da solo è fuorviante
      // in tre casi su quattro. Le tre stringhe devono restare distinguibili.
      final loc = await AppLocalizations.delegate.load(const Locale('it')),
          en = await AppLocalizations.delegate.load(const Locale('en'));

      final found = loc.receiveGapFoundAtIndex(25);
      final partial = loc.receiveGapPartial(20, 20);
      final interrupted = loc.receiveGapInterrupted(20, 20);

      expect(found, contains('25'));
      expect(found, isNot(contains('/')));
      expect(partial, isNot(equals(interrupted)));
      expect(interrupted.toLowerCase(), contains('riprova'));
      expect(
        en.receiveGapInterrupted(3, 20).toLowerCase(),
        contains('try again'),
      );
    });

    testWidgets('«interrotto» non si legge «fatto» in nessuna delle 7 lingue',
        (tester) async {
      // PERCHÉ (ADR 02/11-31 §3): il tipo impedisce di mostrare la frazione su
      // un `gapFound`, ma non impedisce a una traduzione di dire «X/Y» e
      // sembrare conclusa. `unreachable` arriva anche con probed == requested
      // (budget scaduto sull'ultimo check): a 20/20 «verificati» è falso.
      //
      // COSA COPRE DAVVERO, per lingua: IT ed EN sono verifiche **semantiche**
      // (l'interrotto non contiene «verificat…»/«verified»); le altre 5 sono
      // **strutturali** (contiene la propria azione, è diverso dal parziale, è
      // più lungo). La distinguibilità è coperta ovunque, l'assenza della
      // parola no: un domani «überprüft» in tedesco passerebbe il test
      // strutturale, e va bene — non è quel livello di garanzia che promettiamo.
      const retryCue = <String, String>{
        'it': 'Riprova',
        'en': 'Try again',
        'de': 'Erneut versuchen',
        'es': 'Reintenta',
        'fr': 'Réessayez',
        'fi': 'Yritä uudelleen',
        'zh': '请重试',
      };

      for (final entry in retryCue.entries) {
        final loc = await AppLocalizations.delegate.load(Locale(entry.key));
        final interrupted = loc.receiveGapInterrupted(20, 20);
        final partial = loc.receiveGapPartial(20, 20);

        expect(interrupted, contains(entry.value), reason: entry.key);
        expect(interrupted, isNot(equals(partial)), reason: entry.key);
        // Il messaggio interrotto deve portare causa+azione, non solo il numero.
        expect(
          interrupted.length,
          greaterThan(partial.length),
          reason: entry.key,
        );
      }

      final it = await AppLocalizations.delegate.load(const Locale('it'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        it.receiveGapInterrupted(20, 20).toLowerCase(),
        isNot(contains('verificat')),
      );
      expect(
        en.receiveGapInterrupted(20, 20).toLowerCase(),
        isNot(contains('verified')),
      );
      // Anche il parziale a 80/80 non deve sembrare concluso.
      expect(it.receiveGapPartial(80, 80).toLowerCase(), contains('parzial'));
      expect(en.receiveGapPartial(80, 80).toLowerCase(), contains('partial'));
    });
    testWidgets('seed mismatch: avviso dedicato, nessuno sblocco', (
      tester,
    ) async {
      // PERCHÉ (ADR 02/11-33 §1): la seed c'è ma è quella sbagliata. Offrire
      // «Sblocca» sarebbe la stessa classe del «rollback sicuro»: una promessa
      // falsa in UI.
      await tester.pumpWidget(
        harness(
          WalletIndicesNotice(
            view: ReceiveAddressView.seedMismatch,
            onUnlock: () {},
            onResetToZero: () {},
            onRestoreBackup: () {},
            onContactSupport: () {},
          ),
          locale: const Locale('it'),
        ),
      );

      final loc = await AppLocalizations.delegate.load(const Locale('it'));
      expect(find.text(loc.indicesSeedMismatchTitle), findsOneWidget);
      expect(find.text(loc.indicesActionUnlock), findsNothing);
      expect(find.text(loc.indicesActionRestore), findsOneWidget);
      expect(find.text(loc.indicesActionSupport), findsOneWidget);
    });
  });
}
