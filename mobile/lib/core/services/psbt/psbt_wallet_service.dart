import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/digests/ripemd160.dart';

import '../../config/bitcoin_network_config.dart';
import '../../models/send_output.dart';
import '../../models/wallet_record.dart';
import '../../utils/coinbase_maturity.dart';
import '../../utils/crypto_utils.dart';
import '../bitcoin_service.dart';
import '../pending_send_registry.dart';
import '../rbf_params_registry.dart';
import 'psbt_service.dart';

/// Bozza di PSBT pronta per essere mostrata e trasportata (QR/testo).
///
/// // PERCHÉ: la UI deve poter dire "fee X, resto Y, N input" PRIMA che
/// // l'utente firmi su un altro dispositivo: sono gli stessi numeri che poi
/// // finiscono nella transazione, calcolati dall'unica economia del servizio.
class PsbtDraft {
  const PsbtDraft({
    required this.psbtBase64,
    required this.feeSats,
    required this.changeSats,
    required this.inputCount,
    required this.outputCount,
    required this.totalOutSats,
    this.changeAddress,
  });

  /// PSBT BIP-174 v0 **non firmata**, base64.
  final String psbtBase64;

  /// Fee effettiva implicita (Σ input − Σ output).
  final int feeSats;

  /// Resto che torna al wallet; 0 quando il residuo è finito nella fee.
  final int changeSats;

  final int inputCount;

  /// Output totali: destinatari + eventuale resto.
  final int outputCount;

  /// Somma dei soli destinatari.
  final int totalOutSats;

  /// Indirizzo di resto usato (null se non c'è output di resto).
  final String? changeAddress;

  @override
  String toString() =>
      'PsbtDraft(inputs=$inputCount, outputs=$outputCount, fee=$feeSats, '
      'change=$changeSats)';
}

/// Ponte tra il wallet (hot o watch-only) e il codec PSBT.
///
/// // PERCHÉ (P4/M1b, 26/10): il codec sa costruire PSBT solo da dati on-chain,
/// // ma la SCELTA degli input, il resto su `/1/N` e la fee devono essere gli
/// // stessi dell'invio diretto (`BitcoinService.buildSignAndSendBatch`).
/// // Duplicarli nella UI creerebbe due economie divergenti; qui c'è l'unica
/// // copia del servizio, e un test di equivalenza la blocca byte per byte.
class PsbtWalletService {
  PsbtWalletService({BitcoinService? bitcoinService})
      : _bitcoin = bitcoinService ?? BitcoinService();

  final BitcoinService _bitcoin;

  /// Soglia dust: identica a `_buildAndSignTx` / [SendOutput.dustLimitSats].
  static const int dustLimitSats = SendOutput.dustLimitSats;

  /// Finestra di derivazione usata per trovare le chiavi da firmare.
  ///
  /// // PERCHÉ: la PSBT dice la PUBKEY di ogni input ma non sempre il path; il
  /// // firmatario deriva gli indirizzi del wallet e confronta. 50 ricezioni e
  /// // 10 resti coprono il gap-limit reale senza costare secondi.
  static const int externalWindow = 50;
  static const int changeWindow = 10;

