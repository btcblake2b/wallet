import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_address.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/wallet_addresses_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBitcoinService extends Mock implements BitcoinService {}

/// Schermata "Indirizzi e UTXO": verifica la sola LETTURA (stato indirizzi,
/// tab UTXO dai dati passati, errore esplicito con retry, copia).
void main() {
  setUpAll(() {
    registerFallbackValue(
      WalletRecord(
        walletId: 'fallback',
        encryptedSeed: '',
        publicAddress: '',
        deviceId: '',
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  final wallet = WalletRecord(
    walletId: 'w1',
    encryptedSeed: 'enc',
    publicAddress: 'bc1qfirstaddress0000000000000000000000000',
    deviceId: 'd1',
    createdAt: DateTime(2024, 1, 1),
  );

  const fundedAddress = 'bc1qfunded00000000000000000000000000000';
  const unusedAddress = 'bc1qunused00000000000000000000000000000';

  const addresses = <WalletAddress>[
    WalletAddress(
      address: fundedAddress,
      branch: WalletAddressBranch.external,
      index: 0,
      derivationPath: "m/84'/0'/0'/0/0",
      balanceSats: 2121,
      txCount: 1,
    ),
    WalletAddress(
      address: unusedAddress,
      branch: WalletAddressBranch.external,
      index: 1,
      derivationPath: "m/84'/0'/0'/0/1",
      balanceSats: 0,
      txCount: 0,
    ),
  ];

  late MockWalletRepository repo;
  late MockBitcoinService service;

  setUp(() {
    repo = MockWalletRepository();
    service = MockBitcoinService();
    when(() => repo.decryptSeed(any())).thenAnswer((_) async => 'mnemonic');
  });

  void stubAddresses(List<WalletAddress> result) {
    when(
      () => service.fetchWalletAddresses(
        mnemonic: any(named: 'mnemonic'),
        derivationPath: any(named: 'derivationPath'),
      ),
    ).thenAnswer((_) async => result);
  }

  Widget wrap({List<UtxoInfo>? utxos}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: WalletAddressesScreen(
          wallet: wallet,
          walletRepository: repo,
          bitcoinService: service,
          initialUtxos: utxos,
        ),
      );

  /// I test degli appunti hanno bisogno di un handler sul canale di piattaforma.
  List<MethodCall> mockClipboard(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }

  testWidgets('mostra indirizzi con stato, path e ramo', (tester) async {
    stubAddresses(addresses);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Addresses & UTXO'), findsOneWidget);
    expect(find.text('Receive (/0)'), findsOneWidget);
    expect(find.text('With funds'), findsOneWidget);
    expect(find.text('Never used'), findsOneWidget);
    expect(find.text("m/84'/0'/0'/0/0"), findsOneWidget);
  });

  testWidgets('tab UTXO: valore, conferme e nessun empty state', (tester) async {
    stubAddresses(addresses);
    final utxo = UtxoInfo(
      txid: 'a' * 64,
      vout: 0,
      valueSat: 2121,
      ownerAddress: fundedAddress,
      ownerDerivationPath: "m/84'/0'/0'/0/0",
      confirmations: 3,
    );

    await tester.pumpWidget(wrap(utxos: [utxo]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UTXO'));
    await tester.pumpAndSettle();

    expect(find.text('3 confirmations'), findsOneWidget);
    expect(find.text('No spendable UTXO found'), findsNothing);
    expect(find.textContaining('/0/0'), findsWidgets);
  });

  testWidgets('tab UTXO senza UTXO → empty state', (tester) async {
    stubAddresses(addresses);
    await tester.pumpWidget(wrap(utxos: const []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UTXO'));
    await tester.pumpAndSettle();

    expect(find.text('No spendable UTXO found'), findsOneWidget);
  });

  testWidgets('errore di rete → stato di errore con retry (mai 0 finto)',
      (tester) async {
    when(
      () => service.fetchWalletAddresses(
        mnemonic: any(named: 'mnemonic'),
        derivationPath: any(named: 'derivationPath'),
      ),
    ).thenThrow(Exception('boom'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('Error deriving addresses'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tap su copia → indirizzo negli appunti', (tester) async {
    final calls = mockClipboard(tester);
    stubAddresses(addresses);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.copy).first);
    await tester.pumpAndSettle();

    expect(
      calls.where((c) => c.method == 'Clipboard.setData'),
      isNotEmpty,
    );
  });
}
