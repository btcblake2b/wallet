import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('it'),
    Locale('en'),
    Locale('de'),
    Locale('fi'),
    Locale('es'),
    Locale('zh'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Btc Blake2b Wallet'**
  String get appTitle;

  /// No description provided for @appErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the app'**
  String get appErrorTitle;

  /// No description provided for @appReload.
  ///
  /// In en, this message translates to:
  /// **'Reload page'**
  String get appReload;

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Btc Blake2b Wallet'**
  String get homeScreenTitle;

  /// No description provided for @homeNoConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get homeNoConnectionTitle;

  /// No description provided for @homeNoConnectionCreate.
  ///
  /// In en, this message translates to:
  /// **'Unable to create wallet without an active internet connection. The address must be verified on the network. Please try again when the connection is restored.'**
  String get homeNoConnectionCreate;

  /// No description provided for @homeNoConnectionImport.
  ///
  /// In en, this message translates to:
  /// **'Unable to import wallet without an active internet connection. The wallet must be registered on the server.'**
  String get homeNoConnectionImport;

  /// No description provided for @homeOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get homeOk;

  /// No description provided for @homeWalletCreated.
  ///
  /// In en, this message translates to:
  /// **'Wallet created successfully.'**
  String get homeWalletCreated;

  /// No description provided for @homeWalletCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating wallet: {error}'**
  String homeWalletCreateError(Object error);

  /// No description provided for @homeImportWallet.
  ///
  /// In en, this message translates to:
  /// **'Import wallet'**
  String get homeImportWallet;

  /// No description provided for @homeCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get homeCreateWallet;

  /// No description provided for @homeReceiveWallet.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get homeReceiveWallet;

  /// No description provided for @homeMultiTransfer.
  ///
  /// In en, this message translates to:
  /// **'Multi-Send'**
  String get homeMultiTransfer;

  /// No description provided for @homeSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get homeSelected;

  /// No description provided for @homeDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get homeDeleteSelected;

  /// No description provided for @homeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} wallets? This action is irreversible.'**
  String homeDeleteConfirm(int count);

  /// No description provided for @homeDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} wallets deleted successfully.'**
  String homeDeleted(Object count);

  /// No description provided for @homeDeleteMultiError.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String homeDeleteMultiError(Object message);

  /// No description provided for @homeWalletImported.
  ///
  /// In en, this message translates to:
  /// **'Wallet imported successfully.'**
  String get homeWalletImported;

  /// No description provided for @homeSecurityWarning.
  ///
  /// In en, this message translates to:
  /// **'This software is provided \"as is\" without any warranty. The manufacturer is not liable for loss of funds, theft, hacking, transaction errors, or any damages arising from use of the app. The wallet does not guarantee protection against previous copies of the seed. Use only for small amounts.'**
  String get homeSecurityWarning;

  /// No description provided for @homeDisclaimerAccept.
  ///
  /// In en, this message translates to:
  /// **'I Accept'**
  String get homeDisclaimerAccept;

  /// No description provided for @legalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Info'**
  String get legalInfoTitle;

  /// No description provided for @homeLocalWallets.
  ///
  /// In en, this message translates to:
  /// **'Local wallets'**
  String get homeLocalWallets;

  /// No description provided for @homeErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading wallet: {error}'**
  String homeErrorLoading(Object error);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallets'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first Bitcoin wallet to get started.'**
  String get homeEmptySubtitle;

  /// No description provided for @homeBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE BALANCE'**
  String get homeBalanceTitle;

  /// No description provided for @balanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Balance unavailable'**
  String get balanceUnavailable;

  /// No description provided for @homeBackupVerified.
  ///
  /// In en, this message translates to:
  /// **'Backup verified'**
  String get homeBackupVerified;

  /// No description provided for @homeBackupNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Backup not verified'**
  String get homeBackupNotVerified;

  /// No description provided for @homeMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get homeMoreOptions;

  /// No description provided for @homeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String homeCreated(Object date);

  /// No description provided for @homeLastTransfer.
  ///
  /// In en, this message translates to:
  /// **'Last transfer: {date}'**
  String homeLastTransfer(Object date);

  /// No description provided for @homeWalletSemantics.
  ///
  /// In en, this message translates to:
  /// **'Wallet {name}{balance}'**
  String homeWalletSemantics(Object balance, Object name);

  /// No description provided for @walletDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletDetailTitle;

  /// No description provided for @walletDetailCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied. Will be removed after 60s.'**
  String walletDetailCopied(Object label);

  /// No description provided for @walletDetailNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get walletDetailNoConnection;

  /// No description provided for @walletDetailTransferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet successfully transferred. Local seed has been deleted.'**
  String get walletDetailTransferSuccess;

  /// No description provided for @walletDetailTransferError.
  ///
  /// In en, this message translates to:
  /// **'Transfer error: {error}'**
  String walletDetailTransferError(Object error);

  /// No description provided for @walletDetailSeedCopied.
  ///
  /// In en, this message translates to:
  /// **'Seed phrase copied. Will be removed after 60s.'**
  String get walletDetailSeedCopied;

  /// No description provided for @walletDetailSeedWarning.
  ///
  /// In en, this message translates to:
  /// **'Store it safely! This is the ONLY way to recover your funds.'**
  String get walletDetailSeedWarning;

  /// No description provided for @walletDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get walletDetailAddress;

  /// No description provided for @walletDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get walletDetailName;

  /// No description provided for @walletDetailBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletDetailBalance;

  /// No description provided for @walletDetailTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get walletDetailTransactions;

  /// No description provided for @walletDetailTxBlockHeight.
  ///
  /// In en, this message translates to:
  /// **'Block height'**
  String get walletDetailTxBlockHeight;

  /// No description provided for @walletDetailTxConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get walletDetailTxConfirmations;

  /// No description provided for @walletDetailTxDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get walletDetailTxDate;

  /// No description provided for @walletDetailTxDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get walletDetailTxDetails;

  /// No description provided for @walletDetailTxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get walletDetailTxEmpty;

  /// No description provided for @walletDetailTxError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get walletDetailTxError;

  /// No description provided for @walletDetailTxFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get walletDetailTxFee;

  /// No description provided for @walletDetailTxIncoming.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get walletDetailTxIncoming;

  /// No description provided for @walletDetailTxOrphan.
  ///
  /// In en, this message translates to:
  /// **'Orphan (lost block)'**
  String get walletDetailTxOrphan;

  /// No description provided for @walletDetailTxOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get walletDetailTxOutgoing;

  /// No description provided for @walletDetailTxPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get walletDetailTxPending;

  /// No description provided for @walletDetailTxReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced (dropped from mempool)'**
  String get walletDetailTxReplaced;

  /// No description provided for @walletDetailTxRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get walletDetailTxRetry;

  /// No description provided for @themeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get themeToggle;

  /// No description provided for @backupSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed backup'**
  String get backupSeedTitle;

  /// No description provided for @backupSeedIntro.
  ///
  /// In en, this message translates to:
  /// **'Write down your seed phrase on paper and store it in a safe place. It is the only way to recover your funds.'**
  String get backupSeedIntro;

  /// No description provided for @backupSeedStart.
  ///
  /// In en, this message translates to:
  /// **'Start backup'**
  String get backupSeedStart;

  /// No description provided for @backupSeedLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get backupSeedLater;

  /// No description provided for @backupSeedSavedContinue.
  ///
  /// In en, this message translates to:
  /// **'I saved the seed'**
  String get backupSeedSavedContinue;

  /// No description provided for @backupSeedVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your backup'**
  String get backupSeedVerifyTitle;

  /// No description provided for @backupSeedVerifyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 3 highlighted words to confirm you saved them.'**
  String get backupSeedVerifyHint;

  /// No description provided for @backupSeedWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word {number}'**
  String backupSeedWordLabel(Object number);

  /// No description provided for @backupSeedVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect words. Try again.'**
  String get backupSeedVerifyError;

  /// No description provided for @backupSeedDone.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupSeedDone;

  /// No description provided for @backupSeedDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Your seed is safe. Remember: whoever holds the seed controls the funds.'**
  String get backupSeedDoneDesc;

  /// No description provided for @backupSeedFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get backupSeedFinish;

  /// No description provided for @backupSeedSkipWarning.
  ///
  /// In en, this message translates to:
  /// **'If you skip, you risk losing your funds if you lose this device. You can do it later from the wallet details.'**
  String get backupSeedSkipWarning;

  /// No description provided for @walletDetailSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get walletDetailSend;

  /// No description provided for @walletDetailReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get walletDetailReceive;

  /// No description provided for @walletDetailTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get walletDetailTransfer;

  /// No description provided for @walletDetailTransferred.
  ///
  /// In en, this message translates to:
  /// **'TRANSFERRED'**
  String get walletDetailTransferred;

  /// No description provided for @walletDetailPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING TRANSFER'**
  String get walletDetailPending;

  /// No description provided for @walletDetailNoName.
  ///
  /// In en, this message translates to:
  /// **'Unnamed wallet'**
  String get walletDetailNoName;

  /// No description provided for @walletDetailTransferredDesc.
  ///
  /// In en, this message translates to:
  /// **'This wallet has been transferred. Read-only mode.'**
  String get walletDetailTransferredDesc;

  /// No description provided for @sendScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Send BTC'**
  String get sendScreenTitle;

  /// No description provided for @sendScreenAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get sendScreenAddressLabel;

  /// No description provided for @sendScreenAddressHint.
  ///
  /// In en, this message translates to:
  /// **'bc1...'**
  String get sendScreenAddressHint;

  /// No description provided for @sendScreenAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BTC)'**
  String get sendScreenAmountLabel;

  /// No description provided for @sendScreenAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get sendScreenAmountHint;

  /// No description provided for @sendScreenFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get sendScreenFeeLabel;

  /// No description provided for @sendScreenFeeLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get sendScreenFeeLow;

  /// No description provided for @sendScreenFeeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get sendScreenFeeNormal;

  /// No description provided for @sendScreenFeeHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get sendScreenFeeHigh;

  /// No description provided for @sendScreenFeeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sendScreenFeeCustom;

  /// No description provided for @sendScreenFeeCustomHint.
  ///
  /// In en, this message translates to:
  /// **'sat/vB'**
  String get sendScreenFeeCustomHint;

  /// No description provided for @sendScreenBalance.
  ///
  /// In en, this message translates to:
  /// **'Available: {balance} {ticker}'**
  String sendScreenBalance(Object balance, Object ticker);

  /// No description provided for @sendScreenFeeEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated fee: {fee} sat'**
  String sendScreenFeeEstimated(Object fee);

  /// No description provided for @sendScreenUtxoControl.
  ///
  /// In en, this message translates to:
  /// **'UTXO selection'**
  String get sendScreenUtxoControl;

  /// No description provided for @sendScreenUtxoSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get sendScreenUtxoSelectAll;

  /// No description provided for @sendScreenUtxoNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one UTXO to send'**
  String get sendScreenUtxoNoneSelected;

  /// No description provided for @sendScreenTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} {ticker}'**
  String sendScreenTotal(Object ticker, Object total);

  /// No description provided for @sendScreenMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get sendScreenMax;

  /// No description provided for @sendScreenSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendScreenSend;

  /// No description provided for @sendScreenSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendScreenSending;

  /// No description provided for @homeDeleteMultiSummary.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} wallets, {errors} errors: {error}'**
  String homeDeleteMultiSummary(int deleted, int errors, Object error);

  /// No description provided for @walletDetailBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get walletDetailBalanceLabel;

  /// No description provided for @walletDetailMasterFingerprint.
  ///
  /// In en, this message translates to:
  /// **'MASTER FINGERPRINT'**
  String get walletDetailMasterFingerprint;

  /// No description provided for @walletDetailDerivationPath.
  ///
  /// In en, this message translates to:
  /// **'DERIVATION PATH'**
  String get walletDetailDerivationPath;

  /// No description provided for @walletDetailSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get walletDetailSettings;

  /// No description provided for @walletDetailAdvancedTools.
  ///
  /// In en, this message translates to:
  /// **'Advanced Tools'**
  String get walletDetailAdvancedTools;

  /// No description provided for @walletDetailUtxos.
  ///
  /// In en, this message translates to:
  /// **'UTXO'**
  String get walletDetailUtxos;

  /// No description provided for @walletDetailUtxoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spendable UTXO found'**
  String get walletDetailUtxoEmpty;

  /// No description provided for @walletDetailUtxoConfirmations.
  ///
  /// In en, this message translates to:
  /// **'{count} confirmations'**
  String walletDetailUtxoConfirmations(int count);

  /// No description provided for @walletDetailUtxoSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected · {sats} sat'**
  String walletDetailUtxoSelected(int count, int sats);

  /// No description provided for @walletDetailUtxoSendSelected.
  ///
  /// In en, this message translates to:
  /// **'Send selected'**
  String get walletDetailUtxoSendSelected;

  /// No description provided for @walletDetailUtxoClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get walletDetailUtxoClearSelection;

  /// No description provided for @walletDetailFirst100Addresses.
  ///
  /// In en, this message translates to:
  /// **'First 100 Addresses'**
  String get walletDetailFirst100Addresses;

  /// No description provided for @walletDetailPasswordSeedReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm password to view the seed phrase'**
  String get walletDetailPasswordSeedReason;

  /// No description provided for @walletDetailBiometricSeedReason.
  ///
  /// In en, this message translates to:
  /// **'Biometric confirmation to view the seed phrase'**
  String get walletDetailBiometricSeedReason;

  /// No description provided for @walletDetailPasswordBumpReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm password to increase the fee'**
  String get walletDetailPasswordBumpReason;

  /// No description provided for @walletDetailBiometricBumpReason.
  ///
  /// In en, this message translates to:
  /// **'Biometric confirmation to increase the fee'**
  String get walletDetailBiometricBumpReason;

  /// No description provided for @walletDetailTxBumpFee.
  ///
  /// In en, this message translates to:
  /// **'Increase fee'**
  String get walletDetailTxBumpFee;

  /// No description provided for @walletDetailBumpFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase transaction fee'**
  String get walletDetailBumpFeeTitle;

  /// No description provided for @walletDetailBumpFeeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current fee: {fee} sat/vB'**
  String walletDetailBumpFeeCurrent(int fee);

  /// No description provided for @walletDetailBumpFeeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Recommended fees unavailable — enter a custom rate'**
  String get walletDetailBumpFeeUnavailable;

  /// No description provided for @walletDetailBumpFeeWarning.
  ///
  /// In en, this message translates to:
  /// **'The original transaction may never confirm if the replacement is mined.'**
  String get walletDetailBumpFeeWarning;

  /// No description provided for @walletDetailBumpFeeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fee increased — new transaction {txid}'**
  String walletDetailBumpFeeSuccess(Object txid);

  /// No description provided for @walletDetailBumpFeeErrorFee.
  ///
  /// In en, this message translates to:
  /// **'The new fee must be higher than the current one'**
  String get walletDetailBumpFeeErrorFee;

  /// No description provided for @sendScreenSigning.
  ///
  /// In en, this message translates to:
  /// **'Signing transaction...'**
  String get sendScreenSigning;

  /// No description provided for @sendScreenBroadcasting.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting to the network...'**
  String get sendScreenBroadcasting;

  /// No description provided for @sendScreenBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Biometric confirmation to authorize the transaction'**
  String get sendScreenBiometricReason;

  /// No description provided for @sendScreenPasswordReason.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to authorize the transaction'**
  String get sendScreenPasswordReason;

  /// No description provided for @sendScreenBiometricRequired.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are required to send. Enable fingerprint or face unlock in your device settings.'**
  String get sendScreenBiometricRequired;

  /// No description provided for @sendScreenFeeTime2h.
  ///
  /// In en, this message translates to:
  /// **'~2 h'**
  String get sendScreenFeeTime2h;

  /// No description provided for @sendScreenFeeTime1h.
  ///
  /// In en, this message translates to:
  /// **'~1 h'**
  String get sendScreenFeeTime1h;

  /// No description provided for @sendScreenFeeTime30m.
  ///
  /// In en, this message translates to:
  /// **'~30 min'**
  String get sendScreenFeeTime30m;

  /// No description provided for @sendScreenFeeTime15m.
  ///
  /// In en, this message translates to:
  /// **'~15 min'**
  String get sendScreenFeeTime15m;

  /// No description provided for @sendScreenFeeTime10m.
  ///
  /// In en, this message translates to:
  /// **'~10 min'**
  String get sendScreenFeeTime10m;

  /// No description provided for @sendScreenFeeTime5m.
  ///
  /// In en, this message translates to:
  /// **'~5 min'**
  String get sendScreenFeeTime5m;

  /// No description provided for @sendScreenMaxHelper.
  ///
  /// In en, this message translates to:
  /// **'Max: {amount}'**
  String sendScreenMaxHelper(Object amount);

  /// No description provided for @sendScreenUtxoSummary.
  ///
  /// In en, this message translates to:
  /// **'{sats} sat · {count} UTXO'**
  String sendScreenUtxoSummary(int sats, int count);

  /// No description provided for @importScreenHintText.
  ///
  /// In en, this message translates to:
  /// **'The seed phrase consists of 12 words separated by spaces. You can paste it directly.'**
  String get importScreenHintText;

  /// No description provided for @onboardingSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String onboardingSubmitError(Object error);

  /// No description provided for @legalMitLicense.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get legalMitLicense;

  /// No description provided for @legalSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get legalSecurityTitle;

  /// No description provided for @legalTermsContent.
  ///
  /// In en, this message translates to:
  /// **'These Terms of Service are provisional and will be replaced by the final version when the official website becomes available.\n\nBtc Blake2b Wallet is a self-custodial Bitcoin wallet for the experimental \"bitcoin-blake2b\" network (a fork of Bitcoin). Private keys and the seed phrase remain solely on your device: we do not hold, transfer or have access to your funds.\n\nThe app is provided free of charge, \"as is\", without warranties of any kind. You use it at your own risk. The bitcoin-blake2b network is an experimental network derived from Bitcoin: its coins may have no market value, may not be recognized by exchanges and may undergo reorganizations. Nothing in the app constitutes financial or investment advice.\n\nYou are solely responsible for keeping your seed phrase and your funds: anyone who has possession of them can spend the coins. The app cannot recover a lost seed. Use for illegal activities is prohibited. You declare that you are at least 16 years old.\n\nBtc Blake2b Wallet is not affiliated with, nor sponsored or endorsed by, Bitcoin, Bitcoin Core or bitcoin.org.'**
  String get legalTermsContent;

  /// No description provided for @legalPrivacyContent.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy is provisional and will be replaced by the final version published on the official website when available.\n\n1) DATA ON YOUR DEVICE. The app does not require an account and does not store personal data on servers operated by the author. The encrypted seed (AES-256-GCM), preferences and consents remain ONLY on your device.\n\n2) DATA SENT TO THIRD PARTIES FOR OPERATION. To display balance and fees the app queries public third-party APIs:\n• mempool.guide (blockchain explorer).\nEach request transmits your IP address and the public address of the queried wallet. Private keys and the seed are NEVER transmitted.\n\n3) NO TRACKERS. No analytics, no advertising, no cookies inside the app.\n\n4) RIGHTS (GDPR arts. 13-14). You have the right of access, rectification, erasure and objection by writing to the data controller: {holder} — {email}. Since we do not store personal data, these rights are already largely guaranteed by the fact that the data stays on your device.'**
  String legalPrivacyContent(String holder, String email);

  /// No description provided for @legalSecurityContact.
  ///
  /// In en, this message translates to:
  /// **'To report security vulnerabilities use the private \"Report a vulnerability\" reporting of the GitHub repository (Security tab) or write to:\n{email}\n\nDo not open public issues for security problems. Response time: 72 hours. Disclosure policy: 90 days.'**
  String legalSecurityContact(String email);

  /// No description provided for @sendScreenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction sent!'**
  String get sendScreenSuccess;

  /// No description provided for @sendScreenSuccessTxid.
  ///
  /// In en, this message translates to:
  /// **'TXID: {txid}'**
  String sendScreenSuccessTxid(Object txid);

  /// No description provided for @sendScreenError.
  ///
  /// In en, this message translates to:
  /// **'Send error: {error}'**
  String sendScreenError(Object error);

  /// No description provided for @sendScreenValidateAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter an address'**
  String get sendScreenValidateAddress;

  /// No description provided for @sendScreenValidateInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid address for {network} (use {prefix})'**
  String sendScreenValidateInvalidAddress(Object network, Object prefix);

  /// No description provided for @sendScreenValidateLength.
  ///
  /// In en, this message translates to:
  /// **'Invalid address length'**
  String get sendScreenValidateLength;

  /// No description provided for @sendScreenValidateSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot send to yourself'**
  String get sendScreenValidateSelf;

  /// No description provided for @sendScreenValidateAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get sendScreenValidateAmount;

  /// No description provided for @sendScreenValidateInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get sendScreenValidateInvalidAmount;

  /// No description provided for @sendScreenValidateDust.
  ///
  /// In en, this message translates to:
  /// **'Amount too low (minimum {dust} satoshi / {dustBtc})'**
  String sendScreenValidateDust(Object dust, Object dustBtc);

  /// No description provided for @sendScreenValidateInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds (balance: {balance}, estimated fee: {fee} sat)'**
  String sendScreenValidateInsufficient(Object balance, Object fee);

  /// No description provided for @sendScreenLoadingUtxos.
  ///
  /// In en, this message translates to:
  /// **'Loading UTXOs...'**
  String get sendScreenLoadingUtxos;

  /// No description provided for @sendScreenUtxoError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load UTXOs: {error}'**
  String sendScreenUtxoError(Object error);

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrTitle;

  /// No description provided for @scanQrError.
  ///
  /// In en, this message translates to:
  /// **'Unable to access the camera. Grant the camera permission and try again.'**
  String get scanQrError;

  /// No description provided for @scanQrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The scanned code is not a valid Bitcoin address.'**
  String get scanQrInvalid;

  /// No description provided for @scanQrTorch.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get scanQrTorch;

  /// No description provided for @sendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm transaction'**
  String get sendConfirmTitle;

  /// No description provided for @sendConfirmWarning.
  ///
  /// In en, this message translates to:
  /// **'This transaction is irreversible. Verify the details before confirming.'**
  String get sendConfirmWarning;

  /// No description provided for @sendConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get sendConfirmSend;

  /// No description provided for @importScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Wallet'**
  String get importScreenTitle;

  /// No description provided for @importScreenHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12 words'**
  String get importScreenHeading;

  /// No description provided for @importScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12-word mnemonic phrase separated by spaces, then choose the account type that matches the original wallet.'**
  String get importScreenSubtitle;

  /// No description provided for @importScriptTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get importScriptTypeLabel;

  /// No description provided for @importScriptTypeNativeSegwit.
  ///
  /// In en, this message translates to:
  /// **'Native SegWit (BIP84)'**
  String get importScriptTypeNativeSegwit;

  /// No description provided for @importScriptTypeNestedSegwit.
  ///
  /// In en, this message translates to:
  /// **'Nested SegWit (BIP49)'**
  String get importScriptTypeNestedSegwit;

  /// No description provided for @importScriptTypeLegacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy (BIP44)'**
  String get importScriptTypeLegacy;

  /// No description provided for @createWalletTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet type to create'**
  String get createWalletTypeTitle;

  /// No description provided for @importScriptTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Addresses start with {prefix}'**
  String importScriptTypeHint(String prefix);

  /// No description provided for @importScreenHint.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3 ...'**
  String get importScreenHint;

  /// No description provided for @importScreenValidateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the mnemonic phrase.'**
  String get importScreenValidateEmpty;

  /// No description provided for @importScreenValidateCount.
  ///
  /// In en, this message translates to:
  /// **'The phrase must contain exactly 12 words (detected: {count}).'**
  String importScreenValidateCount(Object count);

  /// No description provided for @importScreenValidateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid mnemonic phrase. Check the spelling of the words.'**
  String get importScreenValidateInvalid;

  /// No description provided for @importScreenImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importScreenImporting;

  /// No description provided for @importScreenImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importScreenImport;

  /// No description provided for @importScreenError.
  ///
  /// In en, this message translates to:
  /// **'Error importing wallet: {error}'**
  String importScreenError(Object error);

  /// No description provided for @importModeSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed phrase'**
  String get importModeSeed;

  /// No description provided for @importModeWatchOnly.
  ///
  /// In en, this message translates to:
  /// **'Watch-only (xpub)'**
  String get importModeWatchOnly;

  /// No description provided for @importWatchOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor an external wallet (balance and history) with only its public extended key. No private key involved — sending is never possible.'**
  String get importWatchOnlySubtitle;

  /// No description provided for @importWatchOnlyXpubLabel.
  ///
  /// In en, this message translates to:
  /// **'Account xpub'**
  String get importWatchOnlyXpubLabel;

  /// No description provided for @importWatchOnlyXpubHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the account xpub (starts with \"xpub\"). Public keys only: never paste an xprv.'**
  String get importWatchOnlyXpubHint;

  /// No description provided for @importWatchOnlyValidateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the account xpub.'**
  String get importWatchOnlyValidateEmpty;

  /// No description provided for @importWatchOnlyValidatePrefix.
  ///
  /// In en, this message translates to:
  /// **'The xpub must start with \"xpub\" (mainnet).'**
  String get importWatchOnlyValidatePrefix;

  /// No description provided for @watchOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'Watch-only'**
  String get watchOnlyBadge;

  /// No description provided for @transferScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Wallet'**
  String get transferScreenTitle;

  /// No description provided for @transferScreenScanning.
  ///
  /// In en, this message translates to:
  /// **'Scan the receiver\'\'s QR Code.'**
  String get transferScreenScanning;

  /// No description provided for @transferScreenProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing and encrypting data...'**
  String get transferScreenProcessing;

  /// No description provided for @transferScreenScanError.
  ///
  /// In en, this message translates to:
  /// **'Error during scan or encryption: {error}'**
  String transferScreenScanError(Object error);

  /// No description provided for @transferScreenNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to receive'**
  String get transferScreenNearbyTitle;

  /// No description provided for @transferScreenNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have the receiver scan this QR Code.'**
  String get transferScreenNearbySubtitle;

  /// No description provided for @transferScreenNearbyCode.
  ///
  /// In en, this message translates to:
  /// **'Manual code: {code}'**
  String transferScreenNearbyCode(Object code);

  /// No description provided for @transferScreenNearbyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transferScreenNearbyCancel;

  /// No description provided for @transferScreenNearbySuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet successfully transferred via Bluetooth. The local seed has been deleted.'**
  String get transferScreenNearbySuccess;

  /// No description provided for @transferScreenNearbyError.
  ///
  /// In en, this message translates to:
  /// **'Transfer error: {error}'**
  String transferScreenNearbyError(Object error);

  /// No description provided for @transferScreenWebRtcConnecting.
  ///
  /// In en, this message translates to:
  /// **'Starting WebRTC connection...'**
  String get transferScreenWebRtcConnecting;

  /// No description provided for @transferScreenWebRtcTransferring.
  ///
  /// In en, this message translates to:
  /// **'Transferring via WebRTC...'**
  String get transferScreenWebRtcTransferring;

  /// No description provided for @transferScreenTransferComplete.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed!'**
  String get transferScreenTransferComplete;

  /// No description provided for @transferScreenMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose transfer method'**
  String get transferScreenMethodTitle;

  /// No description provided for @transferScreenMethodQr.
  ///
  /// In en, this message translates to:
  /// **'QR Code (2-Phase)'**
  String get transferScreenMethodQr;

  /// No description provided for @transferScreenMethodQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the receiver\'\'s QR code, then generate a QR code with the encrypted seed.'**
  String get transferScreenMethodQrDesc;

  /// No description provided for @transferScreenMethodNearby.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth P2P'**
  String get transferScreenMethodNearby;

  /// No description provided for @transferScreenMethodNearbyDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct device-to-device transfer. Requires Bluetooth.'**
  String get transferScreenMethodNearbyDesc;

  /// No description provided for @transferScreenMethodWebRtc.
  ///
  /// In en, this message translates to:
  /// **'WebRTC (Internet)'**
  String get transferScreenMethodWebRtc;

  /// No description provided for @transferScreenMethodWebRtcDesc.
  ///
  /// In en, this message translates to:
  /// **'P2P via browser. Requires internet on both devices.'**
  String get transferScreenMethodWebRtcDesc;

  /// No description provided for @transferScreenWebRtcQrDescription.
  ///
  /// In en, this message translates to:
  /// **'The receiver must scan this QR. Transfer will happen via WebRTC (no size limit).'**
  String get transferScreenWebRtcQrDescription;

  /// No description provided for @transferScreenEncryptedQrDescription.
  ///
  /// In en, this message translates to:
  /// **'Show this QR Code to the receiving device. Once scanned and reception is complete, the wallet will be automatically removed from this device.'**
  String get transferScreenEncryptedQrDescription;

  /// No description provided for @transferScreenWebRtcTimeout.
  ///
  /// In en, this message translates to:
  /// **'WebRTC connection failed after 30 seconds. Try again or use the 2-phase QR Code method.'**
  String get transferScreenWebRtcTimeout;

  /// No description provided for @receiveScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive Wallet'**
  String get receiveScreenTitle;

  /// No description provided for @receiveScreenInit.
  ///
  /// In en, this message translates to:
  /// **'Initializing asymmetric key...'**
  String get receiveScreenInit;

  /// No description provided for @receiveScreenShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show this QR Code to the sender.'**
  String get receiveScreenShowQr;

  /// No description provided for @receiveScreenScanSender.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR Code on the sender\'\'s device.'**
  String get receiveScreenScanSender;

  /// No description provided for @receiveScreenAutoDetectMethod.
  ///
  /// In en, this message translates to:
  /// **'The app automatically detects the transfer method used by the sender.'**
  String get receiveScreenAutoDetectMethod;

  /// No description provided for @receiveScreenKeyError.
  ///
  /// In en, this message translates to:
  /// **'Key generation error: {error}'**
  String receiveScreenKeyError(Object error);

  /// No description provided for @receiveScreenDecrypting.
  ///
  /// In en, this message translates to:
  /// **'Data received. Decrypting and server validation in progress...'**
  String get receiveScreenDecrypting;

  /// No description provided for @receiveScreenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet received and imported successfully.'**
  String get receiveScreenSuccess;

  /// No description provided for @receiveScreenQrSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet received via QR Code.'**
  String get receiveScreenQrSuccess;

  /// No description provided for @receiveScreenNearbyConnecting.
  ///
  /// In en, this message translates to:
  /// **'Code {code} read. Connecting...'**
  String receiveScreenNearbyConnecting(Object code);

  /// No description provided for @receiveScreenNearbySuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet received via Bluetooth P2P.'**
  String get receiveScreenNearbySuccess;

  /// No description provided for @receiveScreenError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String receiveScreenError(Object error);

  /// No description provided for @receiveScreenWebRtcTitle.
  ///
  /// In en, this message translates to:
  /// **'WebRTC Room'**
  String get receiveScreenWebRtcTitle;

  /// No description provided for @receiveScreenWebRtcConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to Room'**
  String get receiveScreenWebRtcConnect;

  /// No description provided for @receiveScreenWebRtcShareQr.
  ///
  /// In en, this message translates to:
  /// **'Share this QR Code with the sender'**
  String get receiveScreenWebRtcShareQr;

  /// No description provided for @receiveScreenWebRtcScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the sender\'\'s room QR Code'**
  String get receiveScreenWebRtcScanQr;

  /// No description provided for @receiveScreenWebRtcWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender connection...'**
  String get receiveScreenWebRtcWait;

  /// No description provided for @receiveScreenRoomId.
  ///
  /// In en, this message translates to:
  /// **'Room ID: {roomId}'**
  String receiveScreenRoomId(Object roomId);

  /// No description provided for @passwordDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Security Password'**
  String get passwordDialogCreateTitle;

  /// No description provided for @passwordDialogCreateContent.
  ///
  /// In en, this message translates to:
  /// **'Set a password to protect sensitive operations on this browser. This password will be stored locally and used to encrypt your data.'**
  String get passwordDialogCreateContent;

  /// No description provided for @passwordDialogCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a secure password'**
  String get passwordDialogCreateHint;

  /// No description provided for @passwordDialogCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get passwordDialogCreateConfirm;

  /// No description provided for @passwordDialogCreateConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter the password'**
  String get passwordDialogCreateConfirmHint;

  /// No description provided for @passwordDialogCreateMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordDialogCreateMismatch;

  /// No description provided for @passwordDialogCreateTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordDialogCreateTooShort;

  /// No description provided for @passwordDialogCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get passwordDialogCreate;

  /// No description provided for @passwordDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get passwordDialogCancel;

  /// No description provided for @passwordDialogEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get passwordDialogEnterTitle;

  /// No description provided for @passwordDialogEnterContent.
  ///
  /// In en, this message translates to:
  /// **'Enter your security password to continue.'**
  String get passwordDialogEnterContent;

  /// No description provided for @passwordDialogEnterHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordDialogEnterHint;

  /// No description provided for @passwordDialogEnter.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get passwordDialogEnter;

  /// No description provided for @passwordDialogWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get passwordDialogWrong;

  /// No description provided for @languageSelector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSelector;

  /// No description provided for @languageSelectorEn.
  ///
  /// In en, this message translates to:
  /// **'🇬🇧 English'**
  String get languageSelectorEn;

  /// No description provided for @languageSelectorIt.
  ///
  /// In en, this message translates to:
  /// **'🇮🇹 Italiano'**
  String get languageSelectorIt;

  /// No description provided for @languageSelectorDe.
  ///
  /// In en, this message translates to:
  /// **'🇩🇪 Deutsch'**
  String get languageSelectorDe;

  /// No description provided for @languageSelectorFi.
  ///
  /// In en, this message translates to:
  /// **'🇫🇮 Suomi'**
  String get languageSelectorFi;

  /// No description provided for @languageSelectorEs.
  ///
  /// In en, this message translates to:
  /// **'🇪🇸 Español'**
  String get languageSelectorEs;

  /// No description provided for @languageSelectorZhCN.
  ///
  /// In en, this message translates to:
  /// **'🇨🇳 中文'**
  String get languageSelectorZhCN;

  /// No description provided for @languageSelectorFrCA.
  ///
  /// In en, this message translates to:
  /// **'🇨🇦 Français (CA)'**
  String get languageSelectorFrCA;

  /// No description provided for @walletDetailRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get walletDetailRefresh;

  /// No description provided for @walletDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet?'**
  String get walletDetailDeleteTitle;

  /// No description provided for @walletDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get walletDetailDeleteConfirm;

  /// No description provided for @walletDetailDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Make sure you have a backup of the seed phrase if there are funds in the wallet.'**
  String get walletDetailDeleteWarning;

  /// No description provided for @walletDetailInfo.
  ///
  /// In en, this message translates to:
  /// **'Wallet Info'**
  String get walletDetailInfo;

  /// No description provided for @walletDetailNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletDetailNameLabel;

  /// No description provided for @walletDetailNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home Savings'**
  String get walletDetailNameHint;

  /// No description provided for @walletDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get walletDetailType;

  /// No description provided for @walletDetailTypeValue.
  ///
  /// In en, this message translates to:
  /// **'HD SegWit (BIP84 Bech32 Native)'**
  String get walletDetailTypeValue;

  /// No description provided for @walletTypeNativeSegwit.
  ///
  /// In en, this message translates to:
  /// **'HD SegWit (BIP84 Bech32 Native)'**
  String get walletTypeNativeSegwit;

  /// No description provided for @walletTypeNestedSegwit.
  ///
  /// In en, this message translates to:
  /// **'Nested SegWit (BIP49 P2SH)'**
  String get walletTypeNestedSegwit;

  /// No description provided for @walletTypeLegacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy P2PKH (BIP44)'**
  String get walletTypeLegacy;

  /// No description provided for @walletDetailUpdating.
  ///
  /// In en, this message translates to:
  /// **'UPDATING...'**
  String get walletDetailUpdating;

  /// No description provided for @walletDetailNTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count} TRANSACTIONS'**
  String walletDetailNTransactions(Object count);

  /// No description provided for @walletDetailReceiveQr.
  ///
  /// In en, this message translates to:
  /// **'Receive Bitcoin'**
  String get walletDetailReceiveQr;

  /// No description provided for @walletDetailSignVerify.
  ///
  /// In en, this message translates to:
  /// **'Sign/Verify Message'**
  String get walletDetailSignVerify;

  /// No description provided for @walletDetailShowAddresses.
  ///
  /// In en, this message translates to:
  /// **'Show addresses'**
  String get walletDetailShowAddresses;

  /// No description provided for @walletDetailWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletDetailWalletAddress;

  /// No description provided for @walletDetailExportSeed.
  ///
  /// In en, this message translates to:
  /// **'Export/Backup Seed'**
  String get walletDetailExportSeed;

  /// No description provided for @walletDetailShowSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'View seed?'**
  String get walletDetailShowSeedTitle;

  /// No description provided for @walletDetailShowSeedContent.
  ///
  /// In en, this message translates to:
  /// **'The seed phrase allows access to all funds. Make sure you are in a safe place.'**
  String get walletDetailShowSeedContent;

  /// No description provided for @walletDetailShowSeedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, show'**
  String get walletDetailShowSeedConfirm;

  /// No description provided for @walletDetailSeedVerifyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to verify that you saved the seed?'**
  String get walletDetailSeedVerifyPrompt;

  /// No description provided for @walletDetailSeedVerifyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, verify'**
  String get walletDetailSeedVerifyYes;

  /// No description provided for @walletDetailSeedVerifyNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get walletDetailSeedVerifyNotNow;

  /// No description provided for @walletDetailSeedVerified.
  ///
  /// In en, this message translates to:
  /// **'Backup verified'**
  String get walletDetailSeedVerified;

  /// No description provided for @walletDetailSeedHidden.
  ///
  /// In en, this message translates to:
  /// **'Seed hidden for security'**
  String get walletDetailSeedHidden;

  /// No description provided for @walletDetailSeedShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Show seed'**
  String get walletDetailSeedShowAgain;

  /// No description provided for @walletDetailHideSeed.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get walletDetailHideSeed;

  /// No description provided for @walletDetailBackupNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Backup not confirmed'**
  String get walletDetailBackupNotConfirmed;

  /// No description provided for @walletDetailBackupNotConfirmedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have not yet saved the seed phrase. If you lose the device or reinstall the app, you will permanently lose access to your funds.'**
  String get walletDetailBackupNotConfirmedDesc;

  /// No description provided for @walletDetailShowXpub.
  ///
  /// In en, this message translates to:
  /// **'Show Wallet XPUB'**
  String get walletDetailShowXpub;

  /// No description provided for @walletDetailDisplayHome.
  ///
  /// In en, this message translates to:
  /// **'Show value in Home'**
  String get walletDetailDisplayHome;

  /// No description provided for @walletDetailUtxoRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get walletDetailUtxoRename;

  /// No description provided for @walletDetailUtxoRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename UTXO'**
  String get walletDetailUtxoRenameTitle;

  /// No description provided for @walletDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get walletDetailSave;

  /// No description provided for @walletDetailId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get walletDetailId;

  /// No description provided for @walletDetailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get walletDetailCreated;

  /// No description provided for @walletDetailTransferredOn.
  ///
  /// In en, this message translates to:
  /// **'Transferred on'**
  String get walletDetailTransferredOn;

  /// No description provided for @walletDetailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get walletDetailClose;

  /// No description provided for @walletDetailSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get walletDetailSign;

  /// No description provided for @walletDetailVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get walletDetailVerify;

  /// No description provided for @walletDetailSignMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign Message'**
  String get walletDetailSignMessage;

  /// No description provided for @walletDetailVerifyMessage.
  ///
  /// In en, this message translates to:
  /// **'Verify Message'**
  String get walletDetailVerifyMessage;

  /// No description provided for @walletDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get walletDetailMessage;

  /// No description provided for @walletDetailBitcoinAddress.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Address'**
  String get walletDetailBitcoinAddress;

  /// No description provided for @walletDetailSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature (Base64)'**
  String get walletDetailSignature;

  /// No description provided for @walletDetailResult.
  ///
  /// In en, this message translates to:
  /// **'Result:'**
  String get walletDetailResult;

  /// No description provided for @walletDetailSignatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature:'**
  String get walletDetailSignatureLabel;

  /// No description provided for @walletDetailCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get walletDetailCopy;

  /// No description provided for @walletDetailAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get walletDetailAddressCopied;

  /// No description provided for @walletDetailXpubTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet XPUB'**
  String get walletDetailXpubTitle;

  /// No description provided for @walletDetailXpubDesc.
  ///
  /// In en, this message translates to:
  /// **'This XPUB allows viewing all future addresses and balances but cannot spend funds.'**
  String get walletDetailXpubDesc;

  /// No description provided for @walletDetailXpubCopied.
  ///
  /// In en, this message translates to:
  /// **'XPUB copied'**
  String get walletDetailXpubCopied;

  /// No description provided for @walletDetailErrorXpub.
  ///
  /// In en, this message translates to:
  /// **'Error deriving XPUB: {error}'**
  String walletDetailErrorXpub(Object error);

  /// No description provided for @walletDetailErrorAddresses.
  ///
  /// In en, this message translates to:
  /// **'Error deriving addresses: {error}'**
  String walletDetailErrorAddresses(Object error);

  /// No description provided for @walletDetailFirst100.
  ///
  /// In en, this message translates to:
  /// **'First 100 Addresses'**
  String get walletDetailFirst100;

  /// No description provided for @walletDetailValidSig.
  ///
  /// In en, this message translates to:
  /// **'VALID SIGNATURE ✓'**
  String get walletDetailValidSig;

  /// No description provided for @walletDetailInvalidSig.
  ///
  /// In en, this message translates to:
  /// **'INVALID SIGNATURE ✗'**
  String get walletDetailInvalidSig;

  /// No description provided for @donateTitle.
  ///
  /// In en, this message translates to:
  /// **'Support the project ❤️'**
  String get donateTitle;

  /// No description provided for @donatePhrase.
  ///
  /// In en, this message translates to:
  /// **'☕ \"If the project is useful to you, buy us a virtual coffee\"'**
  String get donatePhrase;

  /// No description provided for @donateAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin donation address:'**
  String get donateAddressLabel;

  /// No description provided for @donateCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get donateCopy;

  /// No description provided for @donateCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied! ✓'**
  String get donateCopied;

  /// No description provided for @donateNote.
  ///
  /// In en, this message translates to:
  /// **'Voluntary donation — no service or benefit is provided in return. Any amount is welcome, even a few satoshis. Thank you! 🧡'**
  String get donateNote;

  /// No description provided for @donateNoWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallet found'**
  String get donateNoWalletTitle;

  /// No description provided for @donateNoWalletMessage.
  ///
  /// In en, this message translates to:
  /// **'No Bitcoin wallet app was found on your device. You can still copy the address and paste it into your favorite wallet.'**
  String get donateNoWalletMessage;

  /// No description provided for @donateOpenWallet.
  ///
  /// In en, this message translates to:
  /// **'Open in wallet'**
  String get donateOpenWallet;

  /// No description provided for @donateButton.
  ///
  /// In en, this message translates to:
  /// **'Support the project ❤️'**
  String get donateButton;

  /// No description provided for @multiTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-Wallet Send'**
  String get multiTransferTitle;

  /// No description provided for @multiTransferSelectWallets.
  ///
  /// In en, this message translates to:
  /// **'Select wallets to send'**
  String get multiTransferSelectWallets;

  /// No description provided for @multiTransferSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 wallet selected} other{{count} wallets selected}}'**
  String multiTransferSelectedCount(num count);

  /// No description provided for @multiTransferTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value: {amount} {ticker}'**
  String multiTransferTotalValue(Object amount, Object ticker);

  /// No description provided for @multiTransferMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer method:'**
  String get multiTransferMethodLabel;

  /// No description provided for @multiTransferMethodWebRtc.
  ///
  /// In en, this message translates to:
  /// **'WebRTC (max {max})'**
  String multiTransferMethodWebRtc(Object max);

  /// No description provided for @multiTransferMethodBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (max {max})'**
  String multiTransferMethodBluetooth(Object max);

  /// No description provided for @multiTransferMethodQr.
  ///
  /// In en, this message translates to:
  /// **'QR Code 2-phase (max {max})'**
  String multiTransferMethodQr(Object max);

  /// No description provided for @multiTransferSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send {count,plural, =1{1 Wallet} other{{count} Wallets}} · {amount} BTC'**
  String multiTransferSendButton(Object amount, num count);

  /// No description provided for @multiTransferProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get multiTransferProgressTitle;

  /// No description provided for @multiTransferProgressWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet {current} of {total}'**
  String multiTransferProgressWallet(Object current, Object total);

  /// No description provided for @multiTransferSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 wallet sent successfully} other{{count} wallets sent successfully}}'**
  String multiTransferSuccess(num count);

  /// No description provided for @multiTransferPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'{success} sent, {failed} failed'**
  String multiTransferPartialSuccess(Object failed, Object success);

  /// No description provided for @multiTransferNoLockedWallets.
  ///
  /// In en, this message translates to:
  /// **'No wallets available for transfer. Only LOCKED wallets can be transferred.'**
  String get multiTransferNoLockedWallets;

  /// No description provided for @multiTransferLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'You selected {selected} wallets. The maximum for {method} is {max}.'**
  String multiTransferLimitExceeded(Object max, Object method, Object selected);

  /// No description provided for @multiTransferReceivingTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-Wallet Receive'**
  String get multiTransferReceivingTitle;

  /// No description provided for @multiTransferReceivingProgress.
  ///
  /// In en, this message translates to:
  /// **'Received {received} of {total} wallets'**
  String multiTransferReceivingProgress(Object received, Object total);

  /// No description provided for @multiTransferMethodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform'**
  String get multiTransferMethodUnavailable;

  /// No description provided for @multiTransferSendingWallet.
  ///
  /// In en, this message translates to:
  /// **'Sending wallet {current} of {total}...'**
  String multiTransferSendingWallet(Object current, Object total);

  /// No description provided for @multiTransferPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing wallet...'**
  String get multiTransferPreparing;

  /// No description provided for @multiTransferWaitingReceiver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for receiver...'**
  String get multiTransferWaitingReceiver;

  /// No description provided for @multiTransferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get multiTransferCompleted;

  /// No description provided for @multiTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get multiTransferFailed;

  /// No description provided for @multiTransferMethodQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Manual 2-phase transfer via QR code. Max {max} wallets.'**
  String multiTransferMethodQrDesc(Object max);

  /// No description provided for @multiTransferMethodWebRtcDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast P2P transfer via internet. Max {max} wallets.'**
  String multiTransferMethodWebRtcDesc(Object max);

  /// No description provided for @multiTransferMethodBluetoothDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct device-to-device transfer. Max {max} wallets.'**
  String multiTransferMethodBluetoothDesc(Object max);

  /// No description provided for @multiTransferNoBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance not available'**
  String get multiTransferNoBalance;

  /// No description provided for @multiTransferConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm send'**
  String get multiTransferConfirmTitle;

  /// No description provided for @multiTransferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to send {count,plural, =1{1 wallet} other{{count} wallets}} totaling {amount} {ticker}. Continue?'**
  String multiTransferConfirmMessage(Object amount, num count, Object ticker);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Btc Blake2b Wallet'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open-source Bitcoin wallet. Self-custody. No KYC.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingResidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Country of tax residence'**
  String get onboardingResidenceLabel;

  /// No description provided for @onboardingResidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get onboardingResidenceHint;

  /// No description provided for @onboardingReverseSolicitation.
  ///
  /// In en, this message translates to:
  /// **'I declare that I am using Btc Blake2b Wallet on my own exclusive initiative (\"reverse solicitation\") and that I reside fiscally in the selected country.'**
  String get onboardingReverseSolicitation;

  /// No description provided for @onboardingTermsAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get onboardingTermsAccept;

  /// No description provided for @onboardingPrivacyAccept.
  ///
  /// In en, this message translates to:
  /// **'I have read the '**
  String get onboardingPrivacyAccept;

  /// No description provided for @onboardingAgeConfirm.
  ///
  /// In en, this message translates to:
  /// **'I declare that I am at least 16 years old'**
  String get onboardingAgeConfirm;

  /// No description provided for @onboardingAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required by GDPR Art. 8 for data processing consent'**
  String get onboardingAgeSubtitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingStepNext;

  /// No description provided for @onboardingStepBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingStepBack;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(Object current, Object total);

  /// No description provided for @onboardingTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy'**
  String get onboardingTermsTitle;

  /// No description provided for @onboardingValidationResidence.
  ///
  /// In en, this message translates to:
  /// **'Select your country of tax residence'**
  String get onboardingValidationResidence;

  /// No description provided for @onboardingValidationCheckbox.
  ///
  /// In en, this message translates to:
  /// **'You must accept all declarations to continue'**
  String get onboardingValidationCheckbox;

  /// No description provided for @onboardingLinkTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboardingLinkTerms;

  /// No description provided for @onboardingLinkPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingLinkPrivacy;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Btc Blake2b Wallet'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Btc Blake2b Wallet is an open-source, self-custody Bitcoin wallet. No registration, no KYC, no tracking. Your keys, your coins.'**
  String get aboutDescription;

  /// No description provided for @aboutLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicenseTitle;

  /// No description provided for @aboutThirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Licenses'**
  String get aboutThirdPartyLicenses;

  /// No description provided for @aboutThirdPartyLicensesDesc.
  ///
  /// In en, this message translates to:
  /// **'View the complete list of open-source licenses'**
  String get aboutThirdPartyLicensesDesc;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get aboutBuiltWith;

  /// No description provided for @aboutDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This software is provided \"AS IS\" without warranty of any kind.'**
  String get aboutDisclaimer;

  /// No description provided for @explorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorerTitle;

  /// No description provided for @explorerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get explorerAddressLabel;

  /// No description provided for @explorerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get explorerRefresh;

  /// No description provided for @explorerBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get explorerBalanceLabel;

  /// No description provided for @explorerTxCount.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get explorerTxCount;

  /// No description provided for @explorerTipHeight.
  ///
  /// In en, this message translates to:
  /// **'Node height'**
  String get explorerTipHeight;

  /// No description provided for @explorerErrorInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid address. Check the format for this network.'**
  String get explorerErrorInvalidAddress;

  /// No description provided for @explorerErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded. Try again in a minute.'**
  String get explorerErrorRateLimited;

  /// No description provided for @explorerErrorNodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Try again later.'**
  String get explorerErrorNodeUnavailable;

  /// No description provided for @explorerErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address or transaction not found.'**
  String get explorerErrorNotFound;

  /// No description provided for @explorerErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Check your connection and retry.'**
  String get explorerErrorTimeout;

  /// No description provided for @explorerErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Check your connection.'**
  String get explorerErrorNetwork;

  /// No description provided for @explorerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get explorerRetry;

  /// No description provided for @explorerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String explorerErrorGeneric(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fi',
        'fr',
        'it',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