  /// Crea la PSBT non firmata per [wallet].
  ///
  /// [mnemonic] serve solo ai wallet **hot** (le chiavi pubbliche si derivano
  /// dal seed); un watch-only lavora con il solo `accountXpub`.
  Future<PsbtDraft> createForWallet({
    required WalletRecord wallet,
    required List<UtxoInfo> utxos,
    required List<SendOutput> outputs,
    required int feeRateSatVb,
    String? mnemonic,
    bool enableRBF = true,
  }) async {
    if (outputs.isEmpty) {
      throw StateError('PSBT: serve almeno un destinatario.');
    }
    for (final output in outputs) {
      if (output.isDust) {
        throw StateError(
          'PSBT: importo sotto il minimo dust ($dustLimitSats sat) '
          'per ${output.address}.',
        );
      }
    }
    if (feeRateSatVb <= 0) {
      throw StateError('PSBT: fee rate non valido ($feeRateSatVb sat/vB).');
    }

    final accountPath = _accountPath(wallet);
    _requireNativeSegwit(accountPath, wallet.kind);

    final keys = _KeySource.forWallet(
      wallet: wallet,
      accountPath: accountPath,
      mnemonic: mnemonic,
    );
    final totalOut = outputs.fold<int>(0, (sum, o) => sum + o.amountSats);
    final recipientCount = outputs.length;

    // STEP: 1 — selezione UTXO identica a `_buildAndSignTx` (greedy, coinbase
    // immaturi esclusi, ristima della fee quando il resto scende sotto dust).
    final split = splitRelayableUtxos(utxos);
    final selected = <_SelectedInput>[];
    var totalIn = 0;
    for (final utxo in split.spendable) {
      final path = utxo.ownerDerivationPath;
      if (path == null) continue;
      final publicKeyHex = keys.publicKeyHex(path);
      final scriptHex = _scriptForInput(utxo, publicKeyHex);
      if (scriptHex == null) continue;

      selected.add(
        _SelectedInput(
          utxo: utxo,
          publicKeyHex: publicKeyHex,
          scriptPubKeyHex: scriptHex,
          derivationPath: path,
        ),
      );
      totalIn += utxo.valueSat;

      var outputCount = recipientCount + 1;
      var estimatedFee =
          estimateTxVbytes(selected.map((e) => e.utxo), outputCount) *
              feeRateSatVb;
      var estimatedChange = totalIn - totalOut - estimatedFee;
      if (estimatedChange <= dustLimitSats) {
        outputCount = recipientCount;
        estimatedFee =
            estimateTxVbytes(selected.map((e) => e.utxo), outputCount) *
                feeRateSatVb;
        estimatedChange = totalIn - totalOut - estimatedFee;
      }
      if (totalIn >= totalOut + estimatedFee && estimatedChange >= 0) break;
    }

    if (selected.isEmpty) {
      throw StateError(
        split.blocked.isNotEmpty
            ? 'PSBT: nessun UTXO spendibile — ${sumUtxoSats(split.blocked)} sat '
                  'provengono da payout di mining (coinbase) non ancora '
                  'propagabili.'
            : 'PSBT: nessun UTXO spendibile per questo wallet (solo input '
                  'P2WPKH con path di derivazione noto).',
      );
    }

    // STEP: 2 — fee e resto finali con la STESSA regola del builder diretto.
    var txSize = estimateTxVbytes(
      selected.map((e) => e.utxo),
      recipientCount + 1,
    );
    var fee = txSize * feeRateSatVb;
    var change = totalIn - totalOut - fee;
    if (change < dustLimitSats) {
      txSize = estimateTxVbytes(selected.map((e) => e.utxo), recipientCount);
      fee = txSize * feeRateSatVb;
      change = totalIn - totalOut - fee;
    }
    if (change < 0) {
      throw StateError(
        split.blocked.isNotEmpty
            ? 'PSBT: fondi insufficienti — ${sumUtxoSats(split.blocked)} sat '
                  'sono coinbase non ancora propagabili.'
            : 'PSBT: fondi insufficienti (incluse le fee).',
      );
    }

    // STEP: 3 — indirizzo di resto sulla catena interna `/1/N` (primo libero).
    String? changeAddress;
    final psbtOutputs = <BitcoinOutput>[
      for (final output in outputs)
        BitcoinOutput(
          address: BitcoinAddress(
            output.address,
            network: BitcoinNetworkConfig.bitcoinBaseNetwork,
          ).baseAddress,
          value: BigInt.from(output.amountSats),
        ),
    ];
    if (change >= dustLimitSats) {
      final changeIndex = nextChangeIndex(utxos, accountPath);
      final changePath = '$accountPath/1/$changeIndex';
      final changePublicKeyHex = keys.publicKeyHex(changePath);
      changeAddress = pubKeyToAddressForType(
        _hexToBytes(changePublicKeyHex),
        type: WalletScriptType.p2wpkh,
      );
      psbtOutputs.add(
        BitcoinOutput(
          address: BitcoinAddress(
            changeAddress,
            network: BitcoinNetworkConfig.bitcoinBaseNetwork,
          ).baseAddress,
          value: BigInt.from(change),
        ),
      );
    }

    final psbtBase64 = createPsbtFromInputs(
      inputs: <PsbtInputSpec>[
        for (final input in selected)
          PsbtInputSpec(
            txid: input.utxo.txid,
            vout: input.utxo.vout,
            valueSats: input.utxo.valueSat,
            scriptPubKeyHex: input.scriptPubKeyHex,
            publicKeyHex: input.publicKeyHex,
            derivationPath: input.derivationPath,
          ),
      ],
      outputs: psbtOutputs,
      fee: BigInt.from(fee),
      enableRBF: enableRBF,
      masterFingerprint: _masterFingerprintBytes(wallet.masterFingerprint),
    );

    debugPrint(
      '[LoopEngineer] PSBT bozza: input=${selected.length} '
      'destinatari=$recipientCount fee=$fee change=$change '
      'changeAddr=${changeAddress ?? "-"}',
    );

    return PsbtDraft(
      psbtBase64: psbtBase64,
      feeSats: fee,
      changeSats: change >= dustLimitSats ? change : 0,
      inputCount: selected.length,
      outputCount: psbtOutputs.length,
      totalOutSats: totalOut,
      changeAddress: changeAddress,
    );
  }

