import 'nostr_event.dart';

/// Trasporto verso un relay Nostr.
///
/// // PERCHÉ: astrazione iniettabile — il client NWC/NCC parla con questa
/// interfaccia sia in produzione (WebSocket) sia nei test (fake transport).
abstract class NostrTransport {
  /// True se il canale è aperto e pronto.
  bool get isConnected;

  /// Istante dell'ultima connessione riuscita (null se disconnesso).
  ///
  /// // PERCHÉ: un socket può morire in silenzio (standby, NAT half-open →
  /// "zombie"): resta `isConnected=true` ma non riceve più nulla. Esporre
  /// l'età permette al service di riciclare la connessione in anticipo.
  DateTime? get connectedSince;

  /// Apre la connessione verso [relayUrl] (wss://…).
  Future<void> connect(String relayUrl);

  /// Pubblica un evento firmato sul relay.
  Future<void> publish(NostrEvent event);

  /// Invia una REQ con i [filters] e ritorna lo stream degli eventi ricevuti.
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters);

  /// Chiude la connessione.
  Future<void> close();
}
