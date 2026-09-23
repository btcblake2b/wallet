import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:nwc_cln_bridge/src/cln/cln_api.dart';
import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:nwc_cln_bridge/src/swap/chain_api.dart';
import 'package:nwc_cln_bridge/src/swap/swap_models.dart';

/// Fake CLN: risposte per metodo, storico chiamate, guasti forzati.
///
/// PERCHÉ: il servizio swap non deve MAI toccare la rete nei test — e le
/// chiamate (pay/decode/listpays/newaddr) vanno ispezionate.
class FakeCln implements ClnApi {
  final Map<String, Map<String, dynamic>> responses = {};
  final Set<String> failingMethods = {};
  final List<String> calls = [];
  final List<Map<String, dynamic>> callParams = [];

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add(method);
    callParams.add(params);
    if (failingMethods.contains(method)) {
      throw RpcError('OTHER', 'guasto simulato su $method');
    }
    final r = responses[method];
    if (r == null) {
      throw RpcError('OTHER', 'comando non simulato: $method');
    }
    return r;
  }
}

/// Fake chain: stato iniettato dai test, trasmissioni registrate.
class FakeChain implements ChainApi {
  int tip = 972000;
  bool failing = false;
  final Map<String, ChainTxStatus> statuses = {};
  final Map<String, String> rawTxs = {};
  final Map<String, List<ChainOutspend>> outspendMap = {};
  final List<String> broadcasts = [];
  String lastBroadcastTxid = '';

  @override
  Future<int> tipHeight() async {
    if (failing) throw ChainApiException('chain simulata giù');
    return tip;
  }

  @override
  Future<ChainTxStatus?> txStatus(String txid) async => statuses[txid];

  @override
  Future<String?> txHex(String txid) async => rawTxs[txid];

  @override
  Future<List<ChainAddressTx>> addressTxs(String address) async => const [];

  @override
  Future<List<ChainOutspend>> outspends(String txid) async =>
      outspendMap[txid] ?? const [];

  @override
  Future<String> broadcast(String rawTxHex) async {
    broadcasts.add(rawTxHex);
    lastBroadcastTxid = 'cd' * 32;
    return lastBroadcastTxid;
  }
}

/// Fixture condivise dei test swap (provider).
abstract final class SwapFixtures {
  /// Preimage fissa; il payment_hash è il suo SHA256 (invariante del provider).
  static const preimageHex =
      'abababababababababababababababababababababababababababababababab';
  static final String paymentHashHex = BytesUtils.toHexString(
    QuickCrypto.sha256Hash(BytesUtils.fromHexString(preimageHex)),
  );

  /// Pubkey utente fittizia ma valida (33 byte compressi).
  static final String refundPubkeyHex = '02${'22' * 32}';

  static const String clientPubkey = 'cccccccccccccccccccccccccccccccc'
      'cccccccccccccccccccccccccccccccc';

  static const String bolt11 = 'lnbc50u1testinvoice';
  static const int nowSec = 1758100000;

  /// Node id fittizio del PROVIDER (il nodo che paga) — 66 hex.
  static final String providerNodeId = '0211${'11' * 31}';

  /// Node id fittizio del PAYEE della invoice (destinazione del pagamento).
  static final String payeeId = '0322${'22' * 31}';

  /// Risposta di `listpeerchannels` con un canale pronto (liquidità in uscita).
  static Map<String, dynamic> listPeerChannelsResponse({
    int spendableMsat = 30000000,
  }) =>
      {
        'channels': [
          {
            'state': 'CHANNELD_NORMAL',
            'short_channel_id': '972787x704x0',
            'spendable_msat': spendableMsat,
          },
        ],
      };

  /// Risposta di `getroutes` con una rotta presente (minima ma con `routes`).
  static Map<String, dynamic> getRoutesResponse() => {
        'probability_ppm': 1000000,
        'routes': [
          {'probability_ppm': 1000000, 'amount_msat': 5000000},
        ],
      };

  /// Pre-flight superato: risposte CLN "provider pronto" (getinfo + canali +
  /// rotta). // PERCHÉ (18/09/2026): quote/create chiamano la guardia di
  /// pagabilità — i test che arrivano al lock devono simulare un nodo pronto.
  static void primeReady(FakeCln cln) {
    cln.responses['getinfo'] = {'id': providerNodeId};
    cln.responses['listpeerchannels'] = listPeerChannelsResponse();
    cln.responses['getroutes'] = getRoutesResponse();
  }

  /// Indirizzo mainnet valido (vettore BIP-173) per il claim.
  static const String destinationAddress =
      'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4';

  /// Risposta di `decode` (CLN) per l'invoice di test.
  static Map<String, dynamic> decodeResponse({
    Object? amountMsat = 5000000,
    int createdAt = nowSec,
    int expiry = 3600,
  }) =>
      {
        'payment_hash': paymentHashHex,
        'payee': payeeId,
        'amount_msat': amountMsat,
        'expiry': expiry,
        'created_at': createdAt,
      };

  /// Raw hex di una tx che paga [amountSats] allo scriptPubKey dell'HTLC.
  static String fundingTxHex(String witnessScriptHex, int amountSats) {
    final program = QuickCrypto.sha256Hash(
      BytesUtils.fromHexString(witnessScriptHex),
    );
    final spkHex = '0020${BytesUtils.toHexString(program)}';
    final tx = BtcTransaction(
      inputs: [TxInput(txId: 'aa' * 32, txIndex: 0)],
      outputs: [
        TxOutput(
          amount: BigInt.from(amountSats),
          scriptPubKey: Script.deserialize(
            bytes: BytesUtils.fromHexString(spkHex),
          ),
        ),
      ],
    );
    return tx.toHex();
  }

  /// Sessione syntetica per test di store/servizio.
  static SwapSession session({
    required String id,
    String? paymentHashHex,
    SwapState state = SwapState.awaitingFunding,
  }) =>
      SwapSession(
        id: id,
        clientPubkey: clientPubkey,
        invoice: bolt11,
        paymentHashHex: paymentHashHex ?? 'aa' * 32,
        amountMsat: 5000000,
        fundingAmountSats: 5250,
        serviceFeeSats: 0,
        claimFeeSats: 250,
        cltvHeight: 972144,
        claimPubkeyHex: '02${'33' * 32}',
        refundPubkeyHex: refundPubkeyHex,
        htlcAddress: 'bc1qfixturesession',
        witnessScriptHex: '63a8ac',
        fundingDeadlineHeight: 972136,
        state: state,
        createdAt: nowSec,
        updatedAt: nowSec,
      );
}
