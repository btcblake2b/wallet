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
  String get appErrorTitle => '无法启动应用';

  @override
  String get appReload => '重新加载页面';

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
  String get homeReceiveWallet => '接收';

  @override
  String get homeMultiTransfer => '批量发送';

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
  String homeDeleteMultiError(Object message) {
    return '$message';
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
  String get homeMoreOptions => '更多选项';

  @override
  String homeCreated(Object date) {
    return '创建于：$date';
  }

  @override
  String homeLastTransfer(Object date) {
    return '上次传输：$date';
  }

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
  String get walletDetailNoConnection => '无连接';

  @override
  String get walletDetailTransferSuccess => '钱包传输成功。本地种子已删除。';

  @override
  String walletDetailTransferError(Object error) {
    return '传输错误：$error';
  }

  @override
  String get walletDetailSeedCopied => '助记词已复制。将在 60 秒后删除。';

  @override
  String get walletDetailSeedWarning => '请安全保管！这是恢复您资金的唯一途径。';

  @override
  String get walletDetailAddress => '地址';

  @override
  String get walletDetailName => '名称';

  @override
  String get walletDetailBalance => '余额';

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
  String get walletDetailTxFee => '手续费';

  @override
  String get walletDetailTxIncoming => '收到';

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
  String get themeToggle => '切换主题';

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
  String get walletDetailTransfer => '传输';

  @override
  String get walletDetailTransferred => '已传输';

  @override
  String get walletDetailPending => '传输待处理';

  @override
  String get walletDetailNoName => '未命名钱包';

  @override
  String get walletDetailTransferredDesc => '此钱包已传输。只读模式。';

  @override
  String get sendScreenTitle => '发送 BTC';

  @override
  String get sendScreenAddressLabel => '接收地址';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => '金额 (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

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
  String get walletDetailFirst100Addresses => '前 100 个地址';

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
  String get importScreenHintText => '助记词由12个以空格分隔的单词组成。您可以直接粘贴。';

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
    return '本隐私政策为临时版本，官网正式版本发布后将被其取代。\n\n1) 设备上的数据。本应用不要求注册账户，也不会将个人数据保存在作者的服务器上。加密的助记词（AES-256-GCM）、偏好设置和同意记录仅保存在您的设备上。\n\n2) 为正常运行而发送给第三方的数据。为显示余额和手续费，本应用会查询第三方公共 API：\n• mempool.guide（区块链浏览器）。\n每次请求都会传输您的 IP 地址以及所查询钱包的公开地址。私钥和助记词绝不会被传输。\n\n3) 无追踪器。应用内不含任何分析、广告或 Cookie。\n\n4) 权利（GDPR 第 13-14 条）。您有权通过写信给数据控制者行使访问、更正、删除和反对的权利：$holder — $email。由于我们不存储个人数据，这些权利在很大程度上已经通过数据仅保存在您设备上这一事实得到保障。';
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
  String sendScreenError(Object error) {
    return '发送错误：$error';
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
  String get importScreenHeading => '输入 12 个单词';

  @override
  String get importScreenSubtitle => '输入以空格分隔的 12 个单词助记词，然后选择与原始钱包匹配的账户类型。';

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
    return '助记词必须恰好包含 12 个单词（检测到：$count）。';
  }

  @override
  String get importScreenValidateInvalid => '助记词无效。请检查单词拼写。';

  @override
  String get importScreenImporting => '导入中...';

  @override
  String get importScreenImport => '导入';

  @override
  String importScreenError(Object error) {
    return '导入错误：$error';
  }

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
  String get transferScreenTitle => '传输钱包';

  @override
  String get transferScreenScanning => '扫描接收方的二维码。';

  @override
  String get transferScreenProcessing => '处理和加密数据中...';

  @override
  String transferScreenScanError(Object error) {
    return '扫描或加密错误：$error';
  }

  @override
  String get transferScreenNearbyTitle => '扫描以接收';

  @override
  String get transferScreenNearbySubtitle => '让接收方扫描此二维码。';

  @override
  String transferScreenNearbyCode(Object code) {
    return '手动代码：$code';
  }

  @override
  String get transferScreenNearbyCancel => '取消';

  @override
  String get transferScreenNearbySuccess => '钱包通过蓝牙成功传输。本地种子已删除。';

  @override
  String transferScreenNearbyError(Object error) {
    return '传输错误：$error';
  }

  @override
  String get transferScreenWebRtcConnecting => '正在启动 WebRTC 连接...';

  @override
  String get transferScreenWebRtcTransferring => '通过 WebRTC 传输中...';

  @override
  String get transferScreenTransferComplete => '传输完成！';

  @override
  String get transferScreenMethodTitle => '选择传输方式';

  @override
  String get transferScreenMethodQr => '二维码（两阶段）';

  @override
  String get transferScreenMethodQrDesc => '扫描接收方的二维码，然后生成带有加密种子的二维码。';

  @override
  String get transferScreenMethodNearby => '蓝牙 P2P';

  @override
  String get transferScreenMethodNearbyDesc => '设备间直接传输。需要蓝牙。';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC（互联网）';

  @override
  String get transferScreenMethodWebRtcDesc => '通过浏览器 P2P。需要两台设备都有互联网。';

  @override
  String get transferScreenWebRtcQrDescription =>
      '接收方必须扫描此QR码。传输将通过WebRTC进行（无大小限制）。';

  @override
  String get transferScreenEncryptedQrDescription =>
      '向接收设备显示此QR码。扫描并完成接收后，钱包将自动从此设备中移除。';

  @override
  String get transferScreenWebRtcTimeout => 'WebRTC连接在30秒后失败。请重试或使用两阶段QR码方法。';

  @override
  String get receiveScreenTitle => '接收钱包';

  @override
  String get receiveScreenInit => '正在初始化非对称密钥...';

  @override
  String get receiveScreenShowQr => '向发送方显示此二维码。';

  @override
  String get receiveScreenScanSender => '扫描发送方设备上的二维码。';

  @override
  String get receiveScreenAutoDetectMethod => '系统会自动检测发送方使用的传输方式。';

  @override
  String receiveScreenKeyError(Object error) {
    return '密钥生成错误：$error';
  }

  @override
  String get receiveScreenDecrypting => '数据已接收。解密和服务器验证中...';

  @override
  String get receiveScreenSuccess => '钱包接收并导入成功。';

  @override
  String get receiveScreenQrSuccess => '通过二维码接收钱包。';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return '代码 $code 已读取。连接中...';
  }

  @override
  String get receiveScreenNearbySuccess => '通过蓝牙 P2P 接收钱包。';

  @override
  String receiveScreenError(Object error) {
    return '错误：$error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'WebRTC 房间';

  @override
  String get receiveScreenWebRtcConnect => '连接到房间';

  @override
  String get receiveScreenWebRtcShareQr => '与发送方分享此二维码';

  @override
  String get receiveScreenWebRtcScanQr => '扫描发送方的房间二维码';

  @override
  String get receiveScreenWebRtcWait => '等待发送方连接...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return '房间 ID：$roomId';
  }

  @override
  String get passwordDialogCreateTitle => '创建安全密码';

  @override
  String get passwordDialogCreateContent => '设置密码以保护此浏览器上的敏感操作。';

  @override
  String get passwordDialogCreateHint => '输入安全密码';

  @override
  String get passwordDialogCreateConfirm => '确认密码';

  @override
  String get passwordDialogCreateConfirmHint => '重新输入密码';

  @override
  String get passwordDialogCreateMismatch => '密码不匹配';

  @override
  String get passwordDialogCreateTooShort => '密码必须至少 8 个字符';

  @override
  String get passwordDialogCreate => '创建';

  @override
  String get passwordDialogCancel => '取消';

  @override
  String get passwordDialogEnterTitle => '输入密码';

  @override
  String get passwordDialogEnterContent => '输入您的安全密码以继续。';

  @override
  String get passwordDialogEnterHint => '输入您的密码';

  @override
  String get passwordDialogEnter => '确认';

  @override
  String get passwordDialogWrong => '密码错误';

  @override
  String get languageSelector => '语言';

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
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

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
  String get walletDetailTransferredOn => '传输于';

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
  String get walletDetailFirst100 => '前 100 个地址';

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
  String get multiTransferTitle => '多钱包发送';

  @override
  String get multiTransferSelectWallets => '选择要发送的钱包';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已选择 $count 个钱包',
      one: '已选择 1 个钱包',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return '总价值：$amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => '传输方式：';

  @override
  String multiTransferMethodWebRtc(Object max) {
    return 'WebRTC（最多 $max 个）';
  }

  @override
  String multiTransferMethodBluetooth(Object max) {
    return '蓝牙（最多 $max 个）';
  }

  @override
  String multiTransferMethodQr(Object max) {
    return '二维码两阶段（最多 $max 个）';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '发送 $count 个钱包',
      one: '发送 1 个钱包',
    );
    return '$_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => '发送中...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return '钱包 $current/$total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个钱包发送成功',
      one: '1 个钱包发送成功',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success 个成功，$failed 个失败';
  }

  @override
  String get multiTransferNoLockedWallets => '没有可传输的钱包。只有已锁定的钱包才能传输。';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return '您选择了 $selected 个钱包。$method 的最大数量为 $max。';
  }

  @override
  String get multiTransferReceivingTitle => '多钱包接收';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return '已接收 $received/$total 个钱包';
  }

  @override
  String get multiTransferMethodUnavailable => '此平台不可用';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return '正在发送钱包 $current/$total...';
  }

  @override
  String get multiTransferPreparing => '正在准备钱包...';

  @override
  String get multiTransferWaitingReceiver => '等待接收方...';

  @override
  String get multiTransferCompleted => '已完成';

  @override
  String get multiTransferFailed => '失败';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return '通过二维码手动两阶段传输。最多 $max 个钱包。';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return '通过互联网快速 P2P 传输。最多 $max 个钱包。';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return '设备间直接传输。最多 $max 个钱包。';
  }

  @override
  String get multiTransferNoBalance => '余额不可用';

  @override
  String get multiTransferConfirmTitle => '确认发送';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个钱包',
      one: '1 个钱包',
    );
    return '您即将发送 $_temp0，总计 $amount $ticker。是否继续？';
  }

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
  String get onboardingValidationCheckbox => '您必须接受所有声明';

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
}
