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
  String get appErrorTitle => 'Unable to start the app';

  @override
  String get appReload => 'Reload page';

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
  String get homeReceiveWallet => 'Receive';

  @override
  String get homeMultiTransfer => 'Multi-Send';

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
  String homeDeleteMultiError(Object message) {
    return '$message';
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
  String get homeMoreOptions => 'More options';

  @override
  String get homeLockVault => 'Lock vault';

  @override
  String get homeVaultLocked => 'Vault locked';

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
  String homeCreated(Object date) {
    return 'Created: $date';
  }

  @override
  String homeLastTransfer(Object date) {
    return 'Last transfer: $date';
  }

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
  String get walletDetailNoConnection => 'No connection';

  @override
  String get walletDetailTransferSuccess =>
      'Wallet successfully transferred. Local seed has been deleted.';

  @override
  String walletDetailTransferError(Object error) {
    return 'Transfer error: $error';
  }

  @override
  String get walletDetailSeedCopied =>
      'Seed phrase copied. Will be removed after 60s.';

  @override
  String get walletDetailSeedWarning =>
      'Store it safely! This is the ONLY way to recover your funds.';

  @override
  String get walletDetailAddress => 'Address';

  @override
  String get walletDetailName => 'Name';

  @override
  String get walletDetailBalance => 'Balance';

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
  String get walletDetailTxFee => 'Fee';

  @override
  String get walletDetailTxIncoming => 'Received';

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
  String get themeToggle => 'Toggle theme';

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
  String get walletDetailTransfer => 'Transfer';

  @override
  String get walletDetailTransferred => 'TRANSFERRED';

  @override
  String get walletDetailPending => 'PENDING TRANSFER';

  @override
  String get walletDetailNoName => 'Unnamed wallet';

  @override
  String get walletDetailTransferredDesc =>
      'This wallet has been transferred. Read-only mode.';

  @override
  String get sendScreenTitle => 'Send BTC';

  @override
  String get sendScreenAddressLabel => 'Recipient address';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => 'Amount (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

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
  String get walletDetailFirst100Addresses => 'First 100 Addresses';

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
    return 'This Privacy Policy is provisional and will be replaced by the final version published on the official website when available.\n\n1) DATA ON YOUR DEVICE. The app does not require an account and does not store personal data on servers operated by the author. The encrypted seed (AES-256-GCM), preferences and consents remain ONLY on your device.\n\n2) DATA SENT TO THIRD PARTIES FOR OPERATION. To display balance and fees the app queries public third-party APIs:\n• mempool.guide (blockchain explorer).\nEach request transmits your IP address and the public address of the queried wallet. Private keys and the seed are NEVER transmitted.\n\n3) NO TRACKERS. No analytics, no advertising, no cookies inside the app.\n\n4) RIGHTS (GDPR arts. 13-14). You have the right of access, rectification, erasure and objection by writing to the data controller: $holder — $email. Since we do not store personal data, these rights are already largely guaranteed by the fact that the data stays on your device.';
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
  String sendScreenError(Object error) {
    return 'Send error: $error';
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
  String get importScreenValidateEmpty => 'Enter the mnemonic phrase.';

  @override
  String importScreenValidateCount(Object count) {
    return 'The phrase must contain 12, 15, 18, 21 or 24 words (detected: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Invalid mnemonic phrase. Check the spelling of the words.';

  @override
  String get importScreenImporting => 'Importing...';

  @override
  String get importScreenImport => 'Import';

  @override
  String importScreenError(Object error) {
    return 'Error importing wallet: $error';
  }

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
  String get transferScreenTitle => 'Transfer Wallet';

  @override
  String get transferScreenScanning => 'Scan the receiver\'s QR Code.';

  @override
  String get transferScreenProcessing => 'Processing and encrypting data...';

  @override
  String transferScreenScanError(Object error) {
    return 'Error during scan or encryption: $error';
  }

  @override
  String get transferScreenNearbyTitle => 'Scan to receive';

  @override
  String get transferScreenNearbySubtitle =>
      'Have the receiver scan this QR Code.';

  @override
  String transferScreenNearbyCode(Object code) {
    return 'Manual code: $code';
  }

  @override
  String get transferScreenNearbyCancel => 'Cancel';

  @override
  String get transferScreenNearbySuccess =>
      'Wallet successfully transferred via Bluetooth. The local seed has been deleted.';

  @override
  String transferScreenNearbyError(Object error) {
    return 'Transfer error: $error';
  }

  @override
  String get transferScreenWebRtcConnecting => 'Starting WebRTC connection...';

  @override
  String get transferScreenWebRtcTransferring => 'Transferring via WebRTC...';

  @override
  String get transferScreenTransferComplete => 'Transfer completed!';

  @override
  String get transferScreenMethodTitle => 'Choose transfer method';

  @override
  String get transferScreenMethodQr => 'QR Code (2-Phase)';

  @override
  String get transferScreenMethodQrDesc =>
      'Scan the receiver\'s QR code, then generate a QR code with the encrypted seed.';

  @override
  String get transferScreenMethodNearby => 'Bluetooth P2P';

  @override
  String get transferScreenMethodNearbyDesc =>
      'Direct device-to-device transfer. Requires Bluetooth.';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC (Internet)';

  @override
  String get transferScreenMethodWebRtcDesc =>
      'P2P via browser. Requires internet on both devices.';

  @override
  String get transferScreenWebRtcQrDescription =>
      'The receiver must scan this QR. Transfer will happen via WebRTC (no size limit).';

  @override
  String get transferScreenEncryptedQrDescription =>
      'Show this QR Code to the receiving device. Once scanned and reception is complete, the wallet will be automatically removed from this device.';

  @override
  String get transferScreenWebRtcTimeout =>
      'WebRTC connection failed after 30 seconds. Try again or use the 2-phase QR Code method.';

  @override
  String get receiveScreenTitle => 'Receive Wallet';

  @override
  String get receiveScreenInit => 'Initializing asymmetric key...';

  @override
  String get receiveScreenShowQr => 'Show this QR Code to the sender.';

  @override
  String get receiveScreenScanSender =>
      'Scan the QR Code on the sender\'s device.';

  @override
  String get receiveScreenAutoDetectMethod =>
      'The app automatically detects the transfer method used by the sender.';

  @override
  String receiveScreenKeyError(Object error) {
    return 'Key generation error: $error';
  }

  @override
  String get receiveScreenDecrypting =>
      'Data received. Decrypting and server validation in progress...';

  @override
  String get receiveScreenSuccess =>
      'Wallet received and imported successfully.';

  @override
  String get receiveScreenQrSuccess => 'Wallet received via QR Code.';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return 'Code $code read. Connecting...';
  }

  @override
  String get receiveScreenNearbySuccess => 'Wallet received via Bluetooth P2P.';

  @override
  String receiveScreenError(Object error) {
    return 'Error: $error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'WebRTC Room';

  @override
  String get receiveScreenWebRtcConnect => 'Connect to Room';

  @override
  String get receiveScreenWebRtcShareQr => 'Share this QR Code with the sender';

  @override
  String get receiveScreenWebRtcScanQr => 'Scan the sender\'s room QR Code';

  @override
  String get receiveScreenWebRtcWait => 'Waiting for sender connection...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return 'Room ID: $roomId';
  }

  @override
  String get passwordDialogCreateTitle => 'Create Security Password';

  @override
  String get passwordDialogCreateContent =>
      'Set a password to protect sensitive operations on this browser. This password will be stored locally and used to encrypt your data.';

  @override
  String get passwordDialogCreateHint => 'Enter a secure password';

  @override
  String get passwordDialogCreateConfirm => 'Confirm password';

  @override
  String get passwordDialogCreateConfirmHint => 'Re-enter the password';

  @override
  String get passwordDialogCreateMismatch => 'Passwords do not match';

  @override
  String get passwordDialogCreateTooShort =>
      'Password must be at least 8 characters';

  @override
  String get passwordDialogCreate => 'Create';

  @override
  String get passwordDialogCancel => 'Cancel';

  @override
  String get passwordDialogEnterTitle => 'Enter Password';

  @override
  String get passwordDialogEnterContent =>
      'Enter your security password to continue.';

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
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

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
  String get walletDetailTransferredOn => 'Transferred on';

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
  String get walletDetailFirst100 => 'First 100 Addresses';

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
  String get multiTransferTitle => 'Multi-Wallet Send';

  @override
  String get multiTransferSelectWallets => 'Select wallets to send';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets selected',
      one: '1 wallet selected',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return 'Total value: $amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => 'Transfer method:';

  @override
  String multiTransferMethodWebRtc(Object max) {
    return 'WebRTC (max $max)';
  }

  @override
  String multiTransferMethodBluetooth(Object max) {
    return 'Bluetooth (max $max)';
  }

  @override
  String multiTransferMethodQr(Object max) {
    return 'QR Code 2-phase (max $max)';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wallets',
      one: '1 Wallet',
    );
    return 'Send $_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => 'Sending...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return 'Wallet $current of $total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets sent successfully',
      one: '1 wallet sent successfully',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success sent, $failed failed';
  }

  @override
  String get multiTransferNoLockedWallets =>
      'No wallets available for transfer. Only LOCKED wallets can be transferred.';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return 'You selected $selected wallets. The maximum for $method is $max.';
  }

  @override
  String get multiTransferReceivingTitle => 'Multi-Wallet Receive';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return 'Received $received of $total wallets';
  }

  @override
  String get multiTransferMethodUnavailable => 'Not available on this platform';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return 'Sending wallet $current of $total...';
  }

  @override
  String get multiTransferPreparing => 'Preparing wallet...';

  @override
  String get multiTransferWaitingReceiver => 'Waiting for receiver...';

  @override
  String get multiTransferCompleted => 'Completed';

  @override
  String get multiTransferFailed => 'Failed';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return 'Manual 2-phase transfer via QR code. Max $max wallets.';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return 'Fast P2P transfer via internet. Max $max wallets.';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return 'Direct device-to-device transfer. Max $max wallets.';
  }

  @override
  String get multiTransferNoBalance => 'Balance not available';

  @override
  String get multiTransferConfirmTitle => 'Confirm send';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return 'You are about to send $_temp0 totaling $amount $ticker. Continue?';
  }

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
  String get onboardingValidationCheckbox =>
      'You must accept all declarations to continue';

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
}
