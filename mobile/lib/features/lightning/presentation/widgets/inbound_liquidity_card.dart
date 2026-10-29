import 'package:flutter/material.dart';

import '../../../../core/services/lightning/lightning_service.dart';
import 'inbound_liquidity_notice.dart';

/// Variante con I/O di [InboundLiquidityNotice]: legge i canali del nodo e
/// mostra l'avviso solo quando l'assenza di liquidità in entrata è dimostrata.
///
/// // PERCHÉ (adozione, 26/10): usata dove la lista dei canali NON è già in
/// // memoria (schermata *Ricevi*). Il widget è **self-gating**: un errore di
/// // rete non deve produrre un falso «non puoi ricevere».
class InboundLiquidityCard extends StatefulWidget {
  const InboundLiquidityCard({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<InboundLiquidityCard> createState() => _InboundLiquidityCardState();
}

class _InboundLiquidityCardState extends State<InboundLiquidityCard> {
  /// `null` = non ancora letto (o lettura fallita) → nessun avviso.
  int? _inboundSats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channels = await widget.lightningService.listChannels();
      if (!mounted) return;
      setState(() {
        _inboundSats = InboundLiquidityNotice.inboundOf(channels);
        _loading = false;
      });
    } catch (e) {
      // PERCHÉ: nodo non raggiungibile → non sappiamo se la liquidità manca.
      debugPrint('[LoopEngineer] inbound: lettura canali fallita: $e');
      if (!mounted) return;
      setState(() {
        _inboundSats = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => InboundLiquidityNotice(
        inboundSats: _inboundSats,
        onRefresh: _loading ? null : _load,
      );
}
