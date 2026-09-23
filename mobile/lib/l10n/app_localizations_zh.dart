// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => '无连接';

  @override
  String get homeNoConnectionCreate => '没有网络连接无法创建钱包。地址需要在网络上验证。连接恢复后请重试。';

  @override
  String get homeNoConnectionImport => '没有网络连接无法导入钱包。';

  @override
  String get homeOk => '确定';

  @override
  String get homeWalletCreated => '钱包创建成功。';

  @override
  String homeWalletCreateError(Object error) {
    return '创建钱包错误：$error';
  }

  @override
  String get homeImportWallet => '导入钱包';

  @override
  String get homeCreateWallet => '创建钱包';

  @override
  String get homeSelected => '已选择';

  @override
  String get homeDeleteSelected => '删除所选';

  @override
  String homeDeleteConfirm(int count) {
    return '删除 $count 个钱包？此操作不可逆。';
  }

  @override
  String homeDeleted(Object count) {
    return '已成功删除 $count 个钱包。';
  }

  @override
  String get homeWalletImported => '钱包导入成功。';

  @override
  String get homeSecurityWarning =>
      '本软件按\"原样\"提供，不作任何担保。制造商对资金损失、盗窃、黑客攻击、交易错误或因使用本应用而产生的任何损害概不负责。钱包不保证防止种子先前副本。仅用于小额资金。';

  @override
  String get homeDisclaimerAccept => '接受';

  @override
  String get legalInfoTitle => '法律信息';

  @override
  String get homeLocalWallets => '本地钱包';

  @override
  String homeErrorLoading(Object error) {
    return '加载钱包错误：$error';
  }

  @override
  String get homeEmptyTitle => '无钱包';

  @override
  String get homeEmptySubtitle => '创建您的第一个比特币钱包以开始使用。';

  @override
  String get homeBalanceTitle => '活跃余额';

  @override
  String get balanceUnavailable => '余额不可用';

  @override
  String get homeBackupVerified => '备份已验证';

  @override
  String get homeBackupNotVerified => '备份未验证';

  @override
  String get homeLockVault => '锁定保险库';

  @override
  String get homeVaultLocked => '保险库已锁定';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionSecurity => '安全';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionTools => '工具';

  @override
  String get settingsSectionInfo => '信息';

  @override
  String get settingsTheme => '深色主题';

  @override
  String get settingsAppLock => '应用锁';

  @override
  String get settingsAppLockDesc => '每次打开都要求生物识别或手机密码';

  @override
  String get settingsAppLockUnavailable => '此设备未注册生物识别';

  @override
  String get settingsAppLockEnableFailed => '验证失败：应用锁未启用';

  @override
  String get settingsAppLockEnabled => '应用锁已启用';

  @override
  String get settingsAppLockDisabled => '应用锁已禁用';

  @override
  String get settingsExplorerMirrors => '备用区块浏览器';

  @override
  String get settingsExplorerMirrorsDesc =>
      '如果 mempool.guide 无响应，本应用会查询两个社区镜像。关闭后仅使用 mempool.guide。';

  @override
  String get settingsSectionInterface => '界面';

  @override
  String get settingsInfoDots => '信息提示';

  @override
  String get settingsInfoDotsDesc => '显示解释每个功能的小信息按钮';

  @override
  String get infoCoinControlTitle => '硬币控制（UTXO 选择）';

  @override
  String get infoCoinControlBody =>
      '你的余额由 UTXO 组成，即你收到的碎片。在这里你可以选择哪些要花费：交易将只使用这些，让你可以将小额或不活跃的碎片保留在一旁。';

  @override
  String get infoDustLimitTitle => '最低金额（灰尘）';

  @override
  String get infoDustLimitBody => '低于 546 sat 的输出会被网络拒绝为灰尘。低于该限额的金额无法发送。';

  @override
  String get infoFeeRateTitle => '交易费用';

  @override
  String get infoFeeRateBody =>
      '费用按交易大小的单位支付（sat/vB）：你想要确认的速度越快，支付的越多。经济型可能需要数小时，优先型只需几分钟。自定义适用于你知道当前 mempool 费率的情况。';

  @override
  String get infoBatchSendTitle => '多个收件人（批量）';

  @override
  String get infoBatchSendBody =>
      '在单笔交易中，你可以支付给最多 5 个地址，分摊费用而不是每次转账支付一次。所有收件人在签名前都会在确认中显示。';

  @override
  String get infoBumpFeeTitle => '增加费用（RBF）';

  @override
  String get infoBumpFeeBody =>
      '待处理交易可以被一笔支付更高费用的新交易替换（BIP125）。原始交易被取消，只有替换交易可以确认——目标地址和金额保持不变。';

  @override
  String get infoXpubTitle => '账户公钥（xpub）';

  @override
  String get infoXpubBody =>
      'xpub 生成你所有的接收地址。它不能移动资金，但会揭示完整的余额和历史：只与你信任的应用分享（例如只读钱包）。';

  @override
  String get infoReceiveAddressTitle => '接收地址';

  @override
  String get infoReceiveAddressBody =>
      '每次接收都会显示一个全新的地址，从未使用过的地址中选择：这样可以保持支付不可关联。重复使用地址不是错误，只是让你的交易更容易被追踪。';

  @override
  String get infoWatchOnlyTitle => '只读钱包';

  @override
  String get infoWatchOnlyBody =>
      '你只导入了 xpub：应用可以看到余额和历史，但不持有私钥，因此无法签名。要从这个钱包支出，你需要持有 seed 的设备。';

  @override
  String get infoSignVerifyTitle => '签名/验证消息';

  @override
  String get infoSignVerifyBody =>
      '签名证明一个地址是你的，而无需移动资金。任何人都可以随后针对该地址和相同消息验证签名。';

  @override
  String get infoChannelCapacityTitle => '通道容量';

  @override
  String get infoChannelCapacityBody =>
      '通道中的聪的总金额，由你和你的节点伙伴平分。更多容量意味着能够处理更大的支付。容量 = 本地余额 + 远程余额。';

  @override
  String get infoChannelReserveTitle => '通道储备';

  @override
  String get infoChannelReserveBody =>
      '你的一部分资金必须作为安全保证金保持锁定（\'储备金\'）。它确保双方都有损失——如果另一方恶意离线，储备金可用于在链上惩罚他们。';

  @override
  String get infoToSelfDelayTitle => '自延迟时间';

  @override
  String get infoToSelfDelayBody =>
      '在强制关闭的情况下，你的链上输出将延迟此数量的区块（通常为 144 = ~1 天）。这给你的节点伙伴时间先领取他们的资金，防止通道状态上的双花攻击。';

  @override
  String get infoHtlcTitle => 'HTLC（哈希时间锁定合约）';

  @override
  String get infoHtlcBody =>
      'HTLC 是一种条件支付：资金被锁定，直到接收方揭示哈希预映像。在 Lightning 网络中，HTLC 实现即时链下路由——你的支付跨越多个通道，而不信任任何中间人。';

  @override
  String get infoOpenChannelPrivateTitle => '私人通道';

  @override
  String get infoOpenChannelPrivateBody =>
      '私人通道不会向网络公告。只有你和你的节点伙伴知道它的存在。当你不希望其他人通过它路由时使用（隐私），或者当通道太小不足以用于路由时。';

  @override
  String get infoRoutingFeesTitle => '路由费用';

  @override
  String get infoRoutingFeesBody =>
      '当其他节点通过你的通道路由支付时，你赚取费用。基础费用（sat）按每次支付收取；费率（ppm）与金额成比例。CLTV 延迟限制转发的 HTLC 结算所需的时间。';

  @override
  String get infoForceCloseTitle => '强制关闭';

  @override
  String get infoForceCloseBody =>
      '在你的链上广播最新的通道状态。这是不可逆的，需要等待自延迟时间后才能花费你的资金。仅在你的节点伙伴无响应或恶意时使用——合作关闭总是更快更便宜。';

  @override
  String get infoPeersTitle => '已连接的节点伙伴';

  @override
  String get infoPeersBody =>
      '节点伙伴是与你通过 TCP/Tor 直接连接的其他 Lightning 节点。每个节点伙伴可以有一个或多个通道。你可以连接到新的节点伙伴以打开通道并增加你节点的流动性和路由能力。';

  @override
  String get infoNodeManagementTitle => '节点管理';

  @override
  String get infoNodeManagementBody =>
      '你的 Lightning 节点身份：公钥、版本、活跃/待处理的通道和节点伙伴数量。此屏幕显示节点 bookkeeper 插件的会计数据和转发统计信息。';

  @override
  String get appLockTitle => '应用已锁定';

  @override
  String get appLockSubtitle => '使用生物识别或手机密码解锁';

  @override
  String get appLockUnlock => '解锁';

  @override
  String get appLockReason => '解锁钱包';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      '应用锁已禁用：手机的屏幕保护（生物识别/密码）已不可用。请在系统设置中重新启用后使用应用锁。';

  @override
  String get appLockNoticeContinue => '继续';

  @override
  String get appLockPromptTitle => '启用应用锁？';

  @override
  String get appLockPromptMessage => '打开应用时将要求生物识别或手机密码。';

  @override
  String get appLockPromptEnable => '启用';

  @override
  String get appLockPromptLater => '稍后';

  @override
  String get aboutLicensesOpenOnline => '在线打开';

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return '钱包 $name$balance';
  }

  @override
  String get walletDetailTitle => '钱包';

  @override
  String walletDetailCopied(Object label) {
    return '$label 已复制。将在 60 秒后删除。';
  }

  @override
  String get walletDetailAddress => '地址';

  @override
  String get walletDetailTransactions => '交易';

  @override
  String get walletDetailTxBlockHeight => '区块高度';

  @override
  String get walletDetailTxConfirmations => '确认数';

  @override
  String get walletDetailTxDate => '日期';

  @override
  String get walletDetailTxDetails => '交易详情';

  @override
  String get walletDetailTxEmpty => '暂无交易';

  @override
  String get walletDetailTxError => '无法加载交易';

  @override
  String get walletDetailTxExport => '导出';

  @override
  String get walletDetailTxExportCsv => 'CSV（表格）';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return '已复制到剪贴板（$fileName）';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return '已开始下载（$fileName）';
  }

  @override
  String get walletDetailTxExportFailed => '导出失败';

  @override
  String get walletDetailTxExportJson => 'JSON（完整）';

  @override
  String get walletDetailTxFee => '手续费';

  @override
  String get walletDetailTxIncoming => '收到';

  @override
  String get walletDetailTxNote => '备注';

  @override
  String get walletDetailTxNoteAdd => '添加备注';

  @override
  String get walletDetailTxNoteEdit => '编辑备注';

  @override
  String get walletDetailTxNoteHint => '私密备注，仅保存在本设备上';

  @override
  String get walletDetailTxNoteRemove => '移除';

  @override
  String get walletDetailTxOrphan => '孤儿 (丢失的区块)';

  @override
  String get walletDetailTxOutgoing => '发送';

  @override
  String get walletDetailTxPending => '待确认';

  @override
  String get walletDetailTxReplaced => '已替换（已从内存池移除）';

  @override
  String get walletDetailTxRetry => '重试';

  @override
  String get backupSeedTitle => '助记词备份';

  @override
  String get backupSeedIntro => '将助记词写在纸上并妥善保管。这是恢复资金的唯一方法。';

  @override
  String get backupSeedStart => '开始备份';

  @override
  String get backupSeedLater => '稍后';

  @override
  String get backupSeedSavedContinue => '我已保存助记词';

  @override
  String get backupSeedVerifyTitle => '验证备份';

  @override
  String get backupSeedVerifyHint => '输入3个高亮单词以确认已保存。';

  @override
  String backupSeedWordLabel(Object number) {
    return '单词 $number';
  }

  @override
  String get backupSeedVerifyError => '单词错误，请重试。';

  @override
  String get backupSeedDone => '备份完成';

  @override
  String get backupSeedDoneDesc => '助记词已安全保存。请记住：拥有助记词的人控制资金。';

  @override
  String get backupSeedFinish => '完成';

  @override
  String get backupSeedSkipWarning => '如果跳过，丢失设备时可能无法找回资金。之后可在钱包详情中完成。';

  @override
  String get walletDetailSend => '发送';

  @override
  String get walletDetailReceive => '接收';

  @override
  String get sendScreenTitle => '发送 BTC';

  @override
  String get sendScreenAddressLabel => '接收地址';

  @override
  String get sendScreenAmountLabel => '金额 (BTC)';

  @override
  String get sendScreenFeeLabel => '费用';

  @override
  String get sendScreenFeeLow => '低';

  @override
  String get sendScreenFeeNormal => '正常';

  @override
  String get sendScreenFeeHigh => '高';

  @override
  String get sendScreenFeeCustom => '自定义';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return '可用：$balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return '预估费用：$fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'UTXO 选择';

  @override
  String get sendScreenUtxoSelectAll => '全选';

  @override
  String get sendScreenUtxoNoneSelected => '请至少选择一个要发送的 UTXO';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return '总计：$total $ticker';
  }

  @override
  String get sendScreenMax => '最大值';

  @override
  String get sendScreenSend => '发送';

  @override
  String get sendScreenSending => '发送中...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return '已删除 $deleted 个钱包，$errors 个错误：$error';
  }

  @override
  String get walletDetailBalanceLabel => '余额';

  @override
  String get walletDetailMasterFingerprint => '主指纹';

  @override
  String get walletDetailDerivationPath => '派生路径';

  @override
  String get walletDetailSettings => '设置';

  @override
  String get walletDetailAdvancedTools => '高级工具';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => '未找到可花费的UTXO';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count 个确认';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '已选 $count 个 · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => '发送所选';

  @override
  String get walletDetailUtxoClearSelection => '清除选择';

  @override
  String get walletDetailPasswordSeedReason => '确认密码以查看助记词';

  @override
  String get walletDetailBiometricSeedReason => '生物识别确认以查看助记词';

  @override
  String get walletDetailPasswordBumpReason => '确认密码以提高手续费';

  @override
  String get walletDetailBiometricBumpReason => '生物识别确认以提高手续费';

  @override
  String get walletDetailTxBumpFee => '提高手续费';

  @override
  String get walletDetailBumpFeeTitle => '提高交易手续费';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return '当前手续费：$fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable => '暂无推荐手续费 — 请输入自定义费率';

  @override
  String get walletDetailBumpFeeWarning => '如果替换交易被挖出，原始交易可能永远不会确认。';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return '手续费已提高 — 新交易 $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee => '新手续费必须高于当前手续费';

  @override
  String get sendScreenSigning => '正在签署交易...';

  @override
  String get sendScreenBroadcasting => '正在广播到网络...';

  @override
  String get sendScreenBiometricReason => '生物识别确认以授权交易';

  @override
  String get sendScreenPasswordReason => '输入密码以授权交易';

  @override
  String get sendScreenBiometricRequired => '发送需要生物识别。请在设备设置中启用指纹或面容解锁。';

  @override
  String get sendScreenFeeTime2h => '约2小时';

  @override
  String get sendBatchToggle => 'Multiple recipients';

  @override
  String get sendBatchToggleSingle => 'Single recipient';

  @override
  String sendBatchRecipientLabel(int index) {
    return 'Recipient $index';
  }

  @override
  String get sendBatchAddRecipient => 'Add recipient';

  @override
  String get sendBatchRemoveRecipient => 'Remove';

  @override
  String get sendBatchMaxRecipients => 'Maximum 20 recipients';

  @override
  String get sendBatchTotalLabel => 'Total to recipients';

  @override
  String get sendBatchDustError => 'Minimum 546 sat per recipient';

  @override
  String get sendBatchDuplicateError => 'Duplicate address';

  @override
  String get sendBatchMinRecipients =>
      'Add at least 2 recipients to send a batch';

  @override
  String sendBatchConfirmRecipients(int count) {
    return '$count recipients';
  }

  @override
  String get sendBatchConfirmTitle => 'Confirm multiple payment';

  @override
  String get sendScreenFeeTime1h => '约1小时';

  @override
  String get sendScreenFeeTime30m => '约30分钟';

  @override
  String get sendScreenFeeTime15m => '约15分钟';

  @override
  String get sendScreenFeeTime10m => '约10分钟';

  @override
  String get sendScreenFeeTime5m => '约5分钟';

  @override
  String sendScreenMaxHelper(Object amount) {
    return '最大：$amount';
  }

  @override
  String sendScreenUtxoSummary(int sats, int count) {
    return '$sats sat · $count 个UTXO';
  }

  @override
  String get importScreenHintText => '助记词由12、15、18、21或24个以空格分隔的单词组成。您可以直接粘贴。';

  @override
  String onboardingSubmitError(Object error) {
    return '错误：$error';
  }

  @override
  String get legalMitLicense => 'MIT 许可证';

  @override
  String get legalSecurityTitle => '安全';

  @override
  String get legalTermsContent =>
      '本服务条款为临时版本，官方网站上线后将被最终版本取代。\n\nBtc Blake2b Wallet 是一款面向实验性网络 \"bitcoin-blake2b\"（比特币的分叉）的自托管比特币钱包。私钥和助记词仅保存在您的设备上：我们不托管、不转移，也无法访问您的资金。\n\n本应用免费提供，\"按原样\"提供，不作任何形式的担保。使用风险由您自行承担。bitcoin-blake2b 网络是从比特币派生的实验性网络：其代币可能没有市场价值，可能不被交易所认可，并可能发生重组。本应用的任何内容均不构成财务或投资建议。\n\n您是助记词和资金的唯一保管责任人：任何持有助记词的人都可以花费这些代币。本应用无法找回丢失的助记词。禁止将本应用用于非法活动。您声明您已年满 16 岁。\n\nBtc Blake2b Wallet 与 Bitcoin、Bitcoin Core 或 bitcoin.org 无关联，也未获得其赞助或认可。';

  @override
  String legalPrivacyContent(String holder, String email) {
    return '本隐私政策为临时版本，官网正式版本发布后将被其取代。\n\n1) 设备上的数据。本应用不要求注册账户，也不会将个人数据保存在作者的服务器上。加密的助记词（AES-256-GCM）、偏好设置和同意记录仅保存在您的设备上。\n\n2) 为正常运行而发送给第三方的数据。为显示余额和手续费，本应用会查询第三方公共 API：\n• mempool.guide（区块链浏览器）。\n• 如果 mempool.guide 不可用，本应用可能会查询两个社区维护的 Esplora 兼容镜像（mempool.kilombino.com、mempool.maveth.ca）。此选项可在设置中关闭。\n每次请求都会传输您的 IP 地址以及所查询钱包的公开地址。私钥和助记词绝不会被传输。\n\n3) 无追踪器。应用内不含任何分析、广告或 Cookie。\n\n4) 权利（GDPR 第 13-14 条）。您有权通过写信给数据控制者行使访问、更正、删除和反对的权利：$holder — $email。由于我们不存储个人数据，这些权利在很大程度上已经通过数据仅保存在您设备上这一事实得到保障。';
  }

  @override
  String legalSecurityContact(String email) {
    return '如需报告安全漏洞，请使用 GitHub 仓库的私密报告 \"Report a vulnerability\"（Security 选项卡），或写信至：\n$email\n\n请勿就安全问题提交公开 issue。响应时间：72 小时。披露政策：90 天。';
  }

  @override
  String get sendScreenSuccess => '交易已发送！';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID：$txid';
  }

  @override
  String get sendScreenValidateAddress => '请输入地址';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return '$network 的地址无效（请使用 $prefix）';
  }

  @override
  String get sendScreenValidateLength => '地址长度无效';

  @override
  String get sendScreenValidateSelf => '无法发送给自己';

  @override
  String get sendScreenValidateAmount => '请输入金额';

  @override
  String get sendScreenValidateInvalidAmount => '金额无效';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return '金额过低（最低 $dust 聪 / $dustBtc）';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return '余额不足（余额：$balance，预估费用：$fee sat）';
  }

  @override
  String get sendScreenLoadingUtxos => '加载 UTXO 中...';

  @override
  String sendScreenUtxoError(Object error) {
    return '无法加载 UTXO：$error';
  }

  @override
  String get scanQrTitle => '扫描二维码';

  @override
  String get scanQrError => '无法访问相机。请授予相机权限后重试。';

  @override
  String get scanQrInvalid => '扫描的代码不是有效的比特币地址。';

  @override
  String get scanQrInvalidInvoice => '扫描的代码不是有效的闪电网络发票。';

  @override
  String get scanQrTorch => '切换手电筒';

  @override
  String get sendConfirmTitle => '确认交易';

  @override
  String get sendConfirmWarning => '此交易不可撤销。确认前请核对详细信息。';

  @override
  String get sendConfirmSend => '确认并发送';

  @override
  String get importScreenTitle => '导入钱包';

  @override
  String get importScreenHeading => '输入助记词';

  @override
  String get importScreenSubtitle =>
      '输入以空格分隔的助记词（12、15、18、21 或 24 个单词），然后选择与原始钱包匹配的账户类型。';

  @override
  String get importScriptTypeLabel => '账户类型';

  @override
  String get importScriptTypeNativeSegwit => '原生 SegWit (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => '嵌套 SegWit (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => '要创建的钱包类型';

  @override
  String importScriptTypeHint(String prefix) {
    return '地址以 $prefix 开头';
  }

  @override
  String get importScreenHint => 'word1 word2 word3 ...';

  @override
  String get importScreenValidateEmpty => '请输入助记词。';

  @override
  String importScreenValidateCount(Object count) {
    return '助记词必须包含 12、15、18、21 或 24 个单词（检测到：$count）。';
  }

  @override
  String get importScreenValidateInvalid => '助记词无效。请检查单词拼写。';

  @override
  String get importScreenImport => '导入';

  @override
  String get importModeSeed => '助记词';

  @override
  String get importModeWatchOnly => '仅观察（xpub）';

  @override
  String get importWatchOnlySubtitle =>
      '仅使用外部钱包的公开扩展密钥监控其余额和历史记录。不涉及私钥——永远无法发送。';

  @override
  String get importWatchOnlyXpubLabel => '账户 xpub';

  @override
  String get importWatchOnlyXpubHint =>
      '粘贴账户 xpub（以 \"xpub\" 开头）。仅限公钥：切勿粘贴 xprv。';

  @override
  String get importWatchOnlyValidateEmpty => '请输入账户 xpub。';

  @override
  String get importWatchOnlyValidatePrefix => 'xpub 必须以 \"xpub\" 开头（主网）。';

  @override
  String get watchOnlyBadge => '仅观察';

  @override
  String get passwordDialogCreateTitle => '创建安全密码';

  @override
  String get passwordDialogCreateHint => '输入安全密码';

  @override
  String get passwordDialogCreateConfirm => '确认密码';

  @override
  String get passwordDialogCreate => '创建';

  @override
  String get passwordDialogCancel => '取消';

  @override
  String get passwordDialogEnterTitle => '输入密码';

  @override
  String get passwordDialogEnterHint => '输入您的密码';

  @override
  String get passwordDialogEnter => '确认';

  @override
  String get passwordDialogWrong => '密码错误';

  @override
  String get languageSelector => '语言';

  @override
  String get languageSelectorAuto => '🌐 自动（跟随系统）';

  @override
  String get languageSelectorEn => '🇬🇧 English';

  @override
  String get languageSelectorIt => '🇮🇹 Italiano';

  @override
  String get languageSelectorDe => '🇩🇪 Deutsch';

  @override
  String get languageSelectorFi => '🇫🇮 Suomi';

  @override
  String get languageSelectorEs => '🇪🇸 Español';

  @override
  String get languageSelectorZhCN => '🇨🇳 中文';

  @override
  String get languageSelectorFrCA => '🇨🇦 Français (CA)';

  @override
  String get walletDetailRefresh => '刷新';

  @override
  String get walletDetailDeleteTitle => '删除钱包？';

  @override
  String get walletDetailDeleteConfirm => '永久删除';

  @override
  String get walletDetailDeleteWarning => '此操作不可逆。如果钱包中有资金，请确保已备份助记词。';

  @override
  String get walletDetailInfo => '钱包信息';

  @override
  String get walletDetailNameLabel => '钱包名称';

  @override
  String get walletDetailNameHint => '例如：家庭储蓄';

  @override
  String get walletDetailType => '类型';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => '嵌套 SegWit (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => '更新中...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count 笔交易';
  }

  @override
  String get walletDetailReceiveQr => '接收比特币';

  @override
  String get walletDetailSignVerify => '签署/验证消息';

  @override
  String get walletDetailShowAddresses => '显示地址';

  @override
  String get walletDetailWalletAddress => '钱包地址';

  @override
  String get walletDetailExportSeed => '导出/备份助记词';

  @override
  String get walletDetailShowSeedTitle => '查看助记词？';

  @override
  String get walletDetailShowSeedContent => '助记词可访问所有资金。请确保您处于安全的环境中。';

  @override
  String get walletDetailShowSeedConfirm => '是，显示';

  @override
  String get walletDetailSeedVerifyPrompt => '是否要验证您已保存助记词？';

  @override
  String get walletDetailSeedVerifyYes => '是，验证';

  @override
  String get walletDetailSeedVerifyNotNow => '暂不';

  @override
  String get walletDetailSeedVerified => '备份已验证';

  @override
  String get walletDetailSeedHidden => '出于安全原因已隐藏助记词';

  @override
  String get walletDetailSeedShowAgain => '显示助记词';

  @override
  String get walletDetailHideSeed => '隐藏';

  @override
  String get walletDetailBackupNotConfirmed => '备份未确认';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      '您尚未保存助记词。如果丢失设备或重新安装应用，您将永久失去对资金的访问权。';

  @override
  String get walletDetailShowXpub => '显示钱包 XPUB';

  @override
  String get walletDetailDisplayHome => '在主页显示余额';

  @override
  String get walletDetailUtxoRename => '重命名';

  @override
  String get walletDetailUtxoRenameTitle => '重命名 UTXO';

  @override
  String get walletDetailSave => '保存';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => '创建于';

  @override
  String get walletDetailClose => '关闭';

  @override
  String get walletDetailSign => '签名';

  @override
  String get walletDetailVerify => '验证';

  @override
  String get walletDetailSignMessage => '签署消息';

  @override
  String get walletDetailVerifyMessage => '验证消息';

  @override
  String get walletDetailMessage => '消息';

  @override
  String get walletDetailBitcoinAddress => '比特币地址';

  @override
  String get walletDetailSignature => '签名（Base64）';

  @override
  String get walletDetailResult => '结果：';

  @override
  String get walletDetailSignatureLabel => '签名：';

  @override
  String get walletDetailCopy => '复制';

  @override
  String get walletDetailAddressCopied => '地址已复制到剪贴板';

  @override
  String get walletDetailXpubTitle => '钱包 XPUB';

  @override
  String get walletDetailXpubDesc => '此 XPUB 可查看所有未来地址和余额，但无法花费资金。';

  @override
  String get walletDetailXpubCopied => 'XPUB 已复制';

  @override
  String walletDetailErrorXpub(Object error) {
    return '派生 XPUB 出错：$error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return '派生地址出错：$error';
  }

  @override
  String get walletDetailValidSig => '签名有效 ✓';

  @override
  String get walletDetailInvalidSig => '签名无效 ✗';

  @override
  String get donateTitle => '支持本项目 ❤️';

  @override
  String get donatePhrase => '☕ \"如果项目对您有用，请我们喝杯虚拟咖啡\"';

  @override
  String get donateAddressLabel => '比特币捐赠地址：';

  @override
  String get donateCopy => '复制';

  @override
  String get donateCopied => '已复制！✓';

  @override
  String get donateNote => '自愿捐赠 — 不提供任何服务或利益作为回报。任何金额都欢迎，即使只有几个聪。谢谢！🧡';

  @override
  String get donateNoWalletTitle => '未找到钱包';

  @override
  String get donateNoWalletMessage => '您的设备上未找到比特币钱包应用。您仍可复制地址并粘贴到您常用的钱包中。';

  @override
  String get donateOpenWallet => '在钱包中打开';

  @override
  String get donateButton => '支持本项目 ❤️';

  @override
  String get onboardingTitle => '欢迎使用 Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle => '开源比特币钱包。自主托管。无需 KYC。';

  @override
  String get onboardingResidenceLabel => '税务居住国';

  @override
  String get onboardingResidenceHint => '选择您的国家';

  @override
  String get onboardingReverseSolicitation =>
      '我声明我主动使用 Btc Blake2b Wallet（\"反向招揽\"），且我的税务居住地在所选国家。';

  @override
  String get onboardingTermsAccept => '我接受';

  @override
  String get onboardingPrivacyAccept => '我已阅读';

  @override
  String get onboardingAgeConfirm => '我声明我年满 16 周岁';

  @override
  String get onboardingAgeSubtitle => 'GDPR 第 8 条要求进行数据处理同意';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingStepNext => '下一步';

  @override
  String get onboardingStepBack => '返回';

  @override
  String onboardingStepOf(Object current, Object total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get onboardingTermsTitle => '条款与隐私';

  @override
  String get onboardingValidationResidence => '选择您的税务居住国';

  @override
  String get onboardingLinkTerms => '服务条款';

  @override
  String get onboardingLinkPrivacy => '隐私政策';

  @override
  String get aboutTitle => '关于 Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet 是一个开源的自托管比特币钱包。无需注册，无需 KYC，无需追踪。您的密钥，您的比特币。';

  @override
  String get aboutLicenseTitle => '许可证';

  @override
  String get aboutThirdPartyLicenses => '第三方许可证';

  @override
  String get aboutThirdPartyLicensesDesc => '查看完整的开源许可证列表';

  @override
  String get aboutBuiltWith => '技术栈';

  @override
  String get aboutDisclaimer => '本软件按\"原样\"提供，不提供任何形式的保证。';

  @override
  String get explorerTitle => '区块浏览器';

  @override
  String get explorerAddressLabel => '地址';

  @override
  String get explorerRefresh => '刷新';

  @override
  String get explorerBalanceLabel => '余额';

  @override
  String get explorerTxCount => '交易';

  @override
  String get explorerTipHeight => '节点高度';

  @override
  String get explorerErrorInvalidAddress => '地址无效。请检查此网络的格式。';

  @override
  String get explorerErrorRateLimited => '请求频率超限。请一分钟后重试。';

  @override
  String get explorerErrorNodeUnavailable => '服务暂时不可用。请稍后重试。';

  @override
  String get explorerErrorNotFound => '未找到地址或交易。';

  @override
  String get explorerErrorTimeout => '请求超时。请检查连接后重试。';

  @override
  String get explorerErrorNetwork => '网络不可用。请检查连接。';

  @override
  String get explorerRetry => '重试';

  @override
  String explorerErrorGeneric(String error) {
    return '错误：$error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => '未连接 Lightning 节点';

  @override
  String get lightningDisconnectedBody =>
      '连接您的 blake2b Lightning 节点以发送和接收付款。应用不会保管您的资金或密钥。';

  @override
  String get lightningConnectButton => '连接节点';

  @override
  String get lightningConnectTitle => '连接 Lightning 节点';

  @override
  String get lightningConnectHint => '粘贴连接字符串（nostr+walletconnect://…）';

  @override
  String get lightningConnectInvalidUri => '连接字符串无效';

  @override
  String get lightningConnectRecentNodes => '最近使用的节点';

  @override
  String get lightningConnectInfo => '节点必须授权此应用（grant）：请检查节点的控制面板。';

  @override
  String get lightningConnecting => '连接中…';

  @override
  String get lightningConnected => '已连接';

  @override
  String get lightningDisconnect => '断开连接';

  @override
  String get lightningBalance => 'Lightning 余额';

  @override
  String get lightningChannels => '通道';

  @override
  String get lightningNoChannels => '无已打开的通道';

  @override
  String get lightningChannelPeer => '对等节点';

  @override
  String get lightningChannelCapacity => '容量';

  @override
  String get lightningChannelLocal => '本地';

  @override
  String get lightningChannelRemote => '远程';

  @override
  String get lightningOpenChannel => '打开通道';

  @override
  String get lightningOpenChannelNodeId => 'Node ID（公钥）';

  @override
  String get lightningOpenChannelHost => '主机（可选，ip:端口）';

  @override
  String get lightningOpenChannelAmount => '金额（聪）';

  @override
  String get lightningOpenChannelPrivate => '私有通道';

  @override
  String get lightningChannelOpened => '已请求打开通道';

  @override
  String get lightningCloseChannel => '关闭通道';

  @override
  String get lightningCloseChannelForce => '强制关闭';

  @override
  String get lightningCloseChannelForceWarning =>
      '强制关闭会在链上广播通道的最新状态。可能产生费用和延迟。是否继续？';

  @override
  String get lightningReceive => '接收';

  @override
  String get lightningSend => '发送';

  @override
  String get lightningInvoiceAmount => '金额（聪）';

  @override
  String get lightningInvoiceDescription => '描述（可选）';

  @override
  String get lightningInvoiceCreate => '创建发票';

  @override
  String get lightningInvoiceTitle => 'Lightning 发票';

  @override
  String get lightningPay => '支付发票';

  @override
  String get lightningPayHint => '粘贴发票（lnbc…）';

  @override
  String get lightningPayDialogTitle => '确认 Lightning 支付';

  @override
  String get lightningPayDialogBody => '支付此发票吗？';

  @override
  String get lightningPaySuccess => '付款已发送';

  @override
  String get lightningCopied => '已复制';

  @override
  String get lightningErrorRestricted => '节点未授权此应用。请为此次连接在节点上创建 grant。';

  @override
  String lightningErrorGeneric(String error) {
    return 'Lightning 错误：$error';
  }

  @override
  String get lightningConfirm => '确认';

  @override
  String get lightningCancel => '取消';

  @override
  String get lightningNodeOnchain => '节点链上';

  @override
  String get lightningDeposit => '充值';

  @override
  String get lightningWithdraw => '链上转账';

  @override
  String get lightningDepositTitle => '链上充值';

  @override
  String get lightningDepositHint => '将 blake2b 资金发送到此节点地址。';

  @override
  String get lightningDepositNewAddress => '新地址';

  @override
  String get lightningDepositWarning => '仅限 blake2b 网络。发送到错误网络的资金将丢失。';

  @override
  String get lightningOnchainSendTitle => '链上转账';

  @override
  String get lightningOnchainAddressLabel => '收款地址';

  @override
  String get lightningOnchainAmountLabel => '金额（sat）';

  @override
  String get lightningOnchainFeeLabel => '网络手续费';

  @override
  String get lightningOnchainFeeMin => '最低';

  @override
  String get lightningOnchainFeeEconomical => '经济';

  @override
  String get lightningOnchainFeePriority => '优先';

  @override
  String get lightningOnchainConfirm => '确认发送';

  @override
  String get lightningOnchainConfirmTitle => '确认链上转账？';

  @override
  String get lightningOnchainWarning => '不可撤销操作：资金将离开节点。';

  @override
  String get lightningOnchainSuccess => '交易已发送';

  @override
  String get lightningOnchainInvalidAddress => '无效的 blake2b 地址';

  @override
  String get lightningOnchainInsufficient => '链上余额不足';

  @override
  String get lightningFeesUnavailable => '手续费估算不可用：将由节点选择手续费';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey 或 pubkey@host:port（onion 需要节点上的 Tor）';

  @override
  String get lightningOpenChannelInvalid =>
      '节点 ID 或 host 无效（66 位十六进制，host:port）';

  @override
  String get lightningActivityDetected => '检测到节点活动';

  @override
  String get lightningPeers => '对等节点';

  @override
  String get lightningPeersEmpty => '没有已连接的对等节点';

  @override
  String get lightningConnectPeer => '连接对等节点';

  @override
  String get lightningDisconnectPeer => '断开';

  @override
  String get lightningPeerDisconnected => '已断开';

  @override
  String get lightningPeerId => '对等节点 ID';

  @override
  String get lightningPeerAddresses => '地址';

  @override
  String get lightningDisconnectPeerConfirm => '断开此对等节点？已打开的通道保持活跃。';

  @override
  String get lightningChannelDetail => '通道详情';

  @override
  String get lightningChannelShortId => '短通道 ID';

  @override
  String get lightningChannelState => '节点状态';

  @override
  String get lightningChannelFee => '手续费';

  @override
  String get lightningChannelSpendable => '可用';

  @override
  String get lightningChannelReceivable => '可接收';

  @override
  String get lightningChannelHtlcs => 'HTLC';

  @override
  String get lightningChannelFundingTxid => '资金交易 ID';

  @override
  String get lightningNodeManagement => '节点管理';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers 个对等节点 · $channels 个通道';
  }

  @override
  String get lightningNodeIdentity => '节点身份';

  @override
  String get lightningNodePubkey => '公钥';

  @override
  String get lightningNodeVersion => '版本';

  @override
  String get lightningNodePeersCount => '对等节点';

  @override
  String get lightningNodeChannelsActive => '活动通道';

  @override
  String get lightningNodeChannelsPending => '待确认通道';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      '此节点不支持：需要 liquidity-ads 插件才能公布租赁条款。';

  @override
  String get lightningLiquidity => '流动性';

  @override
  String get lightningLiquidityTotal => '总容量';

  @override
  String get lightningLiquidityOutbound => '出站';

  @override
  String get lightningLiquidityInbound => '入站';

  @override
  String get lightningLiquidityWarning => '没有入站流动性：在对等节点向此节点开启通道前无法收款。';

  @override
  String get lightningMovements => '交易记录';

  @override
  String get lightningMovementsEmpty => '暂无记录';

  @override
  String get lightningMovementsAll => '全部记录';

  @override
  String get lightningMovementsLoadMore => '加载更多';

  @override
  String get lightningMovementDeposit => '链上充值';

  @override
  String get lightningMovementWithdrawal => '链上发送';

  @override
  String get lightningMovementChannelOpen => '通道开启';

  @override
  String get lightningMovementChannelClose => '通道关闭';

  @override
  String get lightningMovementInvoice => '闪电支付';

  @override
  String get lightningMovementOnchainFee => '链上手续费';

  @override
  String get lightningMovementForward => '转发';

  @override
  String get lightningMovementOther => '记录';

  @override
  String lightningChannelsAll(int count) {
    return '全部通道（$count）';
  }

  @override
  String get lightningOnchainNode => '节点链上';

  @override
  String get lightningOnchainBalance => '链上余额';

  @override
  String get lightningOnchainConfirmed => '已确认';

  @override
  String get lightningOnchainPending => '待确认';

  @override
  String get lightningOnchainUtxos => 'UTXO';

  @override
  String get lightningOnchainUtxosEmpty => '没有 UTXO';

  @override
  String get lightningOnchainAddresses => '节点地址';

  @override
  String get lightningOnchainNewAddress => '新地址';

  @override
  String get lightningOnchainAddressType => '地址类型';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32（bc1q）';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot（bc1p）';

  @override
  String get lightningOnchainHasFunds => '有余额';

  @override
  String get lightningOnchainReserved => '已预留';

  @override
  String get lightningOnchainBlockHeight => '区块';

  @override
  String get lightningPayments => '支付';

  @override
  String get lightningInvoices => '发票';

  @override
  String get lightningInvoicesEmpty => '暂无发票';

  @override
  String get lightningInvoiceStatusPaid => '已支付';

  @override
  String get lightningInvoiceStatusPending => '等待支付';

  @override
  String get lightningInvoiceStatusExpired => '已过期';

  @override
  String lightningInvoicePaidOn(String date) {
    return '支付于 $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return '到期于 $date';
  }

  @override
  String get lightningReceivePaid => '发票已支付';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total 张发票 · $pending 等待中';
  }

  @override
  String get lightningPays => '已发送付款';

  @override
  String get lightningPaysEmpty => '暂无付款';

  @override
  String get lightningPaymentFee => '手续费';

  @override
  String get lightningPaymentCompleted => '已完成';

  @override
  String get lightningPaymentPending => '进行中';

  @override
  String get lightningPaymentFailed => '失败';

  @override
  String get lightningHtlcsEmpty => '没有 HTLC';

  @override
  String get lightningHtlcInProgress => '进行中';

  @override
  String get lightningHtlcIncoming => '入站';

  @override
  String get lightningHtlcOutgoing => '出站';

  @override
  String get lightningChannelFees => '路由费率';

  @override
  String get lightningFeeEdit => '修改费率';

  @override
  String get lightningFeeBefore => '当前';

  @override
  String get lightningFeeAfter => '新的';

  @override
  String get lightningFeeBaseLabel => '基础费 (sat)';

  @override
  String get lightningFeePpmLabel => '比例费 (ppm)';

  @override
  String get lightningHtlcMinLabel => '最小 HTLC (sat)';

  @override
  String get lightningHtlcMaxLabel => '最大 HTLC (sat)';

  @override
  String get lightningCltvLabel => 'CLTV 增量';

  @override
  String get lightningChannelReserve => '我方储备';

  @override
  String get lightningChannelToSelfDelay => '自有延迟';

  @override
  String get lightningFeeConfirmTitle => '应用这些路由费率？';

  @override
  String get lightningFeeWarning => '费率影响被路由的支付。网络每天只接受少量变更，对等节点可能需要时间采用。';

  @override
  String get lightningFeeUpdated => '费率策略已更新';

  @override
  String get lightningDiagnostics => '诊断';

  @override
  String get lightningDiagnosticsSubtitle => '账务、插件与转发';

  @override
  String get lightningStatsEconomy => '经济';

  @override
  String get lightningStatsNet => '净额';

  @override
  String get lightningStatsSource => '来自节点账务（bookkeeper）';

  @override
  String get lightningStatsEmpty => '暂无账务数据';

  @override
  String get lightningStatsTagDeposit => '入金';

  @override
  String get lightningStatsTagInvoice => '发票';

  @override
  String get lightningStatsTagWithdrawal => '提现';

  @override
  String get lightningStatsTagOnchainFee => '链上手续费';

  @override
  String get lightningStatsTagChannelOpen => '通道开启';

  @override
  String get lightningStatsTagChannelClose => '通道关闭';

  @override
  String get lightningStatsTagRouted => '已赚取的路由手续费';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => '插件';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count 个已启用';
  }

  @override
  String get lightningPluginInactive => '未启用';

  @override
  String get lightningForwardsTitle => '转发';

  @override
  String get lightningForwardsEmpty => '还没有转发的支付';

  @override
  String get lightningForwardSettled => '已结算';

  @override
  String get lightningForwardFailed => '失败';

  @override
  String get lightningForwardOffered => '进行中';

  @override
  String get lightningKeysendTitle => '发送到节点（keysend）';

  @override
  String get lightningKeysendHint => '目标节点公钥（66 hex）';

  @override
  String get lightningKeysendAmountLabel => '金额（sat）';

  @override
  String get lightningKeysendMaxFeeLabel => '最大手续费（sat）';

  @override
  String get lightningKeysendMaxFeeHelp => '留空使用节点默认值（0.5%）';

  @override
  String get lightningKeysendWarning => 'Keysend 向没有发票的节点付款：资金立即转出且无法撤销。';

  @override
  String get lightningKeysendConfirmTitle => '发送这笔 keysend 支付？';

  @override
  String get lightningKeysendDestination => '目标';

  @override
  String get lightningKeysendSent => 'Keysend 已发送';

  @override
  String get lightningKeysendInvalidPubkey => '节点公钥无效';

  @override
  String get lightningKeysendInvalidAmount => '请输入大于零的金额';

  @override
  String get lightningKeysendSend => '发送';

  @override
  String get walletAddressesTitle => '地址与 UTXO';

  @override
  String get walletAddressesTabAddresses => '地址';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => '收款 (/0)';

  @override
  String get walletAddressesChangeBranch => '找零 (/1)';

  @override
  String get walletAddressesStatusUnused => '从未使用';

  @override
  String get walletAddressesStatusUsed => '已使用';

  @override
  String get walletAddressesStatusFunds => '有余额';

  @override
  String walletAddressesTxCount(int count) {
    return '$count 笔交易';
  }

  @override
  String get walletAddressesEmpty => '没有可显示的地址';

  @override
  String get walletAddressesHintTap => '点击地址即可复制';

  @override
  String get lightningPeeringGateTitle => '仅允许 bit 68 版本的节点互联';

  @override
  String get lightningPeeringGateBody =>
      '此节点在握手时要求 option_blake2b（bit 68），因此旧版本节点无法连接。这是节点的选择，不是应用或桥接的问题。请使用 .4 或更新版本的节点，或等待社区将该 bit 改为可选。';

  @override
  String get lightningPeeringGateLink => '兼容性矩阵';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count 个已注册节点，均未连接';
  }

  @override
  String get lightningSwapOpen => '无需节点支付发票（swap）';

  @override
  String get lightningSwapWebOnlyNote =>
      '网页版：Lightning 支付通过交换（swap）服务商完成，无需节点。连接自己的节点请使用 Android 应用。';

  @override
  String get lightningSwapTitle => '通过服务商进行 Lightning 支付';

  @override
  String get lightningSwapIntro =>
      '资金始终由你保管：它们进入链上 HTLC（P2WSH），只有在服务商支付你的发票时才会释放。若支付失败，时间锁到期后可取回资金。';

  @override
  String get lightningSwapProviderUriHint => '服务商 URI（nostr+swap://...）';

  @override
  String get lightningSwapProviderConnect => '连接服务商';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return '服务商已连接：$pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => '断开连接';

  @override
  String get lightningSwapInvoiceHint => 'Lightning 发票（lnbc...）';

  @override
  String get lightningSwapStart => '继续';

  @override
  String get lightningSwapAmount => '发票金额';

  @override
  String get lightningSwapFees => '费用（claim + 服务）';

  @override
  String get lightningSwapTotal => '需锁定的总额';

  @override
  String get lightningSwapFund => '发送资金并开始 swap';

  @override
  String get lightningSwapFundHint => '资金将发送到上方显示的 HTLC 地址。1 次确认后开始支付。';

  @override
  String get lightningSwapStateLabel => '状态';

  @override
  String get lightningSwapHtlc => 'HTLC 地址';

  @override
  String lightningSwapCltv(int height) {
    return '可从区块 $height 开始退款';
  }

  @override
  String get swapStateAwaitingFunding => '等待链上资金';

  @override
  String get swapStateConfirming => '等待确认';

  @override
  String get swapStatePaying => 'Lightning 支付进行中';

  @override
  String get swapStatePaid => '发票已支付，claim 进行中';

  @override
  String get swapStateClaiming => 'Claim 进行中';

  @override
  String get swapStateCompleted => '已完成';

  @override
  String get swapStatePaymentFailed => '支付失败 —— 资金可恢复';

  @override
  String get swapStateExpired => '已过期 —— 资金可恢复';

  @override
  String get swapStateRefunded => '已退款';

  @override
  String get lightningSwapRecoveryTitle => '资金恢复';

  @override
  String get lightningSwapRecoveryHint => '恢复 blob（swaprecover1....）';

  @override
  String get lightningSwapRecoveryImport => '导入会话';

  @override
  String get lightningSwapRefund => '恢复资金（refund）';

  @override
  String lightningSwapRefundNotYet(int height) {
    return '暂时无法退款：从区块 $height 起可退款';
  }

  @override
  String get lightningSwapCopyBlob => '复制恢复 blob';

  @override
  String get lightningSwapBlobCopied => '恢复 blob 已复制';

  @override
  String get lightningSwapClaimTxid => 'Claim 交易 ID';

  @override
  String get lightningSwapClaimHint =>
      'Claim 是一笔链上交易：将在下一个区块（约 12 分钟）确认。点击链接进行验证。';

  @override
  String get lightningSwapInvalidInvoice => '这不像是一个 Lightning 发票';

  @override
  String get lightningSwapWatchOnly => 'Swap 需要带 seed 的钱包（不支持 watch-only）';

  @override
  String get lightningSwapNoUtxos => '此钱包没有可花费的资金';

  @override
  String lightningSwapErrorGeneric(String message) {
    return '错误：$message';
  }

  @override
  String get lightningSwapKnownUris => '已保存的服务商 URI';

  @override
  String get lightningSwapWalletLabel => '钱包';

  @override
  String lightningSwapWalletBalance(String balance) {
    return '余额：$balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return '资金不足：需要 $needed sat，可用 $available sat';
  }

  @override
  String get lightningSwapCancel => '取消 swap';

  @override
  String get lightningSwapErrorConnectFailed => '无法连接到服务商。请检查网络后重试。';

  @override
  String get lightningSwapErrorDisconnected => '与服务商的连接已断开。请重新连接。';

  @override
  String get lightningSwapErrorNotConnected => '服务商未连接。';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      '该服务商使用的中继在网页版无法访问。请在手机上使用移动版完成支付。';

  @override
  String get lightningSwapCancelTitle => '取消此 swap？';

  @override
  String get lightningSwapCancelBody =>
      '应用将忘记此 swap。服务商会在到期前自行丢弃，不会锁定任何资金。若要在同一发票上重试，需等其过期后才能新建会话，否则请生成新发票。';

  @override
  String get lightningSwapCancelConfirm => '是的，取消';

  @override
  String get lightningSwapWalletMissing => '与此 swap 关联的钱包已不可用';

  @override
  String lightningSwapBoundWallet(String name) {
    return '关联钱包：$name';
  }

  @override
  String get lightningInvoiceDelete => '删除发票';

  @override
  String get lightningInvoiceDeleteTitle => '删除此发票？';

  @override
  String get lightningInvoiceDeleteBody => '发票将从节点中删除。若未支付，将无法再支付。';

  @override
  String get lightningInvoiceDeleteConfirm => '是的，删除';

  @override
  String get lightningInvoiceDeleted => '发票已删除';

  @override
  String get lightningChannelPeerAddress => '对等节点地址';
}
