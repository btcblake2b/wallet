// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get appErrorTitle => 'Sovellusta ei voida käynnistää';

  @override
  String get appReload => 'Lataa sivu uudelleen';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'Ei yhteyttä';

  @override
  String get homeNoConnectionCreate =>
      'Lompakkoa ei voida luoda ilman Internet-yhteyttä. Osoite on varmistettava verkossa. Yritä uudelleen, kun yhteys on palautettu.';

  @override
  String get homeNoConnectionImport =>
      'Lompakkoa ei voida tuoda ilman Internet-yhteyttä.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Lompakko luotu onnistuneesti.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Virhe lompakon luomisessa: $error';
  }

  @override
  String get homeImportWallet => 'Tuo lompakko';

  @override
  String get homeCreateWallet => 'Luo lompakko';

  @override
  String get homeReceiveWallet => 'Vastaanota';

  @override
  String get homeMultiTransfer => 'Moni-lähetys';

  @override
  String get homeSelected => 'valittu';

  @override
  String get homeDeleteSelected => 'Poista valitut';

  @override
  String homeDeleteConfirm(int count) {
    return 'Poistetaanko $count lompakkoa? Tämä toimenpide on peruuttamaton.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count lompakkoa poistettu onnistuneesti.';
  }

  @override
  String homeDeleteMultiError(Object message) {
    return '$message';
  }

  @override
  String get homeWalletImported => 'Lompakko tuotu onnistuneesti.';

  @override
  String get homeSecurityWarning =>
      'Tämä ohjelmisto toimitetaan \"sellaisenaan\" ilman mitään takuuta. Valmistaja ei ole vastuussa varojen menetyksestä, varkaudesta, hakkeroinnista, transaktiovirheistä tai mistään vahingoista, jotka johtuvat sovelluksen käytöstä. Lompakko ei takaa suojaa siemenen aiempia kopioita vastaan. Käytä vain pienille määrille.';

  @override
  String get homeDisclaimerAccept => 'Hyväksyn';

  @override
  String get legalInfoTitle => 'Oikeudelliset tiedot';

  @override
  String get homeLocalWallets => 'Paikalliset lompakot';

  @override
  String homeErrorLoading(Object error) {
    return 'Virhe ladataan lompakkoa: $error';
  }

  @override
  String get homeEmptyTitle => 'Ei lompakoita';

  @override
  String get homeEmptySubtitle =>
      'Luo ensimmäinen Bitcoin-lompakkosi aloittaaksesi.';

  @override
  String get homeBalanceTitle => 'AKTIIVINEN SALDO';

  @override
  String get balanceUnavailable => 'Saldo ei saatavilla';

  @override
  String get homeBackupVerified => 'Varmuuskopio vahvistettu';

  @override
  String get homeBackupNotVerified => 'Varmuuskopiota ei ole vahvistettu';

  @override
  String get homeMoreOptions => 'Lisää vaihtoehtoja';

  @override
  String get homeLockVault => 'Lukitse holvi';

  @override
  String get homeVaultLocked => 'Holvi lukittu';

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get settingsSectionSecurity => 'Turvallisuus';

  @override
  String get settingsSectionAppearance => 'Ulkoasu';

  @override
  String get settingsSectionTools => 'Työkalut';

  @override
  String get settingsSectionInfo => 'Tiedot';

  @override
  String get settingsTheme => 'Tumma teema';

  @override
  String get settingsAppLock => 'Sovelluksen lukitus';

  @override
  String get settingsAppLockDesc =>
      'Pyydä biometria tai puhelimen PIN jokaisella avauskerralla';

  @override
  String get settingsAppLockUnavailable =>
      'Tähän laitteeseen ei ole rekisteröity biometriaa';

  @override
  String get settingsAppLockEnableFailed =>
      'Vahvistus epäonnistui: lukitusta ei otettu käyttöön';

  @override
  String get settingsAppLockEnabled => 'Lukitus käytössä';

  @override
  String get settingsAppLockDisabled => 'Lukitus poistettu käytöstä';

  @override
  String get appLockTitle => 'Sovellus lukittu';

  @override
  String get appLockSubtitle => 'Avaa biometrialla tai puhelimen PIN-koodilla';

  @override
  String get appLockUnlock => 'Avaa';

  @override
  String get appLockReason => 'Avaa lompakko';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'Lukitus poistettu käytöstä: puhelimen näytön suojaus (biometria/PIN) ei ole enää käytettävissä. Ota se uudelleen käyttöön järjestelmäasetuksissa.';

  @override
  String get appLockNoticeContinue => 'Jatka';

  @override
  String get appLockPromptTitle => 'Otetaanko lukitus käyttöön?';

  @override
  String get appLockPromptMessage =>
      'Sovelluksen avaaminen vaatii biometrian tai puhelimen PIN-koodin.';

  @override
  String get appLockPromptEnable => 'Ota käyttöön';

  @override
  String get appLockPromptLater => 'Myöhemmin';

  @override
  String get aboutLicensesOpenOnline => 'Avaa verkossa';

  @override
  String homeCreated(Object date) {
    return 'Luotu: $date';
  }

  @override
  String homeLastTransfer(Object date) {
    return 'Viimeisin siirto: $date';
  }

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Lompakko $name$balance';
  }

  @override
  String get walletDetailTitle => 'Lompakko';

  @override
  String walletDetailCopied(Object label) {
    return '$label kopioitu. Poistetaan 60 s kuluttua.';
  }

  @override
  String get walletDetailNoConnection => 'Ei yhteyttä';

  @override
  String get walletDetailTransferSuccess =>
      'Lompakko siirretty onnistuneesti. Paikallinen siemen poistettu.';

  @override
  String walletDetailTransferError(Object error) {
    return 'Siirtovirhe: $error';
  }

  @override
  String get walletDetailSeedCopied =>
      'Siemenlause kopioitu. Poistetaan 60 s kuluttua.';

  @override
  String get walletDetailSeedWarning =>
      'Säilytä turvallisesti! Tämä on AINOA tapa palauttaa varasi.';

  @override
  String get walletDetailAddress => 'Osoite';

  @override
  String get walletDetailName => 'Nimi';

  @override
  String get walletDetailBalance => 'Saldo';

  @override
  String get walletDetailTransactions => 'Tapahtumat';

  @override
  String get walletDetailTxBlockHeight => 'Lohkokorkeus';

  @override
  String get walletDetailTxConfirmations => 'Vahvistukset';

  @override
  String get walletDetailTxDate => 'Päivämäärä';

  @override
  String get walletDetailTxDetails => 'Tapahtuman tiedot';

  @override
  String get walletDetailTxEmpty => 'Ei tapahtumia';

  @override
  String get walletDetailTxError => 'Tapahtumia ei voitu ladata';

  @override
  String get walletDetailTxFee => 'Maksu';

  @override
  String get walletDetailTxIncoming => 'Vastaanotetut';

  @override
  String get walletDetailTxOrphan => 'Orpo (kadonnut lohko)';

  @override
  String get walletDetailTxOutgoing => 'Lähetetyt';

  @override
  String get walletDetailTxPending => 'Odottaa vahvistusta';

  @override
  String get walletDetailTxReplaced => 'Korvattu (poistettu mempoolista)';

  @override
  String get walletDetailTxRetry => 'Yritä uudelleen';

  @override
  String get themeToggle => 'Vaihda teemaa';

  @override
  String get backupSeedTitle => 'Siementen varmuuskopio';

  @override
  String get backupSeedIntro =>
      'Kirjoita siemenlauseesi paperille ja säilytä se turvallisessa paikassa. Se on ainoa tapa palauttaa varasi.';

  @override
  String get backupSeedStart => 'Aloita varmuuskopio';

  @override
  String get backupSeedLater => 'Myöhemmin';

  @override
  String get backupSeedSavedContinue => 'Olen tallentanut siemenen';

  @override
  String get backupSeedVerifyTitle => 'Varmista varmuuskopiosi';

  @override
  String get backupSeedVerifyHint =>
      'Syötä 3 korostettua sanaa vahvistaaksesi, että olet tallentanut ne.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Sana $number';
  }

  @override
  String get backupSeedVerifyError => 'Väärät sanat. Yritä uudelleen.';

  @override
  String get backupSeedDone => 'Varmuuskopio valmis';

  @override
  String get backupSeedDoneDesc =>
      'Siemenesesi on turvassa. Muista: se, joka omistaa siemenen, hallitsee varat.';

  @override
  String get backupSeedFinish => 'Valmis';

  @override
  String get backupSeedSkipWarning =>
      'Jos ohitat, saatat menettää varasi laitteen katoamisen yhteydessä. Voit tehdä sen myöhemmin lompakon tiedoista.';

  @override
  String get walletDetailSend => 'Lähetä';

  @override
  String get walletDetailReceive => 'Vastaanota';

  @override
  String get walletDetailTransfer => 'Siirrä';

  @override
  String get walletDetailTransferred => 'SIIRRETTY';

  @override
  String get walletDetailPending => 'SIIRTO ODOTTAA';

  @override
  String get walletDetailNoName => 'Nimetön lompakko';

  @override
  String get walletDetailTransferredDesc =>
      'Tämä lompakko on siirretty. Vain luku -tila.';

  @override
  String get sendScreenTitle => 'Lähetä BTC';

  @override
  String get sendScreenAddressLabel => 'Vastaanottajan osoite';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => 'Määrä (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

  @override
  String get sendScreenFeeLabel => 'Maksu';

  @override
  String get sendScreenFeeLow => 'Matala';

  @override
  String get sendScreenFeeNormal => 'Normaali';

  @override
  String get sendScreenFeeHigh => 'Korkea';

  @override
  String get sendScreenFeeCustom => 'Mukautettu';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Käytettävissä: $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Arvioitu maksu: $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'UTXO-valinta';

  @override
  String get sendScreenUtxoSelectAll => 'Valitse kaikki';

  @override
  String get sendScreenUtxoNoneSelected =>
      'Valitse vähintään yksi lähetettävä UTXO';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Yhteensä: $total $ticker';
  }

  @override
  String get sendScreenMax => 'Max';

  @override
  String get sendScreenSend => 'Lähetä';

  @override
  String get sendScreenSending => 'Lähetetään...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return '$deleted lompakkoa poistettu, $errors virhettä: $error';
  }

  @override
  String get walletDetailBalanceLabel => 'SALDO';

  @override
  String get walletDetailMasterFingerprint => 'PÄÄSORMEJÄLKI';

  @override
  String get walletDetailDerivationPath => 'JOHDATUSPOLKU';

  @override
  String get walletDetailSettings => 'ASETUKSET';

  @override
  String get walletDetailAdvancedTools => 'Lisätyökalut';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'Käytettäviä UTXOita ei löytynyt';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count vahvistusta';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count valittu · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Lähetä valitut';

  @override
  String get walletDetailUtxoClearSelection => 'Tyhjennä valinta';

  @override
  String get walletDetailFirst100Addresses => 'Ensimmäiset 100 osoitetta';

  @override
  String get walletDetailPasswordSeedReason =>
      'Vahvista salasana nähdäksesi siemenlauseen';

  @override
  String get walletDetailBiometricSeedReason =>
      'Biometrinen vahvistus siemenlauseen näyttämiseen';

  @override
  String get walletDetailPasswordBumpReason =>
      'Vahvista salasana korottaaksesi palkkiota';

  @override
  String get walletDetailBiometricBumpReason =>
      'Biometrinen vahvistus palkkion korottamiseksi';

  @override
  String get walletDetailTxBumpFee => 'Korota palkkiota';

  @override
  String get walletDetailBumpFeeTitle => 'Korota transaktiopalkkiota';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Nykyinen palkkio: $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Suositeltuja palkkioita ei saatavilla — anna mukautettu hinta';

  @override
  String get walletDetailBumpFeeWarning =>
      'Alkuperäinen transaktio ei ehkä koskaan vahvistu, jos korvaava louhitaan.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Palkkiota korotettu — uusi transaktio $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'Uuden palkkion on oltava nykyistä suurempi';

  @override
  String get sendScreenSigning => 'Allekirjoitetaan tapahtumaa...';

  @override
  String get sendScreenBroadcasting => 'Lähetetään verkkoon...';

  @override
  String get sendScreenBiometricReason =>
      'Biometrinen vahvistus tapahtuman valtuuttamiseksi';

  @override
  String get sendScreenPasswordReason =>
      'Anna salasana tapahtuman valtuuttamiseksi';

  @override
  String get sendScreenBiometricRequired =>
      'Lähettäminen vaatii biometrisen tunnistuksen. Ota sormenjälki- tai kasvojentunnistus käyttöön laitteen asetuksista.';

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
      'Siemenlause koostuu 12, 15, 18, 21 tai 24 sanasta, jotka erotetaan välilyönneillä. Voit liittää sen suoraan.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Virhe: $error';
  }

  @override
  String get legalMitLicense => 'MIT-lisenssi';

  @override
  String get legalSecurityTitle => 'Turvallisuus';

  @override
  String get legalTermsContent =>
      'Nämä käyttöehdot ovat väliaikaiset, ja ne korvataan lopullisella versiolla, kun virallinen verkkosivusto on saatavilla.\n\nBtc Blake2b Wallet on itsehallittava Bitcoin-lompakko kokeelliselle \"bitcoin-blake2b\"-verkolle (Bitcoinin forkki). Yksityiset avaimet ja siemenlause pysyvät yksinomaan laitteellasi: emme säilytä, siirrä emmekä pääse käsiksi varoihisi.\n\nSovellus tarjotaan maksutta \"sellaisenaan\" ilman minkäänlaisia takuita. Käytät sitä omalla vastuullasi. Bitcoin-blake2b-verkko on Bitcoinista johdettu kokeellinen verkko: sen kolikoilla ei välttämättä ole markkina-arvoa, pörssit eivät välttämättä tunnista niitä, ja ne voivat joutua uudelleenjärjestelyjen kohteeksi. Mikään sovelluksen sisältö ei ole taloudellista tai sijoitusneuvontaa.\n\nOlet yksin vastuussa siemenlauseesi ja varojesi säilyttämisestä: jokainen, jolla on siemenlause hallussaan, voi käyttää kolikot. Sovellus ei voi palauttaa kadonnutta siemenlausetta. Käyttö laittomaan toimintaan on kielletty. Vakuutat olevasi vähintään 16-vuotias.\n\nBtc Blake2b Wallet ei liity Bitcoiniin, Bitcoin Coreen tai bitcoin.orgiin, eikä Bitcoin, Bitcoin Core tai bitcoin.org sponsoroi tai hyväksy sitä.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'Tämä tietosuojakäytäntö on väliaikainen, ja se korvataan lopullisella versiolla, joka julkaistaan virallisella verkkosivustolla, kun se on saatavilla.\n\n1) LAITTEELLA OLEVAT TIEDOT. Sovellus ei vaadi tiliä eikä tallenna henkilötietoja tekijän palvelimille. Salattu siemenlause (AES-256-GCM), asetukset ja suostumukset pysyvät VAIN laitteellasi.\n\n2) KOLMANSILLE OSAPUOLILLE TOIMINTAA VARTEN LÄHETETTÄVÄT TIEDOT. Saldon ja maksujen näyttämiseksi sovellus kysyy julkisia kolmansien osapuolten rajapintoja:\n• mempool.guide (lohkoketjuselain).\nJokaisessa pyynnössä lähetetään IP-osoitteesi ja kysytyn lompakon julkinen osoite. Yksityisiä avaimia ja siemenlausetta EI KOSKAAN lähetetä.\n\n3) EI SEURANTAA. Ei analytiikkaa, ei mainontaa, ei evästeitä sovelluksen sisällä.\n\n4) OIKEUDET (GDPR, 13-14 art.). Sinulla on oikeus saada pääsy tietoihin sekä oikeus oikaisuun, poistamiseen ja vastustamiseen kirjoittamalla rekisterinpitäjälle: $holder — $email. Koska emme säilytä henkilötietoja, nämä oikeudet ovat suurelta osin jo taattuja sillä, että tiedot pysyvät laitteellasi.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'Ilmoita tietoturva-aukoista käyttämällä GitHub-tietovaraston yksityistä \"Report a vulnerability\" -ilmoitusta (Security-välilehti) tai kirjoita osoitteeseen:\n$email\n\nÄlä avaa julkisia issue-merkintöjä tietoturvaongelmista. Vastausaika: 72 tuntia. Julkaisukäytäntö: 90 päivää.';
  }

  @override
  String get sendScreenSuccess => 'Tapahtuma lähetetty!';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID: $txid';
  }

  @override
  String sendScreenError(Object error) {
    return 'Lähetysvirhe: $error';
  }

  @override
  String get sendScreenValidateAddress => 'Anna osoite';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Virheellinen osoite ($network), käytä $prefix';
  }

  @override
  String get sendScreenValidateLength => 'Virheellinen osoitteen pituus';

  @override
  String get sendScreenValidateSelf => 'Et voi lähettää itsellesi';

  @override
  String get sendScreenValidateAmount => 'Anna määrä';

  @override
  String get sendScreenValidateInvalidAmount => 'Virheellinen määrä';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Määrä liian pieni (vähintään $dust satoshia / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Riittämättömät varat (saldo: $balance, arvioitu maksu: $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'Ladataan UTXO:ita...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'UTXO:ita ei voida ladata: $error';
  }

  @override
  String get scanQrTitle => 'Skannaa QR-koodi';

  @override
  String get scanQrError =>
      'Kameraa ei voi käyttää. Myönnä kameran käyttöoikeus ja yritä uudelleen.';

  @override
  String get scanQrInvalid =>
      'Skannattu koodi ei ole kelvollinen Bitcoin-osoite.';

  @override
  String get scanQrInvalidInvoice =>
      'Skannattu koodi ei ole kelvollinen Lightning-lasku.';

  @override
  String get scanQrTorch => 'Vaihda taskulamppua';

  @override
  String get sendConfirmTitle => 'Vahvista tapahtuma';

  @override
  String get sendConfirmWarning =>
      'Tämä tapahtuma on peruuttamaton. Tarkista tiedot ennen vahvistamista.';

  @override
  String get sendConfirmSend => 'Vahvista ja lähetä';

  @override
  String get importScreenTitle => 'Tuo lompakko';

  @override
  String get importScreenHeading => 'Anna siemenlause';

  @override
  String get importScreenSubtitle =>
      'Anna 12, 15, 18, 21 tai 24 sanan muistilause välilyönneillä erotettuna ja valitse sitten alkuperäistä lompakkoa vastaava tilityyppi.';

  @override
  String get importScriptTypeLabel => 'Tilityyppi';

  @override
  String get importScriptTypeNativeSegwit => 'Natiivi SegWit (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'Sisäkkäinen SegWit (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Luotava lompakkotyyppi';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Osoitteet alkavat $prefix';
  }

  @override
  String get importScreenHint => 'sana1 sana2 sana3 ...';

  @override
  String get importScreenValidateEmpty => 'Anna muistilause.';

  @override
  String importScreenValidateCount(Object count) {
    return 'Lauseen on sisällettävä 12, 15, 18, 21 tai 24 sanaa (havaittu: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Virheellinen muistilause. Tarkista oikeinkirjoitus.';

  @override
  String get importScreenImporting => 'Tuodaan...';

  @override
  String get importScreenImport => 'Tuo';

  @override
  String importScreenError(Object error) {
    return 'Virhe tuotaessa: $error';
  }

  @override
  String get importModeSeed => 'Siemenlause';

  @override
  String get importModeWatchOnly => 'Vain luku (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Tarkkaile ulkoista lompakkoa (saldo ja historia) vain sen julkisella laajennetulla avaimella. Yksityistä avainta ei käytetä — lähettäminen ei ole koskaan mahdollista.';

  @override
  String get importWatchOnlyXpubLabel => 'Tilin xpub';

  @override
  String get importWatchOnlyXpubHint =>
      'Liitä tilin xpub (alkaa \"xpub\"). Vain julkiset avaimet: älä koskaan liitä xprv:tä.';

  @override
  String get importWatchOnlyValidateEmpty => 'Anna tilin xpub.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'Xpubin on alettava \"xpub\" (pääverkko).';

  @override
  String get watchOnlyBadge => 'Vain luku';

  @override
  String get transferScreenTitle => 'Siirrä lompakko';

  @override
  String get transferScreenScanning => 'Skannaa vastaanottajan QR-koodi.';

  @override
  String get transferScreenProcessing => 'Käsitellään ja salataan tietoja...';

  @override
  String transferScreenScanError(Object error) {
    return 'Virhe skannauksessa tai salauksessa: $error';
  }

  @override
  String get transferScreenNearbyTitle => 'Skannaa vastaanottaaksesi';

  @override
  String get transferScreenNearbySubtitle =>
      'Anna vastaanottajan skannata tämä QR-koodi.';

  @override
  String transferScreenNearbyCode(Object code) {
    return 'Manuaalinen koodi: $code';
  }

  @override
  String get transferScreenNearbyCancel => 'Peruuta';

  @override
  String get transferScreenNearbySuccess =>
      'Lompakko siirretty onnistuneesti Bluetoothilla. Paikallinen siemen poistettu.';

  @override
  String transferScreenNearbyError(Object error) {
    return 'Siirtovirhe: $error';
  }

  @override
  String get transferScreenWebRtcConnecting =>
      'Käynnistetään WebRTC-yhteyttä...';

  @override
  String get transferScreenWebRtcTransferring => 'Siirretään WebRTC:llä...';

  @override
  String get transferScreenTransferComplete => 'Siirto valmis!';

  @override
  String get transferScreenMethodTitle => 'Valitse siirtotapa';

  @override
  String get transferScreenMethodQr => 'QR-koodi (2-vaiheinen)';

  @override
  String get transferScreenMethodQrDesc =>
      'Skannaa vastaanottajan QR ja luo sitten QR salatulla siemenellä.';

  @override
  String get transferScreenMethodNearby => 'Bluetooth P2P';

  @override
  String get transferScreenMethodNearbyDesc =>
      'Suora laitteiden välinen siirto. Vaatii Bluetoothin.';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC (Internet)';

  @override
  String get transferScreenMethodWebRtcDesc =>
      'P2P selaimen kautta. Vaatii Internetin molemmilla laitteilla.';

  @override
  String get transferScreenWebRtcQrDescription =>
      'Vastaanottajan on skannattava tämä QR. Siirto tapahtuu WebRTC:n kautta (ei kokorajoitusta).';

  @override
  String get transferScreenEncryptedQrDescription =>
      'Näytä tämä QR-koodi vastaanottavalle laitteelle. Kun skannaus ja vastaanotto on valmis, lompakko poistetaan automaattisesti tältä laitteelta.';

  @override
  String get transferScreenWebRtcTimeout =>
      'WebRTC-yhteys epäonnistui 30 sekunnin jälkeen. Yritä uudelleen tai käytä 2-vaiheista QR-koodimenetelmää.';

  @override
  String get receiveScreenTitle => 'Vastaanota lompakko';

  @override
  String get receiveScreenInit => 'Alustetaan epäsymmetristä avainta...';

  @override
  String get receiveScreenShowQr => 'Näytä tämä QR-koodi lähettäjälle.';

  @override
  String get receiveScreenScanSender =>
      'Skannaa QR-koodi lähettäjän laitteelta.';

  @override
  String get receiveScreenAutoDetectMethod =>
      'Järjestelmä tunnistaa automaattisesti lähettäjän käyttämän siirtomenetelmän.';

  @override
  String receiveScreenKeyError(Object error) {
    return 'Avaimen luontivirhe: $error';
  }

  @override
  String get receiveScreenDecrypting =>
      'Tiedot vastaanotettu. Salauksen purku ja palvelimen validointi...';

  @override
  String get receiveScreenSuccess =>
      'Lompakko vastaanotettu ja tuotu onnistuneesti.';

  @override
  String get receiveScreenQrSuccess => 'Lompakko vastaanotettu QR-koodilla.';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return 'Koodi $code luettu. Yhdistetään...';
  }

  @override
  String get receiveScreenNearbySuccess =>
      'Lompakko vastaanotettu Bluetooth P2P:llä.';

  @override
  String receiveScreenError(Object error) {
    return 'Virhe: $error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'WebRTC-huone';

  @override
  String get receiveScreenWebRtcConnect => 'Yhdistä huoneeseen';

  @override
  String get receiveScreenWebRtcShareQr => 'Jaa tämä QR-koodi lähettäjälle';

  @override
  String get receiveScreenWebRtcScanQr => 'Skannaa lähettäjän huoneen QR-koodi';

  @override
  String get receiveScreenWebRtcWait => 'Odotetaan lähettäjän yhteyttä...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return 'Huoneen ID: $roomId';
  }

  @override
  String get passwordDialogCreateTitle => 'Luo suojaussalasana';

  @override
  String get passwordDialogCreateContent =>
      'Aseta salasana suojaamaan arkaluonteisia toimintoja tässä selaimessa.';

  @override
  String get passwordDialogCreateHint => 'Anna turvallinen salasana';

  @override
  String get passwordDialogCreateConfirm => 'Vahvista salasana';

  @override
  String get passwordDialogCreateConfirmHint => 'Anna salasana uudelleen';

  @override
  String get passwordDialogCreateMismatch => 'Salasanat eivät täsmää';

  @override
  String get passwordDialogCreateTooShort =>
      'Salasanan on oltava vähintään 8 merkkiä';

  @override
  String get passwordDialogCreate => 'Luo';

  @override
  String get passwordDialogCancel => 'Peruuta';

  @override
  String get passwordDialogEnterTitle => 'Anna salasana';

  @override
  String get passwordDialogEnterContent =>
      'Anna suojaussalasanasi jatkaaksesi.';

  @override
  String get passwordDialogEnterHint => 'Anna salasanasi';

  @override
  String get passwordDialogEnter => 'Vahvista';

  @override
  String get passwordDialogWrong => 'Väärä salasana';

  @override
  String get languageSelector => 'Kieli';

  @override
  String get languageSelectorAuto => '🌐 Automaattinen (järjestelmä)';

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
  String get walletDetailRefresh => 'Päivitä';

  @override
  String get walletDetailDeleteTitle => 'Poista lompakko?';

  @override
  String get walletDetailDeleteConfirm => 'Poista pysyvästi';

  @override
  String get walletDetailDeleteWarning =>
      'Tämä toimenpide on peruuttamaton. Varmista, että sinulla on varmuuskopio siemenlauseesta, jos lompakossa on varoja.';

  @override
  String get walletDetailInfo => 'Lompakon tiedot';

  @override
  String get walletDetailNameLabel => 'Lompakon nimi';

  @override
  String get walletDetailNameHint => 'esim. Säästöt';

  @override
  String get walletDetailType => 'Tyyppi';

  @override
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'Sisäkkäinen SegWit (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'PÄIVITETÄÄN...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TAPAHTUMAA';
  }

  @override
  String get walletDetailReceiveQr => 'Vastaanota Bitcoin';

  @override
  String get walletDetailSignVerify => 'Allekirjoita/Varmista viesti';

  @override
  String get walletDetailShowAddresses => 'Näytä osoitteet';

  @override
  String get walletDetailWalletAddress => 'Lompakon osoite';

  @override
  String get walletDetailExportSeed => 'Vie/Varmuuskopioi siemenlause';

  @override
  String get walletDetailShowSeedTitle => 'Näytä siemenlause?';

  @override
  String get walletDetailShowSeedContent =>
      'Siemenlause antaa pääsyn kaikkiin varoihin. Varmista, että olet turvallisessa paikassa.';

  @override
  String get walletDetailShowSeedConfirm => 'Kyllä, näytä';

  @override
  String get walletDetailSeedVerifyPrompt =>
      'Haluatko varmistaa, että olet tallentanut siemenlauseen?';

  @override
  String get walletDetailSeedVerifyYes => 'Kyllä, varmista';

  @override
  String get walletDetailSeedVerifyNotNow => 'Ei nyt';

  @override
  String get walletDetailSeedVerified => 'Varmuuskopio vahvistettu';

  @override
  String get walletDetailSeedHidden =>
      'Siemenlause piilotettu turvallisuussyistä';

  @override
  String get walletDetailSeedShowAgain => 'Näytä siemenlause';

  @override
  String get walletDetailHideSeed => 'Piilota';

  @override
  String get walletDetailBackupNotConfirmed =>
      'Varmuuskopiota ei ole vahvistettu';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'Et ole vielä tallentanut siemenlausetta. Jos menetät laitteen tai asennat sovelluksen uudelleen, menetät pysyvästi pääsyn varoihisi.';

  @override
  String get walletDetailShowXpub => 'Näytä lompakon XPUB';

  @override
  String get walletDetailDisplayHome => 'Näytä arvo etusivulla';

  @override
  String get walletDetailUtxoRename => 'Nimeä uudelleen';

  @override
  String get walletDetailUtxoRenameTitle => 'Nimeä UTXO uudelleen';

  @override
  String get walletDetailSave => 'Tallenna';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Luotu';

  @override
  String get walletDetailTransferredOn => 'Siirretty';

  @override
  String get walletDetailClose => 'Sulje';

  @override
  String get walletDetailSign => 'Allekirjoita';

  @override
  String get walletDetailVerify => 'Varmista';

  @override
  String get walletDetailSignMessage => 'Allekirjoita viesti';

  @override
  String get walletDetailVerifyMessage => 'Varmista viesti';

  @override
  String get walletDetailMessage => 'Viesti';

  @override
  String get walletDetailBitcoinAddress => 'Bitcoin-osoite';

  @override
  String get walletDetailSignature => 'Allekirjoitus (Base64)';

  @override
  String get walletDetailResult => 'Tulos:';

  @override
  String get walletDetailSignatureLabel => 'Allekirjoitus:';

  @override
  String get walletDetailCopy => 'Kopioi';

  @override
  String get walletDetailAddressCopied => 'Osoite kopioitu leikepöydälle';

  @override
  String get walletDetailXpubTitle => 'Lompakon XPUB';

  @override
  String get walletDetailXpubDesc =>
      'Tämä XPUB mahdollistaa kaikkien tulevien osoitteiden ja saldojen tarkastelun, mutta sillä ei voi käyttää varoja.';

  @override
  String get walletDetailXpubCopied => 'XPUB kopioitu';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Virhe XPUB:n johtamisessa: $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Virhe osoitteiden johtamisessa: $error';
  }

  @override
  String get walletDetailFirst100 => 'Ensimmäiset 100 osoitetta';

  @override
  String get walletDetailValidSig => 'KELPOLLINEN ALLEKIRJOITUS ✓';

  @override
  String get walletDetailInvalidSig => 'VIRHEELLINEN ALLEKIRJOITUS ✗';

  @override
  String get donateTitle => 'Tue projektia ❤️';

  @override
  String get donatePhrase =>
      '☕ \"Jos projekti on sinulle hyödyllinen, tarjoa meille virtuaalikahvi\"';

  @override
  String get donateAddressLabel => 'Bitcoin-lahjoitusosoite:';

  @override
  String get donateCopy => 'Kopioi';

  @override
  String get donateCopied => 'Kopioitu! ✓';

  @override
  String get donateNote =>
      'Vapaaehtoinen lahjoitus — emme tarjoa vastineeksi palvelua tai etua. Mikä tahansa summa on tervetullut, jopa muutama satoshi. Kiitos! 🧡';

  @override
  String get donateNoWalletTitle => 'Lompakkoa ei löytynyt';

  @override
  String get donateNoWalletMessage =>
      'Laitteeltasi ei löytynyt Bitcoin-lompakkosovellusta. Voit silti kopioida osoitteen ja liittää sen suosikkilompakkoosi.';

  @override
  String get donateOpenWallet => 'Avaa lompakossa';

  @override
  String get donateButton => 'Tue projektia ❤️';

  @override
  String get multiTransferTitle => 'Usean lompakon lähetys';

  @override
  String get multiTransferSelectWallets => 'Valitse lähetettävät lompakot';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lompakkoa valittu',
      one: '1 lompakko valittu',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return 'Kokonaisarvo: $amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => 'Siirtomenetelmä:';

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
    return 'QR-koodi 2-vaihe (max. $max)';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lähetä $count lompakkoa',
      one: 'Lähetä 1 lompakko',
    );
    return '$_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => 'Lähetetään...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return 'Lompakko $current/$total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lompakkoa lähetetty onnistuneesti',
      one: '1 lompakko lähetetty onnistuneesti',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success lähetetty, $failed epäonnistui';
  }

  @override
  String get multiTransferNoLockedWallets =>
      'Ei siirrettäviä lompakoita. Vain lukitut lompakot voidaan siirtää.';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return 'Valitsit $selected lompakkoa. Maksimi menetelmälle $method on $max.';
  }

  @override
  String get multiTransferReceivingTitle => 'Usean lompakon vastaanotto';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return 'Vastaanotettu $received/$total lompakkoa';
  }

  @override
  String get multiTransferMethodUnavailable => 'Ei saatavilla tällä alustalla';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return 'Lähetetään lompakkoa $current/$total...';
  }

  @override
  String get multiTransferPreparing => 'Valmistellaan lompakkoa...';

  @override
  String get multiTransferWaitingReceiver => 'Odotetaan vastaanottajaa...';

  @override
  String get multiTransferCompleted => 'Valmis';

  @override
  String get multiTransferFailed => 'Epäonnistui';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return 'Manuaalinen 2-vaiheen siirto QR-koodilla. Max. $max lompakkoa.';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return 'Nopea P2P-siirto internetin kautta. Max. $max lompakkoa.';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return 'Suora laitteiden välinen siirto. Max. $max lompakkoa.';
  }

  @override
  String get multiTransferNoBalance => 'Saldo ei saatavilla';

  @override
  String get multiTransferConfirmTitle => 'Vahvista lähetys';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lompakkoa',
      one: '1 lompakkoa',
    );
    return 'Olet lähettämässä $_temp0 yhteensä $amount $ticker. Jatketaanko?';
  }

  @override
  String get onboardingTitle => 'Tervetuloa Btc Blake2b Walletiin';

  @override
  String get onboardingSubtitle =>
      'Avoimen lähdekoodin Bitcoin-lompakko. Oma säilytys. Ei KYC:tä.';

  @override
  String get onboardingResidenceLabel => 'Verotuksellinen asuinmaa';

  @override
  String get onboardingResidenceHint => 'Valitse maasi';

  @override
  String get onboardingReverseSolicitation =>
      'Vakuutan käyttäväni Btc Blake2b Walletia omasta aloitteestani (\"reverse solicitation\") ja että verotuksellinen asuinpaikkani on valitussa maassa.';

  @override
  String get onboardingTermsAccept => 'Hyväksyn ';

  @override
  String get onboardingPrivacyAccept => 'Olen lukenut ';

  @override
  String get onboardingAgeConfirm => 'Vakuutan olevani vähintään 16-vuotias';

  @override
  String get onboardingAgeSubtitle =>
      'GDPR Art. 8 edellyttämä tietojenkäsittelyn suostumukselle';

  @override
  String get onboardingContinue => 'Jatka';

  @override
  String get onboardingStepNext => 'Seuraava';

  @override
  String get onboardingStepBack => 'Takaisin';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Vaihe $current / $total';
  }

  @override
  String get onboardingTermsTitle => 'Ehdot ja tietosuoja';

  @override
  String get onboardingValidationResidence =>
      'Valitse verotuksellinen asuinmaasi';

  @override
  String get onboardingValidationCheckbox =>
      'Sinun on hyväksyttävä kaikki vakuutukset';

  @override
  String get onboardingLinkTerms => 'käyttöehdot';

  @override
  String get onboardingLinkPrivacy => 'tietosuojaselosteen';

  @override
  String get aboutTitle => 'Tietoja Btc Blake2b Walletista';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet on avoimen lähdekoodin Bitcoin-lompakko. Ei rekisteröintiä, ei KYC:tä, ei seurantaa. Sinun avaimesi, sinun bitcoinit.';

  @override
  String get aboutLicenseTitle => 'Lisenssi';

  @override
  String get aboutThirdPartyLicenses => 'Kolmannen osapuolen lisenssit';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'Näytä täydellinen luettelo avoimen lähdekoodin lisensseistä';

  @override
  String get aboutBuiltWith => 'Rakennettu käyttäen';

  @override
  String get aboutDisclaimer =>
      'Tämä ohjelmisto toimitetaan \"SELLAISENAAN\" ilman minkäänlaista takuuta.';

  @override
  String get explorerTitle => 'Selain';

  @override
  String get explorerAddressLabel => 'Osoite';

  @override
  String get explorerRefresh => 'Päivitä';

  @override
  String get explorerBalanceLabel => 'Saldo';

  @override
  String get explorerTxCount => 'Tapahtumat';

  @override
  String get explorerTipHeight => 'Solmun korkeus';

  @override
  String get explorerErrorInvalidAddress =>
      'Virheellinen osoite. Tarkista muoto tässä verkossa.';

  @override
  String get explorerErrorRateLimited =>
      'Pyyntöraja ylitetty. Yritä uudelleen minuutin kuluttua.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Palvelu tilapäisesti ei käytettävissä. Yritä myöhemmin uudelleen.';

  @override
  String get explorerErrorNotFound => 'Osoitetta tai tapahtumaa ei löytynyt.';

  @override
  String get explorerErrorTimeout =>
      'Pyyntö aikakatkaistiin. Tarkista yhteys ja yritä uudelleen.';

  @override
  String get explorerErrorNetwork =>
      'Verkko ei käytettävissä. Tarkista yhteys.';

  @override
  String get explorerRetry => 'Yritä uudelleen';

  @override
  String explorerErrorGeneric(String error) {
    return 'Virhe: $error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'Ei Lightning-solmua yhdistetty';

  @override
  String get lightningDisconnectedBody =>
      'Yhdistä blake2b-Lightning-solmusi lähettääksesi ja vastaanottaaksesi maksuja. Sovellus ei koskaan säilytä varojasi tai avaimiasi.';

  @override
  String get lightningConnectButton => 'Yhdistä solmu';

  @override
  String get lightningConnectTitle => 'Yhdistä Lightning-solmu';

  @override
  String get lightningConnectHint =>
      'Liitä yhteysmerkkijono (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Virheellinen yhteysmerkkijono';

  @override
  String get lightningConnectInfo =>
      'Solmun on valtuutettava tämä sovellus (grant): tarkista solmusi hallintapaneeli.';

  @override
  String get lightningConnecting => 'Yhdistetään…';

  @override
  String get lightningConnected => 'Yhdistetty';

  @override
  String get lightningDisconnect => 'Katkaise yhteys';

  @override
  String get lightningBalance => 'Lightning-saldo';

  @override
  String get lightningChannels => 'Kanavat';

  @override
  String get lightningNoChannels => 'Ei avoimia kanavia';

  @override
  String get lightningChannelPeer => 'Vastapuoli';

  @override
  String get lightningChannelCapacity => 'Kapasiteetti';

  @override
  String get lightningChannelLocal => 'Paikallinen';

  @override
  String get lightningChannelRemote => 'Etä';

  @override
  String get lightningOpenChannel => 'Avaa kanava';

  @override
  String get lightningOpenChannelNodeId => 'Node ID (pubkey)';

  @override
  String get lightningOpenChannelHost => 'Isäntä (valinnainen, ip:portti)';

  @override
  String get lightningOpenChannelAmount => 'Määrä (sat)';

  @override
  String get lightningOpenChannelPrivate => 'Yksityinen kanava';

  @override
  String get lightningChannelOpened => 'Kanavan avaus pyydetty';

  @override
  String get lightningCloseChannel => 'Sulje kanava';

  @override
  String get lightningCloseChannelForce => 'Pakotettu sulkeminen';

  @override
  String get lightningCloseChannelForceWarning =>
      'Pakotettu sulkeminen julkaisee kanavan viimeisimmän tilan on-chain. Voi aiheuttaa kuluja ja viiveitä. Jatketaanko?';

  @override
  String get lightningReceive => 'Vastaanota';

  @override
  String get lightningSend => 'Lähetä';

  @override
  String get lightningInvoiceAmount => 'Määrä (sat)';

  @override
  String get lightningInvoiceDescription => 'Kuvaus (valinnainen)';

  @override
  String get lightningInvoiceCreate => 'Luo lasku';

  @override
  String get lightningInvoiceTitle => 'Lightning-lasku';

  @override
  String get lightningPay => 'Maksa lasku';

  @override
  String get lightningPayHint => 'Liitä lasku (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Vahvista Lightning-maksu';

  @override
  String get lightningPayDialogBody => 'Maksetaanko tämä lasku?';

  @override
  String get lightningPaySuccess => 'Maksu lähetetty';

  @override
  String get lightningCopied => 'Kopioitu';

  @override
  String get lightningErrorRestricted =>
      'Solmu ei ole valtuuttanut tätä sovellusta. Luo grant solmuusi tälle yhteydelle.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Lightning-virhe: $error';
  }

  @override
  String get lightningConfirm => 'Vahvista';

  @override
  String get lightningCancel => 'Peruuta';

  @override
  String get lightningNodeOnchain => 'Noden on-chain';

  @override
  String get lightningDeposit => 'Talleta';

  @override
  String get lightningWithdraw => 'Lähetä on-chain';

  @override
  String get lightningDepositTitle => 'On-chain-talletus';

  @override
  String get lightningDepositHint =>
      'Lähetä blake2b-varoja tähän noden osoitteeseen.';

  @override
  String get lightningDepositNewAddress => 'Uusi osoite';

  @override
  String get lightningDepositWarning =>
      'Lähetä vain blake2b-verkossa. Väärässä verkossa lähetetyt varat menetetään.';

  @override
  String get lightningOnchainSendTitle => 'On-chain-lähetys';

  @override
  String get lightningOnchainAddressLabel => 'Vastaanottajan osoite';

  @override
  String get lightningOnchainAmountLabel => 'Summa (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Verkkokulu';

  @override
  String get lightningOnchainFeeMin => 'Minimi';

  @override
  String get lightningOnchainFeeEconomical => 'Edullinen';

  @override
  String get lightningOnchainFeePriority => 'Prioriteetti';

  @override
  String get lightningOnchainConfirm => 'Vahvista lähetys';

  @override
  String get lightningOnchainConfirmTitle => 'Vahvistetaanko on-chain-lähetys?';

  @override
  String get lightningOnchainWarning =>
      'Peruuttamaton toiminto: varat poistuvat nodesta.';

  @override
  String get lightningOnchainSuccess => 'Tapahtuma lähetetty';

  @override
  String get lightningOnchainInvalidAddress => 'Virheellinen blake2b-osoite';

  @override
  String get lightningOnchainInsufficient => 'On-chain-varat riittämättömät';

  @override
  String get lightningFeesUnavailable =>
      'Kuluarviot eivät saatavilla: node valitsee kulun';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey tai pubkey@host:port (onion vaatii Torin nodessa)';

  @override
  String get lightningOpenChannelInvalid =>
      'Virheellinen node-ID tai host (66 hex, host:port)';

  @override
  String get lightningActivityDetected => 'Aktiviteettia havaittu nodessa';

  @override
  String get lightningPeers => 'Peerit';

  @override
  String get lightningPeersEmpty => 'Ei peer-yhteyksiä';

  @override
  String get lightningConnectPeer => 'Yhdistä peer';

  @override
  String get lightningDisconnectPeer => 'Katkaise';

  @override
  String get lightningPeerDisconnected => 'Katkaistu';

  @override
  String get lightningPeerId => 'Peer-ID';

  @override
  String get lightningPeerAddresses => 'Osoitteet';

  @override
  String get lightningDisconnectPeerConfirm =>
      'Katkaistaanko tämä peer? Avoimet kanavat pysyvät aktiivisina.';

  @override
  String get lightningChannelDetail => 'Kanavan tiedot';

  @override
  String get lightningChannelShortId => 'Short channel ID';

  @override
  String get lightningChannelState => 'Noden tila';

  @override
  String get lightningChannelFee => 'Kulu';

  @override
  String get lightningChannelSpendable => 'Käytettävissä';

  @override
  String get lightningChannelReceivable => 'Vastaanotettavissa';

  @override
  String get lightningChannelHtlcs => 'HTLC';

  @override
  String get lightningChannelFundingTxid => 'Funding-txid';

  @override
  String get lightningNodeManagement => 'Solmun hallinta';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers peeriä · $channels kanavaa';
  }

  @override
  String get lightningNodeIdentity => 'Solmun identiteetti';

  @override
  String get lightningNodePubkey => 'Julkinen avain';

  @override
  String get lightningNodeVersion => 'Versio';

  @override
  String get lightningNodePeersCount => 'Peerit';

  @override
  String get lightningNodeChannelsActive => 'Aktiiviset kanavat';

  @override
  String get lightningNodeChannelsPending => 'Odottavat kanavat';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'Ei saatavilla tässä solmussa: leasing-ehtojen julkaisu vaatii liquidity-ads-lisäosan.';

  @override
  String get lightningLiquidity => 'Likviditeetti';

  @override
  String get lightningLiquidityTotal => 'Kokonaiskapasiteetti';

  @override
  String get lightningLiquidityOutbound => 'Lähtevä';

  @override
  String get lightningLiquidityInbound => 'Saapuva';

  @override
  String get lightningLiquidityWarning =>
      'Ei saapuvaa likviditeettiä: maksuja ei voi vastaanottaa ennen kuin peer avaa kanavan tähän solmuun.';

  @override
  String get lightningMovements => 'Tapahtumat';

  @override
  String get lightningMovementsEmpty => 'Ei tapahtumia';

  @override
  String get lightningMovementsAll => 'Kaikki tapahtumat';

  @override
  String get lightningMovementsLoadMore => 'Lataa lisää';

  @override
  String get lightningMovementDeposit => 'On-chain-talletus';

  @override
  String get lightningMovementWithdrawal => 'On-chain-lähetys';

  @override
  String get lightningMovementChannelOpen => 'Kanavan avaus';

  @override
  String get lightningMovementChannelClose => 'Kanavan sulkeminen';

  @override
  String get lightningMovementInvoice => 'Lightning-maksu';

  @override
  String get lightningMovementOnchainFee => 'On-chain-kulu';

  @override
  String get lightningMovementForward => 'Välitys';

  @override
  String get lightningMovementOther => 'Tapahtuma';

  @override
  String lightningChannelsAll(int count) {
    return 'Kaikki kanavat ($count)';
  }

  @override
  String get lightningOnchainNode => 'Solmun on-chain';

  @override
  String get lightningOnchainBalance => 'On-chain-saldo';

  @override
  String get lightningOnchainConfirmed => 'Vahvistetut';

  @override
  String get lightningOnchainPending => 'Odottaa';

  @override
  String get lightningOnchainUtxos => 'UTXO:t';

  @override
  String get lightningOnchainUtxosEmpty => 'Ei UTXO:ita';

  @override
  String get lightningOnchainAddresses => 'Solmun osoitteet';

  @override
  String get lightningOnchainNewAddress => 'Uusi osoite';

  @override
  String get lightningOnchainAddressType => 'Osoitetyyppi';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'Saldolla';

  @override
  String get lightningOnchainReserved => 'Varattu';

  @override
  String get lightningOnchainBlockHeight => 'Lohko';

  @override
  String get lightningPayments => 'Maksut';

  @override
  String get lightningInvoices => 'Laskut';

  @override
  String get lightningInvoicesEmpty => 'Ei laskuja';

  @override
  String get lightningInvoiceStatusPaid => 'Maksettu';

  @override
  String get lightningInvoiceStatusPending => 'Odottaa maksua';

  @override
  String get lightningInvoiceStatusExpired => 'Vanhentunut';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Maksettu $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Vanhenee $date';
  }

  @override
  String get lightningReceivePaid => 'Lasku maksettu';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total laskua · $pending odottaa';
  }

  @override
  String get lightningPays => 'Lähetetyt maksut';

  @override
  String get lightningPaysEmpty => 'Ei maksuja';

  @override
  String get lightningPaymentFee => 'Kulu';

  @override
  String get lightningPaymentCompleted => 'Valmis';

  @override
  String get lightningPaymentPending => 'Kesken';

  @override
  String get lightningPaymentFailed => 'Epäonnistui';

  @override
  String get lightningHtlcsEmpty => 'Ei HTLC:ita';

  @override
  String get lightningHtlcInProgress => 'Matkalla';

  @override
  String get lightningHtlcIncoming => 'Saapuva';

  @override
  String get lightningHtlcOutgoing => 'Lähtevä';

  @override
  String get lightningChannelFees => 'Reitityskulut';

  @override
  String get lightningFeeEdit => 'Muokkaa kuluja';

  @override
  String get lightningFeeBefore => 'Nykyiset';

  @override
  String get lightningFeeAfter => 'Uudet';

  @override
  String get lightningFeeBaseLabel => 'Perus (sat)';

  @override
  String get lightningFeePpmLabel => 'Hinta (ppm)';

  @override
  String get lightningHtlcMinLabel => 'Min HTLC (sat)';

  @override
  String get lightningHtlcMaxLabel => 'Max HTLC (sat)';

  @override
  String get lightningCltvLabel => 'CLTV-delta';

  @override
  String get lightningChannelReserve => 'Oma varaus';

  @override
  String get lightningChannelToSelfDelay => 'To-self-viive';

  @override
  String get lightningFeeConfirmTitle =>
      'Otetaanko nämä reitityskulut käyttöön?';

  @override
  String get lightningFeeWarning =>
      'Kulut koskevat reititettyjä maksuja. Verkko hyväksyy vain muutaman muutoksen päivässä ja peerit voivat viivästyä.';

  @override
  String get lightningFeeUpdated => 'Kulupolitiikka päivitetty';

  @override
  String get lightningDiagnostics => 'Diagnostiikka';

  @override
  String get lightningDiagnosticsSubtitle =>
      'Kirjanpito, liitännäiset ja välitys';

  @override
  String get lightningStatsEconomy => 'Talous';

  @override
  String get lightningStatsNet => 'Netto';

  @override
  String get lightningStatsSource => 'Noden kirjanpidosta (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'Ei vielä kirjanpitotietoja';

  @override
  String get lightningStatsTagDeposit => 'Talletukset';

  @override
  String get lightningStatsTagInvoice => 'Laskut';

  @override
  String get lightningStatsTagWithdrawal => 'Nostot';

  @override
  String get lightningStatsTagOnchainFee => 'On-chain-kulut';

  @override
  String get lightningStatsTagChannelOpen => 'Kanavien avaukset';

  @override
  String get lightningStatsTagChannelClose => 'Kanavien sulkemiset';

  @override
  String get lightningStatsTagRouted => 'Ansaitut reitityskulut';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tapahtumaa',
      one: '1 tapahtuma',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Liitännäiset';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count aktiivista';
  }

  @override
  String get lightningPluginInactive => 'ei aktiivinen';

  @override
  String get lightningForwardsTitle => 'Välitys';

  @override
  String get lightningForwardsEmpty => 'Ei vielä välitettyjä maksuja';

  @override
  String get lightningForwardSettled => 'Toteutunut';

  @override
  String get lightningForwardFailed => 'Epäonnistui';

  @override
  String get lightningForwardOffered => 'Käynnissä';

  @override
  String get lightningKeysendTitle => 'Lähetä nodelle (keysend)';

  @override
  String get lightningKeysendHint => 'Vastaanottavan noden pubkey (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Summa (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Enimmäiskulu (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Jätä tyhjäksi käyttääksesi noden oletusta (0,5 %)';

  @override
  String get lightningKeysendWarning =>
      'Keysend maksaa nodelle ilman laskua: varat siirtyvät heti eikä niitä voi peruuttaa.';

  @override
  String get lightningKeysendConfirmTitle => 'Lähetetäänkö tämä keysend-maksu?';

  @override
  String get lightningKeysendDestination => 'Kohde';

  @override
  String get lightningKeysendSent => 'Keysend lähetetty';

  @override
  String get lightningKeysendInvalidPubkey => 'Virheellinen noden pubkey';

  @override
  String get lightningKeysendInvalidAmount => 'Syötä nollaa suurempi summa';

  @override
  String get lightningKeysendSend => 'Lähetä';
}