  /// Firma una PSBT con il seed del wallet. Mai per un watch-only.
  ///
  /// // PERCHÉ: `signPsbtBase64` firma il digest UNIFIED degli input che
  /// // riconosce; la finestra di derivazione serve perché la PSBT dichiara le
  /// // PUBKEY, non sempre i path (una PSBT che arriva da un altro telefono).
  Future<String> signForWallet({
    required WalletRecord wallet,
    required String psbtBase64,
    String? mnemonic,
  }) async {
    if (wallet.kind == WalletKind.watchOnly) {
      throw StateError(
        'PSBT: un wallet watch-only non ha chiavi — firmala su un dispositivo '
        'che possiede il seed.',
      );
    }
    final seedPhrase = mnemonic;
    if (seedPhrase == null || seedPhrase.trim().isEmpty) {
      throw StateError('PSBT: serve il seed del wallet per firmare.');
    }
    final accountPath = _accountPath(wallet);
    _requireNativeSegwit(accountPath, wallet.kind);

    final root = bip32.BIP32.fromSeed(
      bip39.mnemonicToSeed(seedPhrase),
      BitcoinNetworkConfig.bip32NetworkType,
    );
    final privateKeys = <String, ECPrivate>{};
    for (final path in _candidatePaths(accountPath)) {
      final child = root.derivePath(path);
      final private = child.privateKey;
      if (private == null) continue;
      privateKeys[BytesUtils.toHexString(child.publicKey)] =
          ECPrivate.fromBytes(private);
    }

    final declared = psbtInputPublicKeys(psbtBase64);
    final missing = declared
        .whereType<String>()
        .where((hex) => !privateKeys.containsKey(hex))
        .toSet();
    if (missing.isNotEmpty) {
      throw StateError(
        'PSBT: ${missing.length} chiave/i degli input non appartengono a questo '
        'wallet (oltre gli ultimi $externalWindow indirizzi derivati).',
      );
    }
    debugPrint(
      '[LoopEngineer] PSBT firma: input=${declared.length} '
      'chiavi derivate=${privateKeys.length} mancanti=${missing.length}',
    );
    return signPsbtBase64(
      psbtBase64: psbtBase64,
      privateKeysByPublicKey: privateKeys,
    );
  }

