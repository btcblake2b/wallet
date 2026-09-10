import 'dart:convert';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bech32/bech32.dart';
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin_base;
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/api.dart' as pc_api;
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/ecc/api.dart' as pc;
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

import '../config/bitcoin_network_config.dart';

/// Dati per la derivazione dell'indirizzo in un isolate.
class AddressDerivationData {
  final String mnemonic;
  final String? derivationPath;
  final int addressCount;
  AddressDerivationData(
    this.mnemonic, [
    this.derivationPath,
    this.addressCount = 100,
  ]);
}

class MessageSignData {
  final String mnemonic;
  final String message;
  MessageSignData(this.mnemonic, this.message);
}

class MessageVerifyData {
  final String address;
  final String message;
  final String signature;

  /// Chiave pubblica compressa (33 byte, esadecimale) del firmatario.
  /// Opzionale: se non fornita, si tenta il recovery ECDSA (più lento).
  final String? publicKeyHex;

  MessageVerifyData(
    this.address,
    this.message,
    this.signature, {
    this.publicKeyHex,
  });
}

/// Dati di output della derivazione completa del wallet.
class WalletDerivationResult {
  final String publicAddress;
  final String masterFingerprint;
  final String derivationPath;
  final String xpub;
  final List<String> addresses;
  // PERCHÉ: la catena change (/1/N) non era mai derivata — il resto delle
  // spese finiva lì e saldo/storico risultavano incompleti (fix vs BlueWallet).
  final List<String> changeAddresses;

  WalletDerivationResult({
    required this.publicAddress,
    required this.masterFingerprint,
    required this.derivationPath,
    required this.xpub,
    required this.addresses,
    required this.changeAddresses,
  });
}

/// Funzione top-level per la derivazione dei dati del wallet.
WalletDerivationResult deriveWalletData(AddressDerivationData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);
  final network = BitcoinNetworkConfig.bip32NetworkType;
  final root = bip32.BIP32.fromSeed(seed, network);

  // Master Fingerprint: first 4 bytes of HASH160 of master public key
  final masterFingerprint = root.fingerprint
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join('')
      .toUpperCase();

  // Use provided derivationPath or default to native SegWit account 0
  final path =
      data.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;
  // PERCHÉ (BIP49): il tipo di indirizzo si deduce dal purpose del path
  // (m/49'… → nested P2SH, altrimenti native bech32). Zero campi nuovi.
  final type = WalletScriptType.fromDerivationPath(path);
  final account = root.derivePath(path);

  // Derive first address for the main publicAddress
  final firstChild = account.derive(0).derive(0);
  final firstAddress = pubKeyToAddressForType(
    firstChild.publicKey,
    type: type,
  );

  // Derive a configurable number of addresses (default 100) per catena:
  // external (ricezione, /0/N) e change (resto spese, /1/N).
  // PERCHÉ: senza la catena change il wallet non vede i propri UTXO di resto
  // (fix saldo/storico vs BlueWallet).
  final addresses = <String>[];
  final changeAddresses = <String>[];
  final count = data.addressCount;
  for (var i = 0; i < count; i++) {
    addresses.add(
      pubKeyToAddressForType(
        account.derive(0).derive(i).publicKey,
        type: type,
      ),
    );
    changeAddresses.add(
      pubKeyToAddressForType(
        account.derive(1).derive(i).publicKey,
        type: type,
      ),
    );
  }

  return WalletDerivationResult(
    publicAddress: firstAddress,
    masterFingerprint: masterFingerprint,
    derivationPath: path,
    // PERCHÉ (sicurezza): toBase58() su un nodo ancora privato restituisce
    // la versione PRIVATA (xprv) — l'account derivato dal seed ha la chiave
    // privata. neutered() rimuove la chiave privata → vero xpub, sicuro da
    // mostrare/condividere (il vecchio codice esponeva l'xprv nel dialog XPUB).
    xpub: account.neutered().toBase58(),
    addresses: addresses,
    changeAddresses: changeAddresses,
  );
}

/// Helper per convertire public key in indirizzo SegWit (Bech32) — default
/// native (usato dal sign/verify messaggi, che firma col ramo BIP84).
String _pubKeyToAddress(Uint8List publicKey) {
  return pubKeyToAddressForType(publicKey);
}

