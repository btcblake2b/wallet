// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get appErrorTitle => 'Impossibile avviare l\'app';

  @override
  String get appReload => 'Ricarica la pagina';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'Nessuna connessione';

  @override
  String get homeNoConnectionCreate =>
      'Impossibile creare il wallet senza una connessione a internet attiva. La creazione richiede di verificare l\'indirizzo sulla rete. Riprova quando la connessione sarà ristabilita.';

  @override
  String get homeNoConnectionImport =>
      'Impossibile importare il wallet senza una connessione a internet attiva. Il wallet deve essere registrato sul server.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Wallet creato con successo.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Errore creazione wallet: $error';
  }

  @override
  String get homeImportWallet => 'Importa wallet';

  @override
  String get homeCreateWallet => 'Crea wallet';

  @override
  String get homeReceiveWallet => 'Ricevi';

  @override
  String get homeMultiTransfer => 'Multi-invio';

  @override
  String get homeSelected => 'selezionati';

  @override
  String get homeDeleteSelected => 'Elimina selezionati';

  @override
  String homeDeleteConfirm(int count) {
    return 'Eliminare $count wallet? L\'operazione è irreversibile.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count wallet eliminati con successo.';
  }

  @override
  String homeDeleteMultiError(Object message) {
    return '$message';
  }

  @override
  String get homeWalletImported => 'Wallet importato con successo.';

  @override
  String get homeSecurityWarning =>
      'Questo software è fornito \"così com\'è\" senza alcuna garanzia. Il produttore non è responsabile per perdite di fondi, furti, hacking, errori di transazione o qualsiasi danno derivante dall\'uso dell\'app. Il wallet non garantisce protezione contro copie precedenti della seed. Usare solo per piccoli importi.';

  @override
  String get homeDisclaimerAccept => 'Accetto';

  @override
  String get legalInfoTitle => 'Info legali';

  @override
  String get homeLocalWallets => 'Wallet locali';

  @override
  String homeErrorLoading(Object error) {
    return 'Errore caricamento wallet: $error';
  }

  @override
  String get homeEmptyTitle => 'Nessun wallet';

  @override
  String get homeEmptySubtitle =>
      'Crea il tuo primo wallet Bitcoin per iniziare.';

  @override
  String get homeBalanceTitle => 'BILANCIO ATTIVO';

  @override
  String get balanceUnavailable => 'Saldo non disponibile';

  @override
  String get homeBackupVerified => 'Backup verificato';

  @override
  String get homeBackupNotVerified => 'Backup non verificato';

  @override
  String get homeMoreOptions => 'Altre opzioni';

  @override
  String homeCreated(Object date) {
    return 'Creato: $date';
  }

  @override
  String homeLastTransfer(Object date) {
    return 'Ultimo trasferimento: $date';
  }

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Wallet $name$balance';
  }

  @override
  String get walletDetailTitle => 'Portafoglio';

  @override
  String walletDetailCopied(Object label) {
    return '$label copiato. Verrà rimosso tra 60s.';
  }

  @override
  String get walletDetailNoConnection => 'Nessuna connessione';

  @override
  String get walletDetailTransferSuccess =>
      'Wallet trasferito con successo. Il seed locale è stato cancellato.';

  @override
  String walletDetailTransferError(Object error) {
    return 'Errore trasferimento: $error';
  }

  @override
  String get walletDetailSeedCopied =>
      'Seed phrase copiata. Verrà rimossa tra 60s.';

  @override
  String get walletDetailSeedWarning =>
      'Conservala al sicuro! È l\'UNICO modo per recuperare i tuoi fondi.';

  @override
  String get walletDetailAddress => 'Indirizzo';

  @override
  String get walletDetailName => 'Nome';

  @override
  String get walletDetailBalance => 'Saldo';

  @override
  String get walletDetailTransactions => 'Transazioni';

  @override
  String get walletDetailTxBlockHeight => 'Altezza blocco';

  @override
  String get walletDetailTxConfirmations => 'Conferme';

  @override
  String get walletDetailTxDate => 'Data';

  @override
  String get walletDetailTxDetails => 'Dettagli transazione';

  @override
  String get walletDetailTxEmpty => 'Nessuna transazione';

  @override
  String get walletDetailTxError => 'Impossibile caricare le transazioni';

  @override
  String get walletDetailTxFee => 'Fee';

  @override
  String get walletDetailTxIncoming => 'Ricevuti';

  @override
  String get walletDetailTxOrphan => 'Orfana (blocco perso)';

  @override
  String get walletDetailTxOutgoing => 'Inviati';

  @override
  String get walletDetailTxPending => 'In attesa di conferma';

  @override
  String get walletDetailTxReplaced => 'Sostituita (espulsa dal mempool)';

  @override
  String get walletDetailTxRetry => 'Riprova';

  @override
  String get themeToggle => 'Cambia tema';

  @override
  String get backupSeedTitle => 'Backup della seed';

  @override
  String get backupSeedIntro =>
      'Scrivi la seed phrase su carta e conservala in un luogo sicuro. È il solo modo per recuperare i fondi.';

  @override
  String get backupSeedStart => 'Inizia il backup';

  @override
  String get backupSeedLater => 'Più tardi';

  @override
  String get backupSeedSavedContinue => 'Ho salvato la seed';

  @override
  String get backupSeedVerifyTitle => 'Verifica il backup';

  @override
  String get backupSeedVerifyHint =>
      'Inserisci le 3 parole evidenziate per confermare di averle salvate.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Parola $number';
  }

  @override
  String get backupSeedVerifyError => 'Parole non corrette. Riprova.';

  @override
  String get backupSeedDone => 'Backup completato';

  @override
  String get backupSeedDoneDesc =>
      'La tua seed è al sicuro. Ricorda: chi possiede la seed controlla i fondi.';

  @override
  String get backupSeedFinish => 'Fine';

  @override
  String get backupSeedSkipWarning =>
      'Se salti, rischi di perdere i fondi se perdi questo dispositivo. Puoi farlo in seguito dal dettaglio wallet.';

  @override
  String get walletDetailSend => 'Invia';

  @override
  String get walletDetailReceive => 'Ricevi';

  @override
  String get walletDetailTransfer => 'Trasferisci';

  @override
  String get walletDetailTransferred => 'TRASFERITO';

  @override
  String get walletDetailPending => 'TRASFERIMENTO IN SOSPESO';

  @override
  String get walletDetailNoName => 'Wallet senza nome';

  @override
  String get walletDetailTransferredDesc =>
      'Questo wallet è stato trasferito. Modalità sola lettura.';

  @override
  String get sendScreenTitle => 'Invia BTC';

  @override
  String get sendScreenAddressLabel => 'Indirizzo destinatario';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => 'Importo (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

  @override
  String get sendScreenFeeLabel => 'Fee';

  @override
  String get sendScreenFeeLow => 'Bassa';

  @override
  String get sendScreenFeeNormal => 'Normale';

  @override
  String get sendScreenFeeHigh => 'Alta';

  @override
  String get sendScreenFeeCustom => 'Personalizzata';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Disponibile: $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Fee stimata: $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'Selezione UTXO';

  @override
  String get sendScreenUtxoSelectAll => 'Seleziona tutti';

  @override
  String get sendScreenUtxoNoneSelected =>
      'Seleziona almeno un UTXO da inviare';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Totale: $total $ticker';
  }

  @override
  String get sendScreenMax => 'Max';

  @override
  String get sendScreenSend => 'Invia';

  @override
  String get sendScreenSending => 'Invio in corso...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return 'Eliminati $deleted wallet, $errors errori: $error';
  }

  @override
  String get walletDetailBalanceLabel => 'SALDO';

  @override
  String get walletDetailMasterFingerprint => 'MASTER FINGERPRINT';

  @override
  String get walletDetailDerivationPath => 'PERCORSO DI DERIVAZIONE';

  @override
  String get walletDetailSettings => 'IMPOSTAZIONI';

  @override
  String get walletDetailAdvancedTools => 'Strumenti Avanzati';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'Nessun UTXO spendibile trovato';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count conferme';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count selezionati · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Invia selezionati';

  @override
  String get walletDetailUtxoClearSelection => 'Deseleziona tutto';

  @override
  String get walletDetailFirst100Addresses => 'Primi 100 Indirizzi';

  @override
  String get walletDetailPasswordSeedReason =>
      'Conferma password per visualizzare la seed phrase';

  @override
  String get walletDetailBiometricSeedReason =>
      'Conferma biometrica per visualizzare la seed phrase';

  @override
  String get walletDetailPasswordBumpReason =>
      'Inserisci la password per aumentare la fee';

  @override
  String get walletDetailBiometricBumpReason =>
      'Conferma biometrica per aumentare la fee';

  @override
  String get walletDetailTxBumpFee => 'Aumenta fee';

  @override
  String get walletDetailBumpFeeTitle => 'Aumenta la fee della transazione';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Fee attuale: $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Stime non disponibili — inserisci una tariffa personalizzata';

  @override
  String get walletDetailBumpFeeWarning =>
      'La transazione originale potrebbe non essere mai confermata se il replacement viene minato.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Fee aumentata — nuova transazione $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'La nuova fee deve essere maggiore di quella attuale';

  @override
  String get sendScreenSigning => 'Firma transazione...';

  @override
  String get sendScreenBroadcasting => 'Broadcast alla rete...';

  @override
  String get sendScreenBiometricReason =>
      'Conferma biometrica per autorizzare la transazione';

  @override
  String get sendScreenPasswordReason =>
      'Inserisci la password per autorizzare la transazione';

  @override
  String get sendScreenBiometricRequired =>
      'Per inviare è richiesta la biometria. Attiva impronta o riconoscimento facciale nelle impostazioni del dispositivo.';

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
      'La seed phrase è composta da 12 parole separate da spazi. Puoi incollarla direttamente.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Errore: $error';
  }

  @override
  String get legalMitLicense => 'Licenza MIT';

  @override
  String get legalSecurityTitle => 'Sicurezza';

  @override
  String get legalTermsContent =>
      'Questi Termini di Servizio sono provvisori e saranno sostituiti dalla versione definitiva quando il sito ufficiale sarà disponibile.\n\nBtc Blake2b Wallet è un wallet Bitcoin self-custodial per la rete sperimentale \"bitcoin-blake2b\" (fork di Bitcoin). Le chiavi private e la seed phrase restano esclusivamente sul tuo dispositivo: non custodiamo, non trasferiamo e non abbiamo accesso ai tuoi fondi.\n\nL\'app è fornita gratuitamente, \"così com\'è\", senza garanzie di alcun tipo. La usi a tuo esclusivo rischio. La rete bitcoin-blake2b è una rete sperimentale derivata da Bitcoin: le sue monete potrebbero non avere valore di mercato, non essere riconosciute dagli exchange e subire riorganizzazioni. Nessun contenuto dell\'app costituisce consulenza finanziaria o di investimento.\n\nSei l\'unico responsabile della custodia della seed phrase e dei tuoi fondi: chiunque ne sia in possesso può spendere le monete. L\'app non può recuperare una seed smarrita. È vietato l\'uso per attività illegali. Dichiari di avere almeno 16 anni.\n\nBtc Blake2b Wallet non è affiliato, sponsorizzato o approvato da Bitcoin, Bitcoin Core o bitcoin.org.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'Questa Informativa Privacy è provvisoria e sarà sostituita dalla versione definitiva pubblicata sul sito ufficiale quando disponibile.\n\n1) DATI SUL DISPOSITIVO. L\'app non richiede account e non salva dati personali su server dell\'autore. Seed cifrata (AES-256-GCM), preferenze e consensi restano SOLO sul tuo dispositivo.\n\n2) DATI TRASMESSI A TERZI PER IL FUNZIONAMENTO. Per mostrare saldo e commissioni l\'app interroga API pubbliche di terze parti:\n• mempool.guide (esploratore blockchain).\nA ogni richiesta vengono trasmessi il tuo indirizzo IP e l\'indirizzo pubblico del wallet interrogato. Chiavi private e seed non vengono MAI trasmessi.\n\n3) NESSUN TRACKER. Nessuna analytics, nessuna pubblicità, nessun cookie all\'interno dell\'app.\n\n4) DIRITTI (GDPR artt. 13-14). Hai diritto di accesso, rettifica, cancellazione e opposizione scrivendo al Titolare del trattamento: $holder — $email. Poiché non conserviamo dati personali, questi diritti sono in gran parte già garantiti dal fatto che i dati restano sul tuo dispositivo.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'Per segnalare vulnerabilità di sicurezza usa la segnalazione privata \"Report a vulnerability\" del repository GitHub (scheda Security) oppure scrivi a:\n$email\n\nNon aprire issue pubbliche per problemi di sicurezza. Tempo di risposta: 72 ore. Politica di divulgazione: 90 giorni.';
  }

  @override
  String get sendScreenSuccess => 'Transazione inviata!';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID: $txid';
  }

  @override
  String sendScreenError(Object error) {
    return 'Errore invio: $error';
  }

  @override
  String get sendScreenValidateAddress => 'Inserisci un indirizzo';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Indirizzo non valido per $network (usa $prefix)';
  }

  @override
  String get sendScreenValidateLength => 'Lunghezza indirizzo non valida';

  @override
  String get sendScreenValidateSelf => 'Non puoi inviare a te stesso';

  @override
  String get sendScreenValidateAmount => 'Inserisci un importo';

  @override
  String get sendScreenValidateInvalidAmount => 'Importo non valido';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Importo troppo basso (minimo $dust satoshi / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Fondi insufficienti (saldo: $balance, fee stimata: $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'Caricamento UTXO...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'Impossibile caricare gli UTXO: $error';
  }

  @override
  String get scanQrTitle => 'Scansiona QR Code';

  @override
  String get scanQrError =>
      'Impossibile accedere alla fotocamera. Consenti il permesso e riprova.';

  @override
  String get scanQrInvalid =>
      'Il codice scansionato non è un indirizzo Bitcoin valido.';

  @override
  String get scanQrTorch => 'Attiva/disattiva torcia';

  @override
  String get sendConfirmTitle => 'Conferma transazione';

  @override
  String get sendConfirmWarning =>
      'Questa transazione è irreversibile. Verifica i dettagli prima di confermare.';

  @override
  String get sendConfirmSend => 'Conferma e Invia';

  @override
  String get importScreenTitle => 'Importa Wallet';

  @override
  String get importScreenHeading => 'Inserisci le 12 parole';

  @override
  String get importScreenSubtitle =>
      'Inserisci la frase mnemonica di 12 parole separata da spazi, poi scegli il tipo di account corrispondente al wallet originale.';

  @override
  String get importScriptTypeLabel => 'Tipo di account';

  @override
  String get importScriptTypeNativeSegwit => 'SegWit nativo (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'SegWit annidato (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Tipo di wallet da creare';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Gli indirizzi iniziano con $prefix';
  }

  @override
  String get importScreenHint => 'word1 word2 word3 ...';

  @override
  String get importScreenValidateEmpty => 'Inserisci la frase mnemonica.';

  @override
  String importScreenValidateCount(Object count) {
    return 'La frase deve contenere esattamente 12 parole (rilevate: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Frase mnemonica non valida. Controlla l\'ortografia delle parole.';

  @override
  String get importScreenImporting => 'Importazione in corso...';

  @override
  String get importScreenImport => 'Importa';

  @override
  String importScreenError(Object error) {
    return 'Errore importazione wallet: $error';
  }

  @override
  String get importModeSeed => 'Frase seed';

  @override
  String get importModeWatchOnly => 'Watch-only (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Monitora un wallet esterno (saldo e storico) usando solo la sua chiave pubblica estesa. Nessuna chiave privata coinvolta: l\'invio non è mai possibile.';

  @override
  String get importWatchOnlyXpubLabel => 'Xpub dell\'account';

  @override
  String get importWatchOnlyXpubHint =>
      'Incolla l\'xpub dell\'account (inizia con \"xpub\"). Solo chiavi pubbliche: non incollare mai un xprv.';

  @override
  String get importWatchOnlyValidateEmpty => 'Inserisci l\'xpub dell\'account.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'L\'xpub deve iniziare con \"xpub\" (mainnet).';

  @override
  String get watchOnlyBadge => 'Solo visualizzazione';

  @override
  String get transferScreenTitle => 'Trasferisci Wallet';

  @override
  String get transferScreenScanning => 'Inquadra il QR Code del ricevente.';

  @override
  String get transferScreenProcessing => 'Elaborazione e cifratura dei dati...';

  @override
  String transferScreenScanError(Object error) {
    return 'Errore durante la scansione o cifratura: $error';
  }

  @override
  String get transferScreenNearbyTitle => 'Scansiona per ricevere';

  @override
  String get transferScreenNearbySubtitle =>
      'Fai scansionare questo QR Code al ricevente.';

  @override
  String transferScreenNearbyCode(Object code) {
    return 'Codice manuale: $code';
  }

  @override
  String get transferScreenNearbyCancel => 'Annulla';

  @override
  String get transferScreenNearbySuccess =>
      'Wallet trasferito con successo via Bluetooth. Il seed locale è stato cancellato.';

  @override
  String transferScreenNearbyError(Object error) {
    return 'Errore trasmissione: $error';
  }

  @override
  String get transferScreenWebRtcConnecting => 'Avvio connessione WebRTC...';

  @override
  String get transferScreenWebRtcTransferring =>
      'Trasferimento via WebRTC in corso...';

  @override
  String get transferScreenTransferComplete => 'Trasferimento completato!';

  @override
  String get transferScreenMethodTitle => 'Scegli metodo di trasferimento';

  @override
  String get transferScreenMethodQr => 'QR Code (2 Fasi)';

  @override
  String get transferScreenMethodQrDesc =>
      'Scansiona il QR code del ricevente, poi genera un QR code con il seed cifrato.';

  @override
  String get transferScreenMethodNearby => 'Bluetooth P2P';

  @override
  String get transferScreenMethodNearbyDesc =>
      'Trasferimento diretto tra dispositivi. Richiede Bluetooth.';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC (Internet)';

  @override
  String get transferScreenMethodWebRtcDesc =>
      'P2P via browser. Richiede internet su entrambi i dispositivi.';

  @override
  String get transferScreenWebRtcQrDescription =>
      'Il ricevente deve scansionare questo QR. Il trasferimento avverrà via WebRTC (nessun limite di dimensione).';

  @override
  String get transferScreenEncryptedQrDescription =>
      'Mostra questo QR Code al dispositivo ricevente. Una volta scansionato e completata la ricezione, il wallet verrà rimosso automaticamente da questo dispositivo.';

  @override
  String get transferScreenWebRtcTimeout =>
      'Connessione WebRTC non riuscita dopo 30 secondi. Riprova o usa il metodo QR Code 2-fasi.';

  @override
  String get receiveScreenTitle => 'Ricevi Wallet';

  @override
  String get receiveScreenInit => 'Inizializzazione chiave asimmetrica...';

  @override
  String get receiveScreenShowQr => 'Mostra questo QR Code al mittente.';

  @override
  String get receiveScreenScanSender =>
      'Inquadra il QR Code sul dispositivo mittente.';

  @override
  String get receiveScreenAutoDetectMethod =>
      'Il sistema rileva automaticamente il metodo usato dal mittente.';

  @override
  String receiveScreenKeyError(Object error) {
    return 'Errore generazione chiave: $error';
  }

  @override
  String get receiveScreenDecrypting =>
      'Dati ricevuti. Decrittografia e validazione server in corso...';

  @override
  String get receiveScreenSuccess =>
      'Wallet ricevuto e importato con successo.';

  @override
  String get receiveScreenQrSuccess => 'Wallet ricevuto via QR Code.';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return 'Codice $code letto. Connessione in corso...';
  }

  @override
  String get receiveScreenNearbySuccess => 'Wallet ricevuto via Bluetooth P2P.';

  @override
  String receiveScreenError(Object error) {
    return 'Errore: $error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'Stanza WebRTC';

  @override
  String get receiveScreenWebRtcConnect => 'Connetti alla Stanza';

  @override
  String get receiveScreenWebRtcShareQr =>
      'Condividi questo QR Code con il mittente';

  @override
  String get receiveScreenWebRtcScanQr =>
      'Scansiona il QR Code della stanza del mittente';

  @override
  String get receiveScreenWebRtcWait =>
      'In attesa della connessione del mittente...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return 'Room ID: $roomId';
  }

  @override
  String get passwordDialogCreateTitle => 'Crea Password di Sicurezza';

  @override
  String get passwordDialogCreateContent =>
      'Imposta una password per proteggere le operazioni sensibili su questo browser. La password verrà memorizzata localmente e usata per cifrare i tuoi dati.';

  @override
  String get passwordDialogCreateHint => 'Inserisci una password sicura';

  @override
  String get passwordDialogCreateConfirm => 'Conferma password';

  @override
  String get passwordDialogCreateConfirmHint => 'Reinserisci la password';

  @override
  String get passwordDialogCreateMismatch => 'Le password non corrispondono';

  @override
  String get passwordDialogCreateTooShort =>
      'La password deve essere di almeno 8 caratteri';

  @override
  String get passwordDialogCreate => 'Crea';

  @override
  String get passwordDialogCancel => 'Annulla';

  @override
  String get passwordDialogEnterTitle => 'Inserisci Password';

  @override
  String get passwordDialogEnterContent =>
      'Inserisci la tua password di sicurezza per continuare.';

  @override
  String get passwordDialogEnterHint => 'Inserisci la tua password';

  @override
  String get passwordDialogEnter => 'Conferma';

  @override
  String get passwordDialogWrong => 'Password errata';

  @override
  String get languageSelector => 'Lingua';

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
  String get walletDetailRefresh => 'Aggiorna';

  @override
  String get walletDetailDeleteTitle => 'Elimina Wallet?';

  @override
  String get walletDetailDeleteConfirm => 'Elimina definitivamente';

  @override
  String get walletDetailDeleteWarning =>
      'Questa azione è irreversibile. Assicurati di avere un backup della seed phrase se ci sono fondi nel wallet.';

  @override
  String get walletDetailInfo => 'Info Wallet';

  @override
  String get walletDetailNameLabel => 'Nome Wallet';

  @override
  String get walletDetailNameHint => 'es. Risparmi Casa';

  @override
  String get walletDetailType => 'Tipo';

  @override
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'SegWit annidato (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'AGGIORNAMENTO...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TRANSAZIONI';
  }

  @override
  String get walletDetailReceiveQr => 'Ricevi Bitcoin';

  @override
  String get walletDetailSignVerify => 'Firma/Verifica Messaggio';

  @override
  String get walletDetailShowAddresses => 'Mostra indirizzi';

  @override
  String get walletDetailWalletAddress => 'Indirizzo Wallet';

  @override
  String get walletDetailExportSeed => 'Esporta/Backup Seed';

  @override
  String get walletDetailShowSeedTitle => 'Visualizzare seed?';

  @override
  String get walletDetailShowSeedContent =>
      'La seed phrase permette di accedere a tutti i fondi. Assicurati di essere in un luogo sicuro.';

  @override
  String get walletDetailShowSeedConfirm => 'Sì, mostra';

  @override
  String get walletDetailSeedVerifyPrompt =>
      'Vuoi verificare di aver salvato la seed?';

  @override
  String get walletDetailSeedVerifyYes => 'Sì, verifica';

  @override
  String get walletDetailSeedVerifyNotNow => 'Non ora';

  @override
  String get walletDetailSeedVerified => 'Backup verificato';

  @override
  String get walletDetailSeedHidden => 'Seed nascosta per sicurezza';

  @override
  String get walletDetailSeedShowAgain => 'Mostra seed';

  @override
  String get walletDetailHideSeed => 'Nascondi';

  @override
  String get walletDetailBackupNotConfirmed => 'Backup non confermato';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'Non hai ancora salvato la seed phrase. Se perdi il dispositivo o reinstalli l\'app, perderai permanentemente l\'accesso ai tuoi fondi.';

  @override
  String get walletDetailShowXpub => 'Mostra Wallet XPUB';

  @override
  String get walletDetailDisplayHome => 'Mostra valore in Home';

  @override
  String get walletDetailUtxoRename => 'Rinomina';

  @override
  String get walletDetailUtxoRenameTitle => 'Rinomina UTXO';

  @override
  String get walletDetailSave => 'Salva';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Creato il';

  @override
  String get walletDetailTransferredOn => 'Trasferito il';

  @override
  String get walletDetailClose => 'Chiudi';

  @override
  String get walletDetailSign => 'Firma';

  @override
  String get walletDetailVerify => 'Verifica';

  @override
  String get walletDetailSignMessage => 'Firma Messaggio';

  @override
  String get walletDetailVerifyMessage => 'Verifica Messaggio';

  @override
  String get walletDetailMessage => 'Messaggio';

  @override
  String get walletDetailBitcoinAddress => 'Indirizzo Bitcoin';

  @override
  String get walletDetailSignature => 'Firma (Base64)';

  @override
  String get walletDetailResult => 'Risultato:';

  @override
  String get walletDetailSignatureLabel => 'Firma:';

  @override
  String get walletDetailCopy => 'Copia';

  @override
  String get walletDetailAddressCopied => 'Indirizzo copiato negli appunti';

  @override
  String get walletDetailXpubTitle => 'XPUB del Wallet';

  @override
  String get walletDetailXpubDesc =>
      'Questo XPUB permette di visualizzare tutti gli indirizzi futuri e i saldi ma non può spendere fondi.';

  @override
  String get walletDetailXpubCopied => 'XPUB copiato';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Errore derivazione XPUB: $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Errore derivazione indirizzi: $error';
  }

  @override
  String get walletDetailFirst100 => 'Primi 100 Indirizzi';

  @override
  String get walletDetailValidSig => 'FIRMA VALIDA ✓';

  @override
  String get walletDetailInvalidSig => 'FIRMA NON VALIDA ✗';

  @override
  String get donateTitle => 'Supporta il progetto ❤️';

  @override
  String get donatePhrase =>
      '☕ \"Se il progetto ti è utile, offrici un caffè virtuale\"';

  @override
  String get donateAddressLabel => 'Indirizzo Bitcoin per donazioni:';

  @override
  String get donateCopy => 'Copia';

  @override
  String get donateCopied => 'Copiato! ✓';

  @override
  String get donateNote =>
      'Donazione volontaria: nessun servizio o vantaggio in cambio. Qualsiasi importo è benvenuto, anche pochi satoshi. Grazie di cuore! 🧡';

  @override
  String get donateNoWalletTitle => 'Nessun wallet trovato';

  @override
  String get donateNoWalletMessage =>
      'Non è stato trovato un wallet Bitcoin installato sul dispositivo. Puoi comunque copiare l\'indirizzo e incollarlo nel tuo wallet preferito.';

  @override
  String get donateOpenWallet => 'Apri nel wallet';

  @override
  String get donateButton => 'Supporta il progetto ❤️';

  @override
  String get multiTransferTitle => 'Invio Multi-Wallet';

  @override
  String get multiTransferSelectWallets => 'Seleziona i wallet da inviare';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallet selezionati',
      one: '1 wallet selezionato',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return 'Valore totale: $amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => 'Metodo di invio:';

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
    return 'QR Code 2-fasi (max $max)';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wallet',
      one: '1 Wallet',
    );
    return 'Invia $_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => 'Invio in corso...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return 'Wallet $current di $total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallet inviati con successo',
      one: '1 wallet inviato con successo',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success inviati, $failed falliti';
  }

  @override
  String get multiTransferNoLockedWallets =>
      'Nessun wallet disponibile per l\'invio. Solo i wallet in stato LOCKED possono essere trasferiti.';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return 'Hai selezionato $selected wallet. Il massimo per $method è $max.';
  }

  @override
  String get multiTransferReceivingTitle => 'Ricezione Multi-Wallet';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return 'Ricevuti $received di $total wallet';
  }

  @override
  String get multiTransferMethodUnavailable =>
      'Non disponibile su questa piattaforma';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return 'Invio wallet $current di $total...';
  }

  @override
  String get multiTransferPreparing => 'Preparazione wallet...';

  @override
  String get multiTransferWaitingReceiver => 'In attesa del ricevente...';

  @override
  String get multiTransferCompleted => 'Completato';

  @override
  String get multiTransferFailed => 'Fallito';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return 'Invio manuale 2-fasi via QR code. Massimo $max wallet.';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return 'Trasferimento P2P veloce via internet. Massimo $max wallet.';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return 'Trasferimento diretto tra dispositivi. Massimo $max wallet.';
  }

  @override
  String get multiTransferNoBalance => 'Saldo non disponibile';

  @override
  String get multiTransferConfirmTitle => 'Conferma invio';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallet',
      one: '1 wallet',
    );
    return 'Stai per inviare $_temp0 per un totale di $amount $ticker. Continuare?';
  }

  @override
  String get onboardingTitle => 'Benvenuto in Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle =>
      'Wallet Bitcoin open-source. Self-custody. No KYC.';

  @override
  String get onboardingResidenceLabel => 'Paese di residenza fiscale';

  @override
  String get onboardingResidenceHint => 'Seleziona il tuo paese';

  @override
  String get onboardingReverseSolicitation =>
      'Dichiaro di utilizzare Btc Blake2b Wallet di mia esclusiva iniziativa (\"reverse solicitation\") e di risiedere fiscalmente nel paese selezionato.';

  @override
  String get onboardingTermsAccept => 'Accetto i ';

  @override
  String get onboardingPrivacyAccept => 'Ho letto la ';

  @override
  String get onboardingAgeConfirm => 'Dichiaro di avere almeno 16 anni';

  @override
  String get onboardingAgeSubtitle =>
      'Richiesto dall\'Art. 8 del GDPR per il consenso al trattamento dati';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String get onboardingStepNext => 'Avanti';

  @override
  String get onboardingStepBack => 'Indietro';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Passo $current di $total';
  }

  @override
  String get onboardingTermsTitle => 'Termini e Privacy';

  @override
  String get onboardingValidationResidence =>
      'Seleziona il tuo paese di residenza fiscale';

  @override
  String get onboardingValidationCheckbox =>
      'Devi accettare tutte le dichiarazioni per continuare';

  @override
  String get onboardingLinkTerms => 'Termini di Servizio';

  @override
  String get onboardingLinkPrivacy => 'Informativa sulla Privacy';

  @override
  String get aboutTitle => 'Info su Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet è un wallet Bitcoin open-source self-custody. Nessuna registrazione, nessun KYC, nessun tracciamento. Le tue chiavi, i tuoi bitcoin.';

  @override
  String get aboutLicenseTitle => 'Licenza';

  @override
  String get aboutThirdPartyLicenses => 'Licenze Terze Parti';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'Visualizza l\'elenco completo delle licenze open-source';

  @override
  String get aboutBuiltWith => 'Realizzato con';

  @override
  String get aboutDisclaimer =>
      'Questo software è fornito \"COSÌ COM\'È\" senza garanzie di alcun tipo.';

  @override
  String get explorerTitle => 'Esplora nodo';

  @override
  String get explorerAddressLabel => 'Indirizzo';

  @override
  String get explorerRefresh => 'Ricarica';

  @override
  String get explorerBalanceLabel => 'Saldo';

  @override
  String get explorerTxCount => 'Transazioni';

  @override
  String get explorerTipHeight => 'Altezza nodo';

  @override
  String get explorerErrorInvalidAddress =>
      'Indirizzo non valido. Controlla il formato per questa rete.';

  @override
  String get explorerErrorRateLimited =>
      'Limite di richieste superato. Riprova tra un minuto.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Servizio temporaneamente non raggiungibile. Riprova più tardi.';

  @override
  String get explorerErrorNotFound => 'Indirizzo o transazione non trovati.';

  @override
  String get explorerErrorTimeout =>
      'Richiesta scaduta. Controlla la connessione e riprova.';

  @override
  String get explorerErrorNetwork =>
      'Rete non disponibile. Controlla la connessione.';

  @override
  String get explorerRetry => 'Riprova';

  @override
  String explorerErrorGeneric(String error) {
    return 'Errore: $error';
  }
}
