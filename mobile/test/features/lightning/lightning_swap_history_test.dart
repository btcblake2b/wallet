import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_session_store.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_swap_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/swap_history_tile.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockSwapService extends Mock implements SwapService {}

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockStorage extends Mock implements FlutterSecureStorage {}

/// Storico delle transazioni via provider nella schermata swap (P9):
/// la sezione elenca le sessioni e il tap apre il dettaglio.
///
/// // PERCHÉ (07/10/2026): l'utente chiedeva di rivedere i pagamenti fatti col
/// // provider — questo test copre il percorso completo lista → dettaglio.
void main() {
  const fundingTxid =
      'a539bc0431d1bc0a86d416677f0197fd4688695863eca9eb49704343bc818605';

  setUpAll(() {
    // mocktail: serve un valore di fallback per i matcher `any()` sui tipi
    // non primitivi usati negli stub (storage e blob di recupero).
    registerFallbackValue('');
    registerFallbackValue(
      SwapSession(
        swapId: 'x',
        invoice: 'lnbc1',
        paymentHashHex: 'ab' * 32,
        fundingAmountSats: 1,
        cltvHeight: 1,
        fundingDeadlineHeight: 1,
        claimPubkeyHex: '02${'11' * 32}',
        refundPubkeyHex: '02${'22' * 32}',
        refundKeyIndex: 0,
        htlcAddress: 'bc1q',
        witnessScriptHex: '00',
        providerPubkey: 'cd' * 32,
        relays: const [],
        state: SwapClientState.completed,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  SwapSession session() => const SwapSession(
        swapId: '76794282bb68bbf0e48ce2d9eb949cb1',
        invoice: 'lnbc50010n1p426phesp5w4qwljzhdj8lyd5mtxpeezt49zu3w3224x',
        paymentHashHex: '64d69bcbfb12c2200947a52c63e5aec7'
            'f6ba4fc96cebd3d4f6dd14adf728a039',
        fundingAmountSats: 5251,
        amountSats: 5001,
        cltvHeight: 972919,
        fundingDeadlineHeight: 972911,
        claimPubkeyHex: '0291d1fca1a250bfd426b3276fa1a4001'
            '8d4a0bf3fb46b8e748c5892066d18b296',
        refundPubkeyHex: '03b3c027ebd87279243821556d9e308f1'
            '398b7746809d131ed3e571355af98913a',
        refundKeyIndex: 1,
        htlcAddress:
            'bc1qnv256rfn79vy2phzm2kwa5ku3wc0yvwgwqzzvxwa6qahruxx502qnj8c98',
        witnessScriptHex: '63a82064d69bcb',
        providerPubkey: '91d1fca1a250bfd426b3276fa1a40018d4a0b'
            'f3fb46b8e748c5892066d18b296',
        relays: ['wss://relay.primal.net'],
        walletId: 'w1',
        walletName: 'Wallet 1',
        state: SwapClientState.completed,
        createdAt: 1789724469,
        updatedAt: 1789725309,
        fundingTxid: fundingTxid,
        fundingVout: 0,
        errorCode: 'PAYMENT_FAILED',
        errorMessage: 'lightning-cli pay fallito (exit 1): …',
      );

  testWidgets('lo storico elenca le sessioni e il tap apre il dettaglio',
      (tester) async {
    final storage = MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (invocation) async =>
          invocation.namedArguments[#key] == 'swap_sessions'
              ? jsonEncode([session().toJson()])
              : null,
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    final service = MockSwapService();
    when(() => service.sessions)
        .thenReturn(SwapSessionStore(storage: storage));
    when(() => service.restoreConnection()).thenAnswer((_) async => null);
    when(() => service.knownProviderUris()).thenAnswer((_) async => []);
    when(() => service.probeProvider(any())).thenAnswer((_) async => false);
    when(() => service.exportRecoveryBlob(any()))
        .thenReturn('swaprecover1.eyJzd2FwX2lkIjoiNzY3OTQyODIifQ==');

    final wallet = WalletRecord(
      walletId: 'w1',
      encryptedSeed: 'enc',
      publicAddress: 'bc1qexamplewalletaddress000000000000000000000',
      deviceId: 'device-1',
      createdAt: DateTime.utc(2026, 1, 1),
      name: 'Wallet 1',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningSwapScreen(
          swapService: service,
          wallets: [wallet],
          walletRepository: MockWalletRepository(),
          bitcoinService: MockBitcoinService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Swap history'), findsOneWidget);
    expect(find.byType(SwapHistoryTile), findsOneWidget);
    // Importo della INVOICE (quanto è stato pagato), non il totale bloccato.
    expect(find.text('5,001 sat'), findsOneWidget);

    await tester.tap(find.byType(SwapHistoryTile));
    await tester.pumpAndSettle();

    expect(find.text('Swap details'), findsOneWidget);
    // Il dettaglio mostra il motivo localizzato dell'errore, non il testo grezzo.
    expect(find.textContaining('could not pay this invoice'), findsOneWidget);
    expect(find.text('Payment hash'), findsOneWidget);
  });
}
