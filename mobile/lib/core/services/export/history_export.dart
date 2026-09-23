import 'dart:convert';

import '../../models/transaction_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXPORT STORICO — logica PURA (CSV / JSON)
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ: la formattazione è separata dalla consegna (appunti/download, vedi
// `export_delivery.dart`) così è testabile senza mock, senza piattaforma e
// senza I/O. Tutto avviene in memoria: l'export NON tocca la rete (privacy).
//
// // PERCHÉ: le chiavi (header CSV e nomi campo JSON) sono in inglese e
// snake_case, NON passano da AppLocalizations: sono un contratto per fogli di
// calcolo e script dell'utente, non testo di interfaccia.

/// Intestazione del CSV, nell'ordine esatto delle colonne esportate.
const List<String> kHistoryCsvHeader = <String>[
  'date_iso',
  'status',
  'direction',
  'amount_sats',
  'fee_sats',
  'confirmations',
  'block_height',
  'txid',
  'note',
];

/// Esito della consegna di un export.
enum ExportDelivery {
  /// Contenuto copiato negli appunti (mobile/desktop).
  copied,

  /// Download del file avviato dal browser (web/PWA).
  downloaded,
}

/// Stato della transazione in forma stabile per l'export.
/// // PERCHÉ: `TransactionRecord` espone flag booleani (isPending/isOrphan/
/// isEvicted) — qui diventano un'unica etichetta leggibile da uno script.
String historyExportStatus(TransactionRecord tx) {
  if (tx.isEvicted) return 'evicted';
  if (tx.isOrphan) return 'orphan';
  if (tx.isPending) return 'pending';
  return 'confirmed';
}

/// Direzione in forma stabile per l'export.
String historyExportDirection(TransactionRecord tx) =>
    tx.direction == TxDirection.incoming ? 'incoming' : 'outgoing';

/// Riga di transazione come mappa (usata dal JSON).
Map<String, dynamic> historyExportMap(
  TransactionRecord tx, {
  String? Function(String txid)? noteFor,
}) {
  return <String, dynamic>{
    'date_iso': tx.timestamp?.toUtc().toIso8601String(),
    'status': historyExportStatus(tx),
    'direction': historyExportDirection(tx),
    'amount_sats': tx.amountSats,
    // PERCHÉ: qui i valori ignoti restano `null` (JSON ha il tipo nullo), a
    // differenza del CSV dove il campo vuoto è l'unica rappresentazione.
    'fee_sats': tx.feeSats,
    'confirmations': tx.confirmations,
    'block_height': tx.blockHeight,
    'txid': tx.txid,
    'note': noteFor?.call(tx.txid),
  };
}

/// Costruisce lo storico in CSV (RFC 4180).
///
/// Ogni riga — intestazione compresa — termina con CRLF; una lista vuota
/// produce la sola intestazione. Le note dell'utente sono incluse tramite
/// [noteFor] (chiave = txid), così l'export resta coerente con ciò che
/// l'utente vede in app.
String buildHistoryCsv(
  List<TransactionRecord> transactions, {
  String? Function(String txid)? noteFor,
}) {
  final buffer = StringBuffer()..write(kHistoryCsvHeader.join(','));
  for (final tx in transactions) {
    buffer
      ..write('\r\n')
      ..write(_csvRow(tx, noteFor: noteFor));
  }
  // PERCHÉ (RFC 4180): il terminatore CRLF è anche la forma che Excel e
  // LibreOffice interpretano senza chiedere nulla all'utente.
  buffer.write('\r\n');
  return buffer.toString();
}

/// Costruisce lo storico in JSON indentato.
///
/// [exportedAt] è un parametro (non `DateTime.now()` interno) per rendere
/// l'output deterministico nei test.
String buildHistoryJson(
  List<TransactionRecord> transactions, {
  required String walletName,
  required DateTime exportedAt,
  String? Function(String txid)? noteFor,
}) {
  final payload = <String, dynamic>{
    'wallet': walletName,
    'network': 'bitcoin-blake2b',
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'count': transactions.length,
    'transactions': <Map<String, dynamic>>[
      for (final tx in transactions) historyExportMap(tx, noteFor: noteFor),
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Nome file suggerito: `btc-blake2b-<wallet>-<yyyyMMdd-HHmm>.<ext>`.
String historyFileName(
  String walletName, {
  required bool json,
  required DateTime now,
}) {
  final extension = json ? 'json' : 'csv';
  return 'btc-blake2b-${slugifyWalletName(walletName)}'
      '-${_utcStamp(now)}.$extension';
}

/// Slug del nome wallet: minuscolo, `[a-z0-9]` con `-`; fallback `wallet`.
/// // PERCHÉ: il nome è scelto dall'utente (spazi, accenti, emoji) e finisce in
/// un nome di file che deve restare portabile su ogni filesystem.
String slugifyWalletName(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'wallet' : slug;
}

String _csvRow(
  TransactionRecord tx, {
  String? Function(String txid)? noteFor,
}) {
  final fields = <String>[
    tx.timestamp?.toUtc().toIso8601String() ?? '',
    historyExportStatus(tx),
    historyExportDirection(tx),
    '${tx.amountSats}',
    tx.feeSats?.toString() ?? '',
    '${tx.confirmations}',
    tx.blockHeight?.toString() ?? '',
    tx.txid,
    noteFor?.call(tx.txid) ?? '',
  ];
  return fields.map(_escapeCsvField).join(',');
}

/// Escaping RFC 4180: campo quotato se contiene virgola, virgolette, CR o LF;
/// le virgolette interne si raddoppiano.
/// // PERCHÉ: una nota utente con la virgola (o un a capo) altrimenti
/// sposterebbe le colonne e romperebbe il file per il foglio di calcolo.
String _escapeCsvField(String value) {
  final needsQuotes = value.contains(',') ||
      value.contains('"') ||
      value.contains('\r') ||
      value.contains('\n');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String _utcStamp(DateTime now) {
  final utc = now.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}'
      '-${two(utc.hour)}${two(utc.minute)}';
}