  /// Finalizza la PSBT firmata, la trasmette e registra pending + RBF.
  ///
  /// // PERCHÉ: un invio via PSBT deve lasciare la traccia identica a un invio
  /// // diretto — senza i registri, la tx non compare tra le pending e non si
  /// // può fare bump fee.
  Future<SendResult> broadcastPsbt({
    required WalletRecord wallet,
    required String signedPsbtBase64,
    required List<UtxoInfo> utxos,
    required List<SendOutput> outputs,
    required int feeRateSatVb,
    bool enableRBF = true,
  }) async {
    if (outputs.isEmpty) {
      throw StateError('PSBT: serve almeno un destinatario.');
    }
    final txHex = finalizePsbtToTxHex(signedPsbtBase64);
    final feeSats = summarizePsbt(signedPsbtBase64).feeSats.toInt();
    final txid = await _bitcoin.broadcastTransaction(txHex);

    final totalOut = outputs.fold<int>(0, (sum, o) => sum + o.amountSats);
    PendingSendRegistry.register(txid, amountSats: totalOut);
    if (enableRBF) {
      RbfParamsRegistry.register(
        txid,
        RbfTxParams(
          kind: RbfTxKind.send,
          outputs: List<SendOutput>.from(outputs),
          derivationPath: _accountPath(wallet),
          originalFeeRateSatVb: feeRateSatVb,
          utxos: List<UtxoInfo>.from(utxos),
        ),
      );
    }
    debugPrint(
      '[LoopEngineer] PSBT trasmessa: txid=${txid.substring(0, 8)}… '
      'fee=$feeSats sat',
    );
    return SendResult(txid: txid, feePaid: feeSats);
  }

  String _accountPath(WalletRecord wallet) =>
      wallet.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;

  /// Trasmette una PSBT firmata **senza** registrare pending/RBF.
  ///
  /// // PERCHÉ (P4/I3): chi firma su un altro dispositivo conosce la
  /// // transazione ma NON la suddivisione destinatari/resto decisa dal wallet
  /// // che l'ha creata — registrare un importo indovinato sporcherebbe lo
  /// // storico. La tx compare comunque dallo scan on-chain degli indirizzi.
  Future<SendResult> broadcastSignedOnly({
    required String signedPsbtBase64,
  }) async {
    final txHex = finalizePsbtToTxHex(signedPsbtBase64);
    final feeSats = summarizePsbt(signedPsbtBase64).feeSats.toInt();
    final txid = await _bitcoin.broadcastTransaction(txHex);
    debugPrint(
      '[LoopEngineer] PSBT firmata altrove trasmessa: '
      'txid=${txid.substring(0, 8)}… fee=$feeSats sat',
    );
    return SendResult(txid: txid, feePaid: feeSats);
  }

  /// // PERCHÉ: il percorso PSBT lavora solo su P2WPKH (`0014…`) — lo stesso
  /// // limite del codec, dichiarato in `PSBT_PLAN.md` (§1, decisione 1).
  /// // Fallire QUI con un messaggio chiaro evita un errore oscuro del codec.
  void _requireNativeSegwit(String accountPath, WalletKind kind) {
    final type = WalletScriptType.fromDerivationPath(accountPath);
    if (type != WalletScriptType.p2wpkh) {
      throw StateError(
        'PSBT: supportati solo wallet native segwit (BIP84, `bc1q…`); questo '
        'wallet usa $accountPath.',
      );
    }
  }

  /// scriptPubKey `0014…` dell'input, verificando che sia NOSTRO.
  ///
  /// // PERCHÉ la verifica: un UTXO la cui chiave non corrisponde allo script
  /// // on-chain non è spendibile da questo wallet (dati stantii o wallet
  /// // sbagliato) — firmarlo produrrebbe una transazione rifiutata.
  String? _scriptForInput(UtxoInfo utxo, String publicKeyHex) {
    final expected = _hash160Hex(publicKeyHex);
    final onChain = utxo.scriptPubKeyHex?.toLowerCase();
    if (onChain != null && onChain.isNotEmpty) {
      if (onChain.length != 44 ||
          !onChain.startsWith('0014') ||
          onChain.substring(4) != expected) {
        return null;
      }
      return onChain;
    }
    // Fallback: script derivato dalla pubkey (stessa fonte del codec).
    return ECPublic.fromBytes(
      _hexToBytes(publicKeyHex),
    ).toSegwitAddress().toScriptPubKey().toHex();
  }

  /// Path derivabili dal firmatario: ricezione `/0/0…49`, resto `/1/0…9`.
  Iterable<String> _candidatePaths(String accountPath) sync* {
    for (var i = 0; i < externalWindow; i++) {
      yield '$accountPath/0/$i';
    }
    for (var i = 0; i < changeWindow; i++) {
      yield '$accountPath/1/$i';
    }
  }

