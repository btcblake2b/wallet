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
  String get homeVaultLockedBody =>
      'Le chiavi sono state rimosse dalla memoria dopo l\'inattività. Inserisci la password per rivedere i saldi e firmare di nuovo. I wallet sono al sicuro: non è stato cancellato nulla.';

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
  String get guideTitle => 'Come funziona';

  @override
  String get guideEntryDesc =>
      'Spiegazioni semplici: wallet, seed, commissioni, Lightning.';

  @override
  String get guideIntro =>
      'Questa guida spiega in parole semplici cosa fa l\'app e perché. Non serve leggerla tutta: apri solo il capitolo che ti interessa. Ogni spiegazione è raggiungibile anche dal pallino ⓘ accanto al campo corrispondente.';

  @override
  String get guideOpenFailed => 'Non è stato possibile aprire il browser.';

  @override
  String get guideHintsNote =>
      'I pallini ⓘ si possono nascondere da Impostazioni → Interfaccia.';

  @override
  String get guideSectionBasics => 'Le basi';

  @override
  String get guideSectionSecurity => 'Sicurezza e backup';

  @override
  String get guideSectionTransactions => 'Inviare e ricevere';

  @override
  String get guideSectionLightning => 'Lightning';

  @override
  String get guideSectionAdvanced => 'Per chi vuole approfondire';

  @override
  String get guideFullGuideTitle => 'Guida completa online';

  @override
  String get guideFullGuideDesc =>
      'Sul sito trovi la versione lunga, con esempi e domande frequenti.';

  @override
  String get guideFullGuideOpen => 'Apri la guida';

  @override
  String get infoWhatIsWalletTitle => 'Cos\'è un wallet (e cosa non è)';

  @override
  String get infoWhatIsWalletBody =>
      'Un wallet non \'contiene\' monete: contiene le chiavi private che ti permettono di spendere le monete registrate sulla blockchain. Il saldo lo calcolano gli altri nodi leggendo la catena; l\'app lo ricostruisce dai tuoi indirizzi. Ecco perché se perdi le chiavi perdi i fondi, mentre se perdi il telefono li recuperi con la frase di 12 parole.';

  @override
  String get infoSelfCustodyTitle =>
      'Autocustodia: nessuno può bloccarti i fondi';

  @override
  String get infoSelfCustodyBody =>
      'Qui sei tu la banca: non c\'è un account, un login o un\'azienda che custodisce i tuoi soldi. Vantaggio: nessuno può congelare il tuo saldo. Rischio: nessuno può recuperare la tua password o la tua frase di recupero. È il prezzo della sovranità, e va accettato consapevolmente.';

  @override
  String get infoSeedPhraseTitle => 'Frase di recupero (12 parole)';

  @override
  String get infoSeedPhraseBody =>
      'È la rappresentazione leggibile della tua chiave privata: da quelle parole si ricostruiscono TUTTI i tuoi indirizzi e quindi i fondi. Scrivila su carta, mai in foto, chat, cloud o password manager. Chi la legge può svuotare il wallet; chi la perde ha perso tutto.';

  @override
  String get infoAppEncryptionTitle => 'Cifratura locale e password';

  @override
  String get infoAppEncryptionBody =>
      'La frase resta sul tuo dispositivo cifrata con AES-GCM: la chiave si ricava dalla tua password (o dall\'impronta, che sblocca il keystore del sistema). Nessun server riceve la password. Se la dimentichi non c\'è un \'recupera password\': serve la frase di recupero.';

  @override
  String get infoNetworkBlake2bTitle => 'La rete: bitcoin-blake2b';

  @override
  String get infoNetworkBlake2bBody =>
      'Stai usando bitcoin-blake2b, una rete SPERIMENTALE con regole proprie (hash BLAKE2b, nessuna protezione replay a livello di consenso): non è Bitcoin e le due reti non condividono monete. Tratta questo wallet come un ambiente da testare, non come il tuo salvadanaio definitivo.';

  @override
  String get infoBalanceUtxoTitle => 'Come si forma il saldo';

  @override
  String get infoBalanceUtxoBody =>
      'Non esiste un \'conto\' con un numero: il saldo è la somma degli UTXO, cioè le monete che hai ricevuto e non ancora speso, come banconote in tasca. Una transazione consuma alcuni UTXO e ne crea di nuovi (pagamento + resto). Quando invii a te stesso, il saldo non cambia.';

  @override
  String get infoConfirmationsTitle => 'Conferme';

  @override
  String get infoConfirmationsBody =>
      'Un invio appena fatto è \'in attesa\' (mempool): esiste, ma nessun blocco lo ha ancora registrato. Ogni blocco successivo aggiunge una conferma; da 3 conferme in su un pagamento è ragionevolmente stabile. In attesa il saldo può risultare non disponibile: non è sparito, sta aspettando.';

  @override
  String get infoFeeConceptTitle => 'Perché si paga una commissione';

  @override
  String get infoFeeConceptBody =>
      'La commissione è il compenso per chi include la tua transazione in un blocco. Si paga per dimensione (sat/vB), non per importo: pagare 1.000 o 1.000.000 sat costa uguale. Se il mempool è pieno i prezzi salgono; la commissione NON è un costo dell\'app: va ai miner.';

  @override
  String get infoChangeAddressTitle => 'Il resto (change)';

  @override
  String get infoChangeAddressBody =>
      'Come al supermercato: se gli UTXO che usi valgono più dell\'importo, la differenza torna a te su un indirizzo NUOVO dello stesso wallet (il \'resto\'). È normale vedere una transazione con due output: il pagamento al destinatario e il resto a te.';

  @override
  String get infoLightningVsOnchainTitle => 'On-chain e Lightning';

  @override
  String get infoLightningVsOnchainBody =>
      'On-chain = ogni movimento è una transazione pubblica sulla catena: sicuro e verificabile, ma più lento e con fee per transazione. Lightning = pagamenti istantanei e quasi gratis dentro \'canali\' aperti con una transazione on-chain. Aprire un canale sposta fondi on-chain nel canale; chiuderlo li riporta on-chain.';

  @override
  String get infoPrivacyBasicsTitle => 'Privacy: cosa vede chi';

  @override
  String get infoPrivacyBasicsBody =>
      'Ogni \'Ricevi\' crea un indirizzo nuovo: riusarlo collega i tuoi pagamenti tra loro. L\'app non ha account né telemetria e chiede i dati on-chain a un\'API pubblica (mempool.guide), che vede il tuo IP. Per la massima privacy usa una VPN o il tuo nodo, e non pubblicare mai la tua xpub.';

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
      'In una sola transazione puoi pagare fino a 20 indirizzi, dividendo la commissione invece di pagarla una volta per bonifico. Prima di firmare vedi l\'elenco completo dei destinatari.';

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
  String get walletUtxoWaitingBadge => 'Periodo di attesa';

  @override
  String walletUtxoWaitingBlocks(int count) {
    return '$count blocchi allo sblocco';
  }

  @override
  String walletUtxoWaitingHint(int blocks) {
    return 'I payout di mining (coinbase) vengono propagati dalla rete solo dopo $blocks blocchi: non sono ancora spendibili.';
  }

  @override
  String walletBalanceWaiting(String amount) {
    return 'In attesa: $amount';
  }

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
    return 'Questa Informativa Privacy è provvisoria e sarà sostituita dalla versione definitiva pubblicata sul sito ufficiale quando disponibile.\n\n1) DATI SUL DISPOSITIVO. L\'app non richiede account e non salva dati personali su server dell\'autore. Seed cifrata (AES-256-GCM), preferenze e consensi restano SOLO sul tuo dispositivo.\n\n2) DATI TRASMESSI A TERZI PER IL FUNZIONAMENTO. Per mostrare saldo e commissioni l\'app interroga API pubbliche di terze parti:\n• mempool.guide (esploratore blockchain).\n• Se mempool.guide non è disponibile, l\'app può interrogare due mirror comunitari Esplora-compatibili (mempool.kilombino.com, mempool.maveth.ca). Questa opzione è disattivabile nelle Impostazioni.\n• Se attivi il prezzo automatico nelle Impostazioni, l\'app legge l\'ultimo trade XBT/USDC da neoxa.exchange (NeoXEX) su richiesta. Se la valuta del controvalore non è USD, l\'app legge anche i cambi USDT da api.coinbase.com. Entrambe le opzioni sono disattivabili nelle Impostazioni.\nA ogni richiesta vengono trasmessi il tuo indirizzo IP e l\'indirizzo pubblico del wallet interrogato. Chiavi private e seed non vengono MAI trasmessi.\n\n3) NESSUN TRACKER. Nessuna analytics, nessuna pubblicità, nessun cookie all\'interno dell\'app.\n\n4) DIRITTI (GDPR artt. 13-14). Hai diritto di accesso, rettifica, cancellazione e opposizione scrivendo al Titolare del trattamento: $holder — $email. Poiché non conserviamo dati personali, questi diritti sono in gran parte già garantiti dal fatto che i dati restano sul tuo dispositivo.';
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
  String get scanQrInvalidMnemonic =>
      'Il codice scansionato non è una frase mnemonica BIP39 valida.';

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
  String get importScreenScanSeed => 'Scansiona il QR della seed';

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
  String get lightningCoinControlTitle => 'Coin control (opzionale)';

  @override
  String get lightningCoinControlHint =>
      'Scegli quali output on-chain del nodo finanziano il canale. Senza selezione il nodo sceglie da sé.';

  @override
  String get lightningCoinControlNoneSelected =>
      'Nessuna selezione: scelta automatica del nodo.';

  @override
  String get lightningCoinControlSelectedTotal => 'Totale selezionato';

  @override
  String get lightningCoinControlUnconfirmed => 'non confermato';

  @override
  String get lightningCoinControlUnavailable =>
      'Elenco output non disponibile: il nodo sceglierà automaticamente.';

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
  String get lightningSplice => 'Ridimensiona canale';

  @override
  String get lightningSpliceTitle => 'Ridimensiona il canale senza chiuderlo';

  @override
  String get lightningSpliceIn => 'Aggiungi fondi';

  @override
  String get lightningSpliceOut => 'Ritira fondi';

  @override
  String get lightningSpliceAmountLabel => 'Importo (sat)';

  @override
  String get lightningSpliceEstimate => 'Stima fee on-chain';

  @override
  String lightningSpliceFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Fee on-chain: circa $feeString sat';
  }

  @override
  String get lightningSpliceFeeUnavailable =>
      'Il nodo non ha restituito una stima della fee';

  @override
  String get lightningSpliceConfirm =>
      'Ridimensionare il canale ora? Il canale resta online e viene trasmessa una transazione on-chain.';

  @override
  String get lightningSpliceDone => 'Canale ridimensionato';

  @override
  String get lightningSpliceInvalidAmount =>
      'Inserisci un importo maggiore di zero';

  @override
  String get lightningSpliceUnavailable =>
      'Il ridimensionamento è disponibile solo su canali utilizzabili e con il peer online.';

  @override
  String get lightningSpliceChannelFailed =>
      'Il nodo ha rifiutato lo splice: il peer potrebbe non supportarlo (serve CLN con le firme unificate). Il canale è rimasto invariato.';

  @override
  String get lightningSpliceBridgeOutdated =>
      'Il bridge di questo nodo non espone ancora il ridimensionamento: aggiorna il bridge sul server.';

  @override
  String lightningSpliceOnchainAvailable(String sats) {
    return 'On-chain del nodo: $sats sat';
  }

  @override
  String get lightningSpliceInsufficientOnchain =>
      'L\'on-chain del nodo non basta per questo importo: ricarica il wallet on-chain del nodo (Deposita) e riprova.';

  @override
  String get lightningReceiveModeInvoice => 'Fattura una volta';

  @override
  String get lightningReceiveModeOffer => 'Codice riutilizzabile';

  @override
  String get lightningOfferTitle => 'Codice di pagamento riutilizzabile';

  @override
  String get lightningOfferReusableHint =>
      'Condividi questo codice: chiunque può pagarlo, scegliendo l\'importo se l\'hai lasciato libero. Non scade come una fattura.';

  @override
  String get lightningOfferAmountOptional => 'Importo (sat) — opzionale';

  @override
  String get lightningOfferAmountLabel => 'Importo (sat)';

  @override
  String get lightningOfferAmountRequired =>
      'Inserisci l\'importo per pagare questa offerta';

  @override
  String lightningOfferFixedAmount(String sats) {
    return 'Importo dell\'offerta: $sats sat';
  }

  @override
  String get lightningOfferDefaultDescription => 'Pagamento';

  @override
  String get lightningPayOffer => 'Paga offerta';

  @override
  String get lightningCrossChainEntry => 'Paga una fattura BTC (SHA-256)';

  @override
  String get lightningCrossChainTitle => 'Pagamento cross-chain';

  @override
  String get lightningCrossChainHint =>
      'Paga una fattura Lightning della chain SHA-256 con i tuoi fondi BLAKE2b, tramite un bridge esterno non-custodial. Il bridge incassa solo dopo aver pagato la fattura; altrimenti il pagamento torna a te.';

  @override
  String get lightningCrossChainCheck => 'Verifica costo';

  @override
  String lightningCrossChainCost(String sats) {
    return 'Paghi: $sats sat';
  }

  @override
  String lightningCrossChainInvoiceAmount(String sats) {
    return 'Importo fattura: $sats sat';
  }

  @override
  String lightningCrossChainRate(String rate) {
    return 'Cambio: 1 XBT = $rate BTC';
  }

  @override
  String lightningCrossChainSpread(String percent) {
    return 'Spread del bridge: $percent%';
  }

  @override
  String lightningCrossChainWait(int seconds) {
    return 'Attesa stimata: circa $seconds s';
  }

  @override
  String get lightningCrossChainPay => 'Paga tramite bridge';

  @override
  String get lightningCrossChainConfirmTitle => 'Pagare tramite il bridge?';

  @override
  String lightningCrossChainConfirmBody(String sats) {
    return 'Pagherai $sats sat su questa chain. I fondi restano in sospeso finché il bridge non paga la fattura di destinazione; se non ci riesce, il pagamento torna a te.';
  }

  @override
  String get lightningCrossChainDone => 'Pagamento completato';

  @override
  String lightningCrossChainState(String state) {
    return 'Stato del bridge: $state';
  }

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
  String get lightningPeeringGateNewTitle =>
      'Peering limitato alle release del nuovo protocollo';

  @override
  String get lightningPeeringGateNewBody =>
      'Questo nodo usa i feature bit definitivi (option_blake2b 512, option_unified_sigs 514): i nodi non aggiornati — release .4 e precedenti — non possono connettersi. È una scelta della rete, non un problema dell\'app o del bridge. I peer devono aggiornare alla release .5 o successiva.';

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
  String get lightningSwapProviderDefaultLabel =>
      'Nodo btcblake2b (consigliato)';

  @override
  String get lightningSwapProviderChecking => 'Verifico il nodo predefinito...';

  @override
  String get lightningSwapProviderReachable => 'Nodo predefinito raggiungibile';

  @override
  String get lightningSwapProviderDown =>
      'Il nodo predefinito non risponde in questo momento.';

  @override
  String lightningSwapProviderSendLimit(String min, String max) {
    return 'Ora puoi inviare da $min a $max sat';
  }

  @override
  String lightningSwapProviderLiquidity(String amount) {
    return 'Liquidità disponibile ora: $amount sat';
  }

  @override
  String get lightningSwapPeerCheck => 'Verifica destinatario';

  @override
  String lightningSwapPeerReachable(String amount) {
    return 'Destinatario raggiungibile: $amount sat da pagare';
  }

  @override
  String get lightningSwapErrorPeerUnreachable =>
      'Il destinatario non è raggiungibile dal provider: nessuna rotta verso il suo nodo. Controlla la fattura o riprova più tardi.';

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
  String get lightningSwapHistoryTitle => 'Storico swap';

  @override
  String get lightningSwapHistoryEmpty =>
      'Nessuno swap per ora: i pagamenti fatti con un provider compariranno qui.';

  @override
  String get lightningSwapDetailTitle => 'Dettaglio swap';

  @override
  String get lightningSwapDetailCreated => 'Creato';

  @override
  String get lightningSwapDetailSummary => 'Riepilogo';

  @override
  String get lightningSwapDetailProtocol => 'Dati di protocollo';

  @override
  String get lightningSwapDetailSwapId => 'ID swap';

  @override
  String get lightningSwapDetailInvoice => 'Invoice';

  @override
  String get lightningSwapDetailPaymentHash => 'Payment hash';

  @override
  String get lightningSwapDetailProvider => 'Provider';

  @override
  String get lightningSwapDetailFundingTx => 'Transazione di funding';

  @override
  String get lightningSwapOpenInExplorer => 'Apri nell\'explorer';

  @override
  String lightningSwapRefundSent(String txid) {
    return 'Refund inviato: $txid';
  }

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
  String lightningSwapInsufficientFundsWaiting(
      String needed, String available, String waiting) {
    return 'Fondi insufficienti: servono $needed sat, disponibili $available sat ($waiting sat in periodo di attesa)';
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
  String get lightningSwapErrorPaymentFailed =>
      'Il provider non è riuscito a pagare questa invoice. I tuoi fondi restano nell\'HTLC: puoi recuperarli con il rimborso (vedi il blocco qui sotto).';

  @override
  String get lightningSwapErrorProviderUnavailable =>
      'Il provider non può pagare in questo momento (nessuna rotta o liquidità insufficiente). Riprova più tardi.';

  @override
  String get lightningSwapErrorRateLimited =>
      'Il provider è temporaneamente al limite di capacità. Riprova più tardi.';

  @override
  String get lightningSwapErrorDuplicateSwap =>
      'Questa invoice è già stata usata in un altro swap.';

  @override
  String get lightningSwapErrorQuoteExpired =>
      'La richiesta è scaduta. Avvia di nuovo lo swap.';

  @override
  String get lightningSwapErrorInvoiceInvalid =>
      'Il provider ha rifiutato questa invoice: non è valida.';

  @override
  String get lightningSwapErrorInvoiceExpired =>
      'Questa invoice è scaduta. Chiedine una nuova.';

  @override
  String get lightningSwapErrorAmountOutOfRange =>
      'Il provider non accetta questo importo (fuori dall\'intervallo consentito).';

  @override
  String get lightningSwapErrorFundingTimeout =>
      'Il funding non è stato confermato in tempo: lo swap è scaduto senza alcun pagamento.';

  @override
  String get lightningSwapErrorTooLate =>
      'Il pagamento è stato annullato perché troppo vicino al time lock. I tuoi fondi sono recuperabili.';

  @override
  String get lightningSwapRefundHint =>
      'Questi fondi restano tuoi: il rimborso si sblocca automaticamente al time lock, anche se il provider sparisce.';

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

  @override
  String get lightningSpliceNodeTooOld =>
      'Ridimensionare un canale richiede un nodo alla release .6 o successiva (consigliata .9). Questo nodo è più vecchio, quindi l\'azione è nascosta. Aggiorna il nodo per abilitarla.';

  @override
  String get lightningSpliceNodeOutdated =>
      'Questo nodo è su una release precedente alla .9: gli aggiornamenti dalla .8 chiudono una vulnerabilità di splice per cui un nodo può perdere i fondi del canale. Il ridimensionamento funziona, ma aggiorna alla .9 appena puoi.';

  @override
  String get lightningDiscoveryTitle => 'Trova peer e liquidità';

  @override
  String get lightningDiscoveryBody =>
      'Su questa rete non esiste un catalogo centrale. Questi sono i punti di riferimento attivi dove la community elenca nodi, canali e liquidità in entrata.';

  @override
  String get lightningDiscoveryNetworkTitle => 'Explorer di rete (Paperclip)';

  @override
  String get lightningDiscoveryNetworkBody =>
      'Nodi pubblici, canali e capacità annunciata.';

  @override
  String get lightningDiscoveryLspTitle =>
      'Liquidità in entrata (LSP Paperclip)';

  @override
  String get lightningDiscoveryLspBody =>
      'Un canale verso il tuo nodo, pagato on-chain in XBT.';

  @override
  String get lightningDiscoveryNodexTitle => 'Nodex - canali e fee';

  @override
  String get lightningDiscoveryNodexBody =>
      'Explorer dei canali con fee nei due versi e uptime.';

  @override
  String get lightningDiscoverySwapTitle => 'Lightning Fork Swap';

  @override
  String get lightningDiscoverySwapBody =>
      'Swap non-custodial tra Lightning e on-chain per spostare liquidità.';

  @override
  String get lightningDiscoveryWatchtowerTitle => 'Watchtower (solo nodi lnd)';

  @override
  String get lightningDiscoveryWatchtowerBody =>
      'Un watchtower sorveglia la catena mentre il nodo è offline e punisce il peer che pubblica uno stato vecchio. Usane più di uno: lnd richiede wtclient.active=true e Tor. I nodi CLN parlano invece BOLT 13 (TEOS), che l\'app non configura ancora. Aggiungile con lncli wtclient add <uri>.';

  @override
  String get lightningDiscoveryOpenFailed =>
      'Il browser non ha aperto il link.';

  @override
  String get lightningInboundMissingTitle => 'Non puoi ancora ricevere';

  @override
  String get lightningInboundMissingBody =>
      'Questo nodo non ha liquidità in entrata: serve che un altro nodo apra un canale verso di lui prima che qualcuno possa pagarti. Finché non succede, le fatture che condividi non possono essere pagate.';

  @override
  String get lightningInboundMissingCta => 'Ottieni liquidità in entrata';

  @override
  String get lightningInboundMissingRefresh => 'Ricontrolla';

  @override
  String get webVaultNoticeTitle => 'Stai usando la versione browser';

  @override
  String get webVaultNoticeBody =>
      'Qui la seed cifrata è salvata nel browser (localStorage, con copia su IndexedDB) e la chiave è avvolta dalla tua password. Il vault si blocca dopo 10 minuti di inattività e quando la pagina viene nascosta, ma codice eseguito nella pagina mentre il vault è sbloccato può leggere le chiavi: il browser non sa difendersi da questo. Per importi reali usa l\'app Android, dove le chiavi restano nel keyring di sistema.';

  @override
  String get webVaultNoticeDownload => 'Scarica l\'app Android';

  @override
  String get splashStartupError => 'Impossibile avviare l\'app';

  @override
  String get splashRetry => 'Riprova';

  @override
  String webVaultOriginOfficial(Object origin) {
    return 'Dominio verificato: $origin';
  }

  @override
  String webVaultOriginDev(Object origin) {
    return 'Ambiente di test locale: $origin';
  }

  @override
  String webVaultOriginUnofficial(Object origin) {
    return 'ATTENZIONE: questo non è il dominio ufficiale. Stai usando $origin — quello vero è app.btcblake2b.org. Non inserire qui seed o password.';
  }

  @override
  String get receiveNeedsBackupTitle => 'Prima metti al sicuro la seed';

  @override
  String get receiveNeedsBackupBody =>
      'Nel browser la seed cifrata sta nello storage di questo sito: un aggiornamento della PWA o «cancella dati del sito» la cancellano, e un indirizzo condiviso adesso riceverebbe fondi che non potresti più spendere. Conferma il backup della seed (o sposta il wallet sull\'app) prima di ricevere.';

  @override
  String get receiveNeedsBackupAction => 'Fai il backup';

  @override
  String get merchantChargeTitle => 'Incassa';

  @override
  String get merchantChargeAmount => 'Importo';

  @override
  String get merchantChargeAmountInvalid =>
      'Inserisci un importo maggiore di zero.';

  @override
  String get merchantChargeLabel => 'Descrizione (facoltativa)';

  @override
  String get merchantChargeModeLightning => 'Lightning';

  @override
  String get merchantChargeModeOnchain => 'On-chain';

  @override
  String get merchantChargeLightningHint =>
      'Il cliente paga la fattura Lightning: l\'accredito è immediato, appena il nodo la riceve.';

  @override
  String get merchantChargeOnchainHint =>
      'Il cliente inquadra il QR: l\'importo è già dentro, deve solo confermare.';

  @override
  String get merchantChargeLightningUnavailable =>
      'Nessun nodo Lightning collegato: per ora puoi incassare on-chain. Collega il nodo dalla scheda Lightning per accettare anche pagamenti Lightning.';

  @override
  String get merchantChargeCreate => 'Crea richiesta di pagamento';

  @override
  String get merchantChargeInvoiceTitle => 'Fattura Lightning';

  @override
  String get merchantChargeUriTitle => 'URI Bitcoin (BIP21)';

  @override
  String get merchantChargeWaiting => 'In attesa di pagamento…';

  @override
  String get merchantChargePaid => 'Pagamento ricevuto';

  @override
  String get merchantChargeNew => 'Nuova richiesta';

  @override
  String get merchantConvertTitle => 'Converti in BTC';

  @override
  String get merchantConvertIntro =>
      'XBT vive sulla rete bitcoin-blake2b, separata da Bitcoin: convertirla in BTC (o il contrario) è uno swap cross-chain. Questa app non lo fa e non può farlo: nessun cambio, nessuna custodia. La conversione avviene su servizi di terzi non-custodial che scegli tu.';

  @override
  String get merchantConvertAddressTitle => 'Il tuo indirizzo XBT';

  @override
  String get merchantConvertAddressBody =>
      'Copia l\'indirizzo del wallet che vuoi usare là, oppure incassa prima XBT qui e converti dopo. Non inviare mai fondi a un servizio che ti chiede la seed.';

  @override
  String get merchantConvertUnnamedWallet => 'Wallet';

  @override
  String get merchantConvertPaperclipTitle => 'Paperclip Bridge (beta)';

  @override
  String get merchantConvertPaperclipBody =>
      'Bridge non-custodial della community: incassa solo a fattura realmente pagata. Beta, non verificato da terzi.';

  @override
  String get merchantConvertForkTitle => 'Lightning Fork Swap';

  @override
  String get merchantConvertForkBody =>
      'Swap della community, con donazioni on-chain usate solo per la sua liquidità. Controlla fee e limiti prima di inviare.';

  @override
  String get merchantConvertWarningTitle => 'Prima di convertire';

  @override
  String get merchantConvertWarningBody =>
      '1) Confronta quanto ricevi con quanto invii: su importi piccoli le fee possono mangiarsi la differenza. 2) Uno swap non è reversibile: controlla indirizzo e rete. 3) Noi non incassiamo, non custodiamo e non garantiamo nulla: se un servizio si blocca, può rispondere solo quel servizio. 4) Per importi reali, fai prima una prova piccola.';

  @override
  String get merchantConvertOpen => 'Converti';

  @override
  String get fiatPriceShow => 'Mostra il controvalore in dollari';

  @override
  String get fiatPriceNotSet =>
      'Nessun prezzo impostato: aggiungilo per vedere il valore';

  @override
  String fiatPriceCurrent(Object cents) {
    return '1 XBT = $cents';
  }

  @override
  String get fiatPriceSet => 'Imposta il prezzo di XBT';

  @override
  String get fiatPriceSetDesc =>
      'Il prezzo usato per il controvalore: inseriscilo tu o fallo leggere da NeoXEX.';

  @override
  String get fiatPriceDialogBody =>
      'Inserisci il prezzo di 1 XBT in USD. Se preferisci, attiva il prezzo automatico nelle Impostazioni: l\'app legge l\'ultimo trade XBT/USDC da NeoXEX su richiesta (e il cambio USDT della valuta scelta). Il valore mostrato è indicativo, non una quotazione.';

  @override
  String get fiatPriceFieldLabel => 'Prezzo di 1 XBT';

  @override
  String get fiatPriceSave => 'Salva';

  @override
  String get fiatPriceInvalid =>
      'Prezzo non valido: usa un numero maggiore di zero, al massimo 2 decimali.';

  @override
  String get fiatPriceManualNote => 'prezzo tuo, non una quotazione';

  @override
  String get fiatPriceMarketNote => 'prezzo di mercato, ultimo trade NeoXEX';

  @override
  String get fiatPriceCurrency => 'Valuta del controvalore';

  @override
  String get fiatPriceCurrencyDesc => 'Convertito col cambio USDT';

  @override
  String get fiatPriceFxFailed =>
      'Cambio non disponibile: collegati a internet e riprova.';

  @override
  String get fiatPriceAuto => 'Leggi il prezzo da NeoXEX';

  @override
  String get fiatPriceAutoDesc =>
      'Legge l\'ultimo trade XBT/USDC su richiesta. Nessun polling, nessuna richiesta in background.';

  @override
  String get fiatPriceAutoUpdated => 'Prezzo aggiornato da NeoXEX';

  @override
  String get fiatPriceAutoFailed =>
      'NeoXEX non raggiungibile: resta il prezzo precedente.';

  @override
  String get balanceChangeUnitHint =>
      'Tocca per passare il saldo fra XBT, sats e dollari';

  @override
  String get psbtSpendTitle => 'Spendi con PSBT';

  @override
  String get psbtSpendIntro =>
      'Un wallet watch-only non può firmare. Crea qui la PSBT, firmala su un dispositivo che ha il seed, poi trasmettila da lì.';

  @override
  String get psbtCreate => 'Crea PSBT';

  @override
  String get psbtCreating => 'Creo la PSBT…';

  @override
  String psbtDraftReady(Object change, Object fee) {
    return 'PSBT pronta · fee $fee sat · resto $change sat';
  }

  @override
  String get psbtQrTitle => 'Scansiona questa PSBT';

  @override
  String psbtQrFrames(Object count) {
    return '$count frame — tieni inquadrato mentre il QR ruota';
  }

  @override
  String get psbtCopyBase64 => 'Copia PSBT (base64)';

  @override
  String get psbtSignTitle => 'Firma una PSBT';

  @override
  String get psbtSignIntro =>
      'Incolla o scansiona una PSBT creata su un altro dispositivo. Controlla destinatari e fee prima di firmare.';

  @override
  String get psbtPasteLabel => 'PSBT (base64)';

  @override
  String get psbtScan => 'Scansiona QR';

  @override
  String get psbtReviewTitle => 'Riepilogo';

  @override
  String psbtReviewFee(Object fee) {
    return 'Fee: $fee sat';
  }

  @override
  String psbtReviewInputs(Object count) {
    return 'Input: $count';
  }

  @override
  String psbtReviewOutputs(Object count) {
    return 'Destinatari: $count';
  }

  @override
  String get psbtSign => 'Firma';

  @override
  String get psbtSignedTitle => 'PSBT firmata';

  @override
  String get psbtBroadcast => 'Trasmetti';

  @override
  String get psbtBroadcasting => 'Trasmissione…';

  @override
  String psbtBroadcastDone(Object txid) {
    return 'Inviata: $txid';
  }

  @override
  String get psbtInvalid => 'PSBT non valida';

  @override
  String get psbtNoFrames => 'Nessun frame PSBT riconosciuto';

  @override
  String psbtScanProgress(Object received, Object total) {
    return 'Frame letti: $received/$total';
  }

  @override
  String get psbtSigning => 'Firma in corso…';

  @override
  String get psbtNeedsSeed =>
      'Questo wallet non ha il seed: firmala sul dispositivo che lo possiede.';

  @override
  String get indicesCorruptTitle => 'Stato indici non disponibile';

  @override
  String get indicesCorruptBody =>
      'Il wallet legge ancora saldo e storico, ma ricezione e invio sono disabilitati finché lo stato degli indici non viene ripristinato. Verifica il backup, poi riprova la scansione o riparti da zero con l’avviso mostrato.';

  @override
  String get indicesAnomalousTitle => 'Indice anomalo';

  @override
  String get indicesAnomalousBody =>
      'L’indice salvato è molto oltre l’intervallo atteso per questo wallet. Ripristina da un backup o contatta il supporto: ripartire da zero riuserebbe indirizzi già derivati.';

  @override
  String get indicesAdoptionTitle => 'Novità: indirizzi a rotazione';

  @override
  String get indicesAdoptionBody =>
      'Da ora il wallet usa un indirizzo nuovo per ogni incasso, così gli incassi non sono più collegabili fra loro. Continuare?';

  @override
  String get indicesAlreadyAssigned =>
      'Questo è l’indirizzo già assegnato: non ne è stato creato uno nuovo.';

  @override
  String receiveGapFoundAtIndex(int index) {
    return 'Ricezione: verificata fino all’indice $index';
  }

  @override
  String receiveGapPartial(int probed, int requested) {
    return 'Ricezione: verifica parziale, $probed/$requested';
  }

  @override
  String receiveGapInterrupted(int probed, int requested) {
    return 'Ricezione: verifica interrotta a $probed/$requested — explorer non raggiungibile o tempo esaurito. Riprova.';
  }

  @override
  String get indicesActionRetry => 'Riprova la scansione';

  @override
  String get indicesActionRestore => 'Ripristina da backup';

  @override
  String get indicesActionSupport => 'Contatta il supporto';

  @override
  String get indicesActionContinue => 'Continua';

  @override
  String get indicesSeedRequiredTitle => 'Sblocca per derivare l’indirizzo';

  @override
  String get indicesSeedRequiredBody =>
      'Questo wallet è stato creato prima che venisse salvata la chiave pubblica dell’account. Sblocca il vault una volta: la chiave viene derivata e salvata, e da quel momento ricevere non richiede più la seed.';

  @override
  String get indicesSeedMismatchTitle => 'Seed non corrispondente';

  @override
  String get indicesSeedMismatchBody =>
      'Il seed salvato su questo dispositivo non deriva gli indirizzi di questo wallet. Per sicurezza non viene salvata alcuna chiave pubblica, così gli indirizzi con storia restano raggiungibili. Verifica di aver importato il wallet giusto o contatta il supporto.';

  @override
  String get indicesActionUnlock => 'Sblocca';
}
