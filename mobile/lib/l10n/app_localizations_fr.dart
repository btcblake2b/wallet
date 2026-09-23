// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'Pas de connexion';

  @override
  String get homeNoConnectionCreate =>
      'Impossible de créer le portefeuille sans connexion Internet active. L\'adresse doit être vérifiée sur le réseau. Réessayez lorsque la connexion sera rétablie.';

  @override
  String get homeNoConnectionImport =>
      'Impossible d\'importer le portefeuille sans connexion Internet.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Portefeuille créé avec succès.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Erreur de création du portefeuille : $error';
  }

  @override
  String get homeImportWallet => 'Importer un portefeuille';

  @override
  String get homeCreateWallet => 'Créer un portefeuille';

  @override
  String get homeSelected => 'sélectionnés';

  @override
  String get homeDeleteSelected => 'Supprimer la sélection';

  @override
  String homeDeleteConfirm(int count) {
    return 'Supprimer $count portefeuilles ? Cette action est irréversible.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count portefeuilles supprimés avec succès.';
  }

  @override
  String get homeWalletImported => 'Portefeuille importé avec succès.';

  @override
  String get homeSecurityWarning =>
      'Ce logiciel est fourni \"tel quel\" sans aucune garantie. Le fabricant n\'est pas responsable des pertes de fonds, vols, piratage, erreurs de transaction ou tout dommage découlant de l\'utilisation de l\'application. Le portefeuille ne garantit pas la protection contre les copies antérieures de la seed. À utiliser uniquement pour de petits montants.';

  @override
  String get homeDisclaimerAccept => 'J\'accepte';

  @override
  String get legalInfoTitle => 'Infos légales';

  @override
  String get homeLocalWallets => 'Portefeuilles locaux';

  @override
  String homeErrorLoading(Object error) {
    return 'Erreur de chargement du portefeuille : $error';
  }

  @override
  String get homeEmptyTitle => 'Aucun portefeuille';

  @override
  String get homeEmptySubtitle =>
      'Créez votre premier portefeuille Bitcoin pour commencer.';

  @override
  String get homeBalanceTitle => 'SOLDE ACTIF';

  @override
  String get balanceUnavailable => 'Solde indisponible';

  @override
  String get homeBackupVerified => 'Sauvegarde vérifiée';

  @override
  String get homeBackupNotVerified => 'Sauvegarde non vérifiée';

  @override
  String get homeLockVault => 'Verrouiller le coffre';

  @override
  String get homeVaultLocked => 'Coffre verrouillé';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionSecurity => 'Sécurité';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionTools => 'Outils';

  @override
  String get settingsSectionInfo => 'Informations';

  @override
  String get settingsTheme => 'Thème sombre';

  @override
  String get settingsAppLock => 'Verrouillage';

  @override
  String get settingsAppLockDesc =>
      'Demander la biométrie ou le code du téléphone à chaque ouverture';

  @override
  String get settingsAppLockUnavailable =>
      'Aucune biométrie enregistrée sur cet appareil';

  @override
  String get settingsAppLockEnableFailed =>
      'Vérification échouée : verrouillage non activé';

  @override
  String get settingsAppLockEnabled => 'Verrouillage activé';

  @override
  String get settingsAppLockDisabled => 'Verrouillage désactivé';

  @override
  String get settingsExplorerMirrors => 'Explorateurs de secours';

  @override
  String get settingsExplorerMirrorsDesc =>
      'Si mempool.guide ne répond pas, l\'app interroge deux miroirs communautaires. Désactivez pour n\'utiliser que mempool.guide.';

  @override
  String get settingsSectionInterface => 'Interface';

  @override
  String get settingsInfoDots => 'Aides info';

  @override
  String get settingsInfoDotsDesc =>
      'Afficher les petits boutons d\'information qui expliquent chaque fonctionnalité';

  @override
  String get infoCoinControlTitle => 'Coin control (sélection UTXO)';

  @override
  String get infoCoinControlBody =>
      'Votre solde est composé d\'UTXO, les pièces que vous avez reçues. Ici, vous pouvez choisir lesquelles dépenser : la transaction n\'utilisera que celles-ci, permettant de garder les petites ou inactives de côté.';

  @override
  String get infoDustLimitTitle => 'Montant minimum (poussière)';

  @override
  String get infoDustLimitBody =>
      'Les sorties inférieures à 546 sat sont rejetées par le réseau comme \'poussière\'. Les montants en dessous de cette limite ne peuvent pas être envoyés.';

  @override
  String get infoFeeRateTitle => 'Frais de transaction';

  @override
  String get infoFeeRateBody =>
      'Les frais sont payés par unité de taille de transaction (sat/vB) : plus vous voulez une confirmation rapide, plus vous payez. \'Économique\' peut prendre des heures, \'Prioritaire\' quelques minutes. \'Personnalisé\' est utilisé quand vous connaissez le taux actuel du mempool.';

  @override
  String get infoBatchSendTitle => 'Destinataires multiples (lot)';

  @override
  String get infoBatchSendBody =>
      'Dans une seule transaction, vous pouvez payer jusqu\'à 5 adresses, partageant les frais au lieu de les payer une fois par transfert. Tous les destinataires sont affichés dans la confirmation avant signature.';

  @override
  String get infoBumpFeeTitle => 'Augmenter les frais (RBF)';

  @override
  String get infoBumpFeeBody =>
      'Une transaction en attente peut être remplacée par une nouvelle payant des frais plus élevés (BIP125). L\'originale est annulée et seule la remplacement peut confirmer — l\'adresse de destination et le montant restent identiques.';

  @override
  String get infoXpubTitle => 'Clé publique du compte (xpub)';

  @override
  String get infoXpubBody =>
      'Le xpub génère toutes vos adresses de réception. Il ne peut pas déplacer de fonds, mais révèle le solde et l\'historique complets : partagez-le uniquement avec des applications de confiance (ex. un wallet en lecture seule).';

  @override
  String get infoReceiveAddressTitle => 'Adresse de réception';

  @override
  String get infoReceiveAddressBody =>
      'Chaque \'Recevoir\' affiche une adresse fraîche, choisie parmi celles jamais utilisées : cela rend les paiements non corrélables. Réutiliser une adresse n\'est pas une erreur, elle rend simplement vos transactions plus faciles à suivre.';

  @override
  String get infoWatchOnlyTitle => 'Wallet en lecture seule';

  @override
  String get infoWatchOnlyBody =>
      'Vous avez importé uniquement le xpub : l\'application voit le solde et l\'historique mais ne détient aucune clé privée, donc elle ne peut pas signer. Pour dépenser depuis ce wallet, vous avez besoin de l\'appareil qui contient la seed.';

  @override
  String get infoSignVerifyTitle => 'Signer / vérifier un message';

  @override
  String get infoSignVerifyBody =>
      'Signer prouve qu\'une adresse vous appartient sans déplacer de fonds. Quiconque peut ensuite vérifier la signature contre cette adresse et le même message.';

  @override
  String get infoChannelCapacityTitle => 'Capacité du canal';

  @override
  String get infoChannelCapacityBody =>
      'Le montant total de satoshis dans le canal, partagé entre vous et votre peer. Plus de capacité signifie pouvoir gérer des paiements plus importants. Capacité = solde local + solde distant.';

  @override
  String get infoChannelReserveTitle => 'Réserve du canal';

  @override
  String get infoChannelReserveBody =>
      'Une petite partie de vos fonds doit rester bloquée comme dépôt de sécurité (la \'réserve\'). Elle garantit que les deux parties ont quelque chose à perdre — si l\'autre côté va hors ligne malveillamment, la réserve peut être utilisée pour le pénaliser on-chain.';

  @override
  String get infoToSelfDelayTitle => 'Délai vers soi-même';

  @override
  String get infoToSelfDelayBody =>
      'En cas de fermeture forcée, votre sortie on-chain est retardée de ce nombre de blocs (généralement 144 = ~1 jour). Cela donne à votre peer le temps de réclamer ses fonds en premier, empêchant les attaques de double dépense sur l\'état du canal.';

  @override
  String get infoHtlcTitle => 'HTLC (Contrat verrouillé par hash et temps)';

  @override
  String get infoHtlcBody =>
      'Un HTLC est un paiement conditionnel : les fonds sont bloqués jusqu\'à ce que le destinataire révèle un préimage hash. Dans Lightning, les HTLC permettent le routage instantané hors chaîne — votre paiement saute à travers plusieurs canaux sans faire confiance à aucun intermédiaire.';

  @override
  String get infoOpenChannelPrivateTitle => 'Canal privé';

  @override
  String get infoOpenChannelPrivateBody =>
      'Un canal privé n\'est pas annoncé au réseau. Seul vous et votre peer savez qu\'il existe. Utilisez-le quand vous ne voulez pas que d\'autres fassent du routage à travers (confidentialité) ou quand le canal est trop petit pour être utile pour le routage.';

  @override
  String get infoRoutingFeesTitle => 'Frais de routage';

  @override
  String get infoRoutingFeesBody =>
      'Quand d\'autres nœuds acheminent des paiements à travers votre canal, vous gagnez des frais. Frais de base (sat) facturés par paiement ; taux (ppm) proportionnel au montant. Le delta CLTV limite combien de temps un HTLC transféré peut mettre à s\'régler.';

  @override
  String get infoForceCloseTitle => 'Fermeture forcée';

  @override
  String get infoForceCloseBody =>
      'Diffuse votre dernier état de canal on-chain. C\'est irréversible et nécessite d\'attendre le délai vers soi-même avant de pouvoir dépenser vos fonds. Utilisez-le seulement si votre peer ne répond pas ou est malveillant — la fermeture coopérative est toujours plus rapide et moins chère.';

  @override
  String get infoPeersTitle => 'Peers connectés';

  @override
  String get infoPeersBody =>
      'Les peers sont d\'autres nœuds Lightning avec lesquels vous êtes directement connecté via TCP/Tor. Chaque peer peut avoir un ou plusieurs canaux. Vous pouvez vous connecter à de nouveaux peers pour ouvrir des canaux et augmenter la liquidité et la capacité de routage de votre nœud.';

  @override
  String get infoNodeManagementTitle => 'Gestion du nœud';

  @override
  String get infoNodeManagementBody =>
      'L\'identité de votre nœud Lightning : pubkey, version, nombre de canaux et peers actifs/en attente. Cet écran montre les données comptables du plugin bookkeeper du nœud et les statistiques de forwarding.';

  @override
  String get appLockTitle => 'Application verrouillée';

  @override
  String get appLockSubtitle =>
      'Déverrouillez avec la biométrie ou le code du téléphone';

  @override
  String get appLockUnlock => 'Déverrouiller';

  @override
  String get appLockReason => 'Déverrouiller le wallet';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'Verrouillage désactivé : la protection de l\'écran (biométrie/code) n\'est plus disponible. Réactivez-la dans les réglages du système pour réutiliser le verrouillage.';

  @override
  String get appLockNoticeContinue => 'Continuer';

  @override
  String get appLockPromptTitle => 'Activer le verrouillage ?';

  @override
  String get appLockPromptMessage =>
      'À chaque ouverture, la biométrie ou le code du téléphone sera demandé.';

  @override
  String get appLockPromptEnable => 'Activer';

  @override
  String get appLockPromptLater => 'Plus tard';

  @override
  String get aboutLicensesOpenOnline => 'Ouvrir en ligne';

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Portefeuille $name$balance';
  }

  @override
  String get walletDetailTitle => 'Portefeuille';

  @override
  String walletDetailCopied(Object label) {
    return '$label copié. Sera supprimé après 60 s.';
  }

  @override
  String get walletDetailAddress => 'Adresse';

  @override
  String get walletDetailTransactions => 'Transactions';

  @override
  String get walletDetailTxBlockHeight => 'Hauteur de bloc';

  @override
  String get walletDetailTxConfirmations => 'Confirmations';

  @override
  String get walletDetailTxDate => 'Date';

  @override
  String get walletDetailTxDetails => 'Détails de la transaction';

  @override
  String get walletDetailTxEmpty => 'Aucune transaction';

  @override
  String get walletDetailTxError => 'Impossible de charger les transactions';

  @override
  String get walletDetailTxExport => 'Exporter';

  @override
  String get walletDetailTxExportCsv => 'CSV (tableur)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'Copié dans le presse-papiers ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Téléchargement lancé ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'Export impossible';

  @override
  String get walletDetailTxExportJson => 'JSON (complet)';

  @override
  String get walletDetailTxFee => 'Frais';

  @override
  String get walletDetailTxIncoming => 'Reçus';

  @override
  String get walletDetailTxNote => 'Note';

  @override
  String get walletDetailTxNoteAdd => 'Ajouter une note';

  @override
  String get walletDetailTxNoteEdit => 'Modifier la note';

  @override
  String get walletDetailTxNoteHint =>
      'Note privée, enregistrée uniquement sur cet appareil';

  @override
  String get walletDetailTxNoteRemove => 'Supprimer';

  @override
  String get walletDetailTxOrphan => 'Orpheline (bloc perdu)';

  @override
  String get walletDetailTxOutgoing => 'Envoyés';

  @override
  String get walletDetailTxPending => 'En attente';

  @override
  String get walletDetailTxReplaced => 'Remplacée (retirée du mempool)';

  @override
  String get walletDetailTxRetry => 'Réessayer';

  @override
  String get backupSeedTitle => 'Sauvegarde de la phrase';

  @override
  String get backupSeedIntro =>
      'Écrivez votre phrase de récupération sur papier et rangez-la en lieu sûr. Ceci est le seul moyen de récupérer vos fonds.';

  @override
  String get backupSeedStart => 'Commencer la sauvegarde';

  @override
  String get backupSeedLater => 'Plus tard';

  @override
  String get backupSeedSavedContinue => 'Phrase sauvegardée';

  @override
  String get backupSeedVerifyTitle => 'Vérifiez votre sauvegarde';

  @override
  String get backupSeedVerifyHint =>
      'Saisissez les 3 mots surlignés pour confirmer que vous les avez sauvegardés.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Mot $number';
  }

  @override
  String get backupSeedVerifyError => 'Mots incorrects. Réessayez.';

  @override
  String get backupSeedDone => 'Sauvegarde terminée';

  @override
  String get backupSeedDoneDesc =>
      'Votre phrase est en sécurité. Rappel : qui détient la phrase contrôle les fonds.';

  @override
  String get backupSeedFinish => 'Terminer';

  @override
  String get backupSeedSkipWarning =>
      'Si vous ignorez, vous risquez de perdre vos fonds en cas de perte de votre appareil. Vous pourrez le faire plus tard depuis les détails du portefeuille.';

  @override
  String get walletDetailSend => 'Envoyer';

  @override
  String get walletDetailReceive => 'Recevoir';

  @override
  String get sendScreenTitle => 'Envoyer BTC';

  @override
  String get sendScreenAddressLabel => 'Adresse du destinataire';

  @override
  String get sendScreenAmountLabel => 'Montant (BTC)';

  @override
  String get sendScreenFeeLabel => 'Frais';

  @override
  String get sendScreenFeeLow => 'Bas';

  @override
  String get sendScreenFeeNormal => 'Normal';

  @override
  String get sendScreenFeeHigh => 'Élevé';

  @override
  String get sendScreenFeeCustom => 'Personnalisé';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Disponible : $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Frais estimés : $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'Sélection des UTXO';

  @override
  String get sendScreenUtxoSelectAll => 'Tout sélectionner';

  @override
  String get sendScreenUtxoNoneSelected =>
      'Sélectionnez au moins un UTXO à envoyer';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Total : $total $ticker';
  }

  @override
  String get sendScreenMax => 'Max';

  @override
  String get sendScreenSend => 'Envoyer';

  @override
  String get sendScreenSending => 'Envoi en cours...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return '$deleted portefeuilles supprimés, $errors erreurs : $error';
  }

  @override
  String get walletDetailBalanceLabel => 'SOLDE';

  @override
  String get walletDetailMasterFingerprint => 'EMPREINTE MAÎTRE';

  @override
  String get walletDetailDerivationPath => 'CHEMIN DE DÉRIVATION';

  @override
  String get walletDetailSettings => 'PARAMÈTRES';

  @override
  String get walletDetailAdvancedTools => 'Outils Avancés';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'Aucun UTXO dépensable trouvé';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count confirmations';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count sélectionnés · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Envoyer la sélection';

  @override
  String get walletDetailUtxoClearSelection => 'Effacer la sélection';

  @override
  String get walletDetailPasswordSeedReason =>
      'Confirmez le mot de passe pour voir la phrase de graine';

  @override
  String get walletDetailBiometricSeedReason =>
      'Confirmation biométrique pour voir la phrase de graine';

  @override
  String get walletDetailPasswordBumpReason =>
      'Confirmez le mot de passe pour augmenter les frais';

  @override
  String get walletDetailBiometricBumpReason =>
      'Confirmation biométrique pour augmenter les frais';

  @override
  String get walletDetailTxBumpFee => 'Augmenter les frais';

  @override
  String get walletDetailBumpFeeTitle => 'Augmenter les frais de transaction';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Frais actuels : $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Frais recommandés indisponibles — saisissez un taux personnalisé';

  @override
  String get walletDetailBumpFeeWarning =>
      'La transaction d’origine pourrait ne jamais être confirmée si le remplacement est miné.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Frais augmentés — nouvelle transaction $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'Les nouveaux frais doivent être supérieurs aux frais actuels';

  @override
  String get sendScreenSigning => 'Signature de la transaction...';

  @override
  String get sendScreenBroadcasting => 'Diffusion vers le réseau...';

  @override
  String get sendScreenBiometricReason =>
      'Confirmation biométrique pour autoriser la transaction';

  @override
  String get sendScreenPasswordReason =>
      'Saisissez votre mot de passe pour autoriser la transaction';

  @override
  String get sendScreenBiometricRequired =>
      'La biométrie est requise pour envoyer. Activez l\'empreinte ou la reconnaissance faciale dans les réglages de l\'appareil.';

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
    return 'Max : $amount';
  }

  @override
  String sendScreenUtxoSummary(int sats, int count) {
    return '$sats sat · $count UTXO';
  }

  @override
  String get importScreenHintText =>
      'La phrase de graine se compose de 12, 15, 18, 21 ou 24 mots séparés par des espaces. Vous pouvez la coller directement.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get legalMitLicense => 'Licence MIT';

  @override
  String get legalSecurityTitle => 'Sécurité';

  @override
  String get legalTermsContent =>
      'Ces conditions d\'utilisation sont provisoires et seront remplacées par la version définitive dès que le site officiel sera disponible.\n\nBtc Blake2b Wallet est un portefeuille Bitcoin en auto-garde pour le réseau expérimental \"bitcoin-blake2b\" (un fork de Bitcoin). Les clés privées et la phrase de récupération restent exclusivement sur votre appareil : nous ne conservons pas, ne transférons pas et n\'avons pas accès à vos fonds.\n\nL\'application est fournie gratuitement, \"telle quelle\", sans garantie d\'aucune sorte. Vous l\'utilisez à vos propres risques. Le réseau bitcoin-blake2b est un réseau expérimental dérivé de Bitcoin : ses pièces peuvent ne pas avoir de valeur de marché, ne pas être reconnues par les plateformes d\'échange et subir des réorganisations. Aucun contenu de l\'application ne constitue un conseil financier ou d\'investissement.\n\nVous êtes seul responsable de la garde de votre phrase de récupération et de vos fonds : quiconque en est en possession peut dépenser les pièces. L\'application ne peut pas récupérer une phrase de récupération perdue. L\'utilisation à des fins illégales est interdite. Vous déclarez avoir au moins 16 ans.\n\nBtc Blake2b Wallet n\'est ni affilié, ni sponsorisé, ni approuvé par Bitcoin, Bitcoin Core ou bitcoin.org.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'Cette politique de confidentialité est provisoire et sera remplacée par la version définitive publiée sur le site officiel lorsqu\'elle sera disponible.\n\n1) DONNÉES SUR L\'APPAREIL. L\'application n\'exige pas de compte et n\'enregistre pas de données personnelles sur les serveurs de l\'auteur. La phrase de récupération chiffrée (AES-256-GCM), les préférences et les consentements restent UNIQUEMENT sur votre appareil.\n\n2) DONNÉES TRANSMISES À DES TIERS POUR LE FONCTIONNEMENT. Pour afficher le solde et les frais, l\'application interroge des API publiques de tiers :\n• mempool.guide (explorateur de blockchain).\n• Si mempool.guide n\'est pas disponible, l\'app peut interroger deux miroirs communautaires compatibles Esplora (mempool.kilombino.com, mempool.maveth.ca). Cette option peut être désactivée dans les Réglages.\nÀ chaque requête, votre adresse IP et l\'adresse publique du portefeuille interrogé sont transmises. Les clés privées et la phrase de récupération ne sont JAMAIS transmises.\n\n3) AUCUN TRACEUR. Aucune analyse, aucune publicité, aucun cookie au sein de l\'application.\n\n4) DROITS (GDPR art. 13-14). Vous disposez des droits d\'accès, de rectification, d\'effacement et d\'opposition en écrivant au responsable du traitement : $holder — $email. Étant donné que nous ne conservons pas de données personnelles, ces droits sont déjà largement garantis par le fait que les données restent sur votre appareil.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'Pour signaler des vulnérabilités de sécurité, utilisez le signalement privé \"Report a vulnerability\" du dépôt GitHub (onglet Security) ou écrivez à :\n$email\n\nN\'ouvrez pas d\'issues publiques pour les problèmes de sécurité. Délai de réponse : 72 heures. Politique de divulgation : 90 jours.';
  }

  @override
  String get sendScreenSuccess => 'Transaction envoyée !';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID : $txid';
  }

  @override
  String get sendScreenValidateAddress => 'Saisissez une adresse';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Adresse non valide pour $network (utilisez $prefix)';
  }

  @override
  String get sendScreenValidateLength => 'Longueur d\'adresse non valide';

  @override
  String get sendScreenValidateSelf =>
      'Vous ne pouvez pas vous envoyer à vous-même';

  @override
  String get sendScreenValidateAmount => 'Saisissez un montant';

  @override
  String get sendScreenValidateInvalidAmount => 'Montant non valide';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Montant trop faible (minimum $dust satoshis / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Fonds insuffisants (solde : $balance, frais estimés : $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'Chargement des UTXOs...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'Impossible de charger les UTXOs : $error';
  }

  @override
  String get scanQrTitle => 'Scanner le QR code';

  @override
  String get scanQrError =>
      'Impossible d\'accéder à la caméra. Autorisez l\'accès et réessayez.';

  @override
  String get scanQrInvalid =>
      'Le code scanné n\'est pas une adresse Bitcoin valide.';

  @override
  String get scanQrInvalidInvoice =>
      'Le code scanné n\'est pas une facture Lightning valide.';

  @override
  String get scanQrTorch => 'Activer la lampe torche';

  @override
  String get sendConfirmTitle => 'Confirmer la transaction';

  @override
  String get sendConfirmWarning =>
      'Cette transaction est irréversible. Vérifiez les détails avant de confirmer.';

  @override
  String get sendConfirmSend => 'Confirmer et envoyer';

  @override
  String get importScreenTitle => 'Importer un portefeuille';

  @override
  String get importScreenHeading => 'Saisissez votre phrase de récupération';

  @override
  String get importScreenSubtitle =>
      'Saisissez la phrase mnémonique (12, 15, 18, 21 ou 24 mots) séparée par des espaces, puis choisissez le type de compte correspondant au portefeuille d\'origine.';

  @override
  String get importScriptTypeLabel => 'Type de compte';

  @override
  String get importScriptTypeNativeSegwit => 'SegWit natif (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'SegWit imbriqué (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Type de portefeuille à créer';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Les adresses commencent par $prefix';
  }

  @override
  String get importScreenHint => 'mot1 mot2 mot3 ...';

  @override
  String get importScreenValidateEmpty => 'Saisissez la phrase mnémonique.';

  @override
  String importScreenValidateCount(Object count) {
    return 'La phrase doit contenir 12, 15, 18, 21 ou 24 mots (détectés : $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Phrase mnémonique non valide. Vérifiez l\'orthographe.';

  @override
  String get importScreenImport => 'Importer';

  @override
  String get importModeSeed => 'Phrase de récupération';

  @override
  String get importModeWatchOnly => 'Lecture seule (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Surveillez un portefeuille externe (solde et historique) avec uniquement sa clé publique étendue. Aucune clé privée impliquée — l\'envoi n\'est jamais possible.';

  @override
  String get importWatchOnlyXpubLabel => 'Xpub du compte';

  @override
  String get importWatchOnlyXpubHint =>
      'Collez l\'xpub du compte (commence par \"xpub\"). Clés publiques uniquement : ne collez jamais un xprv.';

  @override
  String get importWatchOnlyValidateEmpty => 'Saisissez l\'xpub du compte.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'L\'xpub doit commencer par \"xpub\" (réseau principal).';

  @override
  String get watchOnlyBadge => 'Lecture seule';

  @override
  String get passwordDialogCreateTitle => 'Créer un mot de passe de sécurité';

  @override
  String get passwordDialogCreateHint => 'Saisissez un mot de passe sécurisé';

  @override
  String get passwordDialogCreateConfirm => 'Confirmer le mot de passe';

  @override
  String get passwordDialogCreate => 'Créer';

  @override
  String get passwordDialogCancel => 'Annuler';

  @override
  String get passwordDialogEnterTitle => 'Saisir le mot de passe';

  @override
  String get passwordDialogEnterHint => 'Saisissez votre mot de passe';

  @override
  String get passwordDialogEnter => 'Confirmer';

  @override
  String get passwordDialogWrong => 'Mot de passe incorrect';

  @override
  String get languageSelector => 'Langue';

  @override
  String get languageSelectorAuto => '🌐 Automatique (système)';

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
  String get walletDetailRefresh => 'Actualiser';

  @override
  String get walletDetailDeleteTitle => 'Supprimer le portefeuille ?';

  @override
  String get walletDetailDeleteConfirm => 'Supprimer définitivement';

  @override
  String get walletDetailDeleteWarning =>
      'Cette action est irréversible. Assurez-vous d\'avoir une sauvegarde de la phrase de récupération si des fonds se trouvent dans le portefeuille.';

  @override
  String get walletDetailInfo => 'Infos du portefeuille';

  @override
  String get walletDetailNameLabel => 'Nom du portefeuille';

  @override
  String get walletDetailNameHint => 'ex. Épargne Maison';

  @override
  String get walletDetailType => 'Type';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'SegWit imbriqué (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'MISE À JOUR...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TRANSACTIONS';
  }

  @override
  String get walletDetailReceiveQr => 'Recevoir du Bitcoin';

  @override
  String get walletDetailSignVerify => 'Signer/Vérifier un message';

  @override
  String get walletDetailShowAddresses => 'Afficher les adresses';

  @override
  String get walletDetailWalletAddress => 'Adresse du portefeuille';

  @override
  String get walletDetailExportSeed =>
      'Exporter/Sauvegarder la phrase de récupération';

  @override
  String get walletDetailShowSeedTitle => 'Afficher la phrase ?';

  @override
  String get walletDetailShowSeedContent =>
      'La phrase de récupération donne accès à tous les fonds. Assurez-vous d\'être dans un endroit sûr.';

  @override
  String get walletDetailShowSeedConfirm => 'Oui, afficher';

  @override
  String get walletDetailSeedVerifyPrompt =>
      'Voulez-vous vérifier que vous avez sauvegardé la phrase de récupération ?';

  @override
  String get walletDetailSeedVerifyYes => 'Oui, vérifier';

  @override
  String get walletDetailSeedVerifyNotNow => 'Pas maintenant';

  @override
  String get walletDetailSeedVerified => 'Sauvegarde vérifiée';

  @override
  String get walletDetailSeedHidden =>
      'Phrase masquée pour des raisons de sécurité';

  @override
  String get walletDetailSeedShowAgain => 'Afficher la phrase';

  @override
  String get walletDetailHideSeed => 'Masquer la phrase';

  @override
  String get walletDetailBackupNotConfirmed => 'Sauvegarde non confirmée';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'Vous n\'avez pas encore sauvegardé la phrase de récupération. Si vous perdez l\'appareil ou réinstallez l\'application, vous perdrez définitivement l\'accès à vos fonds.';

  @override
  String get walletDetailShowXpub => 'Afficher le XPUB du portefeuille';

  @override
  String get walletDetailDisplayHome => 'Afficher la valeur sur l’accueil';

  @override
  String get walletDetailUtxoRename => 'Renommer';

  @override
  String get walletDetailUtxoRenameTitle => 'Renommer l’UTXO';

  @override
  String get walletDetailSave => 'Enregistrer';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Créé';

  @override
  String get walletDetailClose => 'Fermer';

  @override
  String get walletDetailSign => 'Signer';

  @override
  String get walletDetailVerify => 'Vérifier';

  @override
  String get walletDetailSignMessage => 'Signer un message';

  @override
  String get walletDetailVerifyMessage => 'Vérifier un message';

  @override
  String get walletDetailMessage => 'Message';

  @override
  String get walletDetailBitcoinAddress => 'Adresse Bitcoin';

  @override
  String get walletDetailSignature => 'Signature (Base64)';

  @override
  String get walletDetailResult => 'Résultat :';

  @override
  String get walletDetailSignatureLabel => 'Signature :';

  @override
  String get walletDetailCopy => 'Copier';

  @override
  String get walletDetailAddressCopied =>
      'Adresse copiée dans le presse-papiers';

  @override
  String get walletDetailXpubTitle => 'XPUB du portefeuille';

  @override
  String get walletDetailXpubDesc =>
      'Ce XPUB permet de consulter toutes les adresses et soldes futurs mais ne peut pas dépenser les fonds.';

  @override
  String get walletDetailXpubCopied => 'XPUB copié';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Erreur de dérivation du XPUB : $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Erreur de dérivation des adresses : $error';
  }

  @override
  String get walletDetailValidSig => 'SIGNATURE VALIDE ✓';

  @override
  String get walletDetailInvalidSig => 'SIGNATURE INVALIDE ✗';

  @override
  String get donateTitle => 'Soutenir le projet ❤️';

  @override
  String get donatePhrase =>
      '☕ \"Si le projet vous est utile, offrez-nous un café virtuel\"';

  @override
  String get donateAddressLabel => 'Adresse Bitcoin de don :';

  @override
  String get donateCopy => 'Copier';

  @override
  String get donateCopied => 'Copié ! ✓';

  @override
  String get donateNote =>
      'Don volontaire : aucun service ni avantage n\'est fourni en échange. Tout montant est le bienvenu, même quelques satoshis. Merci ! 🧡';

  @override
  String get donateNoWalletTitle => 'Aucun portefeuille trouvé';

  @override
  String get donateNoWalletMessage =>
      'Aucune application de portefeuille Bitcoin n\'a été trouvée sur votre appareil. Vous pouvez toujours copier l\'adresse et la coller dans votre portefeuille préféré.';

  @override
  String get donateOpenWallet => 'Ouvrir dans le portefeuille';

  @override
  String get donateButton => 'Soutenir le projet ❤️';

  @override
  String get onboardingTitle => 'Bienvenue sur Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle =>
      'Portefeuille Bitcoin open-source. Auto-garde. Sans KYC.';

  @override
  String get onboardingResidenceLabel => 'Pays de résidence fiscale';

  @override
  String get onboardingResidenceHint => 'Sélectionnez votre pays';

  @override
  String get onboardingReverseSolicitation =>
      'Je déclare utiliser Btc Blake2b Wallet de ma propre initiative (\"reverse solicitation\") et résider fiscalement dans le pays sélectionné.';

  @override
  String get onboardingTermsAccept => 'J\'accepte les ';

  @override
  String get onboardingPrivacyAccept => 'J\'ai lu la ';

  @override
  String get onboardingAgeConfirm => 'Je déclare avoir au moins 16 ans';

  @override
  String get onboardingAgeSubtitle =>
      'Requis par l\'Art. 8 du RGPD pour le consentement au traitement des données';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingStepNext => 'Suivant';

  @override
  String get onboardingStepBack => 'Retour';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingTermsTitle => 'Conditions et confidentialité';

  @override
  String get onboardingValidationResidence =>
      'Sélectionnez votre pays de résidence fiscale';

  @override
  String get onboardingLinkTerms => 'Conditions d\'utilisation';

  @override
  String get onboardingLinkPrivacy => 'Politique de confidentialité';

  @override
  String get aboutTitle => 'À propos de Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet est un portefeuille Bitcoin open-source en auto-garde. Pas d\'inscription, pas de KYC, pas de suivi. Vos clés, vos bitcoins.';

  @override
  String get aboutLicenseTitle => 'Licence';

  @override
  String get aboutThirdPartyLicenses => 'Licences tierces';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'Voir la liste complète des licences open-source';

  @override
  String get aboutBuiltWith => 'Construit avec';

  @override
  String get aboutDisclaimer =>
      'Ce logiciel est fourni \"TEL QUEL\" sans garantie d\'aucune sorte.';

  @override
  String get explorerTitle => 'Explorateur';

  @override
  String get explorerAddressLabel => 'Adresse';

  @override
  String get explorerRefresh => 'Actualiser';

  @override
  String get explorerBalanceLabel => 'Solde';

  @override
  String get explorerTxCount => 'Nombre de transactions';

  @override
  String get explorerTipHeight => 'Hauteur du nœud';

  @override
  String get explorerErrorInvalidAddress =>
      'Adresse invalide. Vérifiez le format pour ce réseau.';

  @override
  String get explorerErrorRateLimited =>
      'Limite de requêtes dépassée. Réessayez dans une minute.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Service temporairement indisponible. Réessayez plus tard.';

  @override
  String get explorerErrorNotFound => 'Adresse ou transaction introuvable.';

  @override
  String get explorerErrorTimeout =>
      'Requête expirée. Vérifiez la connexion et réessayez.';

  @override
  String get explorerErrorNetwork =>
      'Réseau indisponible. Vérifiez la connexion.';

  @override
  String get explorerRetry => 'Réessayer';

  @override
  String explorerErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'Aucun nœud Lightning connecté';

  @override
  String get lightningDisconnectedBody =>
      'Connectez votre nœud Lightning blake2b pour envoyer et recevoir des paiements. L\'app ne détient jamais vos fonds ni vos clés.';

  @override
  String get lightningConnectButton => 'Connecter un nœud';

  @override
  String get lightningConnectTitle => 'Connecter le nœud Lightning';

  @override
  String get lightningConnectHint =>
      'Collez la chaîne de connexion (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Chaîne de connexion invalide';

  @override
  String get lightningConnectRecentNodes => 'Nœuds récents';

  @override
  String get lightningConnectInfo =>
      'Le nœud doit autoriser cette app (grant) : vérifiez le panneau de contrôle de votre nœud.';

  @override
  String get lightningConnecting => 'Connexion…';

  @override
  String get lightningConnected => 'Connecté';

  @override
  String get lightningDisconnect => 'Déconnecter';

  @override
  String get lightningBalance => 'Solde Lightning';

  @override
  String get lightningChannels => 'Canaux';

  @override
  String get lightningNoChannels => 'Aucun canal ouvert';

  @override
  String get lightningChannelPeer => 'Pair';

  @override
  String get lightningChannelCapacity => 'Capacité';

  @override
  String get lightningChannelLocal => 'Local';

  @override
  String get lightningChannelRemote => 'Distant';

  @override
  String get lightningOpenChannel => 'Ouvrir un canal';

  @override
  String get lightningOpenChannelNodeId => 'Node ID (pubkey)';

  @override
  String get lightningOpenChannelHost => 'Hôte (optionnel, ip:port)';

  @override
  String get lightningOpenChannelAmount => 'Montant (sat)';

  @override
  String get lightningOpenChannelPrivate => 'Canal privé';

  @override
  String get lightningChannelOpened => 'Ouverture du canal demandée';

  @override
  String get lightningCloseChannel => 'Fermer le canal';

  @override
  String get lightningCloseChannelForce => 'Fermeture forcée';

  @override
  String get lightningCloseChannelForceWarning =>
      'La fermeture forcée publie le dernier état du canal on-chain. Des frais et des délais peuvent s\'appliquer. Continuer ?';

  @override
  String get lightningReceive => 'Recevoir';

  @override
  String get lightningSend => 'Envoyer';

  @override
  String get lightningInvoiceAmount => 'Montant (sat)';

  @override
  String get lightningInvoiceDescription => 'Description (optionnelle)';

  @override
  String get lightningInvoiceCreate => 'Créer une facture';

  @override
  String get lightningInvoiceTitle => 'Facture Lightning';

  @override
  String get lightningPay => 'Payer la facture';

  @override
  String get lightningPayHint => 'Collez la facture (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Confirmer le paiement Lightning';

  @override
  String get lightningPayDialogBody => 'Payer cette facture ?';

  @override
  String get lightningPaySuccess => 'Paiement envoyé';

  @override
  String get lightningCopied => 'Copié';

  @override
  String get lightningErrorRestricted =>
      'Le nœud n\'a pas autorisé cette app. Créez un grant sur votre nœud pour cette connexion.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Erreur Lightning : $error';
  }

  @override
  String get lightningConfirm => 'Confirmer';

  @override
  String get lightningCancel => 'Annuler';

  @override
  String get lightningNodeOnchain => 'On-chain du nœud';

  @override
  String get lightningDeposit => 'Déposer';

  @override
  String get lightningWithdraw => 'Envoyer on-chain';

  @override
  String get lightningDepositTitle => 'Dépôt on-chain';

  @override
  String get lightningDepositHint =>
      'Envoyez des fonds blake2b à cette adresse du nœud.';

  @override
  String get lightningDepositNewAddress => 'Nouvelle adresse';

  @override
  String get lightningDepositWarning =>
      'Envoyez uniquement sur le réseau blake2b. Les fonds envoyés sur le mauvais réseau sont perdus.';

  @override
  String get lightningOnchainSendTitle => 'Envoi on-chain';

  @override
  String get lightningOnchainAddressLabel => 'Adresse du destinataire';

  @override
  String get lightningOnchainAmountLabel => 'Montant (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Frais réseau';

  @override
  String get lightningOnchainFeeMin => 'Minimale';

  @override
  String get lightningOnchainFeeEconomical => 'Économique';

  @override
  String get lightningOnchainFeePriority => 'Prioritaire';

  @override
  String get lightningOnchainConfirm => 'Confirmer envoi';

  @override
  String get lightningOnchainConfirmTitle => 'Confirmer envoi on-chain ?';

  @override
  String get lightningOnchainWarning =>
      'Opération irréversible : les fonds quitteront le nœud.';

  @override
  String get lightningOnchainSuccess => 'Transaction envoyée';

  @override
  String get lightningOnchainInvalidAddress => 'Adresse blake2b non valide';

  @override
  String get lightningOnchainInsufficient => 'Fonds on-chain insuffisants';

  @override
  String get lightningFeesUnavailable =>
      'Estimations de frais indisponibles : le nœud choisira les frais';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey ou pubkey@host:port (onion nécessite Tor sur le nœud)';

  @override
  String get lightningOpenChannelInvalid =>
      'Node ID ou hôte non valide (66 hex, host:port)';

  @override
  String get lightningActivityDetected => 'Activité détectée sur le nœud';

  @override
  String get lightningPeers => 'Pairs';

  @override
  String get lightningPeersEmpty => 'Aucun pair connecté';

  @override
  String get lightningConnectPeer => 'Connecter un pair';

  @override
  String get lightningDisconnectPeer => 'Déconnecter';

  @override
  String get lightningPeerDisconnected => 'Déconnecté';

  @override
  String get lightningPeerId => 'ID du pair';

  @override
  String get lightningPeerAddresses => 'Adresses';

  @override
  String get lightningDisconnectPeerConfirm =>
      'Déconnecter ce pair ? Les canaux ouverts restent actifs.';

  @override
  String get lightningChannelDetail => 'Détails du canal';

  @override
  String get lightningChannelShortId => 'Short channel ID';

  @override
  String get lightningChannelState => 'État du nœud';

  @override
  String get lightningChannelFee => 'Frais';

  @override
  String get lightningChannelSpendable => 'Dépensable';

  @override
  String get lightningChannelReceivable => 'Recevable';

  @override
  String get lightningChannelHtlcs => 'HTLC';

  @override
  String get lightningChannelFundingTxid => 'Txid de funding';

  @override
  String get lightningNodeManagement => 'Gestion du nœud';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers pairs · $channels canaux';
  }

  @override
  String get lightningNodeIdentity => 'Identité du nœud';

  @override
  String get lightningNodePubkey => 'Clé publique';

  @override
  String get lightningNodeVersion => 'Version';

  @override
  String get lightningNodePeersCount => 'Pairs';

  @override
  String get lightningNodeChannelsActive => 'Canaux actifs';

  @override
  String get lightningNodeChannelsPending => 'Canaux en attente';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'Non disponible sur ce nœud : pour annoncer des conditions de lease, le plugin liquidity-ads est requis.';

  @override
  String get lightningLiquidity => 'Liquidité';

  @override
  String get lightningLiquidityTotal => 'Capacité totale';

  @override
  String get lightningLiquidityOutbound => 'Sortante';

  @override
  String get lightningLiquidityInbound => 'Entrante';

  @override
  String get lightningLiquidityWarning =>
      'Aucune liquidité entrante : impossible de recevoir tant qu\'un pair n\'a pas ouvert de canal vers ce nœud.';

  @override
  String get lightningMovements => 'Mouvements';

  @override
  String get lightningMovementsEmpty => 'Aucun mouvement';

  @override
  String get lightningMovementsAll => 'Tous les mouvements';

  @override
  String get lightningMovementsLoadMore => 'Charger plus';

  @override
  String get lightningMovementDeposit => 'Dépôt on-chain';

  @override
  String get lightningMovementWithdrawal => 'Envoi on-chain';

  @override
  String get lightningMovementChannelOpen => 'Ouverture de canal';

  @override
  String get lightningMovementChannelClose => 'Fermeture de canal';

  @override
  String get lightningMovementInvoice => 'Paiement Lightning';

  @override
  String get lightningMovementOnchainFee => 'Frais on-chain';

  @override
  String get lightningMovementForward => 'Routage';

  @override
  String get lightningMovementOther => 'Mouvement';

  @override
  String lightningChannelsAll(int count) {
    return 'Tous les canaux ($count)';
  }

  @override
  String get lightningOnchainNode => 'On-chain du nœud';

  @override
  String get lightningOnchainBalance => 'Solde on-chain';

  @override
  String get lightningOnchainConfirmed => 'Confirmés';

  @override
  String get lightningOnchainPending => 'En attente';

  @override
  String get lightningOnchainUtxos => 'UTXO';

  @override
  String get lightningOnchainUtxosEmpty => 'Aucun UTXO';

  @override
  String get lightningOnchainAddresses => 'Adresses du nœud';

  @override
  String get lightningOnchainNewAddress => 'Nouvelle adresse';

  @override
  String get lightningOnchainAddressType => 'Type d adresse';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'Avec solde';

  @override
  String get lightningOnchainReserved => 'Réservé';

  @override
  String get lightningOnchainBlockHeight => 'Bloc';

  @override
  String get lightningPayments => 'Paiements';

  @override
  String get lightningInvoices => 'Factures';

  @override
  String get lightningInvoicesEmpty => 'Aucune facture';

  @override
  String get lightningInvoiceStatusPaid => 'Payée';

  @override
  String get lightningInvoiceStatusPending => 'En attente de paiement';

  @override
  String get lightningInvoiceStatusExpired => 'Expirée';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Payée le $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get lightningReceivePaid => 'Facture payée';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total factures · $pending en attente';
  }

  @override
  String get lightningPays => 'Paiements envoyés';

  @override
  String get lightningPaysEmpty => 'Aucun paiement';

  @override
  String get lightningPaymentFee => 'Frais';

  @override
  String get lightningPaymentCompleted => 'Terminé';

  @override
  String get lightningPaymentPending => 'En cours';

  @override
  String get lightningPaymentFailed => 'Échoué';

  @override
  String get lightningHtlcsEmpty => 'Aucun HTLC';

  @override
  String get lightningHtlcInProgress => 'En vol';

  @override
  String get lightningHtlcIncoming => 'Entrant';

  @override
  String get lightningHtlcOutgoing => 'Sortant';

  @override
  String get lightningChannelFees => 'Frais de routage';

  @override
  String get lightningFeeEdit => 'Modifier les frais';

  @override
  String get lightningFeeBefore => 'Actuels';

  @override
  String get lightningFeeAfter => 'Nouveaux';

  @override
  String get lightningFeeBaseLabel => 'Base (sat)';

  @override
  String get lightningFeePpmLabel => 'Taux (ppm)';

  @override
  String get lightningHtlcMinLabel => 'HTLC min (sat)';

  @override
  String get lightningHtlcMaxLabel => 'HTLC max (sat)';

  @override
  String get lightningCltvLabel => 'Delta CLTV';

  @override
  String get lightningChannelReserve => 'Notre réserve';

  @override
  String get lightningChannelToSelfDelay => 'Délai to-self';

  @override
  String get lightningFeeConfirmTitle => 'Appliquer ces frais de routage ?';

  @override
  String get lightningFeeWarning =>
      'Les frais concernent les paiements routés. Le réseau accepte peu de changements par jour et les pairs peuvent tarder à les adopter.';

  @override
  String get lightningFeeUpdated => 'Politique de frais mise à jour';

  @override
  String get lightningDiagnostics => 'Diagnostic';

  @override
  String get lightningDiagnosticsSubtitle => 'Comptabilité, plugins et routage';

  @override
  String get lightningStatsEconomy => 'Économie';

  @override
  String get lightningStatsNet => 'Net';

  @override
  String get lightningStatsSource =>
      'D\'après la comptabilité du nœud (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'Pas encore de données comptables';

  @override
  String get lightningStatsTagDeposit => 'Dépôts';

  @override
  String get lightningStatsTagInvoice => 'Factures';

  @override
  String get lightningStatsTagWithdrawal => 'Retraits';

  @override
  String get lightningStatsTagOnchainFee => 'Frais on-chain';

  @override
  String get lightningStatsTagChannelOpen => 'Ouvertures de canaux';

  @override
  String get lightningStatsTagChannelClose => 'Fermetures de canaux';

  @override
  String get lightningStatsTagRouted => 'Frais de routage gagnés';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écritures',
      one: '1 écriture',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Plugins';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count actifs';
  }

  @override
  String get lightningPluginInactive => 'inactif';

  @override
  String get lightningForwardsTitle => 'Routage';

  @override
  String get lightningForwardsEmpty => 'Aucun paiement routé';

  @override
  String get lightningForwardSettled => 'Réglé';

  @override
  String get lightningForwardFailed => 'Échoué';

  @override
  String get lightningForwardOffered => 'En cours';

  @override
  String get lightningKeysendTitle => 'Envoyer à un nœud (keysend)';

  @override
  String get lightningKeysendHint => 'Pubkey du nœud destinataire (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Montant (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Frais max (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Laisser vide pour le défaut du nœud (0,5 %)';

  @override
  String get lightningKeysendWarning =>
      'Keysend paie un nœud sans facture : les fonds partent immédiatement et ne peuvent pas être annulés.';

  @override
  String get lightningKeysendConfirmTitle => 'Envoyer ce paiement keysend ?';

  @override
  String get lightningKeysendDestination => 'Destination';

  @override
  String get lightningKeysendSent => 'Keysend envoyé';

  @override
  String get lightningKeysendInvalidPubkey => 'Pubkey de nœud invalide';

  @override
  String get lightningKeysendInvalidAmount =>
      'Saisissez un montant supérieur à zéro';

  @override
  String get lightningKeysendSend => 'Envoyer';

  @override
  String get walletAddressesTitle => 'Adresses et UTXO';

  @override
  String get walletAddressesTabAddresses => 'Adresses';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Réception (/0)';

  @override
  String get walletAddressesChangeBranch => 'Monnaie (/1)';

  @override
  String get walletAddressesStatusUnused => 'Jamais utilisée';

  @override
  String get walletAddressesStatusUsed => 'Utilisée';

  @override
  String get walletAddressesStatusFunds => 'Avec solde';

  @override
  String walletAddressesTxCount(int count) {
    return '$count transactions';
  }

  @override
  String get walletAddressesEmpty => 'Aucune adresse à afficher';

  @override
  String get walletAddressesHintTap => 'Touchez une adresse pour la copier';

  @override
  String get lightningPeeringGateTitle =>
      'Peering limité aux versions avec bit 68';

  @override
  String get lightningPeeringGateBody =>
      'Ce nœud exige option_blake2b (bit 68) lors de la poignée de main : les nœuds sur des versions antérieures ne peuvent pas se connecter. C\'est un choix du nœud, pas un problème de l\'app ni du bridge. Utilisez des pairs en version .4 ou ultérieure, ou attendez que la communauté rende le bit optionnel.';

  @override
  String get lightningPeeringGateLink => 'Matrice de compatibilité';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count pairs enregistrés, aucun connecté';
  }

  @override
  String get lightningSwapOpen => 'Payer une facture sans nœud (swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'Application web : les paiements Lightning passent par un fournisseur de swap (aucun nœud requis). La connexion de votre propre nœud est disponible dans l\'application Android.';

  @override
  String get lightningSwapTitle => 'Paiement Lightning via fournisseur';

  @override
  String get lightningSwapIntro =>
      'Les fonds restent sous votre garde : ils vont dans un HTLC on-chain (P2WSH) et ne sont libérés que lorsque le fournisseur paie votre facture. Si le paiement échoue, vous pouvez récupérer les fonds après le time lock.';

  @override
  String get lightningSwapProviderUriHint =>
      'URI du fournisseur (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Connecter le fournisseur';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Fournisseur connecté : $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Déconnecter';

  @override
  String get lightningSwapInvoiceHint => 'Facture Lightning (lnbc...)';

  @override
  String get lightningSwapStart => 'Continuer';

  @override
  String get lightningSwapAmount => 'Montant de la facture';

  @override
  String get lightningSwapFees => 'Frais (claim + service)';

  @override
  String get lightningSwapTotal => 'Total à bloquer';

  @override
  String get lightningSwapFund => 'Envoyer les fonds et démarrer le swap';

  @override
  String get lightningSwapFundHint =>
      'Les fonds vont à l\'adresse HTLC ci-dessus. Le paiement démarre après 1 confirmation.';

  @override
  String get lightningSwapStateLabel => 'Statut';

  @override
  String get lightningSwapHtlc => 'Adresse HTLC';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund disponible à partir du bloc $height';
  }

  @override
  String get swapStateAwaitingFunding => 'En attente des fonds on-chain';

  @override
  String get swapStateConfirming => 'En attente des confirmations';

  @override
  String get swapStatePaying => 'Paiement Lightning en cours';

  @override
  String get swapStatePaid => 'Facture payée, claim en cours';

  @override
  String get swapStateClaiming => 'Claim en cours';

  @override
  String get swapStateCompleted => 'Terminé';

  @override
  String get swapStatePaymentFailed => 'Paiement échoué — fonds récupérables';

  @override
  String get swapStateExpired => 'Expiré — fonds récupérables';

  @override
  String get swapStateRefunded => 'Remboursé';

  @override
  String get lightningSwapRecoveryTitle => 'Récupération des fonds';

  @override
  String get lightningSwapRecoveryHint =>
      'Blob de récupération (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Importer la session';

  @override
  String get lightningSwapRefund => 'Récupérer les fonds (refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Remboursement pas encore disponible : ouvrira à partir du bloc $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Copier le blob de récupération';

  @override
  String get lightningSwapBlobCopied => 'Blob de récupération copié';

  @override
  String get lightningSwapClaimTxid => 'Txid du claim';

  @override
  String get lightningSwapClaimHint =>
      'Le claim est une transaction on-chain : la confirmation arrive au bloc suivant (~12 min). Touchez le lien pour la vérifier.';

  @override
  String get lightningSwapInvalidInvoice =>
      'Cela ne ressemble pas à une facture Lightning';

  @override
  String get lightningSwapWatchOnly =>
      'Le swap nécessite un portefeuille avec seed (pas watch-only)';

  @override
  String get lightningSwapNoUtxos =>
      'Aucun fonds dépensable dans ce portefeuille';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Erreur : $message';
  }

  @override
  String get lightningSwapKnownUris => 'URI de fournisseur enregistrées';

  @override
  String get lightningSwapWalletLabel => 'Portefeuille';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Solde : $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Fonds insuffisants : $needed sat requis, $available sat disponibles';
  }

  @override
  String get lightningSwapCancel => 'Annuler le swap';

  @override
  String get lightningSwapErrorConnectFailed =>
      'Fournisseur injoignable. Vérifiez votre connexion et réessayez.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Connexion au fournisseur perdue. Réessayez de vous connecter.';

  @override
  String get lightningSwapErrorNotConnected => 'Fournisseur non connecté.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'Ce fournisseur utilise un relais inaccessible depuis la version web. Utilisez la version mobile sur votre téléphone pour payer avec ce fournisseur.';

  @override
  String get lightningSwapCancelTitle => 'Annuler ce swap ?';

  @override
  String get lightningSwapCancelBody =>
      'L\'app oubliera ce swap. Le fournisseur l\'abandonne de lui-même avant l\'échéance et aucun fonds n\'est verrouillé. Pour réessayer avec la même facture, il faut une nouvelle session seulement après expiration — sinon générez une nouvelle facture.';

  @override
  String get lightningSwapCancelConfirm => 'Oui, annuler';

  @override
  String get lightningSwapWalletMissing =>
      'Le portefeuille lié à ce swap n\'est plus disponible';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Portefeuille lié : $name';
  }

  @override
  String get lightningInvoiceDelete => 'Supprimer la facture';

  @override
  String get lightningInvoiceDeleteTitle => 'Supprimer cette facture ?';

  @override
  String get lightningInvoiceDeleteBody =>
      'La facture sera retirée du nœud. Si elle n\'est pas payée, elle ne pourra plus l\'être.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Oui, supprimer';

  @override
  String get lightningInvoiceDeleted => 'Facture supprimée';

  @override
  String get lightningChannelPeerAddress => 'Adresse du pair';
}
