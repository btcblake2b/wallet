import '../../models/lightning_balance.dart';
import '../../models/lightning_channel.dart';
import '../../models/lightning_channel_fees.dart';
import '../../models/lightning_connection.dart';
import '../../models/lightning_forward.dart';
import '../../models/lightning_htlc.dart';
import '../../models/lightning_invoice.dart';
import '../../models/lightning_invoice_record.dart';
import '../../models/lightning_keysend_result.dart';
import '../../models/lightning_movement.dart';
import '../../models/lightning_network_node.dart';
import '../../models/lightning_node_address.dart';
import '../../models/lightning_node_info.dart';
import '../../models/lightning_node_stats.dart';
import '../../models/lightning_onchain_fees.dart';
import '../../models/lightning_onchain_result.dart';
import '../../models/lightning_peer.dart';
import '../../models/lightning_payment_record.dart';
import '../../models/lightning_payment_result.dart';
import '../../models/lightning_route.dart';
import '../../models/lightning_utxo.dart';

/// Stato della connessione verso il nodo Lightning remoto.
enum LightningConnectionState { disconnected, connecting, connected }

/// Errore del protocollo Lightning (codici dal nodo: RESTRICTED, OTHER, …).
class LightningException implements Exception {
  const LightningException(this.code, this.message);

  final String code;
  final String message;

  /// True se il nodo ha rifiutato per permessi mancanti (grant NCC/NWC assente
  /// per questa app): la UI mostra le istruzioni dedicate.
  bool get isPermissionDenied =>
      code.toUpperCase() == 'RESTRICTED' ||
      code.toUpperCase() == 'UNAUTHORIZED';

  @override
  String toString() => 'LightningException($code): $message';
}

/// Astrazione del client Lightning (nodo remoto via NWC/NCC).
///
/// // FLOW: Lightning via nodo remoto (NWC/NCC)
/// L'app NON è mai un nodo: nessun servizio in background, nessuna chiave
/// Lightning custodita — solo comandi verso un nodo esterno.
abstract class LightningService {
  LightningConnectionState get connectionState;
  bool get isConnected;

  /// Stream degli stati di connessione (per la UI).
  Stream<LightningConnectionState> get stateStream;

  /// Stream di "qualcosa è cambiato sul nodo" (notifiche NWC/NCC):
  /// la UI lo usa per ricaricare saldo/canali.
  Stream<void> get notifications;

  /// Connessione corrente (null se disconnesso).
  LightningConnection? get connection;

  Future<void> connect(LightningConnection connection);
  Future<void> disconnect();

  Future<LightningNodeInfo> getInfo();
  Future<int> getBalanceMsat();

  /// Saldo con breakdown on-chain/Lightning (fallback sul totale).
  ///
  /// // PERCHÉ (I1): il dashboard mostra i due saldi separati — se il nodo
  /// non espone il breakdown, `onchainMsat`/`lightningMsat` restano null.
  Future<LightningBalance> getBalance();

  /// Nuovo indirizzo on-chain del nodo per il deposito.
  ///
  /// [addressType] = `bech32` (default del nodo) oppure `p2tr` (taproot).
  Future<LightningNodeAddress> makeNewAddress({String? addressType});

  /// Stime fee on-chain (sat/vB) per l'invio dal nodo.
  Future<LightningOnchainFees> estimateOnchainFees();

  /// Invio on-chain dal nodo. [feeRateSatVb] null = scelta del nodo.
  ///
  /// // PERCHÉ: importo esplicito in sat — la conversione al protocollo
  /// (perkw) resta dentro il client, la UI ragiona in sat/vB.
  Future<LightningOnchainResult> payOnchain({
    required String address,
    required int amountSats,
    int? feeRateSatVb,
  });

  /// Indirizzi on-chain noti del nodo (deposito/audit).
  Future<List<LightningNodeAddress>> listAddresses();

  /// UTXO on-chain del nodo (su quali output poggia il saldo).
  Future<List<LightningUtxo>> listUtxos();

  /// Storico fatture del nodo, dalla più recente.
  Future<List<LightningInvoiceRecord>> listInvoices({
    int limit = 25,
    int offset = 0,
  });

