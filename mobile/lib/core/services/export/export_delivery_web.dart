// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';

import 'history_export.dart';

/// Consegna un export testuale all'utente (variante web/PWA).
///
/// // PERCHÉ: sul web la clipboard da sola non basta (non c'è un file manager):
/// si fa ENTRAMBE — copia negli appunti (incolla immediato) e download del file
/// tramite un Blob locale. Il contenuto non lascia mai il browser.
Future<ExportDelivery> deliverHistoryExport({
  required String content,
  required String fileName,
  required String mimeType,
}) async {
  // PERCHÉ: il click di download avviene PRIMA di ogni `await` — un'attesa
  // consuma il gesto utente e alcuni browser bloccano il download programmatico
  // (o lo presentano come popup). La clipboard viene dopo, senza fretta.
  final blob = html.Blob(<String>[content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();

  await Clipboard.setData(ClipboardData(text: content));

  // PERCHÉ: la revoca arriva DOPO — revocare l'object URL subito dopo il click
  // può interrompere il download in alcuni browser.
  html.Url.revokeObjectUrl(url);

  if (kDebugMode) {
    debugPrint(
      '[LoopEngineer] export $mimeType ($fileName) scaricato dal browser '
      '(${content.length} caratteri)',
    );
  }
  return ExportDelivery.downloaded;
}
