import 'package:btc_blake2b_wallet/core/widgets/glass_container.dart';
import 'package:btc_blake2b_wallet/core/widgets/web_vault_notice.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('su web mostra l\'avviso e il link all\'app Android',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const WebVaultNotice(
          isWeb: true,
          origin: 'https://app.btcblake2b.org',
        ),
      ),
    );

    expect(find.text('You are using the browser version'), findsOneWidget);
    expect(find.text('Get the Android app'), findsOneWidget);
    // Il testo deve dire il rischio reale, non rassicurare: la parola chiave
    // (localStorage) è ciò che rende l'avviso verificabile e onesto.
    expect(
      find.textContaining('localStorage'),
      findsOneWidget,
    );
  });

  testWidgets('dominio ufficiale → origine mostrata come verificata',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const WebVaultNotice(
          isWeb: true,
          origin: 'https://app.btcblake2b.org',
        ),
      ),
    );

    expect(
      find.text('Verified domain: https://app.btcblake2b.org'),
      findsOneWidget,
    );
  });

  testWidgets('dominio diverso → avviso di phishing con l\'origine reale',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const WebVaultNotice(isWeb: true, origin: 'https://app-btcblake2b.org'),
      ),
    );

    // L'origine REALE (letta a runtime) è quella che smaschera la copia.
    expect(find.textContaining('https://app-btcblake2b.org'), findsOneWidget);
    expect(find.textContaining('not the official domain'), findsOneWidget);
    expect(find.byIcon(Icons.gpp_bad), findsOneWidget);
  });

  testWidgets('localhost → ambiente di test, non un allarme', (tester) async {
    await tester.pumpWidget(
      wrap(
        const WebVaultNotice(isWeb: true, origin: 'http://localhost:8788'),
      ),
    );

    expect(
      find.text('Local test environment: http://localhost:8788'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.gpp_bad), findsNothing);
  });

  testWidgets('fuori dal web non disegna nulla', (tester) async {
    await tester.pumpWidget(wrap(const WebVaultNotice(isWeb: false)));

    expect(find.text('You are using the browser version'), findsNothing);
    expect(find.byType(GlassContainer), findsNothing);
  });
}