/// Converte una chiave pubblica compressa (33 byte) nell'indirizzo del
/// [type] richiesto:
/// - [WalletScriptType.p2wpkh] (default): SegWit native Bech32 (`bc1q…`);
/// - [WalletScriptType.p2shP2wpkh]: Nested SegWit P2SH base58 (`3…`, BIP49);
/// - [WalletScriptType.p2pkh]: Legacy P2PKH base58 (`1…`, BIP44).
///
/// [network] opzionale: di default la rete corrente (mainnet/testnet). È
/// esposto per i test che verificano i vettori ufficiali su testnet.
// PERCHÉ: choke-point unico pubkey→indirizzo — lo scan e la derivazione
// diventano tipo-consapevoli senza toccare i servizi a valle.
String pubKeyToAddressForType(
  Uint8List publicKey, {
  WalletScriptType type = WalletScriptType.p2wpkh,
  bitcoin_base.BitcoinNetwork? network,
}) {
  if (publicKey.length != 33) {
    throw StateError('Compressed public key non valida.');
  }

  final shaHashed = Uint8List.fromList(sha256.convert(publicKey).bytes);
  final ripemd = RIPEMD160Digest();
  final pubKeyHash = ripemd.process(shaHashed);

  if (type == WalletScriptType.p2shP2wpkh) {
    // PERCHÉ (BIP49): l'indirizzo è P2SH del witness program 0014{pkh}:
    // addressBytes = HASH160(0x0014{pubKeyHash}), base58check con prefisso
    // P2SH di rete ('3' mainnet / '2' testnet). Riusa bitcoin_base così lo
    // script coincide con quello usato in firma (unified_sighash).
    final net = network ?? BitcoinNetworkConfig.bitcoinBaseNetwork;
    return _p2shFor(pubKeyHash).toAddress(net);
  }

  if (type == WalletScriptType.p2pkh) {
    // PERCHÉ (BIP44): base58check(hash160(pub)) con version byte di rete
    // (0x00 mainnet '1', 0x6f testnet 'm/n'). Choke-point unico come BIP49.
    final net = network ?? BitcoinNetworkConfig.bitcoinBaseNetwork;
    return bitcoin_base.P2pkhAddress.fromHash160(
      addrHash: hex.encode(pubKeyHash),
    ).toAddress(net);
  }

  // segwit.encode gestisce internamente la conversione 8→5 bits
  return segwit.encode(Segwit(BitcoinNetworkConfig.bech32Hrp, 0, pubKeyHash));
}

/// Costruisce l'indirizzo P2SH (nested segwit) dal pubKeyHash del witness
/// program. Lo script `0014{pkh}` coincide con quello usato in firma
/// (unified_sighash `_spentScriptFor`).
bitcoin_base.P2shAddress _p2shFor(List<int> pubKeyHash) {
  final segwitScript = bitcoin_base.Script(
    script: [
      bitcoin_base.BitcoinOpcode.op0,
      hex.encode(pubKeyHash),
    ],
  );
  return bitcoin_base.P2shAddress.fromScript(
    script: segwitScript,
    type: bitcoin_base.P2shAddressType.p2wpkhInP2sh,
  );
}

String deriveBitcoinAddress(AddressDerivationData data) {
  final result = deriveWalletData(data);
  return result.publicAddress;
}

String signBitcoinMessage(MessageSignData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);
  final network = BitcoinNetworkConfig.bip32NetworkType;
  final root = bip32.BIP32.fromSeed(seed, network);
  final defaultPath = BitcoinNetworkConfig.defaultDerivationPath;
  final account = root.derivePath(defaultPath).derive(0).derive(0);

  // Standard Bitcoin Message Prefix
  const prefix = "\x18Bitcoin Signed Message:\n";
  final msgBytes = utf8.encode(data.message);
  final prefixBytes = utf8.encode(prefix);

  // VarInt length of message (not used in this simplified signing flow)

  final fullMessage = <int>[
    ...prefixBytes,
    ..._encodeVarInt(msgBytes.length),
    ...msgBytes,
  ];

  final hash = sha256.convert(sha256.convert(fullMessage).bytes).bytes;

  // Sign using BIP32/ECDSA
  // Note: Standard Bitcoin signatures require recovery ID (v).
  // This is a simplified signature (64 bytes r+s) as full BIP137 recovery is complex in pure Dart without a dedicated lib.
  // We'll return Base64 of the 64-byte signature for demonstration.
  final sig = account.sign(Uint8List.fromList(hash));
  return base64.encode(sig);
}

