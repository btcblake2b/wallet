// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'No connection';

  @override
  String get homeNoConnectionCreate =>
      'Unable to create wallet without an active internet connection. The address must be verified on the network. Please try again when the connection is restored.';

  @override
  String get homeNoConnectionImport =>
      'Unable to import wallet without an active internet connection. The wallet must be registered on the server.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Wallet created successfully.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Error creating wallet: $error';
  }

  @override
  String get homeImportWallet => 'Import wallet';

  @override
  String get homeCreateWallet => 'Create wallet';

  @override
  String get homeSelected => 'selected';

  @override
  String get homeDeleteSelected => 'Delete Selected';

  @override
  String homeDeleteConfirm(int count) {
    return 'Delete $count wallets? This action is irreversible.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count wallets deleted successfully.';
  }

  @override
  String get homeWalletImported => 'Wallet imported successfully.';

  @override
  String get homeSecurityWarning =>
      'This software is provided \"as is\" without any warranty. The manufacturer is not liable for loss of funds, theft, hacking, transaction errors, or any damages arising from use of the app. The wallet does not guarantee protection against previous copies of the seed. Use only for small amounts.';

  @override
  String get homeDisclaimerAccept => 'I Accept';

  @override
  String get legalInfoTitle => 'Legal Info';

  @override
  String get homeLocalWallets => 'Local wallets';

  @override
  String homeErrorLoading(Object error) {
    return 'Error loading wallet: $error';
  }

  @override
  String get homeEmptyTitle => 'No wallets';

  @override
  String get homeEmptySubtitle =>
      'Create your first Bitcoin wallet to get started.';

  @override
  String get homeBalanceTitle => 'ACTIVE BALANCE';

  @override
  String get balanceUnavailable => 'Balance unavailable';

  @override
  String get homeBackupVerified => 'Backup verified';

  @override
  String get homeBackupNotVerified => 'Backup not verified';

  @override
  String get homeLockVault => 'Lock vault';

  @override
  String get homeVaultLocked => 'Vault locked';

  @override
  String get homeVaultLockedBody =>
      'The keys were removed from memory after inactivity. Enter your password to see balances and sign again. Your wallets are safe: nothing was deleted.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionTools => 'Tools';

  @override
  String get settingsSectionInfo => 'Information';

  @override
  String get settingsTheme => 'Dark theme';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsAppLockDesc =>
      'Require biometrics or phone PIN on every open';

  @override
  String get settingsAppLockUnavailable =>
      'No biometrics enrolled on this device';

  @override
  String get settingsAppLockEnableFailed =>
      'Verification failed: app lock not enabled';

  @override
  String get settingsAppLockEnabled => 'App lock enabled';

  @override
  String get settingsAppLockDisabled => 'App lock disabled';

  @override
  String get settingsExplorerMirrors => 'Backup explorers';

  @override
  String get settingsExplorerMirrorsDesc =>
      'If mempool.guide does not respond, the app queries two community mirrors. Turn off to use mempool.guide only.';

  @override
  String get settingsSectionInterface => 'Interface';

  @override
  String get settingsInfoDots => 'Info hints';

  @override
  String get settingsInfoDotsDesc =>
      'Show the small info buttons that explain each feature';

  @override
  String get guideTitle => 'How it works';

  @override
  String get guideEntryDesc =>
      'Plain-language explanations: wallet, seed, fees, Lightning.';

  @override
  String get guideIntro =>
      'This guide explains in plain words what the app does and why. You do not need to read it all: open only the chapter you need. Every explanation is also reachable from the ⓘ dot next to the matching field.';

  @override
  String get guideOpenFailed => 'Could not open the browser.';

  @override
  String get guideHintsNote =>
      'You can hide the ⓘ dots in Settings → Interface.';

  @override
  String get guideSectionBasics => 'Basics';

  @override
  String get guideSectionSecurity => 'Security and backup';

  @override
  String get guideSectionTransactions => 'Sending and receiving';

  @override
  String get guideSectionLightning => 'Lightning';

  @override
  String get guideSectionAdvanced => 'Going deeper';

  @override
  String get guideFullGuideTitle => 'Full guide online';

  @override
  String get guideFullGuideDesc =>
      'The website has the long version, with examples and FAQ.';

  @override
  String get guideFullGuideOpen => 'Open the guide';

  @override
  String get infoWhatIsWalletTitle => 'What a wallet is (and is not)';

  @override
  String get infoWhatIsWalletBody =>
      'A wallet does not \'contain\' coins: it holds the private keys that let you spend coins recorded on the blockchain. Nodes calculate the balance by reading the chain, and the app rebuilds it from your addresses. That is why losing the keys means losing the funds, while losing the phone can be recovered with the 12-word phrase.';

  @override
  String get infoSelfCustodyTitle =>
      'Self-custody: nobody can freeze your funds';

  @override
  String get infoSelfCustodyBody =>
      'Here you are the bank: no account, no login, no company holding your money. The upside: nobody can freeze your balance. The risk: nobody can recover your password or your recovery phrase. That is the price of sovereignty — accept it knowingly.';

  @override
  String get infoSeedPhraseTitle => 'Recovery phrase (12 words)';

  @override
  String get infoSeedPhraseBody =>
      'It is the human-readable form of your private key: those words rebuild ALL your addresses, and therefore your funds. Write it on paper, never as a photo, in chats, in the cloud or in a password manager. Whoever reads it can empty the wallet; whoever loses it has lost everything.';

  @override
  String get infoAppEncryptionTitle => 'Local encryption and password';

  @override
  String get infoAppEncryptionBody =>
      'The phrase stays on your device encrypted with AES-GCM: the key is derived from your password (or from your fingerprint, which unlocks the system keystore). No server ever receives the password. If you forget it there is no \'reset\': the recovery phrase is the only way back.';

  @override
  String get infoNetworkBlake2bTitle => 'The network: bitcoin-blake2b';

  @override
  String get infoNetworkBlake2bBody =>
      'You are using bitcoin-blake2b, an EXPERIMENTAL network with its own rules (BLAKE2b hashing, no consensus-level replay protection): it is not Bitcoin and the two chains do not share coins. Treat this wallet as a test environment, not as your final savings vault.';

  @override
  String get infoBalanceUtxoTitle => 'How the balance is built';

  @override
  String get infoBalanceUtxoBody =>
      'There is no \'account\' with a number: the balance is the sum of UTXOs, the coins you received and have not spent yet — like banknotes in a pocket. A transaction consumes some UTXOs and creates new ones (payment + change). Sending to yourself leaves the balance unchanged.';

  @override
  String get infoConfirmationsTitle => 'Confirmations';

  @override
  String get infoConfirmationsBody =>
      'A new payment is \'pending\' (mempool): it exists, but no block has recorded it yet. Every later block adds a confirmation; from 3 confirmations on a payment is reasonably stable. While pending, the amount may show as unavailable: it has not vanished, it is waiting.';

  @override
  String get infoFeeConceptTitle => 'Why you pay a fee';

  @override
  String get infoFeeConceptBody =>
      'The fee is the reward for whoever includes your transaction in a block. You pay per size (sat/vB), not per amount: sending 1,000 or 1,000,000 sat costs the same. When the mempool is busy prices rise; the fee is NOT an app fee — it goes to the miners.';

  @override
  String get infoChangeAddressTitle => 'Change';

  @override
  String get infoChangeAddressBody =>
      'Like at the shop: if the UTXOs you spend are worth more than the amount, the difference comes back to you on a NEW address of the same wallet (the \'change\'). Seeing a transaction with two outputs is normal: the payment to the recipient and the change to you.';

  @override
  String get infoLightningVsOnchainTitle => 'On-chain and Lightning';

  @override
  String get infoLightningVsOnchainBody =>
      'On-chain means every movement is a public transaction on the chain: safe and verifiable, but slower and with a fee per transaction. Lightning means instant, almost free payments inside \'channels\' opened with one on-chain transaction. Opening a channel moves on-chain funds into the channel; closing it moves them back on-chain.';

  @override
  String get infoPrivacyBasicsTitle => 'Privacy: who sees what';

  @override
  String get infoPrivacyBasicsBody =>
      'Every \'Receive\' creates a new address: reusing one links your payments together. The app has no account and no telemetry, and asks a public API (mempool.guide) for on-chain data — that API sees your IP. For maximum privacy use a VPN or your own node, and never publish your xpub.';

  @override
  String get infoCoinControlTitle => 'Coin control (UTXO selection)';

  @override
  String get infoCoinControlBody =>
      'Your balance is made of UTXOs, the pieces you received. Here you can pick which ones to spend: the transaction will use only those, letting you keep small or inactive pieces aside.';

  @override
  String get infoDustLimitTitle => 'Minimum amount (dust)';

  @override
  String get infoDustLimitBody =>
      'Outputs below 546 sat are rejected by the network as dust. Amounts under that limit cannot be sent.';

  @override
  String get infoFeeRateTitle => 'Transaction fee';

  @override
  String get infoFeeRateBody =>
      'The fee is paid per unit of transaction size (sat/vB): the faster you want the confirmation, the more you pay. Economical can take hours, Priority a few minutes. Custom is for when you know the current mempool rate.';

  @override
  String get infoBatchSendTitle => 'Multiple recipients (batch)';

  @override
  String get infoBatchSendBody =>
      'In a single transaction you can pay up to 20 addresses, sharing the fee instead of paying it once per transfer. All recipients are shown in the confirmation before signing.';

  @override
  String get infoBumpFeeTitle => 'Increase fee (RBF)';

  @override
  String get infoBumpFeeBody =>
      'A pending transaction can be replaced by a new one paying a higher fee (BIP125). The original is cancelled and only the replacement can confirm — the destination address and amount stay the same.';

  @override
  String get infoXpubTitle => 'Account public key (xpub)';

  @override
  String get infoXpubBody =>
      'The xpub generates all your receiving addresses. It cannot move funds, but it reveals the whole balance and history: share it only with apps you trust (e.g. a watch-only wallet).';

  @override
  String get infoReceiveAddressTitle => 'Receiving address';

  @override
  String get infoReceiveAddressBody =>
      'Each Receive shows a fresh address, chosen from those never used: this keeps payments unlinkable. Reusing an address is not an error, it just makes your transactions easier to trace.';

  @override
  String get infoWatchOnlyTitle => 'Watch-only wallet';

  @override
  String get infoWatchOnlyBody =>
      'You imported only the xpub: the app sees balance and history but holds no private key, so it cannot sign. To spend from this wallet you need the device that holds the seed.';

  @override
  String get infoSignVerifyTitle => 'Sign / verify message';

  @override
  String get infoSignVerifyBody =>
      'Signing proves that an address is yours without moving funds. Anyone can then verify the signature against that address and the same message.';

  @override
  String get infoChannelCapacityTitle => 'Channel capacity';

  @override
  String get infoChannelCapacityBody =>
      'The total amount of satoshis in the channel, split between you and your peer. The more capacity, the larger payments it can handle. Capacity = local balance + remote balance.';

  @override
  String get infoChannelReserveTitle => 'Channel reserve';

  @override
  String get infoChannelReserveBody =>
      'A small portion of your funds must stay locked as a security deposit (the reserve). It ensures both parties have skin in the game — if the other side goes offline maliciously, the reserve can be used to penalize them on-chain.';

  @override
  String get infoToSelfDelayTitle => 'To-self delay';

  @override
  String get infoToSelfDelayBody =>
      'When a force close happens, your on-chain output is delayed by this many blocks (typically 144 = ~1 day). This gives your peer time to claim their funds first, preventing double-spend attacks on the channel state.';

  @override
  String get infoHtlcTitle => 'HTLC (Hashed Time-Locked Contract)';

  @override
  String get infoHtlcBody =>
      'An HTLC is a conditional payment: funds are locked until the recipient reveals a secret hash preimage. In Lightning, HTLCs enable instant off-chain routing — your payment hops through multiple channels without trusting any intermediary.';

  @override
  String get infoOpenChannelPrivateTitle => 'Private channel';

  @override
  String get infoOpenChannelPrivateBody =>
      'A private channel is not announced to the network. Only you and your peer know it exists. Use it when you don\'t want others to route through it (privacy) or when the channel is too small to be useful for routing.';

  @override
  String get infoRoutingFeesTitle => 'Routing fees';

  @override
  String get infoRoutingFeesBody =>
      'When other nodes route payments through your channel, you earn fees. Base fee (sat) is charged per payment; rate (ppm) is proportional to the amount. CLTV delta limits how long a forwarded HTLC can take to settle.';

  @override
  String get infoForceCloseTitle => 'Force close';

  @override
  String get infoForceCloseBody =>
      'Broadcasts your latest channel state on-chain. This is irreversible and requires waiting for the to-self delay before you can spend your funds. Use only if your peer is unresponsive or malicious — cooperative close is always faster and cheaper.';

  @override
  String get infoPeersTitle => 'Connected peers';

  @override
  String get infoPeersBody =>
      'Peers are other Lightning nodes you\'re directly connected to via TCP/Tor. Each peer can hold one or more channels. You can connect to new peers to open channels and increase your node\'s liquidity and routing capability.';

  @override
  String get infoNodeManagementTitle => 'Node management';

  @override
  String get infoNodeManagementBody =>
      'Your Lightning node identity: pubkey, version, number of active/pending channels and peers. This screen shows accounting data from the node\'s bookkeeper plugin and forwarding statistics.';

  @override
  String get appLockTitle => 'App locked';

  @override
  String get appLockSubtitle => 'Unlock with biometrics or phone PIN';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockReason => 'Unlock the wallet';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'App lock disabled: the phone screen protection (biometrics/PIN) is no longer available. Re-enable it in the system settings to use app lock again.';

  @override
  String get appLockNoticeContinue => 'Continue';

  @override
  String get appLockPromptTitle => 'Enable app lock?';

  @override
  String get appLockPromptMessage =>
      'Opening the wallet will require biometrics or your phone PIN.';

  @override
  String get appLockPromptEnable => 'Enable';

  @override
  String get appLockPromptLater => 'Later';

  @override
  String get aboutLicensesOpenOnline => 'Open online';

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Wallet $name$balance';
  }

  @override
  String get walletDetailTitle => 'Wallet';

  @override
  String walletDetailCopied(Object label) {
    return '$label copied. Will be removed after 60s.';
  }

  @override
  String get walletDetailAddress => 'Address';

  @override
  String get walletDetailTransactions => 'Transactions';

  @override
  String get walletDetailTxBlockHeight => 'Block height';

  @override
  String get walletDetailTxConfirmations => 'Confirmations';

  @override
  String get walletDetailTxDate => 'Date';

  @override
  String get walletDetailTxDetails => 'Transaction details';

  @override
  String get walletDetailTxEmpty => 'No transactions';

  @override
  String get walletDetailTxError => 'Failed to load transactions';

  @override
  String get walletDetailTxExport => 'Export';

  @override
  String get walletDetailTxExportCsv => 'CSV (spreadsheet)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'Copied to clipboard ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Download started ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'Export failed';

  @override
  String get walletDetailTxExportJson => 'JSON (complete)';

  @override
  String get walletDetailTxFee => 'Fee';

  @override
  String get walletDetailTxIncoming => 'Received';

  @override
  String get walletDetailTxNote => 'Note';

  @override
  String get walletDetailTxNoteAdd => 'Add note';

  @override
  String get walletDetailTxNoteEdit => 'Edit note';

  @override
  String get walletDetailTxNoteHint =>
      'Private note, saved on this device only';

  @override
  String get walletDetailTxNoteRemove => 'Remove';

  @override
  String get walletDetailTxOrphan => 'Orphan (lost block)';

  @override
  String get walletDetailTxOutgoing => 'Sent';

  @override
  String get walletDetailTxPending => 'Pending';

  @override
  String get walletDetailTxReplaced => 'Replaced (dropped from mempool)';

  @override
  String get walletDetailTxRetry => 'Retry';

  @override
  String get backupSeedTitle => 'Seed backup';

  @override
  String get backupSeedIntro =>
      'Write down your seed phrase on paper and store it in a safe place. It is the only way to recover your funds.';

  @override
  String get backupSeedStart => 'Start backup';

  @override
  String get backupSeedLater => 'Later';

  @override
  String get backupSeedSavedContinue => 'I saved the seed';

  @override
  String get backupSeedVerifyTitle => 'Verify your backup';

  @override
  String get backupSeedVerifyHint =>
      'Enter the 3 highlighted words to confirm you saved them.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Word $number';
  }

  @override
  String get backupSeedVerifyError => 'Incorrect words. Try again.';

  @override
  String get backupSeedDone => 'Backup complete';

  @override
  String get backupSeedDoneDesc =>
      'Your seed is safe. Remember: whoever holds the seed controls the funds.';

  @override
  String get backupSeedFinish => 'Finish';

  @override
  String get backupSeedSkipWarning =>
      'If you skip, you risk losing your funds if you lose this device. You can do it later from the wallet details.';

  @override
  String get walletDetailSend => 'Send';

  @override
  String get walletDetailReceive => 'Receive';

  @override
  String get sendScreenTitle => 'Send BTC';

  @override
  String get sendScreenAddressLabel => 'Recipient address';

  @override
  String get sendScreenAmountLabel => 'Amount (BTC)';

  @override
  String get sendScreenFeeLabel => 'Fee';

  @override
  String get sendScreenFeeLow => 'Low';

  @override
  String get sendScreenFeeNormal => 'Normal';

  @override
  String get sendScreenFeeHigh => 'High';

  @override
  String get sendScreenFeeCustom => 'Custom';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Available: $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Estimated fee: $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'UTXO selection';

  @override
  String get sendScreenUtxoSelectAll => 'Select all';

  @override
  String get sendScreenUtxoNoneSelected => 'Select at least one UTXO to send';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Total: $total $ticker';
  }

  @override
  String get sendScreenMax => 'Max';

  @override
  String get sendScreenSend => 'Send';

  @override
  String get sendScreenSending => 'Sending...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return 'Deleted $deleted wallets, $errors errors: $error';
  }

  @override
  String get walletDetailBalanceLabel => 'BALANCE';

  @override
  String get walletDetailMasterFingerprint => 'MASTER FINGERPRINT';

  @override
  String get walletDetailDerivationPath => 'DERIVATION PATH';

  @override
  String get walletDetailSettings => 'SETTINGS';

  @override
  String get walletDetailAdvancedTools => 'Advanced Tools';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'No spendable UTXO found';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count confirmations';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count selected · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Send selected';

  @override
  String get walletDetailUtxoClearSelection => 'Clear selection';

  @override
  String get walletUtxoWaitingBadge => 'Waiting period';

  @override
  String walletUtxoWaitingBlocks(int count) {
    return '$count blocks to unlock';
  }

  @override
  String walletUtxoWaitingHint(int blocks) {
    return 'Mining payouts (coinbase) are relayed by the network only after $blocks blocks: they cannot be spent yet.';
  }

  @override
  String walletBalanceWaiting(String amount) {
    return 'Waiting period: $amount';
  }

  @override
  String get walletDetailPasswordSeedReason =>
      'Confirm password to view the seed phrase';

  @override
  String get walletDetailBiometricSeedReason =>
      'Biometric confirmation to view the seed phrase';

  @override
  String get walletDetailPasswordBumpReason =>
      'Confirm password to increase the fee';

  @override
  String get walletDetailBiometricBumpReason =>
      'Biometric confirmation to increase the fee';

  @override
  String get walletDetailTxBumpFee => 'Increase fee';

  @override
  String get walletDetailBumpFeeTitle => 'Increase transaction fee';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Current fee: $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Recommended fees unavailable — enter a custom rate';

  @override
  String get walletDetailBumpFeeWarning =>
      'The original transaction may never confirm if the replacement is mined.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Fee increased — new transaction $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'The new fee must be higher than the current one';

  @override
  String get sendScreenSigning => 'Signing transaction...';

  @override
  String get sendScreenBroadcasting => 'Broadcasting to the network...';

  @override
  String get sendScreenBiometricReason =>
      'Biometric confirmation to authorize the transaction';

  @override
  String get sendScreenPasswordReason =>
      'Enter your password to authorize the transaction';

  @override
  String get sendScreenBiometricRequired =>
      'Biometrics are required to send. Enable fingerprint or face unlock in your device settings.';

  @override
  String get sendScreenFeeTime2h => '~2 h';

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
  String get sendScreenFeeTime1h => '~1 h';

  @override
  String get sendScreenFeeTime30m => '~30 min';

  @override
  String get sendScreenFeeTime15m => '~15 min';

  @override
  String get sendScreenFeeTime10m => '~10 min';

  @override
  String get sendScreenFeeTime5m => '~5 min';

  @override
  String sendScreenMaxHelper(Object amount) {
    return 'Max: $amount';
  }

  @override
  String sendScreenUtxoSummary(int sats, int count) {
    return '$sats sat · $count UTXO';
  }

  @override
  String get importScreenHintText =>
      'The seed phrase consists of 12, 15, 18, 21 or 24 words separated by spaces. You can paste it directly.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Error: $error';
  }

  @override
  String get legalMitLicense => 'MIT License';

  @override
  String get legalSecurityTitle => 'Security';

  @override
  String get legalTermsContent =>
      'These Terms of Service are provisional and will be replaced by the final version when the official website becomes available.\n\nBtc Blake2b Wallet is a self-custodial Bitcoin wallet for the experimental \"bitcoin-blake2b\" network (a fork of Bitcoin). Private keys and the seed phrase remain solely on your device: we do not hold, transfer or have access to your funds.\n\nThe app is provided free of charge, \"as is\", without warranties of any kind. You use it at your own risk. The bitcoin-blake2b network is an experimental network derived from Bitcoin: its coins may have no market value, may not be recognized by exchanges and may undergo reorganizations. Nothing in the app constitutes financial or investment advice.\n\nYou are solely responsible for keeping your seed phrase and your funds: anyone who has possession of them can spend the coins. The app cannot recover a lost seed. Use for illegal activities is prohibited. You declare that you are at least 16 years old.\n\nBtc Blake2b Wallet is not affiliated with, nor sponsored or endorsed by, Bitcoin, Bitcoin Core or bitcoin.org.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'This Privacy Policy is provisional and will be replaced by the final version published on the official website when available.\n\n1) DATA ON YOUR DEVICE. The app does not require an account and does not store personal data on servers operated by the author. The encrypted seed (AES-256-GCM), preferences and consents remain ONLY on your device.\n\n2) DATA SENT TO THIRD PARTIES FOR OPERATION. To display balance and fees the app queries public third-party APIs:\n• mempool.guide (blockchain explorer).\n• If mempool.guide is unavailable, the app may query two community Esplora-compatible mirrors (mempool.kilombino.com, mempool.maveth.ca). This can be turned off in Settings.\n• If you enable the automatic price in Settings, the app reads the last XBT/USDC trade from neoxa.exchange (NeoXEX) on demand. If your value currency is not USD, the app also reads the USDT exchange rates from api.coinbase.com. Both can be turned off in Settings.\nEach request transmits your IP address and the public address of the queried wallet. Private keys and the seed are NEVER transmitted.\n\n3) NO TRACKERS. No analytics, no advertising, no cookies inside the app.\n\n4) RIGHTS (GDPR arts. 13-14). You have the right of access, rectification, erasure and objection by writing to the data controller: $holder — $email. Since we do not store personal data, these rights are already largely guaranteed by the fact that the data stays on your device.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'To report security vulnerabilities use the private \"Report a vulnerability\" reporting of the GitHub repository (Security tab) or write to:\n$email\n\nDo not open public issues for security problems. Response time: 72 hours. Disclosure policy: 90 days.';
  }

  @override
  String get sendScreenSuccess => 'Transaction sent!';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID: $txid';
  }

  @override
  String get sendScreenValidateAddress => 'Enter an address';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Invalid address for $network (use $prefix)';
  }

  @override
  String get sendScreenValidateLength => 'Invalid address length';

  @override
  String get sendScreenValidateSelf => 'You cannot send to yourself';

  @override
  String get sendScreenValidateAmount => 'Enter an amount';

  @override
  String get sendScreenValidateInvalidAmount => 'Invalid amount';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Amount too low (minimum $dust satoshi / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Insufficient funds (balance: $balance, estimated fee: $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'Loading UTXOs...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'Unable to load UTXOs: $error';
  }

  @override
  String get scanQrTitle => 'Scan QR Code';

  @override
  String get scanQrError =>
      'Unable to access the camera. Grant the camera permission and try again.';

  @override
  String get scanQrInvalid =>
      'The scanned code is not a valid Bitcoin address.';

  @override
  String get scanQrInvalidInvoice =>
      'The scanned code is not a valid Lightning invoice.';

  @override
  String get scanQrInvalidMnemonic =>
      'The scanned code is not a valid BIP39 recovery phrase.';

  @override
  String get scanQrTorch => 'Toggle flashlight';

  @override
  String get sendConfirmTitle => 'Confirm transaction';

  @override
  String get sendConfirmWarning =>
      'This transaction is irreversible. Verify the details before confirming.';

  @override
  String get sendConfirmSend => 'Confirm & Send';

  @override
  String get importScreenTitle => 'Import Wallet';

  @override
  String get importScreenHeading => 'Enter your seed phrase';

  @override
  String get importScreenSubtitle =>
      'Enter the mnemonic phrase (12, 15, 18, 21 or 24 words) separated by spaces, then choose the account type that matches the original wallet.';

  @override
  String get importScriptTypeLabel => 'Account type';

  @override
  String get importScriptTypeNativeSegwit => 'Native SegWit (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'Nested SegWit (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Wallet type to create';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Addresses start with $prefix';
  }

  @override
  String get importScreenHint => 'word1 word2 word3 ...';

  @override
  String get importScreenScanSeed => 'Scan seed QR code';

  @override
  String get importScreenValidateEmpty => 'Enter the mnemonic phrase.';

  @override
  String importScreenValidateCount(Object count) {
    return 'The phrase must contain 12, 15, 18, 21 or 24 words (detected: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Invalid mnemonic phrase. Check the spelling of the words.';

  @override
  String get importScreenImport => 'Import';

  @override
  String get importModeSeed => 'Seed phrase';

  @override
  String get importModeWatchOnly => 'Watch-only (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Monitor an external wallet (balance and history) with only its public extended key. No private key involved — sending is never possible.';

  @override
  String get importWatchOnlyXpubLabel => 'Account xpub';

  @override
  String get importWatchOnlyXpubHint =>
      'Paste the account xpub (starts with \"xpub\"). Public keys only: never paste an xprv.';

  @override
  String get importWatchOnlyValidateEmpty => 'Enter the account xpub.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'The xpub must start with \"xpub\" (mainnet).';

  @override
  String get watchOnlyBadge => 'Watch-only';

  @override
  String get passwordDialogCreateTitle => 'Create Security Password';

  @override
  String get passwordDialogCreateHint => 'Enter a secure password';

  @override
  String get passwordDialogCreateConfirm => 'Confirm password';

  @override
  String get passwordDialogCreate => 'Create';

  @override
  String get passwordDialogCancel => 'Cancel';

  @override
  String get passwordDialogEnterTitle => 'Enter Password';

  @override
  String get passwordDialogEnterHint => 'Enter your password';

  @override
  String get passwordDialogEnter => 'Confirm';

  @override
  String get passwordDialogWrong => 'Incorrect password';

  @override
  String get languageSelector => 'Language';

  @override
  String get languageSelectorAuto => '🌐 Automatic (system)';

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
  String get walletDetailRefresh => 'Refresh';

  @override
  String get walletDetailDeleteTitle => 'Delete Wallet?';

  @override
  String get walletDetailDeleteConfirm => 'Delete permanently';

  @override
  String get walletDetailDeleteWarning =>
      'This action is irreversible. Make sure you have a backup of the seed phrase if there are funds in the wallet.';

  @override
  String get walletDetailInfo => 'Wallet Info';

  @override
  String get walletDetailNameLabel => 'Wallet Name';

  @override
  String get walletDetailNameHint => 'e.g. Home Savings';

  @override
  String get walletDetailType => 'Type';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'Nested SegWit (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'UPDATING...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TRANSACTIONS';
  }

  @override
  String get walletDetailReceiveQr => 'Receive Bitcoin';

  @override
  String get walletDetailSignVerify => 'Sign/Verify Message';

  @override
  String get walletDetailShowAddresses => 'Show addresses';

  @override
  String get walletDetailWalletAddress => 'Wallet Address';

  @override
  String get walletDetailExportSeed => 'Export/Backup Seed';

  @override
  String get walletDetailShowSeedTitle => 'View seed?';

  @override
  String get walletDetailShowSeedContent =>
      'The seed phrase allows access to all funds. Make sure you are in a safe place.';

  @override
  String get walletDetailShowSeedConfirm => 'Yes, show';

  @override
  String get walletDetailSeedVerifyPrompt =>
      'Do you want to verify that you saved the seed?';

  @override
  String get walletDetailSeedVerifyYes => 'Yes, verify';

  @override
  String get walletDetailSeedVerifyNotNow => 'Not now';

  @override
  String get walletDetailSeedVerified => 'Backup verified';

  @override
  String get walletDetailSeedHidden => 'Seed hidden for security';

  @override
  String get walletDetailSeedShowAgain => 'Show seed';

  @override
  String get walletDetailHideSeed => 'Hide';

  @override
  String get walletDetailBackupNotConfirmed => 'Backup not confirmed';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'You have not yet saved the seed phrase. If you lose the device or reinstall the app, you will permanently lose access to your funds.';

  @override
  String get walletDetailShowXpub => 'Show Wallet XPUB';

  @override
  String get walletDetailDisplayHome => 'Show value in Home';

  @override
  String get walletDetailUtxoRename => 'Rename';

  @override
  String get walletDetailUtxoRenameTitle => 'Rename UTXO';

  @override
  String get walletDetailSave => 'Save';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Created';

  @override
  String get walletDetailClose => 'Close';

  @override
  String get walletDetailSign => 'Sign';

  @override
  String get walletDetailVerify => 'Verify';

  @override
  String get walletDetailSignMessage => 'Sign Message';

  @override
  String get walletDetailVerifyMessage => 'Verify Message';

  @override
  String get walletDetailMessage => 'Message';

  @override
  String get walletDetailBitcoinAddress => 'Bitcoin Address';

  @override
  String get walletDetailSignature => 'Signature (Base64)';

  @override
  String get walletDetailResult => 'Result:';

  @override
  String get walletDetailSignatureLabel => 'Signature:';

  @override
  String get walletDetailCopy => 'Copy';

  @override
  String get walletDetailAddressCopied => 'Address copied to clipboard';

  @override
  String get walletDetailXpubTitle => 'Wallet XPUB';

  @override
  String get walletDetailXpubDesc =>
      'This XPUB allows viewing all future addresses and balances but cannot spend funds.';

  @override
  String get walletDetailXpubCopied => 'XPUB copied';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Error deriving XPUB: $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Error deriving addresses: $error';
  }

  @override
  String get walletDetailValidSig => 'VALID SIGNATURE ✓';

  @override
  String get walletDetailInvalidSig => 'INVALID SIGNATURE ✗';

  @override
  String get donateTitle => 'Support the project ❤️';

  @override
  String get donatePhrase =>
      '☕ \"If the project is useful to you, buy us a virtual coffee\"';

  @override
  String get donateAddressLabel => 'Bitcoin donation address:';

  @override
  String get donateCopy => 'Copy';

  @override
  String get donateCopied => 'Copied! ✓';

  @override
  String get donateNote =>
      'Voluntary donation — no service or benefit is provided in return. Any amount is welcome, even a few satoshis. Thank you! 🧡';

  @override
  String get donateNoWalletTitle => 'No wallet found';

  @override
  String get donateNoWalletMessage =>
      'No Bitcoin wallet app was found on your device. You can still copy the address and paste it into your favorite wallet.';

  @override
  String get donateOpenWallet => 'Open in wallet';

  @override
  String get donateButton => 'Support the project ❤️';

  @override
  String get onboardingTitle => 'Welcome to Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle =>
      'Open-source Bitcoin wallet. Self-custody. No KYC.';

  @override
  String get onboardingResidenceLabel => 'Country of tax residence';

  @override
  String get onboardingResidenceHint => 'Select your country';

  @override
  String get onboardingReverseSolicitation =>
      'I declare that I am using Btc Blake2b Wallet on my own exclusive initiative (\"reverse solicitation\") and that I reside fiscally in the selected country.';

  @override
  String get onboardingTermsAccept => 'I accept the ';

  @override
  String get onboardingPrivacyAccept => 'I have read the ';

  @override
  String get onboardingAgeConfirm =>
      'I declare that I am at least 16 years old';

  @override
  String get onboardingAgeSubtitle =>
      'Required by GDPR Art. 8 for data processing consent';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingStepNext => 'Next';

  @override
  String get onboardingStepBack => 'Back';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingTermsTitle => 'Terms and Privacy';

  @override
  String get onboardingValidationResidence =>
      'Select your country of tax residence';

  @override
  String get onboardingLinkTerms => 'Terms of Service';

  @override
  String get onboardingLinkPrivacy => 'Privacy Policy';

  @override
  String get aboutTitle => 'About Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet is an open-source, self-custody Bitcoin wallet. No registration, no KYC, no tracking. Your keys, your coins.';

  @override
  String get aboutLicenseTitle => 'License';

  @override
  String get aboutThirdPartyLicenses => 'Third-Party Licenses';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'View the complete list of open-source licenses';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutDisclaimer =>
      'This software is provided \"AS IS\" without warranty of any kind.';

  @override
  String get explorerTitle => 'Explorer';

  @override
  String get explorerAddressLabel => 'Address';

  @override
  String get explorerRefresh => 'Refresh';

  @override
  String get explorerBalanceLabel => 'Balance';

  @override
  String get explorerTxCount => 'Transactions';

  @override
  String get explorerTipHeight => 'Node height';

  @override
  String get explorerErrorInvalidAddress =>
      'Invalid address. Check the format for this network.';

  @override
  String get explorerErrorRateLimited =>
      'Rate limit exceeded. Try again in a minute.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Service temporarily unavailable. Try again later.';

  @override
  String get explorerErrorNotFound => 'Address or transaction not found.';

  @override
  String get explorerErrorTimeout =>
      'Request timed out. Check your connection and retry.';

  @override
  String get explorerErrorNetwork =>
      'Network unavailable. Check your connection.';

  @override
  String get explorerRetry => 'Retry';

  @override
  String explorerErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'No Lightning node connected';

  @override
  String get lightningDisconnectedBody =>
      'Connect your blake2b Lightning node to send and receive payments. The app never holds your funds or keys.';

  @override
  String get lightningConnectButton => 'Connect node';

  @override
  String get lightningConnectTitle => 'Connect Lightning node';

  @override
  String get lightningConnectHint =>
      'Paste the connection string (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Invalid connection string';

  @override
  String get lightningConnectRecentNodes => 'Recent nodes';

  @override
  String get lightningConnectInfo =>
      'The node must authorize this app (grant): check your node\'s control panel.';

  @override
  String get lightningConnecting => 'Connecting…';

  @override
  String get lightningConnected => 'Connected';

  @override
  String get lightningDisconnect => 'Disconnect';

  @override
  String get lightningBalance => 'Lightning balance';

  @override
  String get lightningChannels => 'Channels';

  @override
  String get lightningNoChannels => 'No open channels';

  @override
  String get lightningChannelPeer => 'Peer';

  @override
  String get lightningChannelCapacity => 'Capacity';

  @override
  String get lightningChannelLocal => 'Local';

  @override
  String get lightningChannelRemote => 'Remote';

  @override
  String get lightningOpenChannel => 'Open channel';

  @override
  String get lightningOpenChannelNodeId => 'Node ID (pubkey)';

  @override
  String get lightningCoinControlTitle => 'Coin control (optional)';

  @override
  String get lightningCoinControlHint =>
      'Pick which of the node\'s on-chain outputs fund the channel. Without a selection the node chooses on its own.';

  @override
  String get lightningCoinControlNoneSelected =>
      'No selection: the node chooses automatically.';

  @override
  String get lightningCoinControlSelectedTotal => 'Selected total';

  @override
  String get lightningCoinControlUnconfirmed => 'unconfirmed';

  @override
  String get lightningCoinControlUnavailable =>
      'Output list unavailable: the node will choose automatically.';

  @override
  String get lightningOpenChannelHost => 'Host (optional, ip:port)';

  @override
  String get lightningOpenChannelAmount => 'Amount (sat)';

  @override
  String get lightningOpenChannelPrivate => 'Private channel';

  @override
  String get lightningChannelOpened => 'Channel opening requested';

  @override
  String get lightningCloseChannel => 'Close channel';

  @override
  String get lightningCloseChannelForce => 'Force close';

  @override
  String get lightningCloseChannelForceWarning =>
      'Force close broadcasts the latest channel state on-chain. Fees and delays may apply. Continue?';

  @override
  String get lightningReceive => 'Receive';

  @override
  String get lightningSend => 'Send';

  @override
  String get lightningInvoiceAmount => 'Amount (sat)';

  @override
  String get lightningInvoiceDescription => 'Description (optional)';

  @override
  String get lightningInvoiceCreate => 'Create invoice';

  @override
  String get lightningInvoiceTitle => 'Lightning invoice';

  @override
  String get lightningPay => 'Pay invoice';

  @override
  String get lightningPayHint => 'Paste the invoice (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Confirm Lightning payment';

  @override
  String get lightningPayDialogBody => 'Pay this invoice?';

  @override
  String get lightningPaySuccess => 'Payment sent';

  @override
  String get lightningCopied => 'Copied';

  @override
  String get lightningErrorRestricted =>
      'The node hasn\'t authorized this app. Create a grant on your node for this connection.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Lightning error: $error';
  }

  @override
  String get lightningConfirm => 'Confirm';

  @override
  String get lightningCancel => 'Cancel';

  @override
  String get lightningNodeOnchain => 'Node on-chain';

  @override
  String get lightningDeposit => 'Deposit';

  @override
  String get lightningWithdraw => 'Send on-chain';

  @override
  String get lightningDepositTitle => 'On-chain deposit';

  @override
  String get lightningDepositHint => 'Send blake2b funds to this node address.';

  @override
  String get lightningDepositNewAddress => 'New address';

  @override
  String get lightningDepositWarning =>
      'Send only on the blake2b network. Funds sent on the wrong network are lost.';

  @override
  String get lightningOnchainSendTitle => 'On-chain send';

  @override
  String get lightningOnchainAddressLabel => 'Recipient address';

  @override
  String get lightningOnchainAmountLabel => 'Amount (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Network fee';

  @override
  String get lightningOnchainFeeMin => 'Min';

  @override
  String get lightningOnchainFeeEconomical => 'Economical';

  @override
  String get lightningOnchainFeePriority => 'Priority';

  @override
  String get lightningOnchainConfirm => 'Confirm send';

  @override
  String get lightningOnchainConfirmTitle => 'Confirm on-chain send?';

  @override
  String get lightningOnchainWarning =>
      'Irreversible operation: funds will leave the node.';

  @override
  String get lightningOnchainSuccess => 'Transaction sent';

  @override
  String get lightningOnchainInvalidAddress => 'Invalid blake2b address';

  @override
  String get lightningOnchainInsufficient => 'Insufficient on-chain funds';

  @override
  String get lightningFeesUnavailable =>
      'Fee estimates unavailable: the node will choose the fee';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey or pubkey@host:port (onion needs Tor on the node)';

  @override
  String get lightningOpenChannelInvalid =>
      'Invalid node ID or host (66 hex, host:port)';

  @override
  String get lightningActivityDetected => 'Node activity detected';

  @override
  String get lightningPeers => 'Peers';

  @override
  String get lightningPeersEmpty => 'No peers connected';

  @override
  String get lightningConnectPeer => 'Connect peer';

  @override
  String get lightningDisconnectPeer => 'Disconnect';

  @override
  String get lightningPeerDisconnected => 'Disconnected';

  @override
  String get lightningPeerId => 'Peer ID';

  @override
  String get lightningPeerAddresses => 'Addresses';

  @override
  String get lightningDisconnectPeerConfirm =>
      'Disconnect this peer? Open channels stay active.';

  @override
  String get lightningChannelDetail => 'Channel details';

  @override
  String get lightningChannelShortId => 'Short channel ID';

  @override
  String get lightningChannelState => 'Node status';

  @override
  String get lightningChannelFee => 'Fee';

  @override
  String get lightningChannelSpendable => 'Spendable';

  @override
  String get lightningChannelReceivable => 'Receivable';

  @override
  String get lightningChannelHtlcs => 'HTLCs';

  @override
  String get lightningChannelFundingTxid => 'Funding txid';

  @override
  String get lightningSplice => 'Resize channel';

  @override
  String get lightningSpliceTitle => 'Resize channel without closing it';

  @override
  String get lightningSpliceIn => 'Add funds';

  @override
  String get lightningSpliceOut => 'Withdraw funds';

  @override
  String get lightningSpliceAmountLabel => 'Amount (sat)';

  @override
  String get lightningSpliceEstimate => 'Estimate on-chain fee';

  @override
  String lightningSpliceFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'On-chain fee: about $feeString sat';
  }

  @override
  String get lightningSpliceFeeUnavailable =>
      'The node did not return a fee estimate';

  @override
  String get lightningSpliceConfirm =>
      'Resize the channel now? The channel stays online and one on-chain transaction is broadcast.';

  @override
  String get lightningSpliceDone => 'Channel resized';

  @override
  String get lightningSpliceInvalidAmount =>
      'Enter an amount greater than zero';

  @override
  String get lightningSpliceUnavailable =>
      'Resizing is available only on usable channels with the peer online.';

  @override
  String get lightningSpliceChannelFailed =>
      'The node refused the splice: the peer may not support it (it needs CLN with unified signatures). The channel is unchanged.';

  @override
  String get lightningSpliceBridgeOutdated =>
      'The bridge of this node does not expose channel resizing yet: update the bridge on the server.';

  @override
  String lightningSpliceOnchainAvailable(String sats) {
    return 'Node on-chain funds: $sats sat';
  }

  @override
  String get lightningSpliceInsufficientOnchain =>
      'Not enough on-chain funds on the node for this amount: top up the node wallet first (Deposit), then try again.';

  @override
  String get lightningReceiveModeInvoice => 'One-time invoice';

  @override
  String get lightningReceiveModeOffer => 'Reusable code';

  @override
  String get lightningOfferTitle => 'Reusable payment code';

  @override
  String get lightningOfferReusableHint =>
      'Share this code: anyone can pay it, choosing the amount if you left it open. It does not expire like an invoice.';

  @override
  String get lightningOfferAmountOptional => 'Amount (sat) — optional';

  @override
  String get lightningOfferAmountLabel => 'Amount (sat)';

  @override
  String get lightningOfferAmountRequired =>
      'Enter the amount to pay this offer';

  @override
  String lightningOfferFixedAmount(String sats) {
    return 'Offer amount: $sats sat';
  }

  @override
  String get lightningOfferDefaultDescription => 'Payment';

  @override
  String get lightningPayOffer => 'Pay offer';

  @override
  String get lightningCrossChainEntry => 'Pay a BTC (SHA-256) invoice';

  @override
  String get lightningCrossChainTitle => 'Cross-chain payment';

  @override
  String get lightningCrossChainHint =>
      'Pays a Lightning invoice of the SHA-256 chain using your BLAKE2b funds, through an external non-custodial bridge. The bridge can only collect once it has paid the invoice; otherwise the payment returns to you.';

  @override
  String get lightningCrossChainCheck => 'Check cost';

  @override
  String lightningCrossChainCost(String sats) {
    return 'You pay: $sats sat';
  }

  @override
  String lightningCrossChainInvoiceAmount(String sats) {
    return 'Invoice amount: $sats sat';
  }

  @override
  String lightningCrossChainRate(String rate) {
    return 'Exchange rate: 1 XBT = $rate BTC';
  }

  @override
  String lightningCrossChainSpread(String percent) {
    return 'Bridge spread: $percent%';
  }

  @override
  String lightningCrossChainWait(int seconds) {
    return 'Estimated wait: about $seconds s';
  }

  @override
  String get lightningCrossChainPay => 'Pay via bridge';

  @override
  String get lightningCrossChainConfirmTitle => 'Pay through the bridge?';

  @override
  String lightningCrossChainConfirmBody(String sats) {
    return 'You will pay $sats sat on this chain. The funds stay held until the bridge pays the destination invoice; if it cannot, the payment returns to you.';
  }

  @override
  String get lightningCrossChainDone => 'Payment completed';

  @override
  String lightningCrossChainState(String state) {
    return 'Bridge state: $state';
  }

  @override
  String get lightningNodeManagement => 'Node management';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers peers · $channels channels';
  }

  @override
  String get lightningNodeIdentity => 'Node identity';

  @override
  String get lightningNodePubkey => 'Public key';

  @override
  String get lightningNodeVersion => 'Version';

  @override
  String get lightningNodePeersCount => 'Peers';

  @override
  String get lightningNodeChannelsActive => 'Active channels';

  @override
  String get lightningNodeChannelsPending => 'Pending channels';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'Not available on this node: advertising lease terms requires the liquidity-ads plugin.';

  @override
  String get lightningLiquidity => 'Liquidity';

  @override
  String get lightningLiquidityTotal => 'Total capacity';

  @override
  String get lightningLiquidityOutbound => 'Outbound';

  @override
  String get lightningLiquidityInbound => 'Inbound';

  @override
  String get lightningLiquidityWarning =>
      'No inbound liquidity: payments can only arrive after a peer opens a channel towards this node.';

  @override
  String get lightningMovements => 'Movements';

  @override
  String get lightningMovementsEmpty => 'No movements yet';

  @override
  String get lightningMovementsAll => 'All movements';

  @override
  String get lightningMovementsLoadMore => 'Load more';

  @override
  String get lightningMovementDeposit => 'On-chain deposit';

  @override
  String get lightningMovementWithdrawal => 'On-chain send';

  @override
  String get lightningMovementChannelOpen => 'Channel opening';

  @override
  String get lightningMovementChannelClose => 'Channel closing';

  @override
  String get lightningMovementInvoice => 'Lightning payment';

  @override
  String get lightningMovementOnchainFee => 'On-chain fee';

  @override
  String get lightningMovementForward => 'Forwarding';

  @override
  String get lightningMovementOther => 'Movement';

  @override
  String lightningChannelsAll(int count) {
    return 'All channels ($count)';
  }

  @override
  String get lightningOnchainNode => 'Node on-chain';

  @override
  String get lightningOnchainBalance => 'On-chain balance';

  @override
  String get lightningOnchainConfirmed => 'Confirmed';

  @override
  String get lightningOnchainPending => 'Pending';

  @override
  String get lightningOnchainUtxos => 'UTXOs';

  @override
  String get lightningOnchainUtxosEmpty => 'No UTXOs';

  @override
  String get lightningOnchainAddresses => 'Node addresses';

  @override
  String get lightningOnchainNewAddress => 'New address';

  @override
  String get lightningOnchainAddressType => 'Address type';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'With funds';

  @override
  String get lightningOnchainReserved => 'Reserved';

  @override
  String get lightningOnchainBlockHeight => 'Block';

  @override
  String get lightningPayments => 'Payments';

  @override
  String get lightningInvoices => 'Invoices';

  @override
  String get lightningInvoicesEmpty => 'No invoices yet';

  @override
  String get lightningInvoiceStatusPaid => 'Paid';

  @override
  String get lightningInvoiceStatusPending => 'Waiting for payment';

  @override
  String get lightningInvoiceStatusExpired => 'Expired';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get lightningReceivePaid => 'Invoice paid';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total invoices · $pending waiting';
  }

  @override
  String get lightningPays => 'Sent payments';

  @override
  String get lightningPaysEmpty => 'No payments yet';

  @override
  String get lightningPaymentFee => 'Fee';

  @override
  String get lightningPaymentCompleted => 'Completed';

  @override
  String get lightningPaymentPending => 'Pending';

  @override
  String get lightningPaymentFailed => 'Failed';

  @override
  String get lightningHtlcsEmpty => 'No HTLCs';

  @override
  String get lightningHtlcInProgress => 'In progress';

  @override
  String get lightningHtlcIncoming => 'Incoming';

  @override
  String get lightningHtlcOutgoing => 'Outgoing';

  @override
  String get lightningChannelFees => 'Routing fees';

  @override
  String get lightningFeeEdit => 'Edit fees';

  @override
  String get lightningFeeBefore => 'Current';

  @override
  String get lightningFeeAfter => 'New';

  @override
  String get lightningFeeBaseLabel => 'Base (sat)';

  @override
  String get lightningFeePpmLabel => 'Rate (ppm)';

  @override
  String get lightningHtlcMinLabel => 'Min HTLC (sat)';

  @override
  String get lightningHtlcMaxLabel => 'Max HTLC (sat)';

  @override
  String get lightningCltvLabel => 'CLTV delta';

  @override
  String get lightningChannelReserve => 'Our reserve';

  @override
  String get lightningChannelToSelfDelay => 'To-self delay';

  @override
  String get lightningFeeConfirmTitle => 'Apply these routing fees?';

  @override
  String get lightningFeeWarning =>
      'Fees apply to routed payments. The network accepts only a few changes per day, and peers may take time to adopt them.';

  @override
  String get lightningFeeUpdated => 'Fee policy updated';

  @override
  String get lightningDiagnostics => 'Diagnostics';

  @override
  String get lightningDiagnosticsSubtitle =>
      'Accounting, plugins and forwarding';

  @override
  String get lightningStatsEconomy => 'Economy';

  @override
  String get lightningStatsNet => 'Net';

  @override
  String get lightningStatsSource => 'From the node\'s accounting (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'No accounting data yet';

  @override
  String get lightningStatsTagDeposit => 'Deposits';

  @override
  String get lightningStatsTagInvoice => 'Invoices';

  @override
  String get lightningStatsTagWithdrawal => 'Withdrawals';

  @override
  String get lightningStatsTagOnchainFee => 'On-chain fees';

  @override
  String get lightningStatsTagChannelOpen => 'Channel opens';

  @override
  String get lightningStatsTagChannelClose => 'Channel closes';

  @override
  String get lightningStatsTagRouted => 'Routing fees earned';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Plugins';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count active';
  }

  @override
  String get lightningPluginInactive => 'inactive';

  @override
  String get lightningForwardsTitle => 'Forwarding';

  @override
  String get lightningForwardsEmpty => 'No forwarded payments yet';

  @override
  String get lightningForwardSettled => 'Settled';

  @override
  String get lightningForwardFailed => 'Failed';

  @override
  String get lightningForwardOffered => 'In progress';

  @override
  String get lightningKeysendTitle => 'Send to node (keysend)';

  @override
  String get lightningKeysendHint => 'Destination node pubkey (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Amount (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Max fee (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Leave empty to use the node default (0.5%)';

  @override
  String get lightningKeysendWarning =>
      'Keysend pays a node without an invoice: funds move immediately and cannot be reversed.';

  @override
  String get lightningKeysendConfirmTitle => 'Send this keysend payment?';

  @override
  String get lightningKeysendDestination => 'Destination';

  @override
  String get lightningKeysendSent => 'Keysend sent';

  @override
  String get lightningKeysendInvalidPubkey => 'Invalid node pubkey';

  @override
  String get lightningKeysendInvalidAmount =>
      'Enter an amount greater than zero';

  @override
  String get lightningKeysendSend => 'Send';

  @override
  String get walletAddressesTitle => 'Addresses & UTXO';

  @override
  String get walletAddressesTabAddresses => 'Addresses';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Receive (/0)';

  @override
  String get walletAddressesChangeBranch => 'Change (/1)';

  @override
  String get walletAddressesStatusUnused => 'Never used';

  @override
  String get walletAddressesStatusUsed => 'Used';

  @override
  String get walletAddressesStatusFunds => 'With funds';

  @override
  String walletAddressesTxCount(int count) {
    return '$count transactions';
  }

  @override
  String get walletAddressesEmpty => 'No address to show';

  @override
  String get walletAddressesHintTap => 'Tap an address to copy it';

  @override
  String get lightningPeeringGateTitle =>
      'Peering restricted to bit 68 releases';

  @override
  String get lightningPeeringGateBody =>
      'This node requires option_blake2b (bit 68) during the connection handshake, so nodes on older releases cannot connect. It is a choice of the node, not a problem of the app or of the bridge. Use peers running release .4 or later, or wait for the community to make the bit optional.';

  @override
  String get lightningPeeringGateLink => 'Compatibility matrix';

  @override
  String get lightningPeeringGateNewTitle =>
      'Peering limited to the new protocol releases';

  @override
  String get lightningPeeringGateNewBody =>
      'This node uses the final feature bits (option_blake2b 512, option_unified_sigs 514): nodes that have not updated — release .4 and earlier — cannot connect. It is a decision of the network, not a problem of the app or of the bridge. Peers must update to release .5 or later.';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count registered peers, none connected';
  }

  @override
  String get lightningSwapOpen => 'Pay an invoice without a node (swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'Web app: Lightning payments use a swap provider (no node required). Connecting your own node is available in the Android app.';

  @override
  String get lightningSwapTitle => 'Lightning payment via provider';

  @override
  String get lightningSwapIntro =>
      'You keep custody of the funds: they go into an on-chain HTLC (P2WSH) and are released only when the provider pays your invoice. If the payment fails, you can recover the funds after the time lock.';

  @override
  String get lightningSwapProviderUriHint => 'Provider URI (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Connect provider';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Provider connected: $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Disconnect';

  @override
  String get lightningSwapProviderDefaultLabel =>
      'btcblake2b node (recommended)';

  @override
  String get lightningSwapProviderChecking => 'Checking the default node...';

  @override
  String get lightningSwapProviderReachable => 'Default node reachable';

  @override
  String get lightningSwapProviderDown =>
      'The default node is not responding right now.';

  @override
  String lightningSwapProviderSendLimit(String min, String max) {
    return 'Right now you can send between $min and $max sat';
  }

  @override
  String lightningSwapProviderLiquidity(String amount) {
    return 'Liquidity available now: $amount sat';
  }

  @override
  String get lightningSwapPeerCheck => 'Check recipient';

  @override
  String lightningSwapPeerReachable(String amount) {
    return 'Recipient reachable: $amount sat to pay';
  }

  @override
  String get lightningSwapErrorPeerUnreachable =>
      'The recipient is not reachable from the provider: no route to their node. Check the invoice or try again later.';

  @override
  String get lightningSwapInvoiceHint => 'Lightning invoice (lnbc...)';

  @override
  String get lightningSwapStart => 'Continue';

  @override
  String get lightningSwapAmount => 'Invoice amount';

  @override
  String get lightningSwapFees => 'Fees (claim + service)';

  @override
  String get lightningSwapTotal => 'Total to lock';

  @override
  String get lightningSwapFund => 'Send funds and start swap';

  @override
  String get lightningSwapFundHint =>
      'The funds go to the HTLC address shown above. Payment starts after 1 confirmation.';

  @override
  String get lightningSwapStateLabel => 'Status';

  @override
  String get lightningSwapHtlc => 'HTLC address';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund available from block $height';
  }

  @override
  String get swapStateAwaitingFunding => 'Waiting for on-chain funding';

  @override
  String get swapStateConfirming => 'Waiting for confirmations';

  @override
  String get swapStatePaying => 'Lightning payment in progress';

  @override
  String get swapStatePaid => 'Invoice paid, claiming in progress';

  @override
  String get swapStateClaiming => 'Claim in progress';

  @override
  String get swapStateCompleted => 'Completed';

  @override
  String get swapStatePaymentFailed => 'Payment failed — funds recoverable';

  @override
  String get swapStateExpired => 'Expired — funds recoverable';

  @override
  String get swapStateRefunded => 'Refunded';

  @override
  String get lightningSwapRecoveryTitle => 'Fund recovery';

  @override
  String get lightningSwapRecoveryHint => 'Recovery blob (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Import session';

  @override
  String get lightningSwapRefund => 'Recover funds (refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Refund not available yet: it opens from block $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Copy recovery blob';

  @override
  String get lightningSwapBlobCopied => 'Recovery blob copied';

  @override
  String get lightningSwapHistoryTitle => 'Swap history';

  @override
  String get lightningSwapHistoryEmpty =>
      'No swaps yet: payments made via a provider will show up here.';

  @override
  String get lightningSwapDetailTitle => 'Swap details';

  @override
  String get lightningSwapDetailCreated => 'Created';

  @override
  String get lightningSwapDetailSummary => 'Summary';

  @override
  String get lightningSwapDetailProtocol => 'Protocol data';

  @override
  String get lightningSwapDetailSwapId => 'Swap ID';

  @override
  String get lightningSwapDetailInvoice => 'Invoice';

  @override
  String get lightningSwapDetailPaymentHash => 'Payment hash';

  @override
  String get lightningSwapDetailProvider => 'Provider';

  @override
  String get lightningSwapDetailFundingTx => 'Funding transaction';

  @override
  String get lightningSwapOpenInExplorer => 'Open in explorer';

  @override
  String lightningSwapRefundSent(String txid) {
    return 'Refund sent: $txid';
  }

  @override
  String get lightningSwapClaimTxid => 'Claim txid';

  @override
  String get lightningSwapClaimHint =>
      'The claim is an on-chain transaction: it is confirmed with the next block (~12 min). Tap the link to verify it.';

  @override
  String get lightningSwapInvalidInvoice =>
      'That does not look like a Lightning invoice';

  @override
  String get lightningSwapWatchOnly =>
      'The swap needs a wallet with seed (not watch-only)';

  @override
  String get lightningSwapNoUtxos => 'No spendable funds in this wallet';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get lightningSwapKnownUris => 'Saved provider URIs';

  @override
  String get lightningSwapWalletLabel => 'Wallet';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Balance: $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Insufficient funds: $needed sat needed, $available sat available';
  }

  @override
  String lightningSwapInsufficientFundsWaiting(
      String needed, String available, String waiting) {
    return 'Insufficient funds: $needed sat needed, $available sat available ($waiting sat in the waiting period)';
  }

  @override
  String get lightningSwapCancel => 'Cancel swap';

  @override
  String get lightningSwapErrorConnectFailed =>
      'Could not reach the provider. Check your connection and try again.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Connection to the provider was lost. Try connecting again.';

  @override
  String get lightningSwapErrorNotConnected => 'Provider not connected.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'This provider uses a relay that the web version cannot reach. Open the app on your phone to pay with this provider.';

  @override
  String get lightningSwapErrorPaymentFailed =>
      'The provider could not pay this invoice. Your funds are still locked in the HTLC: you can recover them with the refund (see the block below).';

  @override
  String get lightningSwapErrorProviderUnavailable =>
      'The provider cannot pay right now (no route or not enough liquidity). Try again later.';

  @override
  String get lightningSwapErrorRateLimited =>
      'The provider is temporarily at full capacity. Try again later.';

  @override
  String get lightningSwapErrorDuplicateSwap =>
      'This invoice was already used in another swap.';

  @override
  String get lightningSwapErrorQuoteExpired =>
      'The quote expired. Start the swap again.';

  @override
  String get lightningSwapErrorInvoiceInvalid =>
      'The provider rejected this invoice: it is not valid.';

  @override
  String get lightningSwapErrorInvoiceExpired =>
      'This invoice has expired. Ask for a new one.';

  @override
  String get lightningSwapErrorAmountOutOfRange =>
      'The provider does not accept this amount (outside the allowed range).';

  @override
  String get lightningSwapErrorFundingTimeout =>
      'The funding was not confirmed in time: the swap expired without any payment.';

  @override
  String get lightningSwapErrorTooLate =>
      'The payment was cancelled because it was too close to the time lock. Your funds can be recovered.';

  @override
  String get lightningSwapRefundHint =>
      'These funds are still yours: the refund unlocks automatically at the time lock, even if the provider disappears.';

  @override
  String get lightningSwapCancelTitle => 'Cancel this swap?';

  @override
  String get lightningSwapCancelBody =>
      'The app will forget this swap. The provider drops it by itself before the deadline and no funds are locked. To retry with the same invoice you need a new session only after it expires — otherwise generate a new invoice.';

  @override
  String get lightningSwapCancelConfirm => 'Yes, cancel';

  @override
  String get lightningSwapWalletMissing =>
      'The wallet bound to this swap is no longer available';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Bound wallet: $name';
  }

  @override
  String get lightningInvoiceDelete => 'Delete invoice';

  @override
  String get lightningInvoiceDeleteTitle => 'Delete this invoice?';

  @override
  String get lightningInvoiceDeleteBody =>
      'The invoice will be removed from the node. If it is unpaid it can no longer be paid.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Yes, delete';

  @override
  String get lightningInvoiceDeleted => 'Invoice deleted';

  @override
  String get lightningChannelPeerAddress => 'Peer address';

  @override
  String get lightningSpliceNodeTooOld =>
      'Resizing a channel needs a node on release .6 or later (we recommend .9). This node is older, so the action is hidden. Update the node to enable it.';

  @override
  String get lightningSpliceNodeOutdated =>
      'This node is on a release before .9: the updates from .8 close a splice vulnerability that can make a node lose channel funds. Resizing still works, but update to .9 as soon as you can.';

  @override
  String get lightningDiscoveryTitle => 'Find peers and liquidity';

  @override
  String get lightningDiscoveryBody =>
      'There is no central catalogue on this network. These are the live reference points where the community lists nodes, channels and inbound liquidity.';

  @override
  String get lightningDiscoveryNetworkTitle => 'Network explorer (Paperclip)';

  @override
  String get lightningDiscoveryNetworkBody =>
      'Public nodes, channels and advertised capacity.';

  @override
  String get lightningDiscoveryLspTitle => 'Inbound liquidity (Paperclip LSP)';

  @override
  String get lightningDiscoveryLspBody =>
      'A channel to your node, paid on-chain in XBT.';

  @override
  String get lightningDiscoveryNodexTitle => 'Nodex - channels and fees';

  @override
  String get lightningDiscoveryNodexBody =>
      'Channel explorer with fees both ways and uptime.';

  @override
  String get lightningDiscoverySwapTitle => 'Lightning Fork Swap';

  @override
  String get lightningDiscoverySwapBody =>
      'Non-custodial swap between Lightning and on-chain to move liquidity.';

  @override
  String get lightningDiscoveryWatchtowerTitle =>
      'Watchtowers (lnd nodes only)';

  @override
  String get lightningDiscoveryWatchtowerBody =>
      'A watchtower watches the chain while your node is offline and punishes a peer that publishes an old state. Use more than one: lnd needs wtclient.active=true and Tor. CLN nodes speak BOLT 13 (TEOS) instead, which the app does not configure yet. Add them with lncli wtclient add <uri>.';

  @override
  String get lightningDiscoveryOpenFailed =>
      'The browser did not open this link.';

  @override
  String get lightningInboundMissingTitle => 'You cannot receive yet';

  @override
  String get lightningInboundMissingBody =>
      'This node has no inbound liquidity: another node must open a channel towards it before anyone can pay you. Until then, the invoices you share cannot be paid.';

  @override
  String get lightningInboundMissingCta => 'Get inbound liquidity';

  @override
  String get lightningInboundMissingRefresh => 'Check again';

  @override
  String get webVaultNoticeTitle => 'You are using the browser version';

  @override
  String get webVaultNoticeBody =>
      'Here the encrypted seed is stored in the browser (localStorage, with an IndexedDB backup) and the key is wrapped by your password. The vault locks after 10 minutes of inactivity and when the page is hidden, but code running on the page while the vault is unlocked could read the keys: the browser cannot protect against that. For real amounts use the Android app, where the keys stay in the system keyring.';

  @override
  String get webVaultNoticeDownload => 'Get the Android app';

  @override
  String get splashStartupError => 'Unable to start the app';

  @override
  String get splashRetry => 'Retry';

  @override
  String webVaultOriginOfficial(Object origin) {
    return 'Verified domain: $origin';
  }

  @override
  String webVaultOriginDev(Object origin) {
    return 'Local test environment: $origin';
  }

  @override
  String webVaultOriginUnofficial(Object origin) {
    return 'WARNING: this is not the official domain. You are on $origin — the real one is app.btcblake2b.org. Do not enter your seed or password here.';
  }

  @override
  String get receiveNeedsBackupTitle => 'Back up the seed first';

  @override
  String get receiveNeedsBackupBody =>
      'In the browser the encrypted seed is stored on this site: a PWA update or clearing site data deletes it, and an address shared now would receive funds you could never spend. Confirm the seed backup (or move the wallet to the app) before receiving.';

  @override
  String get receiveNeedsBackupAction => 'Back up now';

  @override
  String get merchantChargeTitle => 'Charge';

  @override
  String get merchantChargeAmount => 'Amount';

  @override
  String get merchantChargeAmountInvalid =>
      'Enter an amount greater than zero.';

  @override
  String get merchantChargeLabel => 'Description (optional)';

  @override
  String get merchantChargeModeLightning => 'Lightning';

  @override
  String get merchantChargeModeOnchain => 'On-chain';

  @override
  String get merchantChargeLightningHint =>
      'The customer pays the Lightning invoice: credited as soon as the node receives it.';

  @override
  String get merchantChargeOnchainHint =>
      'The customer scans the QR: the amount is already inside, they only confirm.';

  @override
  String get merchantChargeLightningUnavailable =>
      'No Lightning node connected: for now you can charge on-chain. Connect your node from the Lightning tab to also accept Lightning payments.';

  @override
  String get merchantChargeCreate => 'Create payment request';

  @override
  String get merchantChargeInvoiceTitle => 'Lightning invoice';

  @override
  String get merchantChargeUriTitle => 'Bitcoin URI (BIP21)';

  @override
  String get merchantChargeWaiting => 'Waiting for payment…';

  @override
  String get merchantChargePaid => 'Payment received';

  @override
  String get merchantChargeNew => 'New request';

  @override
  String get merchantConvertTitle => 'Convert to BTC';

  @override
  String get merchantConvertIntro =>
      'XBT lives on the bitcoin-blake2b network, a separate chain from Bitcoin: converting XBT into BTC (or the other way round) is a cross-chain swap. This app does not do it and cannot do it: no exchange, no custody. The conversion happens on third-party non-custodial services you choose.';

  @override
  String get merchantConvertAddressTitle => 'Your XBT address';

  @override
  String get merchantConvertAddressBody =>
      'Copy the address of the wallet you want to use there, or receive XBT here first and convert later. Never send funds to a service that asks for your seed phrase.';

  @override
  String get merchantConvertUnnamedWallet => 'Wallet';

  @override
  String get merchantConvertPaperclipTitle => 'Paperclip Bridge (beta)';

  @override
  String get merchantConvertPaperclipBody =>
      'Non-custodial bridge from the community: it collects only when the invoice is actually paid. Beta, not independently audited.';

  @override
  String get merchantConvertForkTitle => 'Lightning Fork Swap';

  @override
  String get merchantConvertForkBody =>
      'Community swap with on-chain donations used only for its own liquidity. Check fees and limits before sending.';

  @override
  String get merchantConvertWarningTitle => 'Before you convert';

  @override
  String get merchantConvertWarningBody =>
      '1) Compare the amount you receive with the amount you send: fees on small sums can eat the difference. 2) A swap is not reversible: check the address and the chain. 3) We do not receive, hold or guarantee anything: if a service freezes, only that service can answer. 4) For real amounts, prefer small tests first.';

  @override
  String get merchantConvertOpen => 'Convert';

  @override
  String get fiatPriceShow => 'Show value in dollars';

  @override
  String get fiatPriceNotSet => 'No price set: add one to see the value';

  @override
  String fiatPriceCurrent(Object cents) {
    return '1 XBT = $cents';
  }

  @override
  String get fiatPriceSet => 'Set the XBT price';

  @override
  String get fiatPriceSetDesc =>
      'The price used for the value: enter it yourself or let the app read it from NeoXEX.';

  @override
  String get fiatPriceDialogBody =>
      'Enter the price of 1 XBT in USD. If you prefer, turn on the automatic price in Settings: the app then reads the latest XBT/USDC trade from NeoXEX on demand (and the USDT exchange rate for the currency you pick). The value shown is indicative, not a quote.';

  @override
  String get fiatPriceFieldLabel => 'Price of 1 XBT';

  @override
  String get fiatPriceSave => 'Save';

  @override
  String get fiatPriceInvalid =>
      'Not a valid price: use a number greater than zero, at most 2 decimals.';

  @override
  String get fiatPriceManualNote => 'your price, not a market quote';

  @override
  String get fiatPriceMarketNote => 'market price, latest NeoXEX trade';

  @override
  String get fiatPriceCurrency => 'Value currency';

  @override
  String get fiatPriceCurrencyDesc => 'Converted with the USDT exchange rate';

  @override
  String get fiatPriceFxFailed =>
      'Exchange rate unavailable: connect to the internet and try again.';

  @override
  String get fiatPriceAuto => 'Fetch the price from NeoXEX';

  @override
  String get fiatPriceAutoDesc =>
      'Reads the last XBT/USDC trade on demand. No polling, no background requests.';

  @override
  String get fiatPriceAutoUpdated => 'Price updated from NeoXEX';

  @override
  String get fiatPriceAutoFailed =>
      'NeoXEX is unreachable: the previous price is kept.';

  @override
  String get balanceChangeUnitHint =>
      'Tap to switch the balance between XBT, sats and dollars';

  @override
  String get psbtSpendTitle => 'Spend with PSBT';

  @override
  String get psbtSpendIntro =>
      'A watch-only wallet cannot sign. Create the PSBT here, sign it on a device that holds the seed, then broadcast it from there.';

  @override
  String get psbtCreate => 'Create PSBT';

  @override
  String get psbtCreating => 'Creating the PSBT…';

  @override
  String psbtDraftReady(Object change, Object fee) {
    return 'PSBT ready · fee $fee sat · change $change sat';
  }

  @override
  String get psbtQrTitle => 'Scan this PSBT';

  @override
  String psbtQrFrames(Object count) {
    return '$count frames — keep the camera pointed while the QR rotates';
  }

  @override
  String get psbtCopyBase64 => 'Copy PSBT (base64)';

  @override
  String get psbtSignTitle => 'Sign a PSBT';

  @override
  String get psbtSignIntro =>
      'Paste or scan a PSBT created on another device. Check recipients and fee before signing.';

  @override
  String get psbtPasteLabel => 'PSBT (base64)';

  @override
  String get psbtScan => 'Scan QR';

  @override
  String get psbtReviewTitle => 'Review';

  @override
  String psbtReviewFee(Object fee) {
    return 'Fee: $fee sat';
  }

  @override
  String psbtReviewInputs(Object count) {
    return 'Inputs: $count';
  }

  @override
  String psbtReviewOutputs(Object count) {
    return 'Recipients: $count';
  }

  @override
  String get psbtSign => 'Sign';

  @override
  String get psbtSignedTitle => 'Signed PSBT';

  @override
  String get psbtBroadcast => 'Broadcast';

  @override
  String get psbtBroadcasting => 'Broadcasting…';

  @override
  String psbtBroadcastDone(Object txid) {
    return 'Sent: $txid';
  }

  @override
  String get psbtInvalid => 'Not a valid PSBT';

  @override
  String get psbtNoFrames => 'No PSBT frame recognised';

  @override
  String psbtScanProgress(Object received, Object total) {
    return 'Frames read: $received/$total';
  }

  @override
  String get psbtSigning => 'Signing…';

  @override
  String get psbtNeedsSeed =>
      'This wallet has no seed: sign on the device that holds it.';
}
