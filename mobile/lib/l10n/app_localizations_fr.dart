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
  String get appErrorTitle => 'Impossible de démarrer l\'application';

  @override
  String get appReload => 'Recharger la page';

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
  String get homeReceiveWallet => 'Recevoir';

  @override
  String get homeMultiTransfer => 'Multi-envoi';

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
  String homeDeleteMultiError(Object message) {
    return '$message';
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
  String get homeMoreOptions => 'Plus d\'options';

  @override
  String homeCreated(Object date) {
    return 'Créé : $date';
  }

  @override
  String homeLastTransfer(Object date) {
    return 'Dernier transfert : $date';
  }

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
  String get walletDetailNoConnection => 'Pas de connexion';

  @override
  String get walletDetailTransferSuccess =>
      'Portefeuille transféré avec succès. La graine locale a été supprimée.';

  @override
  String walletDetailTransferError(Object error) {
    return 'Erreur de transfert : $error';
  }

  @override
  String get walletDetailSeedCopied =>
      'Phrase de graine copiée. Sera supprimée après 60 s.';

  @override
  String get walletDetailSeedWarning =>
      'Conservez-la en lieu sûr ! C\'est le SEUL moyen de récupérer vos fonds.';

  @override
  String get walletDetailAddress => 'Adresse';

  @override
  String get walletDetailName => 'Nom';

  @override
  String get walletDetailBalance => 'Solde';

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
  String get walletDetailTxFee => 'Frais';

  @override
  String get walletDetailTxIncoming => 'Reçus';

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
  String get themeToggle => 'Changer de thème';

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
  String get walletDetailTransfer => 'Transférer';

  @override
  String get walletDetailTransferred => 'TRANSFÉRÉ';

  @override
  String get walletDetailPending => 'TRANSFERT EN ATTENTE';

  @override
  String get walletDetailNoName => 'Portefeuille sans nom';

  @override
  String get walletDetailTransferredDesc =>
      'Ce portefeuille a été transféré. Mode lecture seule.';

  @override
  String get sendScreenTitle => 'Envoyer BTC';

  @override
  String get sendScreenAddressLabel => 'Adresse du destinataire';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => 'Montant (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

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
  String get walletDetailFirst100Addresses => '100 premières adresses';

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
      'La phrase de graine se compose de 12 mots séparés par des espaces. Vous pouvez la coller directement.';

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
    return 'Cette politique de confidentialité est provisoire et sera remplacée par la version définitive publiée sur le site officiel lorsqu\'elle sera disponible.\n\n1) DONNÉES SUR L\'APPAREIL. L\'application n\'exige pas de compte et n\'enregistre pas de données personnelles sur les serveurs de l\'auteur. La phrase de récupération chiffrée (AES-256-GCM), les préférences et les consentements restent UNIQUEMENT sur votre appareil.\n\n2) DONNÉES TRANSMISES À DES TIERS POUR LE FONCTIONNEMENT. Pour afficher le solde et les frais, l\'application interroge des API publiques de tiers :\n• mempool.guide (explorateur de blockchain).\nÀ chaque requête, votre adresse IP et l\'adresse publique du portefeuille interrogé sont transmises. Les clés privées et la phrase de récupération ne sont JAMAIS transmises.\n\n3) AUCUN TRACEUR. Aucune analyse, aucune publicité, aucun cookie au sein de l\'application.\n\n4) DROITS (GDPR art. 13-14). Vous disposez des droits d\'accès, de rectification, d\'effacement et d\'opposition en écrivant au responsable du traitement : $holder — $email. Étant donné que nous ne conservons pas de données personnelles, ces droits sont déjà largement garantis par le fait que les données restent sur votre appareil.';
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
  String sendScreenError(Object error) {
    return 'Erreur d\'envoi : $error';
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
  String get importScreenHeading => 'Saisissez les 12 mots';

  @override
  String get importScreenSubtitle =>
      'Saisissez la phrase mnémonique de 12 mots séparés par des espaces, puis choisissez le type de compte correspondant au portefeuille d\'origine.';

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
    return 'La phrase doit contenir exactement 12 mots (détectés : $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Phrase mnémonique non valide. Vérifiez l\'orthographe.';

  @override
  String get importScreenImporting => 'Importation en cours...';

  @override
  String get importScreenImport => 'Importer';

  @override
  String importScreenError(Object error) {
    return 'Erreur d\'importation : $error';
  }

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
  String get transferScreenTitle => 'Transférer le portefeuille';

  @override
  String get transferScreenScanning => 'Scannez le code QR du destinataire.';

  @override
  String get transferScreenProcessing =>
      'Traitement et chiffrement des données...';

  @override
  String transferScreenScanError(Object error) {
    return 'Erreur de scan ou de chiffrement : $error';
  }

  @override
  String get transferScreenNearbyTitle => 'Scanner pour recevoir';

  @override
  String get transferScreenNearbySubtitle =>
      'Faites scanner ce code QR au destinataire.';

  @override
  String transferScreenNearbyCode(Object code) {
    return 'Code manuel : $code';
  }

  @override
  String get transferScreenNearbyCancel => 'Annuler';

  @override
  String get transferScreenNearbySuccess =>
      'Portefeuille transféré avec succès via Bluetooth. Graine locale supprimée.';

  @override
  String transferScreenNearbyError(Object error) {
    return 'Erreur de transfert : $error';
  }

  @override
  String get transferScreenWebRtcConnecting =>
      'Démarrage de la connexion WebRTC...';

  @override
  String get transferScreenWebRtcTransferring => 'Transfert via WebRTC...';

  @override
  String get transferScreenTransferComplete => 'Transfert terminé !';

  @override
  String get transferScreenMethodTitle => 'Choisir la méthode de transfert';

  @override
  String get transferScreenMethodQr => 'Code QR (2 phases)';

  @override
  String get transferScreenMethodQrDesc =>
      'Scannez le QR du destinataire, puis générez un QR avec la graine chiffrée.';

  @override
  String get transferScreenMethodNearby => 'Bluetooth P2P';

  @override
  String get transferScreenMethodNearbyDesc =>
      'Transfert direct entre appareils. Nécessite Bluetooth.';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC (Internet)';

  @override
  String get transferScreenMethodWebRtcDesc =>
      'P2P via navigateur. Nécessite Internet sur les deux appareils.';

  @override
  String get transferScreenWebRtcQrDescription =>
      'Le destinataire doit scanner ce QR. Le transfert se fera via WebRTC (aucune limite de taille).';

  @override
  String get transferScreenEncryptedQrDescription =>
      'Montrez ce QR code à l\'appareil récepteur. Une fois scanné et la réception terminée, le portefeuille sera automatiquement supprimé de cet appareil.';

  @override
  String get transferScreenWebRtcTimeout =>
      'Connexion WebRTC échouée après 30 secondes. Réessayez ou utilisez la méthode QR code en 2 phases.';

  @override
  String get receiveScreenTitle => 'Recevoir un portefeuille';

  @override
  String get receiveScreenInit => 'Initialisation de la clé asymétrique...';

  @override
  String get receiveScreenShowQr => 'Montrez ce code QR à l\'expéditeur.';

  @override
  String get receiveScreenScanSender =>
      'Scannez le code QR sur l\'appareil de l\'expéditeur.';

  @override
  String get receiveScreenAutoDetectMethod =>
      'Le système détecte automatiquement la méthode de transfert utilisée par l\'expéditeur.';

  @override
  String receiveScreenKeyError(Object error) {
    return 'Erreur de génération de clé : $error';
  }

  @override
  String get receiveScreenDecrypting =>
      'Données reçues. Déchiffrement et validation serveur...';

  @override
  String get receiveScreenSuccess =>
      'Portefeuille reçu et importé avec succès.';

  @override
  String get receiveScreenQrSuccess => 'Portefeuille reçu via code QR.';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return 'Code $code lu. Connexion en cours...';
  }

  @override
  String get receiveScreenNearbySuccess =>
      'Portefeuille reçu via Bluetooth P2P.';

  @override
  String receiveScreenError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'Salle WebRTC';

  @override
  String get receiveScreenWebRtcConnect => 'Se connecter à la salle';

  @override
  String get receiveScreenWebRtcShareQr => 'Partager ce QR avec l\'expéditeur';

  @override
  String get receiveScreenWebRtcScanQr =>
      'Scanner le QR de la salle de l\'expéditeur';

  @override
  String get receiveScreenWebRtcWait =>
      'En attente de connexion de l\'expéditeur...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return 'ID de salle : $roomId';
  }

  @override
  String get passwordDialogCreateTitle => 'Créer un mot de passe de sécurité';

  @override
  String get passwordDialogCreateContent =>
      'Définissez un mot de passe pour protéger les opérations sensibles sur ce navigateur.';

  @override
  String get passwordDialogCreateHint => 'Saisissez un mot de passe sécurisé';

  @override
  String get passwordDialogCreateConfirm => 'Confirmer le mot de passe';

  @override
  String get passwordDialogCreateConfirmHint =>
      'Saisissez à nouveau le mot de passe';

  @override
  String get passwordDialogCreateMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get passwordDialogCreateTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get passwordDialogCreate => 'Créer';

  @override
  String get passwordDialogCancel => 'Annuler';

  @override
  String get passwordDialogEnterTitle => 'Saisir le mot de passe';

  @override
  String get passwordDialogEnterContent =>
      'Saisissez votre mot de passe de sécurité pour continuer.';

  @override
  String get passwordDialogEnterHint => 'Saisissez votre mot de passe';

  @override
  String get passwordDialogEnter => 'Confirmer';

  @override
  String get passwordDialogWrong => 'Mot de passe incorrect';

  @override
  String get languageSelector => 'Langue';

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
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

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
  String get walletDetailTransferredOn => 'Transféré le';

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
  String get walletDetailFirst100 => '100 premières adresses';

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
  String get multiTransferTitle => 'Envoi Multi-Portefeuille';

  @override
  String get multiTransferSelectWallets =>
      'Sélectionner les portefeuilles à envoyer';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portefeuilles sélectionnés',
      one: '1 portefeuille sélectionné',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return 'Valeur totale : $amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => 'Méthode de transfert :';

  @override
  String multiTransferMethodWebRtc(Object max) {
    return 'WebRTC (max. $max)';
  }

  @override
  String multiTransferMethodBluetooth(Object max) {
    return 'Bluetooth (max. $max)';
  }

  @override
  String multiTransferMethodQr(Object max) {
    return 'Code QR 2 phases (max. $max)';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count portefeuilles',
      one: 'Envoyer 1 portefeuille',
    );
    return '$_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => 'Envoi en cours...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return 'Portefeuille $current sur $total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portefeuilles envoyés avec succès',
      one: '1 portefeuille envoyé avec succès',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success envoyés, $failed échoués';
  }

  @override
  String get multiTransferNoLockedWallets =>
      'Aucun portefeuille disponible pour le transfert. Seuls les portefeuilles verrouillés peuvent être transférés.';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return 'Vous avez sélectionné $selected portefeuilles. Le maximum pour $method est de $max.';
  }

  @override
  String get multiTransferReceivingTitle => 'Réception Multi-Portefeuille';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return '$received portefeuilles reçus sur $total';
  }

  @override
  String get multiTransferMethodUnavailable =>
      'Non disponible sur cette plateforme';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return 'Envoi du portefeuille $current sur $total...';
  }

  @override
  String get multiTransferPreparing => 'Préparation du portefeuille...';

  @override
  String get multiTransferWaitingReceiver => 'En attente du destinataire...';

  @override
  String get multiTransferCompleted => 'Terminé';

  @override
  String get multiTransferFailed => 'Échoué';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return 'Transfert manuel en 2 phases par code QR. Max. $max portefeuilles.';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return 'Transfert P2P rapide via internet. Max. $max portefeuilles.';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return 'Transfert direct entre appareils. Max. $max portefeuilles.';
  }

  @override
  String get multiTransferNoBalance => 'Solde non disponible';

  @override
  String get multiTransferConfirmTitle => 'Confirmer l\'envoi';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portefeuilles',
      one: '1 portefeuille',
    );
    return 'Vous allez envoyer $_temp0 pour un total de $amount $ticker. Continuer ?';
  }

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
  String get onboardingValidationCheckbox =>
      'Vous devez accepter toutes les déclarations';

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
}
