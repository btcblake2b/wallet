/// Statistiche economiche del nodo e stato dei plugin (spec dln
/// `get_node_stats`).
///
/// // PERCHÉ: il netto e i tag arrivano dall'accounting del nodo (`bkpr`): i
/// tag sono aperti (deposit, invoice, onchain_fee, routed…) quindi il modello
/// li conserva **grezzi** — l'etichetta leggibile la sceglie la UI.
class LightningNodeStats {
  const LightningNodeStats({
    this.netMsat = 0,
    this.creditsMsat = 0,
    this.debitsMsat = 0,
    this.tags = const [],
    this.plugins = const [],
    this.forwardCount = 0,
  });

  final int netMsat;
  final int creditsMsat;
  final int debitsMsat;

  /// Movimenti aggregati per tag, dal più pesante (netto assoluto).
  final List<LightningIncomeTag> tags;

  /// Plugin del nodo (nome corto) con stato.
  final List<LightningPluginInfo> plugins;

  /// Forwarding visti dal nodo (0 = non ha ancora instradato nulla).
  final int forwardCount;

  int get netSats => netMsat ~/ 1000;
  int get creditsSats => creditsMsat ~/ 1000;
  int get debitsSats => debitsMsat ~/ 1000;
  int get activePluginCount => plugins.where((p) => p.active).length;

  factory LightningNodeStats.fromJson(Map<String, dynamic> json) =>
      LightningNodeStats(
        netMsat: (json['net_msat'] as num?)?.toInt() ?? 0,
        creditsMsat: (json['credits_msat'] as num?)?.toInt() ?? 0,
        debitsMsat: (json['debits_msat'] as num?)?.toInt() ?? 0,
        tags: [
          for (final t in (json['tags'] as List? ?? const []))
            LightningIncomeTag.fromJson((t as Map).cast<String, dynamic>()),
        ],
        plugins: [
          for (final p in (json['plugins'] as List? ?? const []))
            LightningPluginInfo.fromJson((p as Map).cast<String, dynamic>()),
        ],
        forwardCount: (json['forward_count'] as num?)?.toInt() ?? 0,
      );
}

/// Movimenti del nodo raggruppati per tag di accounting.
class LightningIncomeTag {
  const LightningIncomeTag({
    required this.tag,
    this.creditsMsat = 0,
    this.debitsMsat = 0,
    this.entries = 0,
  });

  /// Tag grezzo del nodo (es. `deposit`, `invoice`, `onchain_fee`).
  final String tag;
  final int creditsMsat;
  final int debitsMsat;
  final int entries;

  int get creditsSats => creditsMsat ~/ 1000;
  int get debitsSats => debitsMsat ~/ 1000;

  /// Netto del tag: positivo = entrata.
  int get netMsat => creditsMsat - debitsMsat;
  int get netSats => netMsat ~/ 1000;

  factory LightningIncomeTag.fromJson(Map<String, dynamic> json) =>
      LightningIncomeTag(
        tag: '${json['tag'] ?? 'unknown'}',
        creditsMsat: (json['credit_msat'] as num?)?.toInt() ?? 0,
        debitsMsat: (json['debit_msat'] as num?)?.toInt() ?? 0,
        entries: (json['entries'] as num?)?.toInt() ?? 0,
      );
}

/// Plugin del nodo: bastano nome corto e stato.
class LightningPluginInfo {
  const LightningPluginInfo({
    required this.name,
    this.active = false,
    this.isDynamic = false,
  });

  final String name;
  final bool active;

  /// True se è stato caricato a runtime (plugin dinamico).
  final bool isDynamic;

  factory LightningPluginInfo.fromJson(Map<String, dynamic> json) =>
      LightningPluginInfo(
        name: '${json['name'] ?? ''}',
        active: json['active'] as bool? ?? false,
        isDynamic: json['dynamic'] as bool? ?? false,
      );
}