  String _hash160Hex(String publicKeyHex) {
    final sha = crypto.sha256.convert(_hexToBytes(publicKeyHex)).bytes;
    final ripemd = RIPEMD160Digest();
    final hash = ripemd.process(Uint8List.fromList(sha));
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int>? _masterFingerprintBytes(String? fingerprintHex) {
    if (fingerprintHex == null) return null;
    final hex = fingerprintHex.trim();
    if (hex.length != 8) return null;
    return _hexToBytes(hex);
  }
}

Uint8List _hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw StateError('Hex dispari: $hex');
  }
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}
/// Input selezionato, con tutto ciò che serve a descriverlo nella PSBT.
class _SelectedInput {
  const _SelectedInput({
    required this.utxo,
    required this.publicKeyHex,
    required this.scriptPubKeyHex,
    required this.derivationPath,
  });

  final UtxoInfo utxo;
  final String publicKeyHex;
  final String scriptPubKeyHex;
  final String derivationPath;
}

/// Sorgente delle chiavi PUBBLICHE di un wallet: seed (hot) o xpub (watch-only).
///
/// // PERCHÉ un'astrazione: creare la PSBT richiede solo dati pubblici in
/// // entrambi i casi; così il codice dell'economia resta UNO e il watch-only
/// // non tocca mai una chiave privata.
abstract class _KeySource {
  String publicKeyHex(String derivationPath);

  static _KeySource forWallet({
    required WalletRecord wallet,
    required String accountPath,
    String? mnemonic,
  }) {
    if (wallet.kind == WalletKind.watchOnly) {
      final xpub = wallet.accountXpub;
      if (xpub == null || xpub.isEmpty) {
        throw StateError(
          'PSBT: il wallet watch-only non ha un xpub: reimportalo per poter '
          'creare una PSBT.',
        );
      }
      return _XpubKeySource(xpub: xpub, accountPath: accountPath);
    }
    final seedPhrase = mnemonic;
    if (seedPhrase == null || seedPhrase.trim().isEmpty) {
      throw StateError('PSBT: serve il seed del wallet per creare la PSBT.');
    }
    return _SeedKeySource(seedPhrase: seedPhrase);
  }
}

class _SeedKeySource implements _KeySource {
  _SeedKeySource({required String seedPhrase})
      : _root = bip32.BIP32.fromSeed(
          bip39.mnemonicToSeed(seedPhrase),
          BitcoinNetworkConfig.bip32NetworkType,
        );

  final bip32.BIP32 _root;

  @override
  String publicKeyHex(String derivationPath) =>
      BytesUtils.toHexString(_root.derivePath(derivationPath).publicKey);
}

class _XpubKeySource implements _KeySource {
  _XpubKeySource({required String xpub, required String accountPath})
      : _account = bip32.BIP32.fromBase58(
          xpub,
          BitcoinNetworkConfig.bip32NetworkType,
        ),
        _prefix = '$accountPath/';

  final bip32.BIP32 _account;
  final String _prefix;

  @override
  String publicKeyHex(String derivationPath) {
    if (!derivationPath.startsWith(_prefix)) {
      throw StateError(
        'PSBT: path $derivationPath fuori dall account ($_prefix…): '
        'derivazione pubblica impossibile.',
      );
    }
    // // PERCHÉ derivazione relativa manuale: `derivePath` accetta solo path
    // // assoluti (`m/…`), mentre dall xpub si deriva la parte dopo l'account.
    var node = _account;
    for (final segment in derivationPath.substring(_prefix.length).split('/')) {
      if (segment.isEmpty) continue;
      final hardened = segment.endsWith('h') || segment.endsWith("'");
      final index = int.parse(
        hardened ? segment.substring(0, segment.length - 1) : segment,
      );
      if (hardened) {
        throw StateError(
          'PSBT: derivazione hardened ($segment) impossibile da un xpub.',
        );
      }
      node = node.derive(index);
    }
    return BytesUtils.toHexString(node.publicKey);
  }
}
