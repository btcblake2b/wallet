import 'dart:convert';
import 'dart:io';

import '../logger.dart';
import 'swap_config.dart';

/// Ammissione dei client del provider swap (B1 + auto-admit, 07/10/2026).
///
/// // PERCHÉ: la chiave del client è casuale per INSTALLAZIONE e l'utente non
/// // la vede → una allowlist mantenuta a mano non è praticabile in produzione.
/// // Qui la lista si popola da sé al primo contatto (`clients.autoAdmit`),
/// // con tetti giornalieri e totali, e resta la possibilità di espellere una
/// // chiave via `deniedClientPubkeys`. La denylist vince SEMPRE (anche su
/// // allowlist statica): un'espulsione non deve richiedere di riscrivere la
/// // config. Il modo aperto puro resta dichiarato con `allowAnyClient`.
///
/// Fail-closed: pubkey non esadecimale, denylist, tetti raggiunti o
/// auto-admit spento → il client NON viene ammesso.
class SwapClientAdmission {
  SwapClientAdmission({
    required SwapConfig config,
    Logger? logger,
    DateTime Function()? clock,
  })  : _config = config,
        _logger = logger ?? Logger(),
        _clock = clock ?? DateTime.now;

  final SwapConfig _config;
  final Logger _logger;
  final DateTime Function() _clock;

  /// Ammissioni automatiche persistite: pubkey → epoch secondi.
  final Map<String, int> _admitted = {};

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Client ammessi automaticamente (allowlist statica esclusa).
  int get admittedCount => _admitted.length;

  /// Carica le ammissioni dal file (assente = nessuna). Idempotente.
  Future<void> load() async {
    final path = _config.clientsFile;
    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final admitted = decoded['admitted'];
      if (admitted is! Map) return;
      var purged = 0;
      admitted.forEach((key, value) {
        final pubkey = '$key'.toLowerCase();
        final ts = (value as num?)?.toInt();
        // PERCHÉ: una entry corrotta non deve impedire il load delle altre:
        // gli altri client continuano a funzionare (fail-closed sul singolo).
        if (ts == null || !_hex64.hasMatch(pubkey)) return;
        if (_config.deniedClientPubkeys.contains(pubkey)) {
          purged++;
          return;
        }
        _admitted[pubkey] = ts;
      });
      _logger.info(
        'swapd: client auto-ammessi caricati: ${_admitted.length}'
        '${purged > 0 ? ' ($purged espulsi dalla denylist)' : ''}',
      );
      if (purged > 0) {
        await _save();
      }
    } catch (e) {
      _logger.warn('swapd: clientsFile illeggibile ($path): $e');
    }
  }

  /// True se [pubkeyHex] può essere servito (senza registrare nulla).
  bool isAllowed(String pubkeyHex) {
    final pk = pubkeyHex.toLowerCase();
    if (_config.deniedClientPubkeys.contains(pk)) return false;
    if (_config.allowAnyClient) return true;
    if (_config.allowedClientPubkeys.contains(pk)) return true;
    return _admitted.containsKey(pk);
  }

  /// Ammette [pubkeyHex] (registrando le nuove ammissioni automatiche).
  ///
  /// Ritorna false se il client va ignorato: denylist, chiave non valida,
  /// auto-admit spento o tetti raggiunti.
  Future<bool> admit(String pubkeyHex) async {
    final pk = pubkeyHex.toLowerCase();
    if (_config.deniedClientPubkeys.contains(pk)) {
      _logger.warn('swapd: client in denylist ignorato: ${_short(pk)}');
      return false;
    }
    if (_config.allowAnyClient) return true;
    if (_config.allowedClientPubkeys.contains(pk)) return true;
    if (_admitted.containsKey(pk)) return true;
    if (!_config.autoAdmit) return false;
    if (!_hex64.hasMatch(pk)) {
      _logger.warn('swapd: client con chiave non valida ignorato');
      return false;
    }
    if (_admitted.length >= _config.autoAdmitMaxTotal) {
      _logger.warn(
        'swapd: auto-admit saturo (${_admitted.length}/'
        '${_config.autoAdmitMaxTotal} totali): nuovo client ignorato',
      );
      return false;
    }
    final cutoff = _nowSec() - 86400;
    final last24h = _admitted.values.where((ts) => ts >= cutoff).length;
    if (last24h >= _config.autoAdmitMaxPerDay) {
      _logger.warn(
        'swapd: auto-admit saturo ($last24h/'
        '${_config.autoAdmitMaxPerDay} nelle ultime 24h): nuovo client '
        'ignorato (${_short(pk)})',
      );
      return false;
    }
    _admitted[pk] = _nowSec();
    await _save();
    _logger.info(
      'swapd: cliente ammesso automaticamente ${_short(pk)} '
      '($last24h + 1/24h, ${_admitted.length}/${_config.autoAdmitMaxTotal} '
      'totali)',
    );
    return true;
  }

  /// Persistenza ATOMICA (tmp + rename), come [SwapStore]: un crash a metà
  /// scrittura non deve corrompere la lista (i client ammessi restano tali).
  Future<void> _save() async {
    final path = _config.clientsFile;
    if (path == null) return;
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final tmp = File('$path.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'admitted': _admitted,
      }),
      flush: true,
    );
    await tmp.rename(path);
  }

  int _nowSec() => _clock().millisecondsSinceEpoch ~/ 1000;

  String _short(String pubkey) =>
      pubkey.length > 12 ? '${pubkey.substring(0, 12)}…' : pubkey;
}
