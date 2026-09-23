import 'package:nwc_cln_bridge/src/cln/cln_cli.dart';
import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:test/test.dart';

/// Parsing dell'output di `lightning-cli` (ClnCliApi): fail-closed.
void main() {
  group('buildLightningCliArgs', () {
    test('forma -k base senza lightning-dir', () {
      final args = buildLightningCliArgs(
        method: 'decode',
        params: const {'string': 'lnbc1test'},
      );
      expect(args, ['-k', 'decode', 'string=lnbc1test']);
    });

    test('lightning-dir in testa, boolean e int serializzati', () {
      final args = buildLightningCliArgs(
        method: 'pay',
        params: const {'bolt11': 'lnbc1x', 'maxfee': 280, 'retry_for': 60},
        lightningDir: '/home/filippo/.lightning',
      );
      expect(args.first, '--lightning-dir=/home/filippo/.lightning');
      expect(args[1], '-k');
      expect(args[2], 'pay');
      expect(args, contains('maxfee=280'));
      expect(args, contains('retry_for=60'));
    });

    test('valori nullable → stringa vuota (parametro opzionale assente)', () {
      final args = buildLightningCliArgs(
        method: 'listpays',
        params: const {'payment_hash': null},
      );
      expect(args.last, 'payment_hash=');
    });
  });

  test('exit 0 + JSON oggetto → mappa', () {
    final res = parseLightningCliResult(
      method: 'decode',
      exitCode: 0,
      stdout: '{\n  "payment_hash": "ab",\n  "amount_msat": 1000\n}\n',
      stderr: '',
    );
    expect(res['payment_hash'], 'ab');
    expect(res['amount_msat'], 1000);
  });

  test('exit ≠ 0 + JSON errore → RpcError col messaggio del nodo', () {
    expect(
      () => parseLightningCliResult(
        method: 'pay',
        exitCode: 1,
        stdout: '',
        stderr: '{"code": 210, "message": "Could not find a route"}\n',
      ),
      throwsA(
        isA<RpcError>().having(
          (e) => e.message,
          'message',
          contains('Could not find a route'),
        ),
      ),
    );
  });

  test('codice errore STRINGA (commando/NIP-XX) preservato', () {
    expect(
      () => parseLightningCliResult(
        method: 'pay',
        exitCode: 1,
        stdout: '{"code": "RESTRICTED", "message": "not authorized"}\n',
        stderr: '',
      ),
      throwsA(isA<RpcError>().having((e) => e.code, 'code', 'RESTRICTED')),
    );
  });

  test('exit ≠ 0 senza JSON → RpcError con la traccia utile', () {
    expect(
      () => parseLightningCliResult(
        method: 'newaddr',
        exitCode: 1,
        stdout: '',
        stderr: 'lightning-cli: Connecting to \'…/lightning-rpc\': No such file',
      ),
      throwsA(
        isA<RpcError>().having(
          (e) => e.message,
          'message',
          contains('No such file'),
        ),
      ),
    );
  });

  test('exit 0 ma output non JSON → RpcError (mai silenziare)', () {
    expect(
      () => parseLightningCliResult(
        method: 'decode',
        exitCode: 0,
        stdout: 'warning: something',
        stderr: '',
      ),
      throwsA(isA<RpcError>()),
    );
  });

  test('righe di log del plugin (`# …`) prima del JSON → parse OK', () {
    // PERCHÉ (incidente 18/09/2026): il fork `.4` mescola log e JSON su stdout;
    // senza il filtro un comando RIUSCITO sembrava "output non JSON".
    final res = parseLightningCliResult(
      method: 'getroutes',
      exitCode: 0,
      stdout: '# Flow 0/1: 5001000msat/40 972800x175x0/0 -> 5001000msat/40 '
          '(prob=100.000%)\n{\n  "routes": [{"probability_ppm": 1000000}]\n}\n',
      stderr: '',
    );
    expect((res['routes'] as List).length, 1);
  });

  test('log del plugin + JSON di errore con exit ≠ 0 → RpcError col messaggio',
      () {
    expect(
      () => parseLightningCliResult(
        method: 'pay',
        exitCode: 1,
        stdout: '# getroute failed with maxparts=6, so retrying without that '
            'restriction\n'
            '{"code": 205, "message": "Unknown source node 02ab"}\n',
        stderr: '',
      ),
      throwsA(
        isA<RpcError>()
            .having((e) => e.message, 'message', contains('Unknown source node')),
      ),
    );
  });
}
