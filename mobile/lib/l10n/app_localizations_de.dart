// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'Keine Verbindung';

  @override
  String get homeNoConnectionCreate =>
      'Wallet kann ohne aktive Internetverbindung nicht erstellt werden. Die Adresse muss im Netzwerk verifiziert werden. Bitte versuche es erneut, wenn die Verbindung wiederhergestellt ist.';

  @override
  String get homeNoConnectionImport =>
      'Wallet kann ohne aktive Internetverbindung nicht importiert werden. Das Wallet muss auf dem Server registriert werden.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Wallet erfolgreich erstellt.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Fehler beim Erstellen des Wallets: $error';
  }

  @override
  String get homeImportWallet => 'Wallet importieren';

  @override
  String get homeCreateWallet => 'Wallet erstellen';

  @override
  String get homeSelected => 'ausgewählt';

  @override
  String get homeDeleteSelected => 'Ausgewählte löschen';

  @override
  String homeDeleteConfirm(int count) {
    return '$count Wallets löschen? Dieser Vorgang ist irreversibel.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count Wallets erfolgreich gelöscht.';
  }

  @override
  String get homeWalletImported => 'Wallet erfolgreich importiert.';

  @override
  String get homeSecurityWarning =>
      'Diese Software wird \"wie besehen\" ohne jegliche Gewährleistung bereitgestellt. Der Hersteller haftet nicht für Verluste von Geldern, Diebstahl, Hacking, Transaktionsfehler oder Schäden aus der Nutzung der App. Die Wallet garantiert keinen Schutz gegen vorherige Kopien der Seed. Nur für kleine Beträge verwenden.';

  @override
  String get homeDisclaimerAccept => 'Akzeptieren';

  @override
  String get legalInfoTitle => 'Rechtliche Infos';

  @override
  String get homeLocalWallets => 'Lokale Wallets';

  @override
  String homeErrorLoading(Object error) {
    return 'Fehler beim Laden des Wallets: $error';
  }

  @override
  String get homeEmptyTitle => 'Keine Wallets';

  @override
  String get homeEmptySubtitle =>
      'Erstelle deine erste Bitcoin-Wallet, um zu beginnen.';

  @override
  String get homeBalanceTitle => 'AKTIVES GUTHABEN';

  @override
  String get balanceUnavailable => 'Saldo nicht verfügbar';

  @override
  String get homeBackupVerified => 'Backup bestätigt';

  @override
  String get homeBackupNotVerified => 'Backup nicht bestätigt';

  @override
  String get homeLockVault => 'Tresor sperren';

  @override
  String get homeVaultLocked => 'Tresor gesperrt';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionSecurity => 'Sicherheit';

  @override
  String get settingsSectionAppearance => 'Darstellung';

  @override
  String get settingsSectionTools => 'Werkzeuge';

  @override
  String get settingsSectionInfo => 'Informationen';

  @override
  String get settingsTheme => 'Dunkles Design';

  @override
  String get settingsAppLock => 'App-Sperre';

  @override
  String get settingsAppLockDesc =>
      'Biometrie oder Telefon-PIN bei jedem Öffnen verlangen';

  @override
  String get settingsAppLockUnavailable =>
      'Auf diesem Gerät ist keine Biometrie registriert';

  @override
  String get settingsAppLockEnableFailed =>
      'Überprüfung fehlgeschlagen: Sperre nicht aktiviert';

  @override
  String get settingsAppLockEnabled => 'App-Sperre aktiviert';

  @override
  String get settingsAppLockDisabled => 'App-Sperre deaktiviert';

  @override
  String get settingsExplorerMirrors => 'Backup-Explorer';

  @override
  String get settingsExplorerMirrorsDesc =>
      'Wenn mempool.guide nicht antwortet, fragt die App zwei Community-Mirror ab. Deaktivieren, um nur mempool.guide zu verwenden.';

  @override
  String get settingsSectionInterface => 'Oberfläche';

  @override
  String get settingsInfoDots => 'Info-Hinweise';

  @override
  String get settingsInfoDotsDesc =>
      'Zeige die kleinen Info-Schaltflächen, die jede Funktion erklären';

  @override
  String get infoCoinControlTitle => 'Coin Control (UTXO-Auswahl)';

  @override
  String get infoCoinControlBody =>
      'Dein Saldo besteht aus UTXOs — den empfangenen Stücken. Hier kannst du auswählen, welche davon ausgegeben werden: Die Transaktion verwendet nur diese und lässt kleine oder inaktive Stücke beiseite.';

  @override
  String get infoDustLimitTitle => 'Mindestbetrag (Dust)';

  @override
  String get infoDustLimitBody =>
      'Outputs unter 546 sat werden vom Netzwerk als Dust abgelehnt. Beträge unter dieser Grenze können nicht gesendet werden.';

  @override
  String get infoFeeRateTitle => 'Transaktionsgebühr';

  @override
  String get infoFeeRateBody =>
      'Die Gebühr wird pro Einheit der Transaktionsgröße (sat/vB) gezahlt: Je schneller du die Bestätigung willst, desto mehr zahlst du. Wirtschaftlich kann Stunden dauern, Priorität wenige Minuten. Benutzerdefiniert ist für den Fall, dass du die aktuelle Mempool-Gebühr kennst.';

  @override
  String get infoBatchSendTitle => 'Mehrere Empfänger (Batch)';

  @override
  String get infoBatchSendBody =>
      'In einer einzigen Transaktion kannst du bis zu 5 Adressen bezahlen und teilst die Gebühr, anstatt sie pro Überweisung einmal zu zahlen. Alle Empfänger werden vor dem Signieren in der Bestätigung angezeigt.';

  @override
  String get infoBumpFeeTitle => 'Gebühr erhöhen (RBF)';

  @override
  String get infoBumpFeeBody =>
      'Eine ausstehende Transaktion kann durch eine neue mit höherer Gebühr ersetzt werden (BIP125). Die Originaltransaktion wird storniert und nur die Ersatztransaktion kann bestätigen — Zieladresse und Betrag bleiben gleich.';

  @override
  String get infoXpubTitle => 'Öffentlicher Kontoschlüssel (xpub)';

  @override
  String get infoXpubBody =>
      'Der xpub generiert alle deine Empfangsadressen. Er kann keine Mittel bewegen, deckt aber vollen Saldo und Verlauf auf: Teile ihn nur mit vertrauenswürdigen Apps (z.B. einem Watch-Only-Wallet).';

  @override
  String get infoReceiveAddressTitle => 'Empfangsadresse';

  @override
  String get infoReceiveAddressBody =>
      'Jede Empfangen-Aktion zeigt eine frische Adresse, ausgewählt aus nie genutzten: So bleiben Zahlungen nicht verknüpfbar. Eine Adresse wiederzuverwenden ist kein Fehler, macht deine Transaktionen aber leichter nachvollziehbar.';

  @override
  String get infoWatchOnlyTitle => 'Watch-Only-Wallet';

  @override
  String get infoWatchOnlyBody =>
      'Du hast nur den xpub importiert: Die App sieht Saldo und Verlauf, besitzt aber keinen privaten Schlüssel und kann daher nicht signieren. Um von diesem Wallet auszugeben, benötigst du das Gerät, das die Seed enthält.';

  @override
  String get infoSignVerifyTitle => 'Nachricht signieren / verifizieren';

  @override
  String get infoSignVerifyBody =>
      'Das Signieren beweist, dass eine Adresse dir gehört, ohne Mittel zu bewegen. Jeder kann dann die Signatur gegen diese Adresse und dieselbe Nachricht verifizieren.';

  @override
  String get infoChannelCapacityTitle => 'Kanal-Kapazität';

  @override
  String get infoChannelCapacityBody =>
      'Die Gesamtmenge an Satoshi im Kanal, aufgeteilt zwischen dir und deinem Peer. Mehr Kapazität bedeutet, größere Zahlungen abwickeln zu können. Kapazität = lokaler Saldo + entfernter Saldo.';

  @override
  String get infoChannelReserveTitle => 'Kanal-Reserve';

  @override
  String get infoChannelReserveBody =>
      'Ein kleiner Teil deiner Mittel muss als Sicherheitsdeposit geblockt bleiben (die \'Reserve\'). Sie stellt sicher, dass beide Parteien etwas zu verlieren haben — wenn die andere Seite böswillig offline geht, kann die Reserve verwendet werden, um sie on-chain zu bestrafen.';

  @override
  String get infoToSelfDelayTitle => 'Verzögerung zum Eigenen';

  @override
  String get infoToSelfDelayBody =>
      'Bei einer Zwangsschließung wird deine On-Chain-Ausgabe um diese Anzahl von Blöcken verzögert (typisch 144 = ~1 Tag). Dies gibt deinem Peer Zeit, seine Mittel zuerst zu beanspruchen und verhindert Double-Spend-Angriffe auf den Kanalstatus.';

  @override
  String get infoHtlcTitle => 'HTLC (Hashed Time-Locked Contract)';

  @override
  String get infoHtlcBody =>
      'Ein HTLC ist eine bedingte Zahlung: Mittel sind gesperrt, bis der Empfänger einen Hash-Vorabbild offenbart. In Lightning ermöglichen HTLCs sofortiges Off-Chain-Routing — deine Zahlung springt durch mehrere Kanäle, ohne einen Vermittler zu vertrauen.';

  @override
  String get infoOpenChannelPrivateTitle => 'Privater Kanal';

  @override
  String get infoOpenChannelPrivateBody =>
      'Ein privater Kanal wird nicht im Netzwerk angekündigt. Nur du und dein Peer wissen, dass er existiert. Verwende ihn, wenn du nicht möchtest, dass andere darüber routen (Datenschutz) oder wenn der Kanal für Routing zu klein ist.';

  @override
  String get infoRoutingFeesTitle => 'Routing-Gebühren';

  @override
  String get infoRoutingFeesBody =>
      'Wenn andere Knoten Zahlungen über deinen Kanal routen, verdienst du Gebühren. Basisgebühr (sat) wird pro Zahlung erhoben; Rate (ppm) ist proportional zum Betrag. CLTV-Delta begrenzt, wie lange ein weitergeleiteter HTLC zur Regulierung brauchen darf.';

  @override
  String get infoForceCloseTitle => 'Zwangsschließung';

  @override
  String get infoForceCloseBody =>
      'Sendet deinen letzten Kanalstatus on-chain. Dies ist irreversibel und erfordert das Warten auf die Verzögerung zum Eigenen, bevor du deine Mittel ausgeben kannst. Verwende es nur, wenn dein Peer nicht antwortet oder böswillig ist — kooperative Schließung ist immer schneller und günstiger.';

  @override
  String get infoPeersTitle => 'Verbundene Peers';

  @override
  String get infoPeersBody =>
      'Peers sind andere Lightning-Knoten, mit denen du direkt über TCP/Tor verbunden bist. Jeder Peer kann einen oder mehrere Kanäle halten. Du kannst neue Peers verbinden, um Kanäle zu öffnen und die Liquidität und Routing-Fähigkeit deines Knotens zu erhöhen.';

  @override
  String get infoNodeManagementTitle => 'Knotenverwaltung';

  @override
  String get infoNodeManagementBody =>
      'Deine Lightning-Knoten-Identität: pubkey, Version, Anzahl aktiver/ausstehender Kanäle und Peers. Dieser Bildschirm zeigt Buchhaltungsdaten vom Bookkeeper-Plugin des Knotens und Weiterleitungsstatistiken.';

  @override
  String get appLockTitle => 'App gesperrt';

  @override
  String get appLockSubtitle => 'Mit Biometrie oder Telefon-PIN entsperren';

  @override
  String get appLockUnlock => 'Entsperren';

  @override
  String get appLockReason => 'Wallet entsperren';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'Sperre deaktiviert: Der Displayschutz (Biometrie/PIN) des Telefons ist nicht mehr verfügbar. Aktiviere ihn in den Systemeinstellungen, um die App-Sperre wieder zu nutzen.';

  @override
  String get appLockNoticeContinue => 'Weiter';

  @override
  String get appLockPromptTitle => 'App-Sperre aktivieren?';

  @override
  String get appLockPromptMessage =>
      'Beim Öffnen des Wallets werden Biometrie oder Telefon-PIN verlangt.';

  @override
  String get appLockPromptEnable => 'Aktivieren';

  @override
  String get appLockPromptLater => 'Später';

  @override
  String get aboutLicensesOpenOnline => 'Online öffnen';

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Wallet $name$balance';
  }

  @override
  String get walletDetailTitle => 'Wallet';

  @override
  String walletDetailCopied(Object label) {
    return '$label kopiert. Wird nach 60s entfernt.';
  }

  @override
  String get walletDetailAddress => 'Adresse';

  @override
  String get walletDetailTransactions => 'Transaktionen';

  @override
  String get walletDetailTxBlockHeight => 'Blockhöhe';

  @override
  String get walletDetailTxConfirmations => 'Bestätigungen';

  @override
  String get walletDetailTxDate => 'Datum';

  @override
  String get walletDetailTxDetails => 'Transaktionsdetails';

  @override
  String get walletDetailTxEmpty => 'Keine Transaktionen';

  @override
  String get walletDetailTxError =>
      'Transaktionen konnten nicht geladen werden';

  @override
  String get walletDetailTxExport => 'Exportieren';

  @override
  String get walletDetailTxExportCsv => 'CSV (Tabelle)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'In die Zwischenablage kopiert ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Download gestartet ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'Export fehlgeschlagen';

  @override
  String get walletDetailTxExportJson => 'JSON (vollständig)';

  @override
  String get walletDetailTxFee => 'Gebühr';

  @override
  String get walletDetailTxIncoming => 'Empfangen';

  @override
  String get walletDetailTxNote => 'Notiz';

  @override
  String get walletDetailTxNoteAdd => 'Notiz hinzufügen';

  @override
  String get walletDetailTxNoteEdit => 'Notiz bearbeiten';

  @override
  String get walletDetailTxNoteHint =>
      'Private Notiz, nur auf diesem Gerät gespeichert';

  @override
  String get walletDetailTxNoteRemove => 'Entfernen';

  @override
  String get walletDetailTxOrphan => 'Verwaist (verlorener Block)';

  @override
  String get walletDetailTxOutgoing => 'Gesendet';

  @override
  String get walletDetailTxPending => 'Ausstehend';

  @override
  String get walletDetailTxReplaced => 'Ersetzt (aus dem Mempool entfernt)';

  @override
  String get walletDetailTxRetry => 'Erneut versuchen';

  @override
  String get backupSeedTitle => 'Seed-Backup';

  @override
  String get backupSeedIntro =>
      'Schreibe deine Seed-Phrase auf Papier und bewahre sie sicher auf. Sie ist der einzige Weg, deine Gelder wiederherzustellen.';

  @override
  String get backupSeedStart => 'Backup starten';

  @override
  String get backupSeedLater => 'Später';

  @override
  String get backupSeedSavedContinue => 'Ich habe die Seed gesichert';

  @override
  String get backupSeedVerifyTitle => 'Backup überprüfen';

  @override
  String get backupSeedVerifyHint =>
      'Gib die 3 hervorgehobenen Wörter ein, um zu bestätigen, dass du sie gesichert hast.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Wort $number';
  }

  @override
  String get backupSeedVerifyError => 'Falsche Wörter. Versuche es erneut.';

  @override
  String get backupSeedDone => 'Backup abgeschlossen';

  @override
  String get backupSeedDoneDesc =>
      'Deine Seed ist sicher. Denke daran: Wer die Seed besitzt, kontrolliert die Gelder.';

  @override
  String get backupSeedFinish => 'Fertig';

  @override
  String get backupSeedSkipWarning =>
      'Wenn du überspringst, riskierst du den Verlust deiner Gelder bei Geräteverlust. Du kannst es später aus den Wallet-Details nachholen.';

  @override
  String get walletDetailSend => 'Senden';

  @override
  String get walletDetailReceive => 'Empfangen';

  @override
  String get sendScreenTitle => 'BTC senden';

  @override
  String get sendScreenAddressLabel => 'Empfängeradresse';

  @override
  String get sendScreenAmountLabel => 'Betrag (BTC)';

  @override
  String get sendScreenFeeLabel => 'Gebühr';

  @override
  String get sendScreenFeeLow => 'Niedrig';

  @override
  String get sendScreenFeeNormal => 'Normal';

  @override
  String get sendScreenFeeHigh => 'Hoch';

  @override
  String get sendScreenFeeCustom => 'Benutzerdefiniert';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Verfügbar: $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Geschätzte Gebühr: $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'UTXO-Auswahl';

  @override
  String get sendScreenUtxoSelectAll => 'Alle auswählen';

  @override
  String get sendScreenUtxoNoneSelected =>
      'Wähle mindestens eine UTXO zum Senden';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Gesamt: $total $ticker';
  }

  @override
  String get sendScreenMax => 'Max';

  @override
  String get sendScreenSend => 'Senden';

  @override
  String get sendScreenSending => 'Wird gesendet...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return '$deleted Wallets gelöscht, $errors Fehler: $error';
  }

  @override
  String get walletDetailBalanceLabel => 'SALDO';

  @override
  String get walletDetailMasterFingerprint => 'MASTER-FINGERABDRUCK';

  @override
  String get walletDetailDerivationPath => 'ABLEITUNGSPFAD';

  @override
  String get walletDetailSettings => 'EINSTELLUNGEN';

  @override
  String get walletDetailAdvancedTools => 'Erweiterte Tools';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'Keine ausgabefähigen UTXO gefunden';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count Bestätigungen';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count ausgewählt · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Ausgewählte senden';

  @override
  String get walletDetailUtxoClearSelection => 'Auswahl löschen';

  @override
  String get walletDetailPasswordSeedReason =>
      'Passwort bestätigen, um die Seed-Phrase anzuzeigen';

  @override
  String get walletDetailBiometricSeedReason =>
      'Biometrische Bestätigung zum Anzeigen der Seed-Phrase';

  @override
  String get walletDetailPasswordBumpReason =>
      'Passwort zur Erhöhung der Gebühr bestätigen';

  @override
  String get walletDetailBiometricBumpReason =>
      'Biometrische Bestätigung zur Erhöhung der Gebühr';

  @override
  String get walletDetailTxBumpFee => 'Gebühr erhöhen';

  @override
  String get walletDetailBumpFeeTitle => 'Transaktionsgebühr erhöhen';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Aktuelle Gebühr: $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Empfohlene Gebühren nicht verfügbar — benutzerdefinierten Satz eingeben';

  @override
  String get walletDetailBumpFeeWarning =>
      'Die ursprüngliche Transaktion wird möglicherweise nie bestätigt, wenn der Ersatz gemint wird.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Gebühr erhöht — neue Transaktion $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'Die neue Gebühr muss höher als die aktuelle sein';

  @override
  String get sendScreenSigning => 'Transaktion wird signiert...';

  @override
  String get sendScreenBroadcasting => 'Sende an das Netzwerk...';

  @override
  String get sendScreenBiometricReason =>
      'Biometrische Bestätigung zum Autorisieren der Transaktion';

  @override
  String get sendScreenPasswordReason =>
      'Passwort eingeben, um die Transaktion zu autorisieren';

  @override
  String get sendScreenBiometricRequired =>
      'Für das Senden ist Biometrie erforderlich. Aktivieren Sie Fingerabdruck- oder Gesichtserkennung in den Geräteeinstellungen.';

  @override
  String get sendScreenFeeTime2h => '~2 Std.';

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
  String get sendScreenFeeTime1h => '~1 Std.';

  @override
  String get sendScreenFeeTime30m => '~30 Min.';

  @override
  String get sendScreenFeeTime15m => '~15 Min.';

  @override
  String get sendScreenFeeTime10m => '~10 Min.';

  @override
  String get sendScreenFeeTime5m => '~5 Min.';

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
      'Die Seed-Phrase besteht aus 12, 15, 18, 21 oder 24 durch Leerzeichen getrennten Wörtern. Sie können sie direkt einfügen.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get legalMitLicense => 'MIT-Lizenz';

  @override
  String get legalSecurityTitle => 'Sicherheit';

  @override
  String get legalTermsContent =>
      'Diese Nutzungsbedingungen sind vorläufig und werden durch die endgültige Fassung ersetzt, sobald die offizielle Website verfügbar ist.\n\nBtc Blake2b Wallet ist eine selbstverwahrte Bitcoin-Wallet für das experimentelle Netzwerk \"bitcoin-blake2b\" (ein Fork von Bitcoin). Private Schlüssel und die Seed-Phrase bleiben ausschließlich auf Ihrem Gerät: Wir verwahren keine Gelder, übertragen sie nicht und haben keinen Zugriff auf Ihre Mittel.\n\nDie App wird kostenlos und \"wie besehen\" ohne Garantie jeglicher Art bereitgestellt. Die Nutzung erfolgt auf eigenes Risiko. Das Netzwerk bitcoin-blake2b ist ein experimentelles, von Bitcoin abgeleitetes Netzwerk: Seine Coins haben möglicherweise keinen Marktwert, werden von Börsen möglicherweise nicht anerkannt und können Reorganisationen unterliegen. Kein Inhalt der App stellt eine Finanz- oder Anlageberatung dar.\n\nSie allein sind für die Verwahrung der Seed-Phrase und Ihrer Mittel verantwortlich: Wer im Besitz der Seed-Phrase ist, kann die Coins ausgeben. Die App kann eine verlorene Seed nicht wiederherstellen. Die Nutzung für illegale Aktivitäten ist verboten. Sie erklären, mindestens 16 Jahre alt zu sein.\n\nBtc Blake2b Wallet ist nicht mit Bitcoin, Bitcoin Core oder bitcoin.org verbunden, wird von ihnen nicht gesponsert und nicht befürwortet.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'Diese Datenschutzerklärung ist vorläufig und wird durch die endgültige Fassung ersetzt, die auf der offiziellen Website veröffentlicht wird, sobald sie verfügbar ist.\n\n1) DATEN AUF DEM GERÄT. Die App erfordert kein Konto und speichert keine personenbezogenen Daten auf Servern des Autors. Verschlüsselte Seed (AES-256-GCM), Einstellungen und Einwilligungen bleiben NUR auf Ihrem Gerät.\n\n2) AN DRITTE ÜBERTRAGENE DATEN FÜR DEN BETRIEB. Zur Anzeige von Guthaben und Gebühren fragt die App öffentliche APIs von Dritten ab:\n• mempool.guide (Blockchain-Explorer).\n• Ist mempool.guide nicht verfügbar, kann die App zwei Esplora-kompatible Community-Mirror abfragen (mempool.kilombino.com, mempool.maveth.ca). Diese Option lässt sich in den Einstellungen deaktivieren.\nBei jeder Anfrage werden Ihre IP-Adresse und die öffentliche Adresse des abgefragten Wallets übertragen. Private Schlüssel und die Seed werden NIE übertragen.\n\n3) KEINE TRACKER. Keine Analyse, keine Werbung, keine Cookies innerhalb der App.\n\n4) RECHTE (GDPR Art. 13-14). Sie haben das Recht auf Auskunft, Berichtigung, Löschung und Widerspruch, indem Sie an den Verantwortlichen schreiben: $holder — $email. Da wir keine personenbezogenen Daten speichern, sind diese Rechte weitgehend bereits dadurch gewährleistet, dass die Daten auf Ihrem Gerät bleiben.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'Um Sicherheitslücken zu melden, verwenden Sie die private Meldung \"Report a vulnerability\" im GitHub-Repository (Registerkarte Security) oder schreiben Sie an:\n$email\n\nÖffnen Sie keine öffentlichen Issues für Sicherheitsprobleme. Antwortzeit: 72 Stunden. Offenlegungsrichtlinie: 90 Tage.';
  }

  @override
  String get sendScreenSuccess => 'Transaktion gesendet!';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID: $txid';
  }

  @override
  String get sendScreenValidateAddress => 'Adresse eingeben';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Ungültige Adresse für $network ($prefix verwenden)';
  }

  @override
  String get sendScreenValidateLength => 'Ungültige Adresslänge';

  @override
  String get sendScreenValidateSelf => 'Senden an sich selbst nicht möglich';

  @override
  String get sendScreenValidateAmount => 'Betrag eingeben';

  @override
  String get sendScreenValidateInvalidAmount => 'Ungültiger Betrag';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Betrag zu niedrig (Minimum $dust satoshi / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Unzureichendes Guthaben (Saldo: $balance, geschätzte Gebühr: $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'UTXOs werden geladen...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'UTXOs können nicht geladen werden: $error';
  }

  @override
  String get scanQrTitle => 'QR-Code scannen';

  @override
  String get scanQrError =>
      'Kamera nicht verfügbar. Erteilen Sie die Kameraberechtigung und versuchen Sie es erneut.';

  @override
  String get scanQrInvalid =>
      'Der gescannte Code ist keine gültige Bitcoin-Adresse.';

  @override
  String get scanQrInvalidInvoice =>
      'Der gescannte Code ist keine gültige Lightning-Rechnung.';

  @override
  String get scanQrTorch => 'Taschenlampe umschalten';

  @override
  String get sendConfirmTitle => 'Transaktion bestätigen';

  @override
  String get sendConfirmWarning =>
      'Diese Transaktion ist unumkehrbar. Prüfen Sie die Details vor der Bestätigung.';

  @override
  String get sendConfirmSend => 'Bestätigen & Senden';

  @override
  String get importScreenTitle => 'Wallet importieren';

  @override
  String get importScreenHeading => 'Seed-Phrase eingeben';

  @override
  String get importScreenSubtitle =>
      'Gib die durch Leerzeichen getrennte Mnemonik-Phrase (12, 15, 18, 21 oder 24 Wörter) ein und wähle dann den Account-Typ, der zur ursprünglichen Wallet passt.';

  @override
  String get importScriptTypeLabel => 'Account-Typ';

  @override
  String get importScriptTypeNativeSegwit => 'Natives SegWit (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'Verschachteltes SegWit (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Zu erstellender Wallet-Typ';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Adressen beginnen mit $prefix';
  }

  @override
  String get importScreenHint => 'wort1 wort2 wort3 ...';

  @override
  String get importScreenValidateEmpty => 'Mnemonik-Phrase eingeben.';

  @override
  String importScreenValidateCount(Object count) {
    return 'Die Phrase muss 12, 15, 18, 21 oder 24 Wörter enthalten (erkannt: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Ungültige Mnemonik-Phrase. Überprüfe die Rechtschreibung.';

  @override
  String get importScreenImport => 'Importieren';

  @override
  String get importModeSeed => 'Seed-Phrase';

  @override
  String get importModeWatchOnly => 'Nur-Lesen (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Überwache eine externe Wallet (Saldo und Verlauf) nur mit ihrem öffentlichen erweiterten Schlüssel. Kein privater Schlüssel beteiligt — Senden ist nie möglich.';

  @override
  String get importWatchOnlyXpubLabel => 'Account-xpub';

  @override
  String get importWatchOnlyXpubHint =>
      'Füge den Account-xpub ein (beginnt mit \"xpub\"). Nur öffentliche Schlüssel: füge niemals einen xprv ein.';

  @override
  String get importWatchOnlyValidateEmpty => 'Gib den Account-xpub ein.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'Der xpub muss mit \"xpub\" beginnen (Mainnet).';

  @override
  String get watchOnlyBadge => 'Nur-Lesen';

  @override
  String get passwordDialogCreateTitle => 'Sicherheitspasswort erstellen';

  @override
  String get passwordDialogCreateHint => 'Sicheres Passwort eingeben';

  @override
  String get passwordDialogCreateConfirm => 'Passwort bestätigen';

  @override
  String get passwordDialogCreate => 'Erstellen';

  @override
  String get passwordDialogCancel => 'Abbrechen';

  @override
  String get passwordDialogEnterTitle => 'Passwort eingeben';

  @override
  String get passwordDialogEnterHint => 'Passwort eingeben';

  @override
  String get passwordDialogEnter => 'Bestätigen';

  @override
  String get passwordDialogWrong => 'Falsches Passwort';

  @override
  String get languageSelector => 'Sprache';

  @override
  String get languageSelectorAuto => '🌐 Automatisch (System)';

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
  String get walletDetailRefresh => 'Aktualisieren';

  @override
  String get walletDetailDeleteTitle => 'Wallet löschen?';

  @override
  String get walletDetailDeleteConfirm => 'Endgültig löschen';

  @override
  String get walletDetailDeleteWarning =>
      'Diese Aktion ist unumkehrbar. Stelle sicher, dass du ein Backup der Seed-Phrase hast, falls sich Gelder in der Wallet befinden.';

  @override
  String get walletDetailInfo => 'Wallet-Info';

  @override
  String get walletDetailNameLabel => 'Wallet-Name';

  @override
  String get walletDetailNameHint => 'z. B. Ersparnisse Haus';

  @override
  String get walletDetailType => 'Typ';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'Verschachteltes SegWit (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'AKTUALISIERUNG...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TRANSAKTIONEN';
  }

  @override
  String get walletDetailReceiveQr => 'Bitcoin empfangen';

  @override
  String get walletDetailSignVerify => 'Nachricht signieren/verifizieren';

  @override
  String get walletDetailShowAddresses => 'Adressen anzeigen';

  @override
  String get walletDetailWalletAddress => 'Wallet-Adresse';

  @override
  String get walletDetailExportSeed => 'Seed exportieren/sichern';

  @override
  String get walletDetailShowSeedTitle => 'Seed anzeigen?';

  @override
  String get walletDetailShowSeedContent =>
      'Die Seed-Phrase ermöglicht den Zugriff auf alle Gelder. Stelle sicher, dass du dich an einem sicheren Ort befindest.';

  @override
  String get walletDetailShowSeedConfirm => 'Ja, anzeigen';

  @override
  String get walletDetailSeedVerifyPrompt =>
      'Möchtest du bestätigen, dass du die Seed gesichert hast?';

  @override
  String get walletDetailSeedVerifyYes => 'Ja, bestätigen';

  @override
  String get walletDetailSeedVerifyNotNow => 'Später';

  @override
  String get walletDetailSeedVerified => 'Backup bestätigt';

  @override
  String get walletDetailSeedHidden =>
      'Seed aus Sicherheitsgründen ausgeblendet';

  @override
  String get walletDetailSeedShowAgain => 'Seed anzeigen';

  @override
  String get walletDetailHideSeed => 'Ausblenden';

  @override
  String get walletDetailBackupNotConfirmed => 'Backup nicht bestätigt';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'Du hast die Seed-Phrase noch nicht gesichert. Wenn du das Gerät verlierst oder die App neu installierst, verlierst du dauerhaft den Zugriff auf deine Gelder.';

  @override
  String get walletDetailShowXpub => 'Wallet-XPUB anzeigen';

  @override
  String get walletDetailDisplayHome => 'Wert auf Startseite anzeigen';

  @override
  String get walletDetailUtxoRename => 'Umbenennen';

  @override
  String get walletDetailUtxoRenameTitle => 'UTXO umbenennen';

  @override
  String get walletDetailSave => 'Speichern';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Erstellt';

  @override
  String get walletDetailClose => 'Schließen';

  @override
  String get walletDetailSign => 'Signieren';

  @override
  String get walletDetailVerify => 'Verifizieren';

  @override
  String get walletDetailSignMessage => 'Nachricht signieren';

  @override
  String get walletDetailVerifyMessage => 'Nachricht verifizieren';

  @override
  String get walletDetailMessage => 'Nachricht';

  @override
  String get walletDetailBitcoinAddress => 'Bitcoin-Adresse';

  @override
  String get walletDetailSignature => 'Signatur (Base64)';

  @override
  String get walletDetailResult => 'Ergebnis:';

  @override
  String get walletDetailSignatureLabel => 'Signatur:';

  @override
  String get walletDetailCopy => 'Kopieren';

  @override
  String get walletDetailAddressCopied =>
      'Adresse in die Zwischenablage kopiert';

  @override
  String get walletDetailXpubTitle => 'Wallet-XPUB';

  @override
  String get walletDetailXpubDesc =>
      'Dieser XPUB ermöglicht das Anzeigen aller zukünftigen Adressen und Salden, kann aber keine Gelder ausgeben.';

  @override
  String get walletDetailXpubCopied => 'XPUB kopiert';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Fehler beim Ableiten des XPUB: $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Fehler beim Ableiten der Adressen: $error';
  }

  @override
  String get walletDetailValidSig => 'GÜLTIGE SIGNATUR ✓';

  @override
  String get walletDetailInvalidSig => 'UNGÜLTIGE SIGNATUR ✗';

  @override
  String get donateTitle => 'Unterstütze das Projekt ❤️';

  @override
  String get donatePhrase =>
      '☕ \"Wenn dir das Projekt nützlich ist, spendier uns einen virtuellen Kaffee\"';

  @override
  String get donateAddressLabel => 'Bitcoin-Spendenadresse:';

  @override
  String get donateCopy => 'Kopieren';

  @override
  String get donateCopied => 'Kopiert! ✓';

  @override
  String get donateNote =>
      'Freiwillige Spende — dafür wird kein Dienst oder Vorteil gewährt. Jeder Betrag ist willkommen, auch ein paar Satoshis. Danke! 🧡';

  @override
  String get donateNoWalletTitle => 'Keine Wallet gefunden';

  @override
  String get donateNoWalletMessage =>
      'Auf deinem Gerät wurde keine Bitcoin-Wallet-App gefunden. Du kannst die Adresse trotzdem kopieren und in deine bevorzugte Wallet einfügen.';

  @override
  String get donateOpenWallet => 'In Wallet öffnen';

  @override
  String get donateButton => 'Unterstütze das Projekt ❤️';

  @override
  String get onboardingTitle => 'Willkommen bei Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle =>
      'Open-Source Bitcoin Wallet. Self-Custody. Kein KYC.';

  @override
  String get onboardingResidenceLabel => 'Land des Steuerwohnsitzes';

  @override
  String get onboardingResidenceHint => 'Wähle dein Land';

  @override
  String get onboardingReverseSolicitation =>
      'Ich erkläre, dass ich Btc Blake2b Wallet aus eigener Initiative nutze (\"Reverse Solicitation\") und meinen Steuerwohnsitz im ausgewählten Land habe.';

  @override
  String get onboardingTermsAccept => 'Ich akzeptiere die ';

  @override
  String get onboardingPrivacyAccept => 'Ich habe die ';

  @override
  String get onboardingAgeConfirm =>
      'Ich erkläre, dass ich mindestens 16 Jahre alt bin';

  @override
  String get onboardingAgeSubtitle =>
      'Erforderlich gemäß DSGVO Art. 8 für die Einwilligung zur Datenverarbeitung';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingStepNext => 'Weiter';

  @override
  String get onboardingStepBack => 'Zurück';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Schritt $current von $total';
  }

  @override
  String get onboardingTermsTitle => 'Bedingungen und Datenschutz';

  @override
  String get onboardingValidationResidence =>
      'Wähle dein Land des Steuerwohnsitzes';

  @override
  String get onboardingLinkTerms => 'Nutzungsbedingungen';

  @override
  String get onboardingLinkPrivacy => 'Datenschutzerklärung';

  @override
  String get aboutTitle => 'Über Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet ist eine Open-Source Bitcoin Wallet mit Selbstverwahrung. Keine Registrierung, kein KYC, kein Tracking. Deine Schlüssel, deine Bitcoins.';

  @override
  String get aboutLicenseTitle => 'Lizenz';

  @override
  String get aboutThirdPartyLicenses => 'Drittanbieter-Lizenzen';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'Vollständige Liste der Open-Source-Lizenzen anzeigen';

  @override
  String get aboutBuiltWith => 'Erstellt mit';

  @override
  String get aboutDisclaimer =>
      'Diese Software wird \"WIE BESEHEN\" ohne jegliche Gewährleistung bereitgestellt.';

  @override
  String get explorerTitle => 'Block-Explorer';

  @override
  String get explorerAddressLabel => 'Adresse';

  @override
  String get explorerRefresh => 'Aktualisieren';

  @override
  String get explorerBalanceLabel => 'Guthaben';

  @override
  String get explorerTxCount => 'Transaktionen';

  @override
  String get explorerTipHeight => 'Knotenhöhe';

  @override
  String get explorerErrorInvalidAddress =>
      'Ungültige Adresse. Prüfen Sie das Format für dieses Netzwerk.';

  @override
  String get explorerErrorRateLimited =>
      'Anfragelimit überschritten. Versuchen Sie es in einer Minute erneut.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Dienst vorübergehend nicht erreichbar. Versuchen Sie es später erneut.';

  @override
  String get explorerErrorNotFound =>
      'Adresse oder Transaktion nicht gefunden.';

  @override
  String get explorerErrorTimeout =>
      'Zeitüberschreitung der Anfrage. Prüfen Sie die Verbindung und versuchen Sie es erneut.';

  @override
  String get explorerErrorNetwork =>
      'Kein Netzwerk verfügbar. Prüfen Sie die Verbindung.';

  @override
  String get explorerRetry => 'Erneut versuchen';

  @override
  String explorerErrorGeneric(String error) {
    return 'Fehler: $error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'Kein Lightning-Node verbunden';

  @override
  String get lightningDisconnectedBody =>
      'Verbinde deinen blake2b-Lightning-Node, um Zahlungen zu senden und zu empfangen. Die App verwahrt niemals deine Fonds oder Schlüssel.';

  @override
  String get lightningConnectButton => 'Node verbinden';

  @override
  String get lightningConnectTitle => 'Lightning-Node verbinden';

  @override
  String get lightningConnectHint =>
      'Verbindungszeichenfolge einfügen (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Ungültige Verbindungszeichenfolge';

  @override
  String get lightningConnectRecentNodes => 'Zuletzt verwendete Knoten';

  @override
  String get lightningConnectInfo =>
      'Der Node muss diese App autorisieren (Grant): prüfe das Kontrollpanel deines Nodes.';

  @override
  String get lightningConnecting => 'Verbindung…';

  @override
  String get lightningConnected => 'Verbunden';

  @override
  String get lightningDisconnect => 'Trennen';

  @override
  String get lightningBalance => 'Lightning-Guthaben';

  @override
  String get lightningChannels => 'Kanäle';

  @override
  String get lightningNoChannels => 'Keine offenen Kanäle';

  @override
  String get lightningChannelPeer => 'Peer';

  @override
  String get lightningChannelCapacity => 'Kapazität';

  @override
  String get lightningChannelLocal => 'Lokal';

  @override
  String get lightningChannelRemote => 'Remote';

  @override
  String get lightningOpenChannel => 'Kanal öffnen';

  @override
  String get lightningOpenChannelNodeId => 'Node-ID (Pubkey)';

  @override
  String get lightningOpenChannelHost => 'Host (optional, ip:port)';

  @override
  String get lightningOpenChannelAmount => 'Betrag (Sat)';

  @override
  String get lightningOpenChannelPrivate => 'Privater Kanal';

  @override
  String get lightningChannelOpened => 'Kanalöffnung angefordert';

  @override
  String get lightningCloseChannel => 'Kanal schließen';

  @override
  String get lightningCloseChannelForce => 'Erzwungene Schließung';

  @override
  String get lightningCloseChannelForceWarning =>
      'Die erzwungene Schließung veröffentlicht den letzten Kanalzustand on-chain. Es können Gebühren und Verzögerungen anfallen. Fortfahren?';

  @override
  String get lightningReceive => 'Empfangen';

  @override
  String get lightningSend => 'Senden';

  @override
  String get lightningInvoiceAmount => 'Betrag (Sat)';

  @override
  String get lightningInvoiceDescription => 'Beschreibung (optional)';

  @override
  String get lightningInvoiceCreate => 'Rechnung erstellen';

  @override
  String get lightningInvoiceTitle => 'Lightning-Rechnung';

  @override
  String get lightningPay => 'Rechnung bezahlen';

  @override
  String get lightningPayHint => 'Rechnung einfügen (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Lightning-Zahlung bestätigen';

  @override
  String get lightningPayDialogBody => 'Diese Rechnung bezahlen?';

  @override
  String get lightningPaySuccess => 'Zahlung gesendet';

  @override
  String get lightningCopied => 'Kopiert';

  @override
  String get lightningErrorRestricted =>
      'Der Node hat diese App nicht autorisiert. Erstelle einen Grant auf deinem Node für diese Verbindung.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Lightning-Fehler: $error';
  }

  @override
  String get lightningConfirm => 'Bestätigen';

  @override
  String get lightningCancel => 'Abbrechen';

  @override
  String get lightningNodeOnchain => 'Node On-Chain';

  @override
  String get lightningDeposit => 'Einzahlen';

  @override
  String get lightningWithdraw => 'On-Chain senden';

  @override
  String get lightningDepositTitle => 'On-Chain-Einzahlung';

  @override
  String get lightningDepositHint =>
      'Sende blake2b-Guthaben an diese Node-Adresse.';

  @override
  String get lightningDepositNewAddress => 'Neue Adresse';

  @override
  String get lightningDepositWarning =>
      'Nur im blake2b-Netz senden. Auf dem falschen Netz gesendete Beträge sind verloren.';

  @override
  String get lightningOnchainSendTitle => 'On-Chain-Sendung';

  @override
  String get lightningOnchainAddressLabel => 'Empfängeradresse';

  @override
  String get lightningOnchainAmountLabel => 'Betrag (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Netzwerkgebühr';

  @override
  String get lightningOnchainFeeMin => 'Minimal';

  @override
  String get lightningOnchainFeeEconomical => 'Günstig';

  @override
  String get lightningOnchainFeePriority => 'Priorität';

  @override
  String get lightningOnchainConfirm => 'Senden bestätigen';

  @override
  String get lightningOnchainConfirmTitle => 'On-Chain-Sendung bestätigen?';

  @override
  String get lightningOnchainWarning =>
      'Unwiderrufliche Aktion: Die Beträge verlassen die Node.';

  @override
  String get lightningOnchainSuccess => 'Transaktion gesendet';

  @override
  String get lightningOnchainInvalidAddress => 'Ungültige blake2b-Adresse';

  @override
  String get lightningOnchainInsufficient => 'Nicht genügend On-Chain-Guthaben';

  @override
  String get lightningFeesUnavailable =>
      'Gebührenschätzung nicht verfügbar: Die Node wählt die Gebühr';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey oder pubkey@host:port (Onion braucht Tor auf der Node)';

  @override
  String get lightningOpenChannelInvalid =>
      'Ungültige Node-ID oder Host (66 Hex, host:port)';

  @override
  String get lightningActivityDetected => 'Aktivität auf der Node erkannt';

  @override
  String get lightningPeers => 'Peers';

  @override
  String get lightningPeersEmpty => 'Keine Peers verbunden';

  @override
  String get lightningConnectPeer => 'Peer verbinden';

  @override
  String get lightningDisconnectPeer => 'Trennen';

  @override
  String get lightningPeerDisconnected => 'Getrennt';

  @override
  String get lightningPeerId => 'Peer-ID';

  @override
  String get lightningPeerAddresses => 'Adressen';

  @override
  String get lightningDisconnectPeerConfirm =>
      'Diesen Peer trennen? Offene Kanäle bleiben aktiv.';

  @override
  String get lightningChannelDetail => 'Kanal-Details';

  @override
  String get lightningChannelShortId => 'Short-Channel-ID';

  @override
  String get lightningChannelState => 'Node-Status';

  @override
  String get lightningChannelFee => 'Gebühr';

  @override
  String get lightningChannelSpendable => 'Ausgebbar';

  @override
  String get lightningChannelReceivable => 'Empfangbar';

  @override
  String get lightningChannelHtlcs => 'HTLCs';

  @override
  String get lightningChannelFundingTxid => 'Funding-Txid';

  @override
  String get lightningNodeManagement => 'Knotenverwaltung';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers Peers · $channels Kanäle';
  }

  @override
  String get lightningNodeIdentity => 'Knoten-Identität';

  @override
  String get lightningNodePubkey => 'Öffentlicher Schlüssel';

  @override
  String get lightningNodeVersion => 'Version';

  @override
  String get lightningNodePeersCount => 'Peers';

  @override
  String get lightningNodeChannelsActive => 'Aktive Kanäle';

  @override
  String get lightningNodeChannelsPending => 'Ausstehende Kanäle';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'Auf diesem Knoten nicht verfügbar: für Leasing-Bedingungen wird das Plugin liquidity-ads benötigt.';

  @override
  String get lightningLiquidity => 'Liquidität';

  @override
  String get lightningLiquidityTotal => 'Gesamtkapazität';

  @override
  String get lightningLiquidityOutbound => 'Ausgehend';

  @override
  String get lightningLiquidityInbound => 'Eingehend';

  @override
  String get lightningLiquidityWarning =>
      'Keine eingehende Liquidität: Zahlungen können erst ankommen, wenn ein Peer einen Kanal zu diesem Knoten öffnet.';

  @override
  String get lightningMovements => 'Bewegungen';

  @override
  String get lightningMovementsEmpty => 'Keine Bewegungen';

  @override
  String get lightningMovementsAll => 'Alle Bewegungen';

  @override
  String get lightningMovementsLoadMore => 'Mehr laden';

  @override
  String get lightningMovementDeposit => 'On-Chain-Einzahlung';

  @override
  String get lightningMovementWithdrawal => 'On-Chain-Sendung';

  @override
  String get lightningMovementChannelOpen => 'Kanaleröffnung';

  @override
  String get lightningMovementChannelClose => 'Kanalschließung';

  @override
  String get lightningMovementInvoice => 'Lightning-Zahlung';

  @override
  String get lightningMovementOnchainFee => 'On-Chain-Gebühr';

  @override
  String get lightningMovementForward => 'Weiterleitung';

  @override
  String get lightningMovementOther => 'Bewegung';

  @override
  String lightningChannelsAll(int count) {
    return 'Alle Kanäle ($count)';
  }

  @override
  String get lightningOnchainNode => 'On-Chain des Knotens';

  @override
  String get lightningOnchainBalance => 'On-Chain-Guthaben';

  @override
  String get lightningOnchainConfirmed => 'Bestätigt';

  @override
  String get lightningOnchainPending => 'Ausstehend';

  @override
  String get lightningOnchainUtxos => 'UTXOs';

  @override
  String get lightningOnchainUtxosEmpty => 'Keine UTXOs';

  @override
  String get lightningOnchainAddresses => 'Adressen des Knotens';

  @override
  String get lightningOnchainNewAddress => 'Neue Adresse';

  @override
  String get lightningOnchainAddressType => 'Adresstyp';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'Mit Guthaben';

  @override
  String get lightningOnchainReserved => 'Reserviert';

  @override
  String get lightningOnchainBlockHeight => 'Block';

  @override
  String get lightningPayments => 'Zahlungen';

  @override
  String get lightningInvoices => 'Rechnungen';

  @override
  String get lightningInvoicesEmpty => 'Noch keine Rechnungen';

  @override
  String get lightningInvoiceStatusPaid => 'Bezahlt';

  @override
  String get lightningInvoiceStatusPending => 'Wartet auf Zahlung';

  @override
  String get lightningInvoiceStatusExpired => 'Abgelaufen';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Bezahlt am $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String get lightningReceivePaid => 'Rechnung bezahlt';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total Rechnungen · $pending offen';
  }

  @override
  String get lightningPays => 'Gesendete Zahlungen';

  @override
  String get lightningPaysEmpty => 'Noch keine Zahlungen';

  @override
  String get lightningPaymentFee => 'Gebühr';

  @override
  String get lightningPaymentCompleted => 'Abgeschlossen';

  @override
  String get lightningPaymentPending => 'Ausstehend';

  @override
  String get lightningPaymentFailed => 'Fehlgeschlagen';

  @override
  String get lightningHtlcsEmpty => 'Keine HTLCs';

  @override
  String get lightningHtlcInProgress => 'Unterwegs';

  @override
  String get lightningHtlcIncoming => 'Eingehend';

  @override
  String get lightningHtlcOutgoing => 'Ausgehend';

  @override
  String get lightningChannelFees => 'Routing-Gebühren';

  @override
  String get lightningFeeEdit => 'Gebühren ändern';

  @override
  String get lightningFeeBefore => 'Aktuell';

  @override
  String get lightningFeeAfter => 'Neu';

  @override
  String get lightningFeeBaseLabel => 'Basis (sat)';

  @override
  String get lightningFeePpmLabel => 'Satz (ppm)';

  @override
  String get lightningHtlcMinLabel => 'Min. HTLC (sat)';

  @override
  String get lightningHtlcMaxLabel => 'Max. HTLC (sat)';

  @override
  String get lightningCltvLabel => 'CLTV-Delta';

  @override
  String get lightningChannelReserve => 'Unsere Reserve';

  @override
  String get lightningChannelToSelfDelay => 'To-self-Delay';

  @override
  String get lightningFeeConfirmTitle => 'Diese Routing-Gebühren anwenden?';

  @override
  String get lightningFeeWarning =>
      'Gebühren gelten für geroutete Zahlungen. Das Netzwerk akzeptiert nur wenige Änderungen pro Tag und Peers brauchen Zeit.';

  @override
  String get lightningFeeUpdated => 'Gebühren aktualisiert';

  @override
  String get lightningDiagnostics => 'Diagnose';

  @override
  String get lightningDiagnosticsSubtitle =>
      'Buchhaltung, Plugins und Weiterleitung';

  @override
  String get lightningStatsEconomy => 'Bilanz';

  @override
  String get lightningStatsNet => 'Netto';

  @override
  String get lightningStatsSource =>
      'Aus der Buchhaltung des Nodes (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'Noch keine Buchhaltungsdaten';

  @override
  String get lightningStatsTagDeposit => 'Einzahlungen';

  @override
  String get lightningStatsTagInvoice => 'Rechnungen';

  @override
  String get lightningStatsTagWithdrawal => 'Auszahlungen';

  @override
  String get lightningStatsTagOnchainFee => 'On-Chain-Gebühren';

  @override
  String get lightningStatsTagChannelOpen => 'Kanal-Eröffnungen';

  @override
  String get lightningStatsTagChannelClose => 'Kanal-Schließungen';

  @override
  String get lightningStatsTagRouted => 'Verdiente Routing-Gebühren';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Plugins';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count aktiv';
  }

  @override
  String get lightningPluginInactive => 'inaktiv';

  @override
  String get lightningForwardsTitle => 'Weiterleitung';

  @override
  String get lightningForwardsEmpty => 'Noch keine weitergeleiteten Zahlungen';

  @override
  String get lightningForwardSettled => 'Abgerechnet';

  @override
  String get lightningForwardFailed => 'Fehlgeschlagen';

  @override
  String get lightningForwardOffered => 'Läuft';

  @override
  String get lightningKeysendTitle => 'An Node senden (Keysend)';

  @override
  String get lightningKeysendHint => 'Pubkey des Ziel-Nodes (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Betrag (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Max. Gebühr (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Leer lassen für den Node-Standard (0,5%)';

  @override
  String get lightningKeysendWarning =>
      'Keysend zahlt einen Node ohne Rechnung: das Geld bewegt sich sofort und kann nicht zurückgeholt werden.';

  @override
  String get lightningKeysendConfirmTitle => 'Diese Keysend-Zahlung senden?';

  @override
  String get lightningKeysendDestination => 'Ziel';

  @override
  String get lightningKeysendSent => 'Keysend gesendet';

  @override
  String get lightningKeysendInvalidPubkey => 'Ungültiger Node-Pubkey';

  @override
  String get lightningKeysendInvalidAmount => 'Betrag größer als null eingeben';

  @override
  String get lightningKeysendSend => 'Senden';

  @override
  String get walletAddressesTitle => 'Adressen & UTXO';

  @override
  String get walletAddressesTabAddresses => 'Adressen';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Empfang (/0)';

  @override
  String get walletAddressesChangeBranch => 'Wechselgeld (/1)';

  @override
  String get walletAddressesStatusUnused => 'Nie verwendet';

  @override
  String get walletAddressesStatusUsed => 'Verwendet';

  @override
  String get walletAddressesStatusFunds => 'Mit Guthaben';

  @override
  String walletAddressesTxCount(int count) {
    return '$count Transaktionen';
  }

  @override
  String get walletAddressesEmpty => 'Keine Adresse anzuzeigen';

  @override
  String get walletAddressesHintTap => 'Zum Kopieren auf eine Adresse tippen';

  @override
  String get lightningPeeringGateTitle =>
      'Peering auf Bit-68-Releases beschränkt';

  @override
  String get lightningPeeringGateBody =>
      'Dieser Knoten verlangt option_blake2b (Bit 68) beim Handshake: Knoten mit älteren Releases können sich nicht verbinden. Das ist eine Entscheidung des Knotens, kein Problem der App oder der Bridge. Verwende Peers mit Release .4 oder neuer oder warte, bis die Community das Bit optional macht.';

  @override
  String get lightningPeeringGateLink => 'Kompatibilitätsmatrix';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count registrierte Peers, keine verbunden';
  }

  @override
  String get lightningSwapOpen => 'Rechnung ohne eigenen Node bezahlen (Swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'Web-App: Lightning-Zahlungen laufen über einen Swap-Anbieter (kein Node nötig). Das Verbinden des eigenen Nodes gibt es in der Android-App.';

  @override
  String get lightningSwapTitle => 'Lightning-Zahlung über Anbieter';

  @override
  String get lightningSwapIntro =>
      'Die Mittel bleiben in deiner Verwahrung: sie gehen in einen On-Chain-HTLC (P2WSH) und werden erst freigegeben, wenn der Anbieter deine Rechnung bezahlt. Schlägt die Zahlung fehl, kannst du die Mittel nach dem Time-Lock zurückholen.';

  @override
  String get lightningSwapProviderUriHint => 'Anbieter-URI (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Anbieter verbinden';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Anbieter verbunden: $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Trennen';

  @override
  String get lightningSwapInvoiceHint => 'Lightning-Rechnung (lnbc...)';

  @override
  String get lightningSwapStart => 'Weiter';

  @override
  String get lightningSwapAmount => 'Rechnungsbetrag';

  @override
  String get lightningSwapFees => 'Gebühren (Claim + Service)';

  @override
  String get lightningSwapTotal => 'Zu sperrender Gesamtbetrag';

  @override
  String get lightningSwapFund => 'Mittel senden und Swap starten';

  @override
  String get lightningSwapFundHint =>
      'Die Mittel gehen an die oben angezeigte HTLC-Adresse. Die Zahlung startet nach 1 Bestätigung.';

  @override
  String get lightningSwapStateLabel => 'Status';

  @override
  String get lightningSwapHtlc => 'HTLC-Adresse';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund ab Block $height';
  }

  @override
  String get swapStateAwaitingFunding => 'Warte auf On-Chain-Mittel';

  @override
  String get swapStateConfirming => 'Warte auf Bestätigungen';

  @override
  String get swapStatePaying => 'Lightning-Zahlung läuft';

  @override
  String get swapStatePaid => 'Rechnung bezahlt, Claim läuft';

  @override
  String get swapStateClaiming => 'Claim läuft';

  @override
  String get swapStateCompleted => 'Abgeschlossen';

  @override
  String get swapStatePaymentFailed =>
      'Zahlung fehlgeschlagen — Mittel wiederherstellbar';

  @override
  String get swapStateExpired => 'Abgelaufen — Mittel wiederherstellbar';

  @override
  String get swapStateRefunded => 'Erstattet';

  @override
  String get lightningSwapRecoveryTitle => 'Mittelwiederherstellung';

  @override
  String get lightningSwapRecoveryHint =>
      'Wiederherstellungs-Blob (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Sitzung importieren';

  @override
  String get lightningSwapRefund => 'Mittel zurückholen (Refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Rückerstattung noch nicht möglich: verfügbar ab Block $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Wiederherstellungs-Blob kopieren';

  @override
  String get lightningSwapBlobCopied => 'Wiederherstellungs-Blob kopiert';

  @override
  String get lightningSwapClaimTxid => 'Txid des Claims';

  @override
  String get lightningSwapClaimHint =>
      'Der Claim ist eine On-Chain-Transaktion: die Bestätigung kommt mit dem nächsten Block (~12 Min). Tippe auf den Link, um sie zu prüfen.';

  @override
  String get lightningSwapInvalidInvoice =>
      'Das sieht nicht nach einer Lightning-Rechnung aus';

  @override
  String get lightningSwapWatchOnly =>
      'Der Swap benötigt eine Wallet mit Seed (nicht watch-only)';

  @override
  String get lightningSwapNoUtxos =>
      'Keine ausgebbaren Mittel in dieser Wallet';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Fehler: $message';
  }

  @override
  String get lightningSwapKnownUris => 'Gespeicherte Anbieter-URIs';

  @override
  String get lightningSwapWalletLabel => 'Wallet';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Guthaben: $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Unzureichende Mittel: $needed sat benötigt, $available sat verfügbar';
  }

  @override
  String get lightningSwapCancel => 'Swap abbrechen';

  @override
  String get lightningSwapErrorConnectFailed =>
      'Der Anbieter ist nicht erreichbar. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Die Verbindung zum Anbieter wurde unterbrochen. Versuche es erneut.';

  @override
  String get lightningSwapErrorNotConnected => 'Anbieter nicht verbunden.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'Dieser Anbieter nutzt ein Relay, das die Web-Version nicht erreichen kann. Nutze die App auf dem Telefon, um mit diesem Anbieter zu zahlen.';

  @override
  String get lightningSwapCancelTitle => 'Diesen Swap abbrechen?';

  @override
  String get lightningSwapCancelBody =>
      'Die App vergisst diesen Swap. Der Anbieter verwirft ihn vor Ablauf von selbst, es sind keine Mittel gesperrt. Für einen neuen Versuch mit derselben Rechnung brauchst du nach Ablauf eine neue Sitzung — sonst erstelle eine neue Rechnung.';

  @override
  String get lightningSwapCancelConfirm => 'Ja, abbrechen';

  @override
  String get lightningSwapWalletMissing =>
      'Die mit diesem Swap verbundene Wallet ist nicht mehr verfügbar';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Verbundene Wallet: $name';
  }

  @override
  String get lightningInvoiceDelete => 'Rechnung löschen';

  @override
  String get lightningInvoiceDeleteTitle => 'Diese Rechnung löschen?';

  @override
  String get lightningInvoiceDeleteBody =>
      'Die Rechnung wird vom Knoten entfernt. Wenn sie unbezahlt ist, kann sie nicht mehr bezahlt werden.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Ja, löschen';

  @override
  String get lightningInvoiceDeleted => 'Rechnung gelöscht';

  @override
  String get lightningChannelPeerAddress => 'Peer-Adresse';
}
