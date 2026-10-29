/// Maturity di relay di un output coinbase — guardia per il coin selection.
///
/// PERCHÉ: da CLN `v26.06.8-blake2b.5` (e dalle regole di policy di Knots,
/// PR `privkeyio/lightning#11`) un output di coinbase non viene propagato dai
/// nodi della rete prima di [BitcoinNetworkConfig.coinbaseRelayMaturityBlocks]
/// blocchi — 6.480 sulla mainnet blake2b, ~45 giorni al block time attuale
/// (~600 s/blocco). Il periodo si misura in BLOCCHI: la UI mostra quanti
/// blocchi mancano, non una data.
/// Il mining del progetto paga in coinbase: un wallet che ne selezionasse uno
/// costruirebbe una transazione che nessun peer accetta nel mempool.
library;

import '../config/bitcoin_network_config.dart';
import '../models/utxo_info.dart';

/// True se un output coinbase è ormai propagabile dalla rete.
///
/// - [isCoinbase] `false` → sempre `true` (nessuna restrizione: la maturity di
///   consenso dei 100 blocchi è già garantita dal wallet dal lato spesa).
/// - [maturityBlocks] `<= 0` → `true` (rete che non applica la regola).
/// - [confirmations] `null` (API fallita) → `false`: **prudente**, perché non
///   possiamo dimostrare la maturità e una tx non propagabile è un fallimento
///   silenzioso (resta nel wallet, non nel mempool).
bool isCoinbaseRelayable({
  required bool isCoinbase,
  required int? confirmations,
  required int maturityBlocks,
}) {
  if (!isCoinbase) return true;
  if (maturityBlocks <= 0) return true;
  final confs = confirmations;
  if (confs == null) return false;
  return confs >= maturityBlocks;
}

/// Come [isCoinbaseRelayable], applicato a un [UtxoInfo] e con la maturity
/// della rete corrente come default.
bool isUtxoRelayable(UtxoInfo utxo, {int? maturityBlocks}) {
  return isCoinbaseRelayable(
    isCoinbase: utxo.isCoinbase,
    confirmations: utxo.confirmations,
    maturityBlocks:
        maturityBlocks ?? BitcoinNetworkConfig.coinbaseRelayMaturityBlocks,
  );
}

/// Esito della separazione di un elenco di UTXO in spendibili e bloccati.
typedef UtxoSplit = ({List<UtxoInfo> spendable, List<UtxoInfo> blocked});

/// Blocchi che mancano perché la rete propaghi la spesa di [utxo].
///
/// - `0` → già spendibile (tx normale, o coinbase matura).
/// - `null` → coinbase con conferme ignote (API fallita): non si può dire
///   quanti blocchi mancano, ma l'UTXO resta NON spendibile (prudenza).
int? remainingRelayBlocks(UtxoInfo utxo, {int? maturityBlocks}) {
  final maturity =
      maturityBlocks ?? BitcoinNetworkConfig.coinbaseRelayMaturityBlocks;
  if (!utxo.isCoinbase) return 0;
  if (maturity <= 0) return 0;
  final confs = utxo.confirmations;
  if (confs == null) return null;
  final missing = maturity - confs;
  return missing > 0 ? missing : 0;
}

/// Blocchi mancanti al PRIMO sblocco fra [utxos] (countdown in UI).
///
/// `null` se la lista è vuota o se per nessun elemento le conferme sono note.
/// Gli elementi con conferme ignote vengono saltati: il minimo dei noti resta
/// una stima utile (mai una data inventata).
int? minRemainingRelayBlocks(Iterable<UtxoInfo> utxos, {int? maturityBlocks}) {
  int? min;
  for (final u in utxos) {
    final remaining = remainingRelayBlocks(u, maturityBlocks: maturityBlocks);
    if (remaining == null || remaining <= 0) continue;
    if (min == null || remaining < min) min = remaining;
  }
  return min;
}

/// Somma in satoshi di un elenco di UTXO.
int sumUtxoSats(Iterable<UtxoInfo> utxos) =>
    utxos.fold<int>(0, (sum, u) => sum + u.valueSat);

/// Separa gli UTXO propagabili da quelli bloccati (coinbase immature).
///
/// PERCHÉ: unico punto di verità della regola — lo usano il coin selection
/// (per non costruire tx che nessun peer accetta) e il SALDO mostrato in UI
/// (che non deve includere fondi non spendibili). L'ordine di [utxos] è
/// preservato in entrambe le liste.
UtxoSplit splitRelayableUtxos(List<UtxoInfo> utxos, {int? maturityBlocks}) {
  final spendable = <UtxoInfo>[];
  final blocked = <UtxoInfo>[];
  for (final u in utxos) {
    if (isUtxoRelayable(u, maturityBlocks: maturityBlocks)) {
      spendable.add(u);
    } else {
      blocked.add(u);
    }
  }
  return (spendable: spendable, blocked: blocked);
}