/// Verifica una firma Bitcoin ECDSA su un messaggio.
///
/// Supporta due modalità:
/// 1. Se [data.publicKeyHex] è fornito: verifica ECDSA diretta + controllo indirizzo
/// 2. Altrimenti: tenta recovery della chiave pubblica dalla firma (BIP137-style)
///
/// Il formato firma è compact r||s (64 byte) in base64, come prodotto da [signBitcoinMessage].
bool verifyBitcoinMessage(MessageVerifyData data) {
  try {
    // 1. Ricostruisci il message hash (stesso processo di signBitcoinMessage)
    const prefix = '\x18Bitcoin Signed Message:\n';
    final msgBytes = utf8.encode(data.message);
    final prefixBytes = utf8.encode(prefix);

    final fullMessage = <int>[
      ...prefixBytes,
      ..._encodeVarInt(msgBytes.length),
      ...msgBytes,
    ];

    final hash = Uint8List.fromList(
      sha256.convert(sha256.convert(fullMessage).bytes).bytes,
    );

    // 2. Decodifica la firma base64
    final sigBytes = base64.decode(data.signature);

    // Estrai r e s (compact: 32+32 byte)
    if (sigBytes.length < 64) {
      return false;
    }
    final rBytes = sigBytes.sublist(0, 32);
    final sBytes = sigBytes.sublist(32, 64);

    final params = ECCurve_secp256k1();

    // 3. Verifica con chiave pubblica nota (se fornita)
    if (data.publicKeyHex != null && data.publicKeyHex!.isNotEmpty) {
      final pubKeyBytes = Uint8List.fromList(hex.decode(data.publicKeyHex!));
      final pubPoint = params.curve.decodePoint(pubKeyBytes);

      final pubKey = pc.ECPublicKey(pubPoint, params);
      final signer = ECDSASigner(null, null);
      signer.init(false, pc_api.PublicKeyParameter(pubKey));

      final r = _bnFromBytes(rBytes, params);
      final s = _bnFromBytes(sBytes, params);
      final ecSig = pc.ECSignature(r, s);

      final verified = signer.verifySignature(hash, ecSig);
      if (!verified) return false;

      // Verifica che l'indirizzo corrisponda
      final derivedAddress = _pubKeyToAddress(pubKeyBytes);
      return derivedAddress == data.address;
    }

    // 4. Recovery: prova i 4 recovery ID possibili
    final r = _bnFromBytes(rBytes, params);
    final s = _bnFromBytes(sBytes, params);

    for (int recId = 0; recId < 4; recId++) {
      try {
        final recoveredPubKey =
            _recoverPublicKeyFromSignature(r, s, recId, hash, params);
        if (recoveredPubKey != null) {
          final derivedAddress = _pubKeyToAddress(recoveredPubKey);
          if (derivedAddress == data.address) {
            return true;
          }
        }
      } catch (_) {
        // Prova prossimo recovery ID
      }
    }

    return false;
  } catch (e) {
    return false;
  }
}

/// Recupera la chiave pubblica compressa (33 byte) da firma ECDSA + recovery ID.
Uint8List? _recoverPublicKeyFromSignature(
  BigInt r,
  BigInt s,
  int recId,
  Uint8List messageHash,
  pc.ECDomainParameters params,
) {
  if (recId < 0 || recId > 3) return null;

  final n = params.n;
  final curve = params.curve;
  final G = params.G;

  if (r >= n || r <= BigInt.zero) return null;

  // x = r + (recId / 2) * n (per secp256k1, il campo è p, diverso da n)
  final prime = (params.curve is ECCurve_secp256k1)
      ? BigInt.parse(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
          radix: 16,
        )
      : n;

  var x = r;
  final isOddY = (recId & 1) == 1;

  // Per secp256k1: y² = x³ + 7 (mod p)
  final p = prime;
  final b = BigInt.from(7);

  final xCubed = (x * x * x) % p;
  final ySquared = (xCubed + b) % p;

  // Calcola la radice quadrata modulare: y = ySquared^((p+1)/4) (per p ≡ 3 mod 4)
  final exp = (p + BigInt.one) >> 2; // (p+1)/4
  var y = _modPow(ySquared, exp, p);

  // Verifica che y sia la radice corretta
  if ((y * y) % p != ySquared) {
    return null;
  }

  // Se y è dispari e isOddY è false (o viceversa), prendi p - y
  if ((y.isOdd && !isOddY) || (!y.isOdd && isOddY)) {
    y = p - y;
  }

  final R = curve.createPoint(x, y);

  // Calcola r^(-1) mod n
  final rInv = r.modInverse(n);

  // z = message hash come numero
  var z = BigInt.zero;
  for (final b in messageHash) {
    z = (z << 8) | BigInt.from(b);
  }
  z = z % n;

  // Q = r^(-1) * (s*R - z*G)
  final sR = R * s;
  final zG = G * z;
  final sRMinusZG = sR! - zG!;
  final Q = sRMinusZG! * rInv;

  if (Q == null) return null;

  // Converte in chiave pubblica compressa (33 byte)
  final qx = Q.x!.toBigInteger()!;
  final qy = Q.y!.toBigInteger()!;

  final prefix = qy.isOdd ? 0x03 : 0x02;
  final qxBytes = _bigIntToBytes(qx, 32);
  final result = Uint8List(33);
  result[0] = prefix;
  result.setAll(1, qxBytes);

  return result;
}

BigInt _modPow(BigInt base, BigInt exp, BigInt mod) {
  if (exp == BigInt.zero) return BigInt.one;
  var result = BigInt.one;
  var b = base % mod;
  var e = exp;
  while (e > BigInt.zero) {
    if (e.isOdd) {
      result = (result * b) % mod;
    }
    e = e >> 1;
    b = (b * b) % mod;
  }
  return result;
}

BigInt _bnFromBytes(Uint8List bytes, pc.ECDomainParameters params) {
  var value = BigInt.zero;
  for (final b in bytes) {
    value = (value << 8) | BigInt.from(b);
  }
  // Normalizza modulo n
  return value % params.n;
}

Uint8List _bigIntToBytes(BigInt value, int length) {
  final result = Uint8List(length);
  var v = value;
  for (int i = length - 1; i >= 0; i--) {
    result[i] = (v & BigInt.from(0xFF)).toInt();
    v = v >> 8;
  }
  return result;
}

List<int> _encodeVarInt(int n) {
  if (n < 253) return [n];
  if (n < 65536) return [253, n & 0xff, (n >> 8) & 0xff];
  return [254, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff];
}
