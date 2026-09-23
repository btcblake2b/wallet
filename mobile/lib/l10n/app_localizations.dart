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
    Locale('en'),
    Locale('it'),
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

  /// No description provided for @homeLockVault.
  ///
  /// In en, this message translates to:
  /// **'Lock vault'**
  String get homeLockVault;

  /// No description provided for @homeVaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get homeVaultLocked;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get settingsSectionTools;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsSectionInfo;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get settingsTheme;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or phone PIN on every open'**
  String get settingsAppLockDesc;

  /// No description provided for @settingsAppLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled on this device'**
  String get settingsAppLockUnavailable;

  /// No description provided for @settingsAppLockEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: app lock not enabled'**
  String get settingsAppLockEnableFailed;

  /// No description provided for @settingsAppLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'App lock enabled'**
  String get settingsAppLockEnabled;

  /// No description provided for @settingsAppLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get settingsAppLockDisabled;

  /// No description provided for @settingsExplorerMirrors.
  ///
  /// In en, this message translates to:
  /// **'Backup explorers'**
  String get settingsExplorerMirrors;

  /// No description provided for @settingsExplorerMirrorsDesc.
  ///
  /// In en, this message translates to:
  /// **'If mempool.guide does not respond, the app queries two community mirrors. Turn off to use mempool.guide only.'**
  String get settingsExplorerMirrorsDesc;

  /// No description provided for @settingsSectionInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get settingsSectionInterface;

  /// No description provided for @settingsInfoDots.
  ///
  /// In en, this message translates to:
  /// **'Info hints'**
  String get settingsInfoDots;

  /// No description provided for @settingsInfoDotsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show the small info buttons that explain each feature'**
  String get settingsInfoDotsDesc;

  /// No description provided for @infoCoinControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Coin control (UTXO selection)'**
  String get infoCoinControlTitle;

  /// No description provided for @infoCoinControlBody.
  ///
  /// In en, this message translates to:
  /// **'Your balance is made of UTXOs, the pieces you received. Here you can pick which ones to spend: the transaction will use only those, letting you keep small or inactive pieces aside.'**
  String get infoCoinControlBody;

  /// No description provided for @infoDustLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount (dust)'**
  String get infoDustLimitTitle;

  /// No description provided for @infoDustLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Outputs below 546 sat are rejected by the network as \'dust\'. Amounts under that limit cannot be sent.'**
  String get infoDustLimitBody;

  /// No description provided for @infoFeeRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction fee'**
  String get infoFeeRateTitle;

  /// No description provided for @infoFeeRateBody.
  ///
  /// In en, this message translates to:
  /// **'The fee is paid per unit of transaction size (sat/vB): the faster you want the confirmation, the more you pay. \'Economical\' can take hours, \'Priority\' a few minutes. \'Custom\' is for when you know the current mempool rate.'**
  String get infoFeeRateBody;

  /// No description provided for @infoBatchSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple recipients (batch)'**
  String get infoBatchSendTitle;

  /// No description provided for @infoBatchSendBody.
  ///
  /// In en, this message translates to:
  /// **'In a single transaction you can pay up to 5 addresses, sharing the fee instead of paying it once per transfer. All recipients are shown in the confirmation before signing.'**
  String get infoBatchSendBody;

  /// No description provided for @infoBumpFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase fee (RBF)'**
  String get infoBumpFeeTitle;

  /// No description provided for @infoBumpFeeBody.
  ///
  /// In en, this message translates to:
  /// **'A pending transaction can be replaced by a new one paying a higher fee (BIP125). The original is cancelled and only the replacement can confirm — the destination address and amount stay the same.'**
  String get infoBumpFeeBody;

  /// No description provided for @infoXpubTitle.
  ///
  /// In en, this message translates to:
  /// **'Account public key (xpub)'**
  String get infoXpubTitle;

  /// No description provided for @infoXpubBody.
  ///
  /// In en, this message translates to:
  /// **'The xpub generates all your receiving addresses. It cannot move funds, but it reveals the whole balance and history: share it only with apps you trust (e.g. a watch-only wallet).'**
  String get infoXpubBody;

  /// No description provided for @infoReceiveAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Receiving address'**
  String get infoReceiveAddressTitle;

  /// No description provided for @infoReceiveAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Each \'Receive\' shows a fresh address, chosen from those never used: this keeps payments unlinkable. Reusing an address is not an error, it just makes your transactions easier to trace.'**
  String get infoReceiveAddressBody;

  /// No description provided for @infoWatchOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch-only wallet'**
  String get infoWatchOnlyTitle;

  /// No description provided for @infoWatchOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'You imported only the xpub: the app sees balance and history but holds no private key, so it cannot sign. To spend from this wallet you need the device that holds the seed.'**
  String get infoWatchOnlyBody;

  /// No description provided for @infoSignVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign / verify message'**
  String get infoSignVerifyTitle;

  /// No description provided for @infoSignVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Signing proves that an address is yours without moving funds. Anyone can then verify the signature against that address and the same message.'**
  String get infoSignVerifyBody;

  /// No description provided for @infoChannelCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel capacity'**
  String get infoChannelCapacityTitle;

  /// No description provided for @infoChannelCapacityBody.
  ///
  /// In en, this message translates to:
  /// **'The total amount of satoshis in the channel, split between you and your peer. The more capacity, the larger payments it can handle. Capacity = local balance + remote balance.'**
  String get infoChannelCapacityBody;

  /// No description provided for @infoChannelReserveTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel reserve'**
  String get infoChannelReserveTitle;

  /// No description provided for @infoChannelReserveBody.
  ///
  /// In en, this message translates to:
  /// **'A small portion of your funds must stay locked as a security deposit (the \'reserve\'). It ensures both parties have skin in the game — if the other side goes offline maliciously, the reserve can be used to penalize them on-chain.'**
  String get infoChannelReserveBody;

  /// No description provided for @infoToSelfDelayTitle.
  ///
  /// In en, this message translates to:
  /// **'To-self delay'**
  String get infoToSelfDelayTitle;

  /// No description provided for @infoToSelfDelayBody.
  ///
  /// In en, this message translates to:
  /// **'When a force close happens, your on-chain output is delayed by this many blocks (typically 144 = ~1 day). This gives your peer time to claim their funds first, preventing double-spend attacks on the channel state.'**
  String get infoToSelfDelayBody;

  /// No description provided for @infoHtlcTitle.
  ///
  /// In en, this message translates to:
  /// **'HTLC (Hashed Time-Locked Contract)'**
  String get infoHtlcTitle;

  /// No description provided for @infoHtlcBody.
  ///
  /// In en, this message translates to:
  /// **'An HTLC is a conditional payment: funds are locked until the recipient reveals a secret hash preimage. In Lightning, HTLCs enable instant off-chain routing — your payment hops through multiple channels without trusting any intermediary.'**
  String get infoHtlcBody;

  /// No description provided for @infoOpenChannelPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private channel'**
  String get infoOpenChannelPrivateTitle;

  /// No description provided for @infoOpenChannelPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'A private channel is not announced to the network. Only you and your peer know it exists. Use it when you don\'\'t want others to route through it (privacy) or when the channel is too small to be useful for routing.'**
  String get infoOpenChannelPrivateBody;

  /// No description provided for @infoRoutingFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routing fees'**
  String get infoRoutingFeesTitle;

  /// No description provided for @infoRoutingFeesBody.
  ///
  /// In en, this message translates to:
  /// **'When other nodes route payments through your channel, you earn fees. Base fee (sat) is charged per payment; rate (ppm) is proportional to the amount. CLTV delta limits how long a forwarded HTLC can take to settle.'**
  String get infoRoutingFeesBody;

  /// No description provided for @infoForceCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Force close'**
  String get infoForceCloseTitle;

  /// No description provided for @infoForceCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Broadcasts your latest channel state on-chain. This is irreversible and requires waiting for the to-self delay before you can spend your funds. Use only if your peer is unresponsive or malicious — cooperative close is always faster and cheaper.'**
  String get infoForceCloseBody;

  /// No description provided for @infoPeersTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected peers'**
  String get infoPeersTitle;

  /// No description provided for @infoPeersBody.
  ///
  /// In en, this message translates to:
  /// **'Peers are other Lightning nodes you\'\'re directly connected to via TCP/Tor. Each peer can hold one or more channels. You can connect to new peers to open channels and increase your node\'\'s liquidity and routing capability.'**
  String get infoPeersBody;

  /// No description provided for @infoNodeManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Node management'**
  String get infoNodeManagementTitle;

  /// No description provided for @infoNodeManagementBody.
  ///
  /// In en, this message translates to:
  /// **'Your Lightning node identity: pubkey, version, number of active/pending channels and peers. This screen shows accounting data from the node\'\'s bookkeeper plugin and forwarding statistics.'**
  String get infoNodeManagementBody;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App locked'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics or phone PIN'**
  String get appLockSubtitle;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @appLockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock the wallet'**
  String get appLockReason;

  /// No description provided for @appLockNoticeDeviceAuthRemoved.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled: the phone screen protection (biometrics/PIN) is no longer available. Re-enable it in the system settings to use app lock again.'**
  String get appLockNoticeDeviceAuthRemoved;

  /// No description provided for @appLockNoticeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get appLockNoticeContinue;

  /// No description provided for @appLockPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable app lock?'**
  String get appLockPromptTitle;

  /// No description provided for @appLockPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Opening the wallet will require biometrics or your phone PIN.'**
  String get appLockPromptMessage;

  /// No description provided for @appLockPromptEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get appLockPromptEnable;

  /// No description provided for @appLockPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appLockPromptLater;

  /// No description provided for @aboutLicensesOpenOnline.
  ///
  /// In en, this message translates to:
  /// **'Open online'**
  String get aboutLicensesOpenOnline;

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

  /// No description provided for @walletDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get walletDetailAddress;

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

  /// No description provided for @walletDetailTxExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get walletDetailTxExport;

  /// No description provided for @walletDetailTxExportCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV (spreadsheet)'**
  String get walletDetailTxExportCsv;

  /// No description provided for @walletDetailTxExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard ({fileName})'**
  String walletDetailTxExportCopied(String fileName);

  /// No description provided for @walletDetailTxExportDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Download started ({fileName})'**
  String walletDetailTxExportDownloaded(String fileName);

  /// No description provided for @walletDetailTxExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get walletDetailTxExportFailed;

  /// No description provided for @walletDetailTxExportJson.
  ///
  /// In en, this message translates to:
  /// **'JSON (complete)'**
  String get walletDetailTxExportJson;

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

  /// No description provided for @walletDetailTxNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get walletDetailTxNote;

  /// No description provided for @walletDetailTxNoteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get walletDetailTxNoteAdd;

  /// No description provided for @walletDetailTxNoteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get walletDetailTxNoteEdit;

  /// No description provided for @walletDetailTxNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Private note, saved on this device only'**
  String get walletDetailTxNoteHint;

  /// No description provided for @walletDetailTxNoteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get walletDetailTxNoteRemove;

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

  /// No description provided for @sendScreenAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BTC)'**
  String get sendScreenAmountLabel;

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

  /// No description provided for @sendBatchToggle.
  ///
  /// In en, this message translates to:
  /// **'Multiple recipients'**
  String get sendBatchToggle;

  /// No description provided for @sendBatchToggleSingle.
  ///
  /// In en, this message translates to:
  /// **'Single recipient'**
  String get sendBatchToggleSingle;

  /// No description provided for @sendBatchRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient {index}'**
  String sendBatchRecipientLabel(int index);

  /// No description provided for @sendBatchAddRecipient.
  ///
  /// In en, this message translates to:
  /// **'Add recipient'**
  String get sendBatchAddRecipient;

  /// No description provided for @sendBatchRemoveRecipient.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sendBatchRemoveRecipient;

  /// No description provided for @sendBatchMaxRecipients.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 recipients'**
  String get sendBatchMaxRecipients;

  /// No description provided for @sendBatchTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total to recipients'**
  String get sendBatchTotalLabel;

  /// No description provided for @sendBatchDustError.
  ///
  /// In en, this message translates to:
  /// **'Minimum 546 sat per recipient'**
  String get sendBatchDustError;

  /// No description provided for @sendBatchDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'Duplicate address'**
  String get sendBatchDuplicateError;

  /// No description provided for @sendBatchMinRecipients.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 recipients to send a batch'**
  String get sendBatchMinRecipients;

  /// No description provided for @sendBatchConfirmRecipients.
  ///
  /// In en, this message translates to:
  /// **'{count} recipients'**
  String sendBatchConfirmRecipients(int count);

  /// No description provided for @sendBatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm multiple payment'**
  String get sendBatchConfirmTitle;

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
  /// **'The seed phrase consists of 12, 15, 18, 21 or 24 words separated by spaces. You can paste it directly.'**
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
  /// **'This Privacy Policy is provisional and will be replaced by the final version published on the official website when available.\n\n1) DATA ON YOUR DEVICE. The app does not require an account and does not store personal data on servers operated by the author. The encrypted seed (AES-256-GCM), preferences and consents remain ONLY on your device.\n\n2) DATA SENT TO THIRD PARTIES FOR OPERATION. To display balance and fees the app queries public third-party APIs:\n• mempool.guide (blockchain explorer).\n• If mempool.guide is unavailable, the app may query two community Esplora-compatible mirrors (mempool.kilombino.com, mempool.maveth.ca). This can be turned off in Settings.\nEach request transmits your IP address and the public address of the queried wallet. Private keys and the seed are NEVER transmitted.\n\n3) NO TRACKERS. No analytics, no advertising, no cookies inside the app.\n\n4) RIGHTS (GDPR arts. 13-14). You have the right of access, rectification, erasure and objection by writing to the data controller: {holder} — {email}. Since we do not store personal data, these rights are already largely guaranteed by the fact that the data stays on your device.'**
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

  /// No description provided for @scanQrInvalidInvoice.
  ///
  /// In en, this message translates to:
  /// **'The scanned code is not a valid Lightning invoice.'**
  String get scanQrInvalidInvoice;

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
  /// **'Enter your seed phrase'**
  String get importScreenHeading;

  /// No description provided for @importScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the mnemonic phrase (12, 15, 18, 21 or 24 words) separated by spaces, then choose the account type that matches the original wallet.'**
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
  /// **'The phrase must contain 12, 15, 18, 21 or 24 words (detected: {count}).'**
  String importScreenValidateCount(Object count);

  /// No description provided for @importScreenValidateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid mnemonic phrase. Check the spelling of the words.'**
  String get importScreenValidateInvalid;

  /// No description provided for @importScreenImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importScreenImport;

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

  /// No description provided for @passwordDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Security Password'**
  String get passwordDialogCreateTitle;

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

  /// No description provided for @languageSelectorAuto.
  ///
  /// In en, this message translates to:
  /// **'🌐 Automatic (system)'**
  String get languageSelectorAuto;

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

  /// No description provided for @walletLayerOnchain.
  ///
  /// In en, this message translates to:
  /// **'On-chain'**
  String get walletLayerOnchain;

  /// No description provided for @walletLayerLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get walletLayerLightning;

  /// No description provided for @lightningDisconnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'No Lightning node connected'**
  String get lightningDisconnectedTitle;

  /// No description provided for @lightningDisconnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your blake2b Lightning node to send and receive payments. The app never holds your funds or keys.'**
  String get lightningDisconnectedBody;

  /// No description provided for @lightningConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect node'**
  String get lightningConnectButton;

  /// No description provided for @lightningConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Lightning node'**
  String get lightningConnectTitle;

  /// No description provided for @lightningConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the connection string (nostr+walletconnect://…)'**
  String get lightningConnectHint;

  /// No description provided for @lightningConnectInvalidUri.
  ///
  /// In en, this message translates to:
  /// **'Invalid connection string'**
  String get lightningConnectInvalidUri;

  /// No description provided for @lightningConnectRecentNodes.
  ///
  /// In en, this message translates to:
  /// **'Recent nodes'**
  String get lightningConnectRecentNodes;

  /// No description provided for @lightningConnectInfo.
  ///
  /// In en, this message translates to:
  /// **'The node must authorize this app (grant): check your node\'\'s control panel.'**
  String get lightningConnectInfo;

  /// No description provided for @lightningConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get lightningConnecting;

  /// No description provided for @lightningConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get lightningConnected;

  /// No description provided for @lightningDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get lightningDisconnect;

  /// No description provided for @lightningBalance.
  ///
  /// In en, this message translates to:
  /// **'Lightning balance'**
  String get lightningBalance;

  /// No description provided for @lightningChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get lightningChannels;

  /// No description provided for @lightningNoChannels.
  ///
  /// In en, this message translates to:
  /// **'No open channels'**
  String get lightningNoChannels;

  /// No description provided for @lightningChannelPeer.
  ///
  /// In en, this message translates to:
  /// **'Peer'**
  String get lightningChannelPeer;

  /// No description provided for @lightningChannelCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get lightningChannelCapacity;

  /// No description provided for @lightningChannelLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get lightningChannelLocal;

  /// No description provided for @lightningChannelRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get lightningChannelRemote;

  /// No description provided for @lightningOpenChannel.
  ///
  /// In en, this message translates to:
  /// **'Open channel'**
  String get lightningOpenChannel;

  /// No description provided for @lightningOpenChannelNodeId.
  ///
  /// In en, this message translates to:
  /// **'Node ID (pubkey)'**
  String get lightningOpenChannelNodeId;

  /// No description provided for @lightningOpenChannelHost.
  ///
  /// In en, this message translates to:
  /// **'Host (optional, ip:port)'**
  String get lightningOpenChannelHost;

  /// No description provided for @lightningOpenChannelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (sat)'**
  String get lightningOpenChannelAmount;

  /// No description provided for @lightningOpenChannelPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private channel'**
  String get lightningOpenChannelPrivate;

  /// No description provided for @lightningChannelOpened.
  ///
  /// In en, this message translates to:
  /// **'Channel opening requested'**
  String get lightningChannelOpened;

  /// No description provided for @lightningCloseChannel.
  ///
  /// In en, this message translates to:
  /// **'Close channel'**
  String get lightningCloseChannel;

  /// No description provided for @lightningCloseChannelForce.
  ///
  /// In en, this message translates to:
  /// **'Force close'**
  String get lightningCloseChannelForce;

  /// No description provided for @lightningCloseChannelForceWarning.
  ///
  /// In en, this message translates to:
  /// **'Force close broadcasts the latest channel state on-chain. Fees and delays may apply. Continue?'**
  String get lightningCloseChannelForceWarning;

  /// No description provided for @lightningReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get lightningReceive;

  /// No description provided for @lightningSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get lightningSend;

  /// No description provided for @lightningInvoiceAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (sat)'**
  String get lightningInvoiceAmount;

  /// No description provided for @lightningInvoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get lightningInvoiceDescription;

  /// No description provided for @lightningInvoiceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get lightningInvoiceCreate;

  /// No description provided for @lightningInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning invoice'**
  String get lightningInvoiceTitle;

  /// No description provided for @lightningPay.
  ///
  /// In en, this message translates to:
  /// **'Pay invoice'**
  String get lightningPay;

  /// No description provided for @lightningPayHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the invoice (lnbc…)'**
  String get lightningPayHint;

  /// No description provided for @lightningPayDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Lightning payment'**
  String get lightningPayDialogTitle;

  /// No description provided for @lightningPayDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Pay this invoice?'**
  String get lightningPayDialogBody;

  /// No description provided for @lightningPaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment sent'**
  String get lightningPaySuccess;

  /// No description provided for @lightningCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get lightningCopied;

  /// No description provided for @lightningErrorRestricted.
  ///
  /// In en, this message translates to:
  /// **'The node hasn\'\'t authorized this app. Create a grant on your node for this connection.'**
  String get lightningErrorRestricted;

  /// No description provided for @lightningErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Lightning error: {error}'**
  String lightningErrorGeneric(String error);

  /// No description provided for @lightningConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get lightningConfirm;

  /// No description provided for @lightningCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lightningCancel;

  /// No description provided for @lightningNodeOnchain.
  ///
  /// In en, this message translates to:
  /// **'Node on-chain'**
  String get lightningNodeOnchain;

  /// No description provided for @lightningDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get lightningDeposit;

  /// No description provided for @lightningWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Send on-chain'**
  String get lightningWithdraw;

  /// No description provided for @lightningDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain deposit'**
  String get lightningDepositTitle;

  /// No description provided for @lightningDepositHint.
  ///
  /// In en, this message translates to:
  /// **'Send blake2b funds to this node address.'**
  String get lightningDepositHint;

  /// No description provided for @lightningDepositNewAddress.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get lightningDepositNewAddress;

  /// No description provided for @lightningDepositWarning.
  ///
  /// In en, this message translates to:
  /// **'Send only on the blake2b network. Funds sent on the wrong network are lost.'**
  String get lightningDepositWarning;

  /// No description provided for @lightningOnchainSendTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain send'**
  String get lightningOnchainSendTitle;

  /// No description provided for @lightningOnchainAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get lightningOnchainAddressLabel;

  /// No description provided for @lightningOnchainAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (sat)'**
  String get lightningOnchainAmountLabel;

  /// No description provided for @lightningOnchainFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get lightningOnchainFeeLabel;

  /// No description provided for @lightningOnchainFeeMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get lightningOnchainFeeMin;

  /// No description provided for @lightningOnchainFeeEconomical.
  ///
  /// In en, this message translates to:
  /// **'Economical'**
  String get lightningOnchainFeeEconomical;

  /// No description provided for @lightningOnchainFeePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get lightningOnchainFeePriority;

  /// No description provided for @lightningOnchainConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm send'**
  String get lightningOnchainConfirm;

  /// No description provided for @lightningOnchainConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm on-chain send?'**
  String get lightningOnchainConfirmTitle;

  /// No description provided for @lightningOnchainWarning.
  ///
  /// In en, this message translates to:
  /// **'Irreversible operation: funds will leave the node.'**
  String get lightningOnchainWarning;

  /// No description provided for @lightningOnchainSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction sent'**
  String get lightningOnchainSuccess;

  /// No description provided for @lightningOnchainInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid blake2b address'**
  String get lightningOnchainInvalidAddress;

  /// No description provided for @lightningOnchainInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient on-chain funds'**
  String get lightningOnchainInsufficient;

  /// No description provided for @lightningFeesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fee estimates unavailable: the node will choose the fee'**
  String get lightningFeesUnavailable;

  /// No description provided for @lightningOpenChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Pubkey or pubkey@host:port (onion needs Tor on the node)'**
  String get lightningOpenChannelHint;

  /// No description provided for @lightningOpenChannelInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid node ID or host (66 hex, host:port)'**
  String get lightningOpenChannelInvalid;

  /// No description provided for @lightningActivityDetected.
  ///
  /// In en, this message translates to:
  /// **'Node activity detected'**
  String get lightningActivityDetected;

  /// No description provided for @lightningPeers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get lightningPeers;

  /// No description provided for @lightningPeersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No peers connected'**
  String get lightningPeersEmpty;

  /// No description provided for @lightningConnectPeer.
  ///
  /// In en, this message translates to:
  /// **'Connect peer'**
  String get lightningConnectPeer;

  /// No description provided for @lightningDisconnectPeer.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get lightningDisconnectPeer;

  /// No description provided for @lightningPeerDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get lightningPeerDisconnected;

  /// No description provided for @lightningPeerId.
  ///
  /// In en, this message translates to:
  /// **'Peer ID'**
  String get lightningPeerId;

  /// No description provided for @lightningPeerAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get lightningPeerAddresses;

  /// No description provided for @lightningDisconnectPeerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect this peer? Open channels stay active.'**
  String get lightningDisconnectPeerConfirm;

  /// No description provided for @lightningChannelDetail.
  ///
  /// In en, this message translates to:
  /// **'Channel details'**
  String get lightningChannelDetail;

  /// No description provided for @lightningChannelShortId.
  ///
  /// In en, this message translates to:
  /// **'Short channel ID'**
  String get lightningChannelShortId;

  /// No description provided for @lightningChannelState.
  ///
  /// In en, this message translates to:
  /// **'Node status'**
  String get lightningChannelState;

  /// No description provided for @lightningChannelFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get lightningChannelFee;

  /// No description provided for @lightningChannelSpendable.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get lightningChannelSpendable;

  /// No description provided for @lightningChannelReceivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get lightningChannelReceivable;

  /// No description provided for @lightningChannelHtlcs.
  ///
  /// In en, this message translates to:
  /// **'HTLCs'**
  String get lightningChannelHtlcs;

  /// No description provided for @lightningChannelFundingTxid.
  ///
  /// In en, this message translates to:
  /// **'Funding txid'**
  String get lightningChannelFundingTxid;

  /// No description provided for @lightningNodeManagement.
  ///
  /// In en, this message translates to:
  /// **'Node management'**
  String get lightningNodeManagement;

  /// No description provided for @lightningNodeManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{peers} peers · {channels} channels'**
  String lightningNodeManagementSubtitle(int peers, int channels);

  /// No description provided for @lightningNodeIdentity.
  ///
  /// In en, this message translates to:
  /// **'Node identity'**
  String get lightningNodeIdentity;

  /// No description provided for @lightningNodePubkey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get lightningNodePubkey;

  /// No description provided for @lightningNodeVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get lightningNodeVersion;

  /// No description provided for @lightningNodePeersCount.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get lightningNodePeersCount;

  /// No description provided for @lightningNodeChannelsActive.
  ///
  /// In en, this message translates to:
  /// **'Active channels'**
  String get lightningNodeChannelsActive;

  /// No description provided for @lightningNodeChannelsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending channels'**
  String get lightningNodeChannelsPending;

  /// No description provided for @lightningNodeLiquidityAdsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not available on this node: advertising lease terms requires the liquidity-ads plugin.'**
  String get lightningNodeLiquidityAdsUnsupported;

  /// No description provided for @lightningLiquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get lightningLiquidity;

  /// No description provided for @lightningLiquidityTotal.
  ///
  /// In en, this message translates to:
  /// **'Total capacity'**
  String get lightningLiquidityTotal;

  /// No description provided for @lightningLiquidityOutbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get lightningLiquidityOutbound;

  /// No description provided for @lightningLiquidityInbound.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get lightningLiquidityInbound;

  /// No description provided for @lightningLiquidityWarning.
  ///
  /// In en, this message translates to:
  /// **'No inbound liquidity: payments can only arrive after a peer opens a channel towards this node.'**
  String get lightningLiquidityWarning;

  /// No description provided for @lightningMovements.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get lightningMovements;

  /// No description provided for @lightningMovementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No movements yet'**
  String get lightningMovementsEmpty;

  /// No description provided for @lightningMovementsAll.
  ///
  /// In en, this message translates to:
  /// **'All movements'**
  String get lightningMovementsAll;

  /// No description provided for @lightningMovementsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get lightningMovementsLoadMore;

  /// No description provided for @lightningMovementDeposit.
  ///
  /// In en, this message translates to:
  /// **'On-chain deposit'**
  String get lightningMovementDeposit;

  /// No description provided for @lightningMovementWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'On-chain send'**
  String get lightningMovementWithdrawal;

  /// No description provided for @lightningMovementChannelOpen.
  ///
  /// In en, this message translates to:
  /// **'Channel opening'**
  String get lightningMovementChannelOpen;

  /// No description provided for @lightningMovementChannelClose.
  ///
  /// In en, this message translates to:
  /// **'Channel closing'**
  String get lightningMovementChannelClose;

  /// No description provided for @lightningMovementInvoice.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment'**
  String get lightningMovementInvoice;

  /// No description provided for @lightningMovementOnchainFee.
  ///
  /// In en, this message translates to:
  /// **'On-chain fee'**
  String get lightningMovementOnchainFee;

  /// No description provided for @lightningMovementForward.
  ///
  /// In en, this message translates to:
  /// **'Forwarding'**
  String get lightningMovementForward;

  /// No description provided for @lightningMovementOther.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get lightningMovementOther;

  /// No description provided for @lightningChannelsAll.
  ///
  /// In en, this message translates to:
  /// **'All channels ({count})'**
  String lightningChannelsAll(int count);

  /// No description provided for @lightningOnchainNode.
  ///
  /// In en, this message translates to:
  /// **'Node on-chain'**
  String get lightningOnchainNode;

  /// No description provided for @lightningOnchainBalance.
  ///
  /// In en, this message translates to:
  /// **'On-chain balance'**
  String get lightningOnchainBalance;

  /// No description provided for @lightningOnchainConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get lightningOnchainConfirmed;

  /// No description provided for @lightningOnchainPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get lightningOnchainPending;

  /// No description provided for @lightningOnchainUtxos.
  ///
  /// In en, this message translates to:
  /// **'UTXOs'**
  String get lightningOnchainUtxos;

  /// No description provided for @lightningOnchainUtxosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No UTXOs'**
  String get lightningOnchainUtxosEmpty;

  /// No description provided for @lightningOnchainAddresses.
  ///
  /// In en, this message translates to:
  /// **'Node addresses'**
  String get lightningOnchainAddresses;

  /// No description provided for @lightningOnchainNewAddress.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get lightningOnchainNewAddress;

  /// No description provided for @lightningOnchainAddressType.
  ///
  /// In en, this message translates to:
  /// **'Address type'**
  String get lightningOnchainAddressType;

  /// No description provided for @lightningOnchainTypeBech32.
  ///
  /// In en, this message translates to:
  /// **'Bech32 (bc1q)'**
  String get lightningOnchainTypeBech32;

  /// No description provided for @lightningOnchainTypeTaproot.
  ///
  /// In en, this message translates to:
  /// **'Taproot (bc1p)'**
  String get lightningOnchainTypeTaproot;

  /// No description provided for @lightningOnchainHasFunds.
  ///
  /// In en, this message translates to:
  /// **'With funds'**
  String get lightningOnchainHasFunds;

  /// No description provided for @lightningOnchainReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get lightningOnchainReserved;

  /// No description provided for @lightningOnchainBlockHeight.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get lightningOnchainBlockHeight;

  /// No description provided for @lightningPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get lightningPayments;

  /// No description provided for @lightningInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get lightningInvoices;

  /// No description provided for @lightningInvoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get lightningInvoicesEmpty;

  /// No description provided for @lightningInvoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get lightningInvoiceStatusPaid;

  /// No description provided for @lightningInvoiceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get lightningInvoiceStatusPending;

  /// No description provided for @lightningInvoiceStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get lightningInvoiceStatusExpired;

  /// No description provided for @lightningInvoicePaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String lightningInvoicePaidOn(String date);

  /// No description provided for @lightningInvoiceExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String lightningInvoiceExpiresOn(String date);

  /// No description provided for @lightningReceivePaid.
  ///
  /// In en, this message translates to:
  /// **'Invoice paid'**
  String get lightningReceivePaid;

  /// No description provided for @lightningPaymentsSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} invoices · {pending} waiting'**
  String lightningPaymentsSummary(int total, int pending);

  /// No description provided for @lightningPays.
  ///
  /// In en, this message translates to:
  /// **'Sent payments'**
  String get lightningPays;

  /// No description provided for @lightningPaysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get lightningPaysEmpty;

  /// No description provided for @lightningPaymentFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get lightningPaymentFee;

  /// No description provided for @lightningPaymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lightningPaymentCompleted;

  /// No description provided for @lightningPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get lightningPaymentPending;

  /// No description provided for @lightningPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get lightningPaymentFailed;

  /// No description provided for @lightningHtlcsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No HTLCs'**
  String get lightningHtlcsEmpty;

  /// No description provided for @lightningHtlcInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get lightningHtlcInProgress;

  /// No description provided for @lightningHtlcIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get lightningHtlcIncoming;

  /// No description provided for @lightningHtlcOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get lightningHtlcOutgoing;

  /// No description provided for @lightningChannelFees.
  ///
  /// In en, this message translates to:
  /// **'Routing fees'**
  String get lightningChannelFees;

  /// No description provided for @lightningFeeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit fees'**
  String get lightningFeeEdit;

  /// No description provided for @lightningFeeBefore.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get lightningFeeBefore;

  /// No description provided for @lightningFeeAfter.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get lightningFeeAfter;

  /// No description provided for @lightningFeeBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base (sat)'**
  String get lightningFeeBaseLabel;

  /// No description provided for @lightningFeePpmLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate (ppm)'**
  String get lightningFeePpmLabel;

  /// No description provided for @lightningHtlcMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min HTLC (sat)'**
  String get lightningHtlcMinLabel;

  /// No description provided for @lightningHtlcMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max HTLC (sat)'**
  String get lightningHtlcMaxLabel;

  /// No description provided for @lightningCltvLabel.
  ///
  /// In en, this message translates to:
  /// **'CLTV delta'**
  String get lightningCltvLabel;

  /// No description provided for @lightningChannelReserve.
  ///
  /// In en, this message translates to:
  /// **'Our reserve'**
  String get lightningChannelReserve;

  /// No description provided for @lightningChannelToSelfDelay.
  ///
  /// In en, this message translates to:
  /// **'To-self delay'**
  String get lightningChannelToSelfDelay;

  /// No description provided for @lightningFeeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply these routing fees?'**
  String get lightningFeeConfirmTitle;

  /// No description provided for @lightningFeeWarning.
  ///
  /// In en, this message translates to:
  /// **'Fees apply to routed payments. The network accepts only a few changes per day, and peers may take time to adopt them.'**
  String get lightningFeeWarning;

  /// No description provided for @lightningFeeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Fee policy updated'**
  String get lightningFeeUpdated;

  /// No description provided for @lightningDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get lightningDiagnostics;

  /// No description provided for @lightningDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting, plugins and forwarding'**
  String get lightningDiagnosticsSubtitle;

  /// No description provided for @lightningStatsEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get lightningStatsEconomy;

  /// No description provided for @lightningStatsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get lightningStatsNet;

  /// No description provided for @lightningStatsSource.
  ///
  /// In en, this message translates to:
  /// **'From the node\'\'s accounting (bookkeeper)'**
  String get lightningStatsSource;

  /// No description provided for @lightningStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounting data yet'**
  String get lightningStatsEmpty;

  /// No description provided for @lightningStatsTagDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get lightningStatsTagDeposit;

  /// No description provided for @lightningStatsTagInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get lightningStatsTagInvoice;

  /// No description provided for @lightningStatsTagWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get lightningStatsTagWithdrawal;

  /// No description provided for @lightningStatsTagOnchainFee.
  ///
  /// In en, this message translates to:
  /// **'On-chain fees'**
  String get lightningStatsTagOnchainFee;

  /// No description provided for @lightningStatsTagChannelOpen.
  ///
  /// In en, this message translates to:
  /// **'Channel opens'**
  String get lightningStatsTagChannelOpen;

  /// No description provided for @lightningStatsTagChannelClose.
  ///
  /// In en, this message translates to:
  /// **'Channel closes'**
  String get lightningStatsTagChannelClose;

  /// No description provided for @lightningStatsTagRouted.
  ///
  /// In en, this message translates to:
  /// **'Routing fees earned'**
  String get lightningStatsTagRouted;

  /// No description provided for @lightningStatsEntries.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 entry} other{{count} entries}}'**
  String lightningStatsEntries(int count);

  /// No description provided for @lightningPluginsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get lightningPluginsTitle;

  /// No description provided for @lightningPluginsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String lightningPluginsActiveCount(int count);

  /// No description provided for @lightningPluginInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get lightningPluginInactive;

  /// No description provided for @lightningForwardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Forwarding'**
  String get lightningForwardsTitle;

  /// No description provided for @lightningForwardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No forwarded payments yet'**
  String get lightningForwardsEmpty;

  /// No description provided for @lightningForwardSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get lightningForwardSettled;

  /// No description provided for @lightningForwardFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get lightningForwardFailed;

  /// No description provided for @lightningForwardOffered.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get lightningForwardOffered;

  /// No description provided for @lightningKeysendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to node (keysend)'**
  String get lightningKeysendTitle;

  /// No description provided for @lightningKeysendHint.
  ///
  /// In en, this message translates to:
  /// **'Destination node pubkey (66 hex)'**
  String get lightningKeysendHint;

  /// No description provided for @lightningKeysendAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (sat)'**
  String get lightningKeysendAmountLabel;

  /// No description provided for @lightningKeysendMaxFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max fee (sat)'**
  String get lightningKeysendMaxFeeLabel;

  /// No description provided for @lightningKeysendMaxFeeHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the node default (0.5%)'**
  String get lightningKeysendMaxFeeHelp;

  /// No description provided for @lightningKeysendWarning.
  ///
  /// In en, this message translates to:
  /// **'Keysend pays a node without an invoice: funds move immediately and cannot be reversed.'**
  String get lightningKeysendWarning;

  /// No description provided for @lightningKeysendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this keysend payment?'**
  String get lightningKeysendConfirmTitle;

  /// No description provided for @lightningKeysendDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get lightningKeysendDestination;

  /// No description provided for @lightningKeysendSent.
  ///
  /// In en, this message translates to:
  /// **'Keysend sent'**
  String get lightningKeysendSent;

  /// No description provided for @lightningKeysendInvalidPubkey.
  ///
  /// In en, this message translates to:
  /// **'Invalid node pubkey'**
  String get lightningKeysendInvalidPubkey;

  /// No description provided for @lightningKeysendInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get lightningKeysendInvalidAmount;

  /// No description provided for @lightningKeysendSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get lightningKeysendSend;

  /// No description provided for @walletAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Addresses & UTXO'**
  String get walletAddressesTitle;

  /// No description provided for @walletAddressesTabAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get walletAddressesTabAddresses;

  /// No description provided for @walletAddressesTabUtxos.
  ///
  /// In en, this message translates to:
  /// **'UTXO'**
  String get walletAddressesTabUtxos;

  /// No description provided for @walletAddressesReceiveBranch.
  ///
  /// In en, this message translates to:
  /// **'Receive (/0)'**
  String get walletAddressesReceiveBranch;

  /// No description provided for @walletAddressesChangeBranch.
  ///
  /// In en, this message translates to:
  /// **'Change (/1)'**
  String get walletAddressesChangeBranch;

  /// No description provided for @walletAddressesStatusUnused.
  ///
  /// In en, this message translates to:
  /// **'Never used'**
  String get walletAddressesStatusUnused;

  /// No description provided for @walletAddressesStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get walletAddressesStatusUsed;

  /// No description provided for @walletAddressesStatusFunds.
  ///
  /// In en, this message translates to:
  /// **'With funds'**
  String get walletAddressesStatusFunds;

  /// No description provided for @walletAddressesTxCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String walletAddressesTxCount(int count);

  /// No description provided for @walletAddressesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No address to show'**
  String get walletAddressesEmpty;

  /// No description provided for @walletAddressesHintTap.
  ///
  /// In en, this message translates to:
  /// **'Tap an address to copy it'**
  String get walletAddressesHintTap;

  /// No description provided for @lightningPeeringGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Peering restricted to bit 68 releases'**
  String get lightningPeeringGateTitle;

  /// No description provided for @lightningPeeringGateBody.
  ///
  /// In en, this message translates to:
  /// **'This node requires option_blake2b (bit 68) during the connection handshake, so nodes on older releases cannot connect. It is a choice of the node, not a problem of the app or of the bridge. Use peers running release .4 or later, or wait for the community to make the bit optional.'**
  String get lightningPeeringGateBody;

  /// No description provided for @lightningPeeringGateLink.
  ///
  /// In en, this message translates to:
  /// **'Compatibility matrix'**
  String get lightningPeeringGateLink;

  /// No description provided for @lightningPeersRegisteredOnly.
  ///
  /// In en, this message translates to:
  /// **'{count} registered peers, none connected'**
  String lightningPeersRegisteredOnly(int count);

  /// No description provided for @lightningSwapOpen.
  ///
  /// In en, this message translates to:
  /// **'Pay an invoice without a node (swap)'**
  String get lightningSwapOpen;

  /// No description provided for @lightningSwapWebOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Web app: Lightning payments use a swap provider (no node required). Connecting your own node is available in the Android app.'**
  String get lightningSwapWebOnlyNote;

  /// No description provided for @lightningSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment via provider'**
  String get lightningSwapTitle;

  /// No description provided for @lightningSwapIntro.
  ///
  /// In en, this message translates to:
  /// **'You keep custody of the funds: they go into an on-chain HTLC (P2WSH) and are released only when the provider pays your invoice. If the payment fails, you can recover the funds after the time lock.'**
  String get lightningSwapIntro;

  /// No description provided for @lightningSwapProviderUriHint.
  ///
  /// In en, this message translates to:
  /// **'Provider URI (nostr+swap://...)'**
  String get lightningSwapProviderUriHint;

  /// No description provided for @lightningSwapProviderConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect provider'**
  String get lightningSwapProviderConnect;

  /// No description provided for @lightningSwapProviderConnected.
  ///
  /// In en, this message translates to:
  /// **'Provider connected: {pubkey}'**
  String lightningSwapProviderConnected(String pubkey);

  /// No description provided for @lightningSwapProviderDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get lightningSwapProviderDisconnect;

  /// No description provided for @lightningSwapInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Lightning invoice (lnbc...)'**
  String get lightningSwapInvoiceHint;

  /// No description provided for @lightningSwapStart.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get lightningSwapStart;

  /// No description provided for @lightningSwapAmount.
  ///
  /// In en, this message translates to:
  /// **'Invoice amount'**
  String get lightningSwapAmount;

  /// No description provided for @lightningSwapFees.
  ///
  /// In en, this message translates to:
  /// **'Fees (claim + service)'**
  String get lightningSwapFees;

  /// No description provided for @lightningSwapTotal.
  ///
  /// In en, this message translates to:
  /// **'Total to lock'**
  String get lightningSwapTotal;

  /// No description provided for @lightningSwapFund.
  ///
  /// In en, this message translates to:
  /// **'Send funds and start swap'**
  String get lightningSwapFund;

  /// No description provided for @lightningSwapFundHint.
  ///
  /// In en, this message translates to:
  /// **'The funds go to the HTLC address shown above. Payment starts after 1 confirmation.'**
  String get lightningSwapFundHint;

  /// No description provided for @lightningSwapStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get lightningSwapStateLabel;

  /// No description provided for @lightningSwapHtlc.
  ///
  /// In en, this message translates to:
  /// **'HTLC address'**
  String get lightningSwapHtlc;

  /// No description provided for @lightningSwapCltv.
  ///
  /// In en, this message translates to:
  /// **'Refund available from block {height}'**
  String lightningSwapCltv(int height);

  /// No description provided for @swapStateAwaitingFunding.
  ///
  /// In en, this message translates to:
  /// **'Waiting for on-chain funding'**
  String get swapStateAwaitingFunding;

  /// No description provided for @swapStateConfirming.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmations'**
  String get swapStateConfirming;

  /// No description provided for @swapStatePaying.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment in progress'**
  String get swapStatePaying;

  /// No description provided for @swapStatePaid.
  ///
  /// In en, this message translates to:
  /// **'Invoice paid, claiming in progress'**
  String get swapStatePaid;

  /// No description provided for @swapStateClaiming.
  ///
  /// In en, this message translates to:
  /// **'Claim in progress'**
  String get swapStateClaiming;

  /// No description provided for @swapStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get swapStateCompleted;

  /// No description provided for @swapStatePaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed — funds recoverable'**
  String get swapStatePaymentFailed;

  /// No description provided for @swapStateExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired — funds recoverable'**
  String get swapStateExpired;

  /// No description provided for @swapStateRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get swapStateRefunded;

  /// No description provided for @lightningSwapRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund recovery'**
  String get lightningSwapRecoveryTitle;

  /// No description provided for @lightningSwapRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Recovery blob (swaprecover1....)'**
  String get lightningSwapRecoveryHint;

  /// No description provided for @lightningSwapRecoveryImport.
  ///
  /// In en, this message translates to:
  /// **'Import session'**
  String get lightningSwapRecoveryImport;

  /// No description provided for @lightningSwapRefund.
  ///
  /// In en, this message translates to:
  /// **'Recover funds (refund)'**
  String get lightningSwapRefund;

  /// No description provided for @lightningSwapRefundNotYet.
  ///
  /// In en, this message translates to:
  /// **'Refund not available yet: it opens from block {height}'**
  String lightningSwapRefundNotYet(int height);

  /// No description provided for @lightningSwapCopyBlob.
  ///
  /// In en, this message translates to:
  /// **'Copy recovery blob'**
  String get lightningSwapCopyBlob;

  /// No description provided for @lightningSwapBlobCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery blob copied'**
  String get lightningSwapBlobCopied;

  /// No description provided for @lightningSwapClaimTxid.
  ///
  /// In en, this message translates to:
  /// **'Claim txid'**
  String get lightningSwapClaimTxid;

  /// No description provided for @lightningSwapClaimHint.
  ///
  /// In en, this message translates to:
  /// **'The claim is an on-chain transaction: it is confirmed with the next block (~12 min). Tap the link to verify it.'**
  String get lightningSwapClaimHint;

  /// No description provided for @lightningSwapInvalidInvoice.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a Lightning invoice'**
  String get lightningSwapInvalidInvoice;

  /// No description provided for @lightningSwapWatchOnly.
  ///
  /// In en, this message translates to:
  /// **'The swap needs a wallet with seed (not watch-only)'**
  String get lightningSwapWatchOnly;

  /// No description provided for @lightningSwapNoUtxos.
  ///
  /// In en, this message translates to:
  /// **'No spendable funds in this wallet'**
  String get lightningSwapNoUtxos;

  /// No description provided for @lightningSwapErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String lightningSwapErrorGeneric(String message);

  /// No description provided for @lightningSwapKnownUris.
  ///
  /// In en, this message translates to:
  /// **'Saved provider URIs'**
  String get lightningSwapKnownUris;

  /// No description provided for @lightningSwapWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get lightningSwapWalletLabel;

  /// No description provided for @lightningSwapWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance} sat'**
  String lightningSwapWalletBalance(String balance);

  /// No description provided for @lightningSwapInsufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds: {needed} sat needed, {available} sat available'**
  String lightningSwapInsufficientFunds(String needed, String available);

  /// No description provided for @lightningSwapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel swap'**
  String get lightningSwapCancel;

  /// No description provided for @lightningSwapErrorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the provider. Check your connection and try again.'**
  String get lightningSwapErrorConnectFailed;

  /// No description provided for @lightningSwapErrorDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Connection to the provider was lost. Try connecting again.'**
  String get lightningSwapErrorDisconnected;

  /// No description provided for @lightningSwapErrorNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Provider not connected.'**
  String get lightningSwapErrorNotConnected;

  /// No description provided for @lightningSwapErrorRelayNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This provider uses a relay that the web version cannot reach. Open the app on your phone to pay with this provider.'**
  String get lightningSwapErrorRelayNotAllowed;

  /// No description provided for @lightningSwapCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this swap?'**
  String get lightningSwapCancelTitle;

  /// No description provided for @lightningSwapCancelBody.
  ///
  /// In en, this message translates to:
  /// **'The app will forget this swap. The provider drops it by itself before the deadline and no funds are locked. To retry with the same invoice you need a new session only after it expires — otherwise generate a new invoice.'**
  String get lightningSwapCancelBody;

  /// No description provided for @lightningSwapCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get lightningSwapCancelConfirm;

  /// No description provided for @lightningSwapWalletMissing.
  ///
  /// In en, this message translates to:
  /// **'The wallet bound to this swap is no longer available'**
  String get lightningSwapWalletMissing;

  /// No description provided for @lightningSwapBoundWallet.
  ///
  /// In en, this message translates to:
  /// **'Bound wallet: {name}'**
  String lightningSwapBoundWallet(String name);

  /// No description provided for @lightningInvoiceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete invoice'**
  String get lightningInvoiceDelete;

  /// No description provided for @lightningInvoiceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this invoice?'**
  String get lightningInvoiceDeleteTitle;

  /// No description provided for @lightningInvoiceDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The invoice will be removed from the node. If it is unpaid it can no longer be paid.'**
  String get lightningInvoiceDeleteBody;

  /// No description provided for @lightningInvoiceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get lightningInvoiceDeleteConfirm;

  /// No description provided for @lightningInvoiceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Invoice deleted'**
  String get lightningInvoiceDeleted;

  /// No description provided for @lightningChannelPeerAddress.
  ///
  /// In en, this message translates to:
  /// **'Peer address'**
  String get lightningChannelPeerAddress;
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