  /// Singola fattura per `paymentHash` (o `label`): usata dal flusso Ricevi
  /// per sapere quando il pagamento è arrivato.
  Future<LightningInvoiceRecord> lookupInvoice({
    String? paymentHash,
    String? label,
  });

  /// Cancella una fattura NON pagata (in attesa o scaduta) dal nodo.
  ///
  /// // PERCHÉ: tiene pulito lo storico. Le fatture PAGATE non sono
  /// // cancellabili (ricevuta contabile del nodo): il bridge rifiuta.
  Future<void> deleteInvoice({String? paymentHash, String? label});

  /// Pagamenti in uscita del nodo (con fee), dal più recente.
  Future<List<LightningPaymentRecord>> listPays({
    int limit = 25,
    int offset = 0,
  });

  /// HTLC del canale: gli elementi con `pending = true` sono in corso.
  Future<List<LightningHtlc>> listPendingHtlcs();

  /// Policy di routing del canale (base, ppm, limiti HTLC, cltv, riserve).
  Future<LightningChannelFees> getChannelFees({required String channelId});

  /// Aggiorna la policy di routing: si inviano solo i campi valorizzati.
  ///
  /// // PERCHÉ: `cltvDelta` non è modificabile (setchannel non lo prevede) —
  /// la UI lo mostra ma non lo invia mai.
  Future<LightningChannelFees> setChannelFees({
    required String channelId,
    int? baseMsat,
    int? ppm,
    int? htlcMinMsat,
    int? htlcMaxMsat,
  });

  /// Statistiche economiche del nodo e plugin (NCC `get_node_stats`).
  ///
  /// // PERCHÉ (I3e): risponde a "il nodo guadagna o perde?" con l'aggregato
  /// dei tag di accounting del nodo (depositi, spese on-chain, pagamenti).
  Future<LightningNodeStats> getNodeStats();

  /// Forwarding instradati dal nodo, dal più recente (NCC `list_forwards`).
  Future<List<LightningForward>> listForwards({
    int limit = 25,
    int offset = 0,
  });

  /// Info sul nodo di rete nel gossip (NCC `get_node_info`).
  ///
  /// // PERCHÉ: serve a mostrare alias/indirizzi della controparte — e a
  /// dare un nome al destinatario prima di un keysend.
  Future<LightningNetworkNode> getNodeInfo(String nodeId);

  /// Percorso verso una destinazione, senza muovere fondi (NCC `get_route`).
  ///
  /// // PERCHÉ: diagnosi dei pagamenti — dice da dove passerebbe il pagamento
  /// e quanto costerebbe PRIMA di inviarlo.
  Future<LightningRoute> getRoute({
    required String destination,
    required int amountMsat,
    int? riskFactor,
  });

  /// Pagamento a un nodo senza invoice (NWC `keysend`).
  ///
  /// // PERCHÉ: muove fondi SUBITO e non è reversibile — la UI deve far vedere
  /// destinazione, importo e fee massima prima di inviare.
  Future<LightningKeysendResult> sendKeysend({
    required String destination,
    required int amountSats,
    int? maxFeeMsat,
    int? retryForSeconds,
  });

  /// Peer del nodo (NCC `list_peers`).
  Future<List<LightningPeer>> listPeers();

  /// Movimenti del nodo (on-chain + Lightning), dal più recente.
  ///
  /// [limit] è il massimo per pagina (il bridge lo limita a 200) e [offset]
  /// serve alla paginazione: lo storico può essere lungo, quindi non si carica
  /// mai tutto in una volta.
  Future<List<LightningMovement>> listTransactions({
    int limit = 50,
    int offset = 0,
  });

  /// Connessione a un peer (NCC `connect_peer`).
  Future<void> connectPeer({required String nodeId, String? host});

  /// Disconnessione da un peer (NCC `disconnect_peer`).
  Future<void> disconnectPeer({required String nodeId, bool force = false});

  Future<LightningInvoice> makeInvoice({
    required int amountMsat,
    String? description,
  });
  Future<LightningPaymentResult> payInvoice(String bolt11);
  Future<List<LightningChannel>> listChannels();
  Future<void> openChannel({
    required String nodeId,
    required int amountSats,
    String? host,
    bool isPrivate,
  });
  Future<void> closeChannel({
    required String channelId,
    bool force,
  });
}
