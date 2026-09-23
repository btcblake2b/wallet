import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';

import 'history_export.dart';

/// Consegna un export testuale all'utente (variante mobile/desktop).
///
/// // PERCHÉ: la clipboard è l'unico canale di "salvataggio" che non richiede
/// dipendenze aggiuntive né permessi di storage. Il nome file suggerito è
/// mostrato in UI insieme all'esito, così l'utente sa come nominare il file.
Future<ExportDelivery> deliverHistoryExport({
  required String content,
  required String fileName,
  required String mimeType,
}) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (kDebugMode) {
    debugPrint(
      '[LoopEngineer] export $mimeType ($fileName) copiato negli appunti '
      '(${content.length} caratteri)',
    );
  }
  return ExportDelivery.copied;
}
