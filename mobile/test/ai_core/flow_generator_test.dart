import 'package:flutter_test/flutter_test.dart';

import '../../ai-core/flow_generator.dart';

void main() {
  group('FlowGenerator.generateBusinessFlows (multi-FLOW per file)', () {
    // PERCHÉ: test end-to-end sul generatore: legge `mobile/lib` (CWD del test
    // = root del package) ed è l'unico modo affidabile di verificare il
    // raggruppamento reale senza esporre helper privati.
    final output = FlowGenerator().generateBusinessFlows();

    String sectionOf(String heading) {
      final start = output.indexOf('## $heading');
      if (start < 0) return '';
      final after = output.substring(start + '## $heading'.length);
      final next = after.indexOf('\n## ');
      return next < 0 ? after : after.substring(0, next);
    }

    test('wallet_repository: il secondo flusso non è più collassato nel primo',
        () {
      // PERCHÉ (regressione multi-FLOW): prima del fix, in un file con più
      // `// FLOW:` tutte le chiamate finivano nel PRIMO flusso → il flusso
      // "Import Wallet Watch-only" non compariva mai.
      expect(output, contains('## Gestione Wallet'));
      expect(output, contains('## Import Wallet Watch-only'));
    });

    test('il flusso Import Wallet Watch-only è separato e contiene i passi '
        'watch-only del repository', () {
      final gestione = sectionOf('Gestione Wallet');
      final watchOnly = sectionOf('Import Wallet Watch-only');

      expect(gestione, contains('encryptSeed'));
      expect(watchOnly, contains('deriveWatchOnlyData'));
      expect(watchOnly, contains('upsertWallet'));
      // NOTA: deriveWatchOnlyData può comparire ANCHE nel bucket directory
      // "Gestione Wallet" (es. wallet_detail_screen la chiama prima della sua
      // FLOW a riga 831) — regola: chiamate prima della prima FLOW → fallback
      // directory-driven. L'asserzione negativa è volutamente assente.
    });

    test('i flussi storici principali restano presenti (nessuna regressione)',
        () {
      for (final flow in [
        'Gestione Wallet',
        'Import Wallet Watch-only',
        'Servizi Core',
        'Onboarding',
      ]) {
        expect(output, contains('## $flow'), reason: 'flusso mancante: $flow');
      }
    });

    test('il percorso di spesa è un flusso business reale (Invio Transazione)',
        () {
      // PERCHÉ (contratto BUSINESS_FLOWS): il flusso di spesa (quello toccato
      // dall'audit di sicurezza) deve comparire con i passi reali, non essere
      // sepolto nel bucket per-directory.
      final invio = sectionOf('Invio Transazione Wallet');
      expect(invio, contains('decryptSeed'));
      expect(invio, contains('buildSignAndSend'));
      expect(invio, isNot(contains('Note over All: Nessun passo')));
    });

    test('home_screen: la creazione wallet ha il passo business reale', () {
      final creazione = sectionOf('Creazione Wallet con Backup proattivo');
      expect(creazione, contains('createWallet'));
      expect(creazione, isNot(contains('Note over All: Nessun passo')));
    });
  });
}
