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
  String get homeLockVault => 'Blocca vault';

  @override
  String get homeVaultLocked => 'Vault bloccato';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionSecurity => 'Sicurezza';

  @override
  String get settingsSectionAppearance => 'Aspetto';

  @override
  String get settingsSectionTools => 'Strumenti';

  @override
  String get settingsSectionInfo => 'Informazioni';

  @override
  String get settingsTheme => 'Tema scuro';

  @override
  String get settingsAppLock => 'Blocco app';

  @override
  String get settingsAppLockDesc =>
      'Richiedi biometria o PIN del telefono a ogni apertura';

  @override
  String get settingsAppLockUnavailable =>
      'Nessuna biometria registrata su questo dispositivo';

  @override
  String get settingsAppLockEnableFailed =>
      'Verifica non riuscita: blocco non attivato';

  @override
  String get settingsAppLockEnabled => 'Blocco app attivato';

  @override
  String get settingsAppLockDisabled => 'Blocco app disattivato';

  @override
  String get settingsExplorerMirrors => 'Explorer di riserva';

  @override
  String get settingsExplorerMirrorsDesc =>
      'Se mempool.guide non risponde, l\'app interroga due mirror comunitari. Disattiva per usare solo mempool.guide.';

  @override
  String get settingsSectionInterface => 'Interfaccia';

  @override
  String get settingsInfoDots => 'Suggerimenti informativi';

  @override
  String get settingsInfoDotsDesc =>
      'Mostra i pallini info che spiegano ogni funzione';

  @override
  String get infoCoinControlTitle => 'Coin control (selezione UTXO)';

  @override
  String get infoCoinControlBody =>
      'Il saldo è formato dagli UTXO, i pezzi ricevuti. Qui scegli quali spendere: la transazione userà solo quelli, così puoi lasciare da parte i pezzi piccoli o inattivi.';

  @override
  String get infoDustLimitTitle => 'Importo minimo (dust)';

  @override
  String get infoDustLimitBody =>
      'Gli output sotto i 546 sat sono rifiutati dalla rete come \'dust\'. Sotto quella soglia l\'importo non è inviabile.';

  @override
  String get infoFeeRateTitle => 'Commissione di transazione';

  @override
  String get infoFeeRateBody =>
      'La commissione si paga per unità di dimensione della transazione (sat/vB): più vuoi conferma rapida, più paghi. \'Economica\' può richiedere ore, \'Prioritaria\' pochi minuti. \'Personalizzata\' serve quando conosci il valore attuale del mempool.';

  @override
  String get infoBatchSendTitle => 'Più destinatari (batch)';

  @override
  String get infoBatchSendBody =>
      'In una sola transazione puoi pagare fino a 5 indirizzi, dividendo la commissione invece di pagarla una volta per bonifico. Prima di firmare vedi l\'elenco completo dei destinatari.';

  @override
  String get infoBumpFeeTitle => 'Aumenta fee (RBF)';

  @override
  String get infoBumpFeeBody =>
      'Una transazione in attesa può essere sostituita da una che paga più commissione (BIP125). L\'originale viene annullata e solo la sostituta può confermare — indirizzo e importo restano identici.';

  @override
  String get infoXpubTitle => 'Chiave pubblica dell\'account (xpub)';

  @override
  String get infoXpubBody =>
      'L\'xpub genera tutti i tuoi indirizzi di ricezione. Non può muovere fondi, ma rivela saldo e storico completi: condividila solo con app di cui ti fidi (es. un wallet di sola lettura).';

  @override
  String get infoReceiveAddressTitle => 'Indirizzo di ricezione';

  @override
  String get infoReceiveAddressBody =>
      'Ogni \'Ricevi\' mostra un indirizzo nuovo, scelto fra quelli mai usati: così i pagamenti non sono collegabili tra loro. Riusare un indirizzo non è un errore, rende solo più facile tracciare i tuoi movimenti.';

  @override
  String get infoWatchOnlyTitle => 'Wallet di sola lettura';

  @override
  String get infoWatchOnlyBody =>
      'Hai importato solo l\'xpub: l\'app vede saldo e storico ma non custodisce chiavi private, quindi non può firmare. Per spendere da questo wallet serve il dispositivo che possiede la seed.';

  @override
  String get infoSignVerifyTitle => 'Firma / verifica messaggio';

  @override
  String get infoSignVerifyBody =>
      'Firmare un messaggio dimostra che l\'indirizzo è tuo senza muovere fondi. Chiunque può poi verificare la firma confrontandola con quell\'indirizzo e lo stesso messaggio.';

  @override
  String get infoChannelCapacityTitle => 'Capacità del canale';

  @override
  String get infoChannelCapacityBody =>
      'Il totale di satoshi nel canale, diviso tra te e il tuo peer. Più capacità significa poter gestire pagamenti più grandi. Capacità = saldo locale + saldo remoto.';

  @override
  String get infoChannelReserveTitle => 'Riserva del canale';

  @override
  String get infoChannelReserveBody =>
      'Una piccola parte dei tuoi fondi deve restare bloccata come deposito di sicurezza (la \'riserva\'). Garantisce che entrambe le parti abbiano qualcosa da perdere — se l\'altro va offline malevolmente, la riserva può essere usata per penalizzarlo on-chain.';

  @override
  String get infoToSelfDelayTitle => 'Ritardo verso sé stessi';

  @override
  String get infoToSelfDelayBody =>
      'Quando avviene una chiusura forzata, il tuo output on-chain è ritardato di questo numero di blocchi (tipicamente 144 = ~1 giorno). Questo dà al tuo peer tempo di reclamare i propri fondi prima, prevenendo attacchi di doppia spesa sullo stato del canale.';

  @override
  String get infoHtlcTitle => 'HTLC (Contratto a Tempo Vincolato con Hash)';

  @override
  String get infoHtlcBody =>
      'Un HTLC è un pagamento condizionato: i fondi sono bloccati finché il destinatario non rivela un preimage hash. In Lightning, gli HTLC abilitano il routing istantaneo off-chain: il tuo pagamento salta attraverso più canali senza fidarsi di alcun intermediario.';

  @override
  String get infoOpenChannelPrivateTitle => 'Canale privato';

  @override
  String get infoOpenChannelPrivateBody =>
      'Un canale privato non è annunciato alla rete. Solo tu e il tuo peer sapete che esiste. Usalo quando non vuoi che altri facciano routing attraverso di esso (privacy) o quando il canale è troppo piccolo per essere utile per il routing.';

  @override
  String get infoRoutingFeesTitle => 'Commissioni di routing';

  @override
  String get infoRoutingFeesBody =>
      'Quando altri nodi instradano pagamenti attraverso il tuo canale, guadagni commissioni. La commissione base (sat) si paga per pagamento; il rate (ppm) è proporzionale all\'importo. Il CLTV delta limita quanto tempo un HTLC inolttrato può impiegare per essere regolato.';

  @override
  String get infoForceCloseTitle => 'Chiusura forzata';

  @override
  String get infoForceCloseBody =>
      'Trasmette l\'ultimo stato del canale on-chain. È irreversibile e richiede di attendere il ritardo verso sé stessi prima di poter spendere i tuoi fondi. Usalo solo se il tuo peer non risponde o è malizioso — la chiusura cooperativa è sempre più veloce ed economica.';

  @override
  String get infoPeersTitle => 'Peer connessi';

  @override
  String get infoPeersBody =>
      'I peer sono altri nodi Lightning con cui sei direttamente connesso via TCP/Tor. Ogni peer può avere uno o più canali. Puoi connetterti a nuovi peer per aprire canali e aumentare la liquidità e la capacità di routing del tuo nodo.';

  @override
  String get infoNodeManagementTitle => 'Gestione nodo';

  @override
  String get infoNodeManagementBody =>
      'L\'identità del tuo nodo Lightning: pubkey, versione, numero di canali e peer attivi/in attesa. Questa schermata mostra dati contabili dal plugin bookkeeper del nodo e statistiche di forwarding.';

  @override
  String get appLockTitle => 'App bloccata';

  @override
  String get appLockSubtitle => 'Sblocca con biometria o PIN del telefono';

  @override
  String get appLockUnlock => 'Sblocca';

  @override
  String get appLockReason => 'Sblocca il wallet';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'Blocco disattivato: la protezione del telefono (biometria/PIN) non è più disponibile. Riattivala nelle impostazioni di sistema per usare di nuovo il blocco app.';

  @override
  String get appLockNoticeContinue => 'Continua';

  @override
  String get appLockPromptTitle => 'Attivare il blocco app?';

  @override
  String get appLockPromptMessage =>
      'Per aprire il wallet userai impronta/volto o il PIN del telefono.';

  @override
  String get appLockPromptEnable => 'Attiva';

  @override
  String get appLockPromptLater => 'Più tardi';

  @override
  String get aboutLicensesOpenOnline => 'Apri online';

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
  String get walletDetailAddress => 'Indirizzo';

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
  String get walletDetailTxExport => 'Esporta';

  @override
  String get walletDetailTxExportCsv => 'CSV (foglio di calcolo)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'Copiato negli appunti ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Download avviato ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'Esportazione non riuscita';

  @override
  String get walletDetailTxExportJson => 'JSON (completo)';

  @override
  String get walletDetailTxFee => 'Fee';

  @override
  String get walletDetailTxIncoming => 'Ricevuti';

  @override
  String get walletDetailTxNote => 'Nota';

  @override
  String get walletDetailTxNoteAdd => 'Aggiungi nota';

  @override
  String get walletDetailTxNoteEdit => 'Modifica nota';

  @override
  String get walletDetailTxNoteHint =>
      'Nota privata, salvata solo su questo dispositivo';

  @override
  String get walletDetailTxNoteRemove => 'Rimuovi';

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
  String get sendScreenTitle => 'Invia BTC';

  @override
  String get sendScreenAddressLabel => 'Indirizzo destinatario';

  @override
  String get sendScreenAmountLabel => 'Importo (BTC)';

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
  String get sendBatchToggle => 'Più destinatari';

  @override
  String get sendBatchToggleSingle => 'Un destinatario';

  @override
  String sendBatchRecipientLabel(int index) {
    return 'Destinatario $index';
  }

  @override
  String get sendBatchAddRecipient => 'Aggiungi destinatario';

  @override
  String get sendBatchRemoveRecipient => 'Rimuovi';

  @override
  String get sendBatchMaxRecipients => 'Massimo 20 destinatari';

  @override
  String get sendBatchTotalLabel => 'Totale destinatari';

  @override
  String get sendBatchDustError => 'Minimo 546 sat per destinatario';

  @override
  String get sendBatchDuplicateError => 'Indirizzo duplicato';

  @override
  String get sendBatchMinRecipients =>
      'Servono almeno 2 destinatari per un invio multiplo';

  @override
  String sendBatchConfirmRecipients(int count) {
    return '$count destinatari';
  }

  @override
  String get sendBatchConfirmTitle => 'Conferma invio multiplo';

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
      'La seed phrase è composta da 12, 15, 18, 21 o 24 parole separate da spazi. Puoi incollarla direttamente.';

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
    return 'Questa Informativa Privacy è provvisoria e sarà sostituita dalla versione definitiva pubblicata sul sito ufficiale quando disponibile.\n\n1) DATI SUL DISPOSITIVO. L\'app non richiede account e non salva dati personali su server dell\'autore. Seed cifrata (AES-256-GCM), preferenze e consensi restano SOLO sul tuo dispositivo.\n\n2) DATI TRASMESSI A TERZI PER IL FUNZIONAMENTO. Per mostrare saldo e commissioni l\'app interroga API pubbliche di terze parti:\n• mempool.guide (esploratore blockchain).\n• Se mempool.guide non è disponibile, l\'app può interrogare due mirror comunitari Esplora-compatibili (mempool.kilombino.com, mempool.maveth.ca). Questa opzione è disattivabile nelle Impostazioni.\nA ogni richiesta vengono trasmessi il tuo indirizzo IP e l\'indirizzo pubblico del wallet interrogato. Chiavi private e seed non vengono MAI trasmessi.\n\n3) NESSUN TRACKER. Nessuna analytics, nessuna pubblicità, nessun cookie all\'interno dell\'app.\n\n4) DIRITTI (GDPR artt. 13-14). Hai diritto di accesso, rettifica, cancellazione e opposizione scrivendo al Titolare del trattamento: $holder — $email. Poiché non conserviamo dati personali, questi diritti sono in gran parte già garantiti dal fatto che i dati restano sul tuo dispositivo.';
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
  String get scanQrInvalidInvoice =>
      'Il codice scansionato non è una invoice Lightning valida.';

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
  String get importScreenHeading => 'Inserisci la seed phrase';

  @override
  String get importScreenSubtitle =>
      'Inserisci la frase mnemonica (12, 15, 18, 21 o 24 parole) separata da spazi, poi scegli il tipo di account corrispondente al wallet originale.';

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
    return 'La frase deve contenere 12, 15, 18, 21 o 24 parole (rilevate: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Frase mnemonica non valida. Controlla l\'ortografia delle parole.';

  @override
  String get importScreenImport => 'Importa';

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
  String get passwordDialogCreateTitle => 'Crea Password di Sicurezza';

  @override
  String get passwordDialogCreateHint => 'Inserisci una password sicura';

  @override
  String get passwordDialogCreateConfirm => 'Conferma password';

  @override
  String get passwordDialogCreate => 'Crea';

  @override
  String get passwordDialogCancel => 'Annulla';

  @override
  String get passwordDialogEnterTitle => 'Inserisci Password';

  @override
  String get passwordDialogEnterHint => 'Inserisci la tua password';

  @override
  String get passwordDialogEnter => 'Conferma';

  @override
  String get passwordDialogWrong => 'Password errata';

  @override
  String get languageSelector => 'Lingua';

  @override
  String get languageSelectorAuto => '🌐 Automatica (sistema)';

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

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'Nessun nodo Lightning connesso';

  @override
  String get lightningDisconnectedBody =>
      'Connetti il tuo nodo Lightning blake2b per inviare e ricevere pagamenti. L\'app non custodisce mai fondi o chiavi.';

  @override
  String get lightningConnectButton => 'Connetti nodo';

  @override
  String get lightningConnectTitle => 'Connetti nodo Lightning';

  @override
  String get lightningConnectHint =>
      'Incolla la stringa di connessione (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Stringa di connessione non valida';

  @override
  String get lightningConnectRecentNodes => 'Nodi recenti';

  @override
  String get lightningConnectInfo =>
      'Il nodo deve autorizzare questa app (grant): controlla il pannello di controllo del nodo.';

  @override
  String get lightningConnecting => 'Connessione…';

  @override
  String get lightningConnected => 'Connesso';

  @override
  String get lightningDisconnect => 'Disconnetti';

  @override
  String get lightningBalance => 'Saldo Lightning';

  @override
  String get lightningChannels => 'Canali';

  @override
  String get lightningNoChannels => 'Nessun canale aperto';

  @override
  String get lightningChannelPeer => 'Peer';

  @override
  String get lightningChannelCapacity => 'Capacità';

  @override
  String get lightningChannelLocal => 'Locale';

  @override
  String get lightningChannelRemote => 'Remoto';

  @override
  String get lightningOpenChannel => 'Apri canale';

  @override
  String get lightningOpenChannelNodeId => 'Node ID (pubkey)';

  @override
  String get lightningOpenChannelHost => 'Host (opzionale, ip:porta)';

  @override
  String get lightningOpenChannelAmount => 'Importo (sat)';

  @override
  String get lightningOpenChannelPrivate => 'Canale privato';

  @override
  String get lightningChannelOpened => 'Apertura canale richiesta';

  @override
  String get lightningCloseChannel => 'Chiudi canale';

  @override
  String get lightningCloseChannelForce => 'Chiusura forzata';

  @override
  String get lightningCloseChannelForceWarning =>
      'La chiusura forzata pubblica l\'ultimo stato del canale on-chain. Potrebbero applicarsi fee e attese. Continuare?';

  @override
  String get lightningReceive => 'Ricevi';

  @override
  String get lightningSend => 'Invia';

  @override
  String get lightningInvoiceAmount => 'Importo (sat)';

  @override
  String get lightningInvoiceDescription => 'Descrizione (opzionale)';

  @override
  String get lightningInvoiceCreate => 'Crea invoice';

  @override
  String get lightningInvoiceTitle => 'Invoice Lightning';

  @override
  String get lightningPay => 'Paga invoice';

  @override
  String get lightningPayHint => 'Incolla l\'invoice (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Conferma pagamento Lightning';

  @override
  String get lightningPayDialogBody => 'Pagare questa invoice?';

  @override
  String get lightningPaySuccess => 'Pagamento inviato';

  @override
  String get lightningCopied => 'Copiato';

  @override
  String get lightningErrorRestricted =>
      'Il nodo non ha autorizzato questa app. Crea un grant sul nodo per questa connessione.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Errore Lightning: $error';
  }

  @override
  String get lightningConfirm => 'Conferma';

  @override
  String get lightningCancel => 'Annulla';

  @override
  String get lightningNodeOnchain => 'On-chain del nodo';

  @override
  String get lightningDeposit => 'Deposita';

  @override
  String get lightningWithdraw => 'Invia on-chain';

  @override
  String get lightningDepositTitle => 'Deposito on-chain';

  @override
  String get lightningDepositHint =>
      'Invia fondi blake2b a questo indirizzo del nodo.';

  @override
  String get lightningDepositNewAddress => 'Nuovo indirizzo';

  @override
  String get lightningDepositWarning =>
      'Invia solo sulla rete blake2b. I fondi inviati sulla rete sbagliata vanno persi.';

  @override
  String get lightningOnchainSendTitle => 'Invio on-chain';

  @override
  String get lightningOnchainAddressLabel => 'Indirizzo destinatario';

  @override
  String get lightningOnchainAmountLabel => 'Importo (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Fee di rete';

  @override
  String get lightningOnchainFeeMin => 'Minima';

  @override
  String get lightningOnchainFeeEconomical => 'Economica';

  @override
  String get lightningOnchainFeePriority => 'Prioritaria';

  @override
  String get lightningOnchainConfirm => 'Conferma invio';

  @override
  String get lightningOnchainConfirmTitle => 'Confermi invio on-chain?';

  @override
  String get lightningOnchainWarning =>
      'Operazione irreversibile: i fondi lasceranno il nodo.';

  @override
  String get lightningOnchainSuccess => 'Transazione inviata';

  @override
  String get lightningOnchainInvalidAddress => 'Indirizzo blake2b non valido';

  @override
  String get lightningOnchainInsufficient => 'Fondi on-chain insufficienti';

  @override
  String get lightningFeesUnavailable =>
      'Stime fee non disponibili: la fee verrà scelta dal nodo';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey oppure pubkey@host:port (per .onion serve Tor sul nodo)';

  @override
  String get lightningOpenChannelInvalid =>
      'Node ID o host non valido (66 esadecimali, host:porta)';

  @override
  String get lightningActivityDetected => 'Attività rilevata sul nodo';

  @override
  String get lightningPeers => 'Peer';

  @override
  String get lightningPeersEmpty => 'Nessun peer connesso';

  @override
  String get lightningConnectPeer => 'Connetti peer';

  @override
  String get lightningDisconnectPeer => 'Disconnetti';

  @override
  String get lightningPeerDisconnected => 'Disconnesso';

  @override
  String get lightningPeerId => 'ID peer';

  @override
  String get lightningPeerAddresses => 'Indirizzi';

  @override
  String get lightningDisconnectPeerConfirm =>
      'Disconnettere questo peer? I canali aperti restano attivi.';

  @override
  String get lightningChannelDetail => 'Dettaglio canale';

  @override
  String get lightningChannelShortId => 'Short channel ID';

  @override
  String get lightningChannelState => 'Stato del nodo';

  @override
  String get lightningChannelFee => 'Fee';

  @override
  String get lightningChannelSpendable => 'Spendibile';

  @override
  String get lightningChannelReceivable => 'Ricevibile';

  @override
  String get lightningChannelHtlcs => 'HTLC';

  @override
  String get lightningChannelFundingTxid => 'Txid di funding';

  @override
  String get lightningNodeManagement => 'Gestione nodo';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers peer · $channels canali';
  }

  @override
  String get lightningNodeIdentity => 'Identità del nodo';

  @override
  String get lightningNodePubkey => 'Chiave pubblica';

  @override
  String get lightningNodeVersion => 'Versione';

  @override
  String get lightningNodePeersCount => 'Peer';

  @override
  String get lightningNodeChannelsActive => 'Canali attivi';

  @override
  String get lightningNodeChannelsPending => 'Canali in attesa';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'Non disponibile su questo nodo: per annunciare termini di lease serve il plugin liquidity-ads.';

  @override
  String get lightningLiquidity => 'Liquidità';

  @override
  String get lightningLiquidityTotal => 'Capacità totale';

  @override
  String get lightningLiquidityOutbound => 'In uscita';

  @override
  String get lightningLiquidityInbound => 'In entrata';

  @override
  String get lightningLiquidityWarning =>
      'Nessuna liquidità in entrata: non puoi ricevere finché un peer non apre un canale verso questo nodo.';

  @override
  String get lightningMovements => 'Movimenti';

  @override
  String get lightningMovementsEmpty => 'Nessun movimento';

  @override
  String get lightningMovementsAll => 'Tutti i movimenti';

  @override
  String get lightningMovementsLoadMore => 'Carica altri';

  @override
  String get lightningMovementDeposit => 'Deposito on-chain';

  @override
  String get lightningMovementWithdrawal => 'Invio on-chain';

  @override
  String get lightningMovementChannelOpen => 'Apertura canale';

  @override
  String get lightningMovementChannelClose => 'Chiusura canale';

  @override
  String get lightningMovementInvoice => 'Pagamento Lightning';

  @override
  String get lightningMovementOnchainFee => 'Fee on-chain';

  @override
  String get lightningMovementForward => 'Forwarding';

  @override
  String get lightningMovementOther => 'Movimento';

  @override
  String lightningChannelsAll(int count) {
    return 'Tutti i canali ($count)';
  }

  @override
  String get lightningOnchainNode => 'On-chain del nodo';

  @override
  String get lightningOnchainBalance => 'Saldo on-chain';

  @override
  String get lightningOnchainConfirmed => 'Confermati';

  @override
  String get lightningOnchainPending => 'In attesa';

  @override
  String get lightningOnchainUtxos => 'UTXO';

  @override
  String get lightningOnchainUtxosEmpty => 'Nessun UTXO';

  @override
  String get lightningOnchainAddresses => 'Indirizzi del nodo';

  @override
  String get lightningOnchainNewAddress => 'Nuovo indirizzo';

  @override
  String get lightningOnchainAddressType => 'Tipo di indirizzo';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'Con saldo';

  @override
  String get lightningOnchainReserved => 'Riservato';

  @override
  String get lightningOnchainBlockHeight => 'Blocco';

  @override
  String get lightningPayments => 'Pagamenti';

  @override
  String get lightningInvoices => 'Fatture';

  @override
  String get lightningInvoicesEmpty => 'Nessuna fattura';

  @override
  String get lightningInvoiceStatusPaid => 'Pagata';

  @override
  String get lightningInvoiceStatusPending => 'In attesa di pagamento';

  @override
  String get lightningInvoiceStatusExpired => 'Scaduta';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Pagata il $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Scade il $date';
  }

  @override
  String get lightningReceivePaid => 'Fattura pagata';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total fatture · $pending in attesa';
  }

  @override
  String get lightningPays => 'Pagamenti inviati';

  @override
  String get lightningPaysEmpty => 'Nessun pagamento';

  @override
  String get lightningPaymentFee => 'Fee';

  @override
  String get lightningPaymentCompleted => 'Completato';

  @override
  String get lightningPaymentPending => 'In corso';

  @override
  String get lightningPaymentFailed => 'Fallito';

  @override
  String get lightningHtlcsEmpty => 'Nessun HTLC';

  @override
  String get lightningHtlcInProgress => 'In volo';

  @override
  String get lightningHtlcIncoming => 'In arrivo';

  @override
  String get lightningHtlcOutgoing => 'In uscita';

  @override
  String get lightningChannelFees => 'Fee di routing';

  @override
  String get lightningFeeEdit => 'Modifica fee';

  @override
  String get lightningFeeBefore => 'Attuali';

  @override
  String get lightningFeeAfter => 'Nuove';

  @override
  String get lightningFeeBaseLabel => 'Base (sat)';

  @override
  String get lightningFeePpmLabel => 'Aliquota (ppm)';

  @override
  String get lightningHtlcMinLabel => 'HTLC minimo (sat)';

  @override
  String get lightningHtlcMaxLabel => 'HTLC massimo (sat)';

  @override
  String get lightningCltvLabel => 'Delta CLTV';

  @override
  String get lightningChannelReserve => 'Nostra riserva';

  @override
  String get lightningChannelToSelfDelay => 'To-self delay';

  @override
  String get lightningFeeConfirmTitle => 'Applicare queste fee di routing?';

  @override
  String get lightningFeeWarning =>
      'Le fee valgono per i pagamenti instradati. La rete accetta poche modifiche al giorno e i peer possono impiegare tempo ad adottarle.';

  @override
  String get lightningFeeUpdated => 'Policy fee aggiornata';

  @override
  String get lightningDiagnostics => 'Diagnostica';

  @override
  String get lightningDiagnosticsSubtitle => 'Contabilità, plugin e forwarding';

  @override
  String get lightningStatsEconomy => 'Economia';

  @override
  String get lightningStatsNet => 'Netto';

  @override
  String get lightningStatsSource => 'Dai dati contabili del nodo (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'Nessun dato contabile';

  @override
  String get lightningStatsTagDeposit => 'Depositi';

  @override
  String get lightningStatsTagInvoice => 'Fatture';

  @override
  String get lightningStatsTagWithdrawal => 'Prelievi';

  @override
  String get lightningStatsTagOnchainFee => 'Fee on-chain';

  @override
  String get lightningStatsTagChannelOpen => 'Aperture canali';

  @override
  String get lightningStatsTagChannelClose => 'Chiusure canali';

  @override
  String get lightningStatsTagRouted => 'Fee di routing guadagnate';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci',
      one: '1 voce',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Plugin';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count attivi';
  }

  @override
  String get lightningPluginInactive => 'inattivo';

  @override
  String get lightningForwardsTitle => 'Forwarding';

  @override
  String get lightningForwardsEmpty => 'Nessun pagamento instradato';

  @override
  String get lightningForwardSettled => 'Regolato';

  @override
  String get lightningForwardFailed => 'Fallito';

  @override
  String get lightningForwardOffered => 'In corso';

  @override
  String get lightningKeysendTitle => 'Invia a un nodo (keysend)';

  @override
  String get lightningKeysendHint => 'Pubkey del nodo destinatario (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Importo (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Fee massima (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Lascia vuoto per usare il default del nodo (0,5%)';

  @override
  String get lightningKeysendWarning =>
      'Keysend paga un nodo senza fattura: i fondi si muovono subito e non si possono annullare.';

  @override
  String get lightningKeysendConfirmTitle =>
      'Inviare questo pagamento keysend?';

  @override
  String get lightningKeysendDestination => 'Destinazione';

  @override
  String get lightningKeysendSent => 'Keysend inviato';

  @override
  String get lightningKeysendInvalidPubkey => 'Pubkey del nodo non valida';

  @override
  String get lightningKeysendInvalidAmount =>
      'Inserisci un importo maggiore di zero';

  @override
  String get lightningKeysendSend => 'Invia';

  @override
  String get walletAddressesTitle => 'Indirizzi e UTXO';

  @override
  String get walletAddressesTabAddresses => 'Indirizzi';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Ricezione (/0)';

  @override
  String get walletAddressesChangeBranch => 'Resto (/1)';

  @override
  String get walletAddressesStatusUnused => 'Mai usato';

  @override
  String get walletAddressesStatusUsed => 'Usato';

  @override
  String get walletAddressesStatusFunds => 'Con saldo';

  @override
  String walletAddressesTxCount(int count) {
    return '$count transazioni';
  }

  @override
  String get walletAddressesEmpty => 'Nessun indirizzo da mostrare';

  @override
  String get walletAddressesHintTap => 'Tocca un indirizzo per copiarlo';

  @override
  String get lightningPeeringGateTitle =>
      'Peering limitato alle release con bit 68';

  @override
  String get lightningPeeringGateBody =>
      'Questo nodo richiede option_blake2b (bit 68) durante l\'handshake: i nodi con release precedenti non possono connettersi. È una scelta del nodo, non un problema dell\'app o del bridge. Usa peer con release .4 o successiva, oppure attendi che la community renda il bit opzionale.';

  @override
  String get lightningPeeringGateLink => 'Matrice di compatibilità';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count peer registrati, nessuno connesso';
  }

  @override
  String get lightningSwapOpen => 'Paga un invoice senza nodo (swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'App web: i pagamenti Lightning usano un provider di swap (nessun nodo richiesto). La connessione al tuo nodo è disponibile nell\'app Android.';

  @override
  String get lightningSwapTitle => 'Pagamento Lightning via provider';

  @override
  String get lightningSwapIntro =>
      'I fondi restano in tua custodia: vanno in un HTLC on-chain (P2WSH) e si sbloccano solo quando il provider paga la tua invoice. Se il pagamento non riesce, puoi recuperare i fondi dopo il time lock.';

  @override
  String get lightningSwapProviderUriHint =>
      'URI del provider (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Collega provider';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Provider collegato: $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Disconnetti';

  @override
  String get lightningSwapInvoiceHint => 'Invoice Lightning (lnbc...)';

  @override
  String get lightningSwapStart => 'Continua';

  @override
  String get lightningSwapAmount => 'Importo invoice';

  @override
  String get lightningSwapFees => 'Commissioni (claim + servizio)';

  @override
  String get lightningSwapTotal => 'Totale da bloccare';

  @override
  String get lightningSwapFund => 'Invia fondi e avvia lo swap';

  @override
  String get lightningSwapFundHint =>
      'I fondi vanno all\'indirizzo HTLC qui sopra. Il pagamento parte dopo 1 conferma.';

  @override
  String get lightningSwapStateLabel => 'Stato';

  @override
  String get lightningSwapHtlc => 'Indirizzo HTLC';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund disponibile dal blocco $height';
  }

  @override
  String get swapStateAwaitingFunding => 'In attesa dei fondi on-chain';

  @override
  String get swapStateConfirming => 'In attesa di conferme';

  @override
  String get swapStatePaying => 'Pagamento Lightning in corso';

  @override
  String get swapStatePaid => 'Invoice pagata, claim in corso';

  @override
  String get swapStateClaiming => 'Claim in corso';

  @override
  String get swapStateCompleted => 'Completato';

  @override
  String get swapStatePaymentFailed => 'Pagamento fallito — fondi recuperabili';

  @override
  String get swapStateExpired => 'Scaduto — fondi recuperabili';

  @override
  String get swapStateRefunded => 'Rimborsato';

  @override
  String get lightningSwapRecoveryTitle => 'Recupero fondi';

  @override
  String get lightningSwapRecoveryHint => 'Blob di recupero (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Importa sessione';

  @override
  String get lightningSwapRefund => 'Recupera fondi (refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Rimborso non ancora disponibile: si sblocca dal blocco $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Copia blob di recupero';

  @override
  String get lightningSwapBlobCopied => 'Blob di recupero copiato';

  @override
  String get lightningSwapClaimTxid => 'Txid del claim';

  @override
  String get lightningSwapClaimHint =>
      'Il claim è una transazione on-chain: la conferma arriva con il blocco successivo (~12 min). Tocca il link per verificarla.';

  @override
  String get lightningSwapInvalidInvoice =>
      'Questo non sembra un invoice Lightning';

  @override
  String get lightningSwapWatchOnly =>
      'Lo swap richiede un wallet con seed (non watch-only)';

  @override
  String get lightningSwapNoUtxos => 'Nessun fondo spendibile in questo wallet';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Errore: $message';
  }

  @override
  String get lightningSwapKnownUris => 'URI provider salvate';

  @override
  String get lightningSwapWalletLabel => 'Wallet';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Saldo: $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Fondi insufficienti: servono $needed sat, disponibili $available sat';
  }

  @override
  String get lightningSwapCancel => 'Annulla swap';

  @override
  String get lightningSwapErrorConnectFailed =>
      'Impossibile raggiungere il provider. Controlla la connessione e riprova.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Collegamento al provider interrotto. Prova a ricollegarti.';

  @override
  String get lightningSwapErrorNotConnected => 'Provider non collegato.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'Questo provider usa un relay che la versione web non può raggiungere. Per pagare con questo provider usa la versione mobile della app.';

  @override
  String get lightningSwapCancelTitle => 'Annullare questo swap?';

  @override
  String get lightningSwapCancelBody =>
      'L\'app dimenticherà questa swap. Il provider la scarta da solo prima della scadenza e nessun fondo è bloccato. Per riprovare con la stessa invoice serve una nuova sessione solo dopo che è scaduta: altrimenti genera una nuova invoice.';

  @override
  String get lightningSwapCancelConfirm => 'Sì, annulla';

  @override
  String get lightningSwapWalletMissing =>
      'Il wallet legato a questa swap non è più disponibile';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Wallet legato: $name';
  }

  @override
  String get lightningInvoiceDelete => 'Cancella fattura';

  @override
  String get lightningInvoiceDeleteTitle => 'Cancellare questa fattura?';

  @override
  String get lightningInvoiceDeleteBody =>
      'La fattura verrà rimossa dal nodo. Se non è pagata non potrà più essere pagata.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Sì, cancella';

  @override
  String get lightningInvoiceDeleted => 'Fattura cancellata';

  @override
  String get lightningChannelPeerAddress => 'Indirizzo peer';
}
