import 'app_localizations.dart';

/// Identificatori dei pallini "info": UNO per concetto, non per punto di
/// aggancio (es. `coinControl` si usa sia nel dettaglio wallet sia nell'invio).
enum InfoHintId {
  coinControl,
  dustLimit,
  feeRate,
  batchSend,
  bumpFee,
  xpub,
  receiveAddress,
  watchOnly,
  signVerify,
  channelCapacity,
  channelReserve,
  toSelfDelay,
  htlc,
  openChannelPrivate,
  routingFees,
  forceClose,
  peers,
  nodeManagement,
}

/// Tabella unica id → stringhe localizzate. Lo `switch` è esaustivo: aggiungere
/// un id senza la relativa chiave ARB non compila.
extension InfoHintL10n on AppLocalizations {
  String infoTitle(InfoHintId id) => switch (id) {
        InfoHintId.coinControl => infoCoinControlTitle,
        InfoHintId.dustLimit => infoDustLimitTitle,
        InfoHintId.feeRate => infoFeeRateTitle,
        InfoHintId.batchSend => infoBatchSendTitle,
        InfoHintId.bumpFee => infoBumpFeeTitle,
        InfoHintId.xpub => infoXpubTitle,
        InfoHintId.receiveAddress => infoReceiveAddressTitle,
        InfoHintId.watchOnly => infoWatchOnlyTitle,
        InfoHintId.signVerify => infoSignVerifyTitle,
        InfoHintId.channelCapacity => infoChannelCapacityTitle,
        InfoHintId.channelReserve => infoChannelReserveTitle,
        InfoHintId.toSelfDelay => infoToSelfDelayTitle,
        InfoHintId.htlc => infoHtlcTitle,
        InfoHintId.openChannelPrivate => infoOpenChannelPrivateTitle,
        InfoHintId.routingFees => infoRoutingFeesTitle,
        InfoHintId.forceClose => infoForceCloseTitle,
        InfoHintId.peers => infoPeersTitle,
        InfoHintId.nodeManagement => infoNodeManagementTitle,
      };

  String infoBody(InfoHintId id) => switch (id) {
        InfoHintId.coinControl => infoCoinControlBody,
        InfoHintId.dustLimit => infoDustLimitBody,
        InfoHintId.feeRate => infoFeeRateBody,
        InfoHintId.batchSend => infoBatchSendBody,
        InfoHintId.bumpFee => infoBumpFeeBody,
        InfoHintId.xpub => infoXpubBody,
        InfoHintId.receiveAddress => infoReceiveAddressBody,
        InfoHintId.watchOnly => infoWatchOnlyBody,
        InfoHintId.signVerify => infoSignVerifyBody,
        InfoHintId.channelCapacity => infoChannelCapacityBody,
        InfoHintId.channelReserve => infoChannelReserveBody,
        InfoHintId.toSelfDelay => infoToSelfDelayBody,
        InfoHintId.htlc => infoHtlcBody,
        InfoHintId.openChannelPrivate => infoOpenChannelPrivateBody,
        InfoHintId.routingFees => infoRoutingFeesBody,
        InfoHintId.forceClose => infoForceCloseBody,
        InfoHintId.peers => infoPeersBody,
        InfoHintId.nodeManagement => infoNodeManagementBody,
      };
}
