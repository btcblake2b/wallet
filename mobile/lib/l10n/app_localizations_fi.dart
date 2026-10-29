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
  String get homeLockVault => 'Lukitse holvi';

  @override
  String get homeVaultLocked => 'Holvi lukittu';

  @override
  String get homeVaultLockedBody =>
      'Avaimet poistettiin muistista käyttämättömyyden jälkeen. Syötä salasanasi nähdäksesi saldot ja allekirjoittaaksesi uudelleen. Lompakkosi ovat turvassa: mitään ei poistettu.';

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
  String get settingsExplorerMirrors => 'Varalla olevat selaimet';

  @override
  String get settingsExplorerMirrorsDesc =>
      'Jos mempool.guide ei vastaa, sovellus kysyy kahta yhteisön peilipalvelinta. Poista käytöstä, jos haluat käyttää vain mempool.guide-palvelua.';

  @override
  String get settingsSectionInterface => 'Käyttöliittymä';

  @override
  String get settingsInfoDots => 'Tietovinkit';

  @override
  String get settingsInfoDotsDesc =>
      'Näytä pienet info-napit, jotka selittävät jokaisen toiminnon';

  @override
  String get guideTitle => 'Näin se toimii';

  @override
  String get guideEntryDesc =>
      'Selkeitä selityksiä: lompakko, seed, maksut, Lightning.';

  @override
  String get guideIntro =>
      'Tämä opas selittää yksinkertaisin sanoin, mitä sovellus tekee ja miksi. Kaikkea ei tarvitse lukea: avaa vain kiinnostava luku. Jokainen selitys löytyy myös ⓘ-merkistä vastaavan kentän vierestä.';

  @override
  String get guideOpenFailed => 'Selainta ei voitu avata.';

  @override
  String get guideHintsNote =>
      'Voit piilottaa ⓘ-merkit kohdasta Asetukset → Käyttöliittymä.';

  @override
  String get guideSectionBasics => 'Perusteet';

  @override
  String get guideSectionSecurity => 'Turvallisuus ja varmuuskopio';

  @override
  String get guideSectionTransactions => 'Lähettäminen ja vastaanotto';

  @override
  String get guideSectionLightning => 'Lightning';

  @override
  String get guideSectionAdvanced => 'Syventävät aiheet';

  @override
  String get guideFullGuideTitle => 'Koko opas verkossa';

  @override
  String get guideFullGuideDesc =>
      'Sivustolla on pitkä versio, esimerkit ja UKK.';

  @override
  String get guideFullGuideOpen => 'Avaa opas';

  @override
  String get infoWhatIsWalletTitle => 'Mikä lompakko on (ja mitä ei)';

  @override
  String get infoWhatIsWalletBody =>
      'Lompakko ei \'sisällä\' kolikoita: se sisältää yksityiset avaimet, joilla käytät lohkoketjuun kirjattuja kolikoita. Saldon laskevat solmut ketjusta, ja sovellus rakentaa sen osoitteistasi. Siksi avainten menetys = varojen menetys, mutta puhelimen menetys palautuu 12 sanan lauseella.';

  @override
  String get infoSelfCustodyTitle =>
      'Itsesäilytys: kukaan ei voi jäädyttää varojasi';

  @override
  String get infoSelfCustodyBody =>
      'Tässä sinä olet pankki: ei tiliä, ei kirjautumista, ei yritystä, joka pitää rahasi. Etu: kukaan ei voi jäädyttää saldoasi. Riski: kukaan ei voi palauttaa salasanaasi tai palautuslausettasi. Se on suvereniteetin hinta.';

  @override
  String get infoSeedPhraseTitle => 'Palautuslause (12 sanaa)';

  @override
  String get infoSeedPhraseBody =>
      'Se on yksityisen avaimesi luettava muoto: noista sanoista rakentuvat KAIKKI osoitteesi ja siten varasi. Kirjoita se paperille, älä koskaan kuvaan, chatteihin, pilveen tai salasanasovellukseen. Sen lukija voi tyhjentää lompakon; sen kadottaja on menettänyt kaiken.';

  @override
  String get infoAppEncryptionTitle => 'Paikallinen salaus ja salasana';

  @override
  String get infoAppEncryptionBody =>
      'Lause pysyy laitteellasi AES-GCM-salattuna: avain johdetaan salasanastasi (tai sormenjäljestä, joka avaa järjestelmän avainsäilön). Mikään palvelin ei saa salasanaa. Jos unohdat sen, \'palautusta\' ei ole: vain palautuslause auttaa.';

  @override
  String get infoNetworkBlake2bTitle => 'Verkko: bitcoin-blake2b';

  @override
  String get infoNetworkBlake2bBody =>
      'Käytät bitcoin-blake2b-verkkoa, joka on KOKEELLINEN ja jolla on omat sääntönsä (BLAKE2b-tiiviste, ei konsensustason replay-suojaa): se ei ole Bitcoin, eivätkä ketjut jaa kolikoita. Kohtele tätä lompakkoa testiympäristönä, älä lopullisena säästöpaikkana.';

  @override
  String get infoBalanceUtxoTitle => 'Miten saldo muodostuu';

  @override
  String get infoBalanceUtxoBody =>
      'Ei ole \'tiliä\', jossa on luku: saldo on UTXOjen summa eli vastaanotetut ja vielä käyttämättömät kolikot, kuin setelit taskussa. Siirto kuluttaa UTXOja ja luo uusia (maksu + vaihtoraha). Itsellesi lähettäminen ei muuta saldoa.';

  @override
  String get infoConfirmationsTitle => 'Vahvistukset';

  @override
  String get infoConfirmationsBody =>
      'Tuore maksu on \'odottava\' (mempool): se on olemassa, mutta yksikään lohko ei ole kirjannut sitä. Jokainen seuraava lohko lisää vahvistuksen; kolmesta vahvistuksesta maksu on melko vakaa. Odottaessa summa voi näkyä käyttämättömänä: se ei ole kadonnut, se odottaa.';

  @override
  String get infoFeeConceptTitle => 'Miksi maksat siirtomaksun';

  @override
  String get infoFeeConceptBody =>
      'Maksu on palkkio sille, joka lisää siirtosi lohkoon. Maksat koosta (sat/vB), et summasta: 1 000 tai 1 000 000 sat maksaa saman. Kun mempool on täynnä, hinnat nousevat; maksu EI ole sovelluksen maksu: se menee louhijoille.';

  @override
  String get infoChangeAddressTitle => 'Vaihtoraha';

  @override
  String get infoChangeAddressBody =>
      'Kuin kaupassa: jos käytetyt UTXOt ovat arvoltaan suurempia kuin summa, erotus palaa sinulle saman lompakon UUTEEN osoitteeseen (\'vaihtoraha\'). Kaksi lähtöä siirrossa on normaalia: maksu vastaanottajalle ja vaihtoraha sinulle.';

  @override
  String get infoLightningVsOnchainTitle => 'On-chain ja Lightning';

  @override
  String get infoLightningVsOnchainBody =>
      'On-chain: jokainen liike on julkinen siirto ketjussa — turvallinen ja todennettava, mutta hitaampi ja maksullinen per siirto. Lightning: välittömät, lähes ilmaiset maksut \'kanavissa\', jotka avataan yhdellä on-chain-siirrolla. Kanavan avaus siirtää varat ketjulta kanavaan; sulkeminen palauttaa ne ketjulle.';

  @override
  String get infoPrivacyBasicsTitle => 'Yksityisyys: kuka näkee mitä';

  @override
  String get infoPrivacyBasicsBody =>
      'Jokainen \'Vastaanota\' luo uuden osoitteen: saman osoitteen käyttö yhdistää maksusi. Sovelluksessa ei ole tiliä eikä telemetriaa, ja ketjutiedot haetaan julkisesta API:sta (mempool.guide), joka näkee IP-osoitteesi. Parhaaseen yksityisyyteen: VPN tai oma solmu, äläkä koskaan julkaise xpub-avaintasi.';

  @override
  String get infoCoinControlTitle => 'Coin control (UTXO-valinta)';

  @override
  String get infoCoinControlBody =>
      'Saldo koostuu UTXOista, eli saamistasi osista. Tässä voit valita, joita niistä käytät: transaktio käyttää vain näitä, jolloin voit jättää pienet tai käyttämättömät osat syrjään.';

  @override
  String get infoDustLimitTitle => 'Vähimmäismäärä (dust)';

  @override
  String get infoDustLimitBody =>
      'Alle 546 sat:n outputit hylätään verkossa pölynä. Alle tämän rajan olevia määriä ei voi lähettää.';

  @override
  String get infoFeeRateTitle => 'Transaktiomaksu';

  @override
  String get infoFeeRateBody =>
      'Maksu maksetaan transaktion koon yksikköä kohden (sat/vB): mitä nopeammin haluat vahvistuksen, sitä enemmän maksat. Taloudellinen voi kestää tunteja, Prioriteetti muutaman minuutin. Mukautettu on, kun tunnet nykyisen mempool-maksun.';

  @override
  String get infoBatchSendTitle => 'Useampi vastaanottaja (erä)';

  @override
  String get infoBatchSendBody =>
      'Yhdessä transaktiossa voit maksaa jopa 20 osoitteelle, jakamalla maksun sen sijaan, että maksaisit sen joka siirrolle erikseen. Kaikki vastaanottajat näytetään vahvistuksessa ennen allekirjoitusta.';

  @override
  String get infoBumpFeeTitle => 'Lisää maksua (RBF)';

  @override
  String get infoBumpFeeBody =>
      'Odottava transaktio voidaan korvata uudella, joka maksaa korkeamman maksun (BIP125). Alkuperäinen peruutetaan ja vain korvaava transaktio voi vahvistua — kohdeosoite ja määrä pysyvät samoina.';

  @override
  String get infoXpubTitle => 'Tilin julkinen avain (xpub)';

  @override
  String get infoXpubBody =>
      'xpub luo kaikki vastaanotto-osoitteesi. Se ei voi siirtää varoja, mutta paljastaa koko saldon ja historian: jaa se vain luotettaville sovelluksille (esim. watch-only-lompakko).';

  @override
  String get infoReceiveAddressTitle => 'Vastaanotto-osoite';

  @override
  String get infoReceiveAddressBody =>
      'Jokainen Vastaanota näyttää uuden osoitteen, joka on valittu koskaan käyttämättömistä: tämä pitää maksut erillään. Osoitteen uudelleenkäyttäminen ei ole virhe, mutta tekee transaktioistasi helpompia seurata.';

  @override
  String get infoWatchOnlyTitle => 'Watch-only-lompakko';

  @override
  String get infoWatchOnlyBody =>
      'Importasit vain xpubin: sovellus näkee saldon ja historian, mutta ei pidä yksityistä avainta, joten se ei voi allekirjoittaa. Tämän lompakon käyttämiseen tarvitset laitteen, jossa seed on.';

  @override
  String get infoSignVerifyTitle => 'Allekirjoita / varmenna viesti';

  @override
  String get infoSignVerifyBody =>
      'Allekirjoitus todistaa, että osoite on sinun, ilman varojen siirtämistä. Kuka tahansa voi sitten varmentaa allekirjoituksen tähän osoitteeseen ja samaan viestiin.';

  @override
  String get infoChannelCapacityTitle => 'Kanavan kapasiteetti';

  @override
  String get infoChannelCapacityBody =>
      'Kanavan satoshien kokonaismäärä, jaettu sinun ja peerisi kesken. Enemmän kapasiteettia tarkoittaa suurempien maksujen käsittelyä. Kapasiteetti = paikallinen saldo + etäsaldo.';

  @override
  String get infoChannelReserveTitle => 'Kanavan reservi';

  @override
  String get infoChannelReserveBody =>
      'Pieni osa varoistasi on pidettävä lukittuna turvavarmuudeksi (\'reservi\'). Se varmistaa, että molemmilla osapuolilla on menetettävää — jos toinen osapuoli menee offline-hallitusti, reserviä voidaan käyttää sen rankaisemiseen on-chain.';

  @override
  String get infoToSelfDelayTitle => 'Viive omaan käyttööön';

  @override
  String get infoToSelfDelayBody =>
      'Pakkosuljetussa tapauksessa on-chain-ulosmaksusi viivästyy tämän määrän blokkeja (tyypillisesti 144 = ~1 päivä). Tämä antaa peerillesi aikaa vaatia omat varojensa ensin, estäen kaksoiskulutus hyökkäykset kanavan tilaan.';

  @override
  String get infoHtlcTitle => 'HTLC (Hashattu Aikablokattu Sopimus)';

  @override
  String get infoHtlcBody =>
      'HTLC on ehdollinen maksu: varat on lukittu, kunnes vastaanottaja paljastaa hash-ennakokuvan. Lightningissa HTLC:t mahdollistavat välittömän off-chain-reitityksen — maksusi hyppii useiden kanavien läpi luottaamatta välittäjään.';

  @override
  String get infoOpenChannelPrivateTitle => 'Yksityinen kanava';

  @override
  String get infoOpenChannelPrivateBody =>
      'Yksityistä kanavaa ei ilmoiteta verkostolle. Vain sinä ja peerisi tiedätte sen olemassaolon. Käytä sitä, kun et halua muiden reitittää sen kautta (yksityisyys) tai kun kanava on liian pieni reititykseen.';

  @override
  String get infoRoutingFeesTitle => 'Reititysmaksut';

  @override
  String get infoRoutingFeesBody =>
      'Kun muut solut reitittävät maksuja kanavasi kautta, ansaitset maksuja. Perusmaksu (sat) peritään jokaista maksua kohden; korko (ppm) on suhteellinen määrään. CLTV-delta rajoittaa, kuinka kauan edelleenlähetetty HTLC voi kestää selvittyään.';

  @override
  String get infoForceCloseTitle => 'Pakkosulku';

  @override
  String get infoForceCloseBody =>
      'Lähettää viimeisen kanavatilasi on-chain. Se on peruuttamaton ja vaatii odottamaan viivettä omaan käyttööön ennen kuin voit käyttää varojasi. Käytä vain, jos peerisi ei vastaa tai on hallitseva — yhteistyösulku on aina nopeampi ja halvempi.';

  @override
  String get infoPeersTitle => 'Yhdistetyt peerit';

  @override
  String get infoPeersBody =>
      'Peerit ovat muita Lightning-soluja, joihin olet yhteydessä suoraan TCP/Tor:n kautta. Jokaisella peerillä voi olla yksi tai useampi kanava. Voit yhdistää uusia peerejä avataksesi kanavia ja lisätäksesi solusi likviditeettiä ja reitityskykyä.';

  @override
  String get infoNodeManagementTitle => 'Solun hallinta';

  @override
  String get infoNodeManagementBody =>
      'Lightning-solusi identiteetti: pubkey, versio, aktiivisten/odottavien kanavien ja peerien määrä. Tämä näyttö näyttää solun bookkeeper-pluginin kirjanpitotiedot ja forwarding-tilastot.';

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
  String get walletDetailAddress => 'Osoite';

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
  String get walletDetailTxExport => 'Vie';

  @override
  String get walletDetailTxExportCsv => 'CSV (taulukko)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'Kopioitu leikepöydälle ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Lataus aloitettu ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'Vienti epäonnistui';

  @override
  String get walletDetailTxExportJson => 'JSON (täydellinen)';

  @override
  String get walletDetailTxFee => 'Maksu';

  @override
  String get walletDetailTxIncoming => 'Vastaanotetut';

  @override
  String get walletDetailTxNote => 'Muistiinpano';

  @override
  String get walletDetailTxNoteAdd => 'Lisää muistiinpano';

  @override
  String get walletDetailTxNoteEdit => 'Muokkaa muistiinpanoa';

  @override
  String get walletDetailTxNoteHint =>
      'Yksityinen muistiinpano, tallennetaan vain tälle laitteelle';

  @override
  String get walletDetailTxNoteRemove => 'Poista';

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
  String get sendScreenTitle => 'Lähetä BTC';

  @override
  String get sendScreenAddressLabel => 'Vastaanottajan osoite';

  @override
  String get sendScreenAmountLabel => 'Määrä (BTC)';

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
  String get walletUtxoWaitingBadge => 'Odotusaika';

  @override
  String walletUtxoWaitingBlocks(int count) {
    return '$count lohkoa vapautumiseen';
  }

  @override
  String walletUtxoWaitingHint(int blocks) {
    return 'Verkko välittää louhintamaksut (coinbase) vasta $blocks lohkon jälkeen: niitä ei voi vielä käyttää.';
  }

  @override
  String walletBalanceWaiting(String amount) {
    return 'Odotusaika: $amount';
  }

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
    return 'Tämä tietosuojakäytäntö on väliaikainen, ja se korvataan lopullisella versiolla, joka julkaistaan virallisella verkkosivustolla, kun se on saatavilla.\n\n1) LAITTEELLA OLEVAT TIEDOT. Sovellus ei vaadi tiliä eikä tallenna henkilötietoja tekijän palvelimille. Salattu siemenlause (AES-256-GCM), asetukset ja suostumukset pysyvät VAIN laitteellasi.\n\n2) KOLMANSILLE OSAPUOLILLE TOIMINTAA VARTEN LÄHETETTÄVÄT TIEDOT. Saldon ja maksujen näyttämiseksi sovellus kysyy julkisia kolmansien osapuolten rajapintoja:\n• mempool.guide (lohkoketjuselain).\n• Jos mempool.guide ei ole saatavilla, sovellus voi kysyä kahta yhteisön ylläpitämää Esplora-yhteensopivaa peilipalvelinta (mempool.kilombino.com, mempool.maveth.ca). Tämän voi poistaa käytöstä asetuksissa.\n• Jos otat automaattisen hinnan käyttöön asetuksissa, sovellus lukee viimeisimmän XBT/USDC-kaupan pyynnöstä osoitteesta neoxa.exchange (NeoXEX). Jos valuuttasi ei ole USD, sovellus lukee myös USDT-kurssit osoitteesta api.coinbase.com. Molemmat voi poistaa käytöstä asetuksissa.\nJokaisessa pyynnössä lähetetään IP-osoitteesi ja kysytyn lompakon julkinen osoite. Yksityisiä avaimia ja siemenlausetta EI KOSKAAN lähetetä.\n\n3) EI SEURANTAA. Ei analytiikkaa, ei mainontaa, ei evästeitä sovelluksen sisällä.\n\n4) OIKEUDET (GDPR, 13-14 art.). Sinulla on oikeus saada pääsy tietoihin sekä oikeus oikaisuun, poistamiseen ja vastustamiseen kirjoittamalla rekisterinpitäjälle: $holder — $email. Koska emme säilytä henkilötietoja, nämä oikeudet ovat suurelta osin jo taattuja sillä, että tiedot pysyvät laitteellasi.';
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
  String get scanQrInvalidMnemonic =>
      'Skannattu koodi ei ole kelvollinen BIP39-muistilause.';

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
  String get importScreenScanSeed => 'Skannaa siemenlauseen QR-koodi';

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
  String get importScreenImport => 'Tuo';

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
  String get passwordDialogCreateTitle => 'Luo suojaussalasana';

  @override
  String get passwordDialogCreateHint => 'Anna turvallinen salasana';

  @override
  String get passwordDialogCreateConfirm => 'Vahvista salasana';

  @override
  String get passwordDialogCreate => 'Luo';

  @override
  String get passwordDialogCancel => 'Peruuta';

  @override
  String get passwordDialogEnterTitle => 'Anna salasana';

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
  String get lightningConnectRecentNodes => 'Viimeisimmät solmut';

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
  String get lightningCoinControlTitle => 'Coin control (valinnainen)';

  @override
  String get lightningCoinControlHint =>
      'Valitse, mitkä solmun on-chain-outputit rahoittavat kanavan. Ilman valintaa solmu päättää itse.';

  @override
  String get lightningCoinControlNoneSelected =>
      'Ei valintaa: solmu valitsee automaattisesti.';

  @override
  String get lightningCoinControlSelectedTotal => 'Valittu yhteensä';

  @override
  String get lightningCoinControlUnconfirmed => 'vahvistamaton';

  @override
  String get lightningCoinControlUnavailable =>
      'Output-luettelo ei saatavilla: solmu valitsee automaattisesti.';

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
  String get lightningSplice => 'Muuta kanavan kokoa';

  @override
  String get lightningSpliceTitle => 'Muuta kanavan kokoa sulkematta sitä';

  @override
  String get lightningSpliceIn => 'Lisää varoja';

  @override
  String get lightningSpliceOut => 'Nosta varoja';

  @override
  String get lightningSpliceAmountLabel => 'Määrä (sat)';

  @override
  String get lightningSpliceEstimate => 'Arvioi ketjun siirtomaksu';

  @override
  String lightningSpliceFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Ketjun siirtomaksu: noin $feeString sat';
  }

  @override
  String get lightningSpliceFeeUnavailable =>
      'Solmu ei antanut arviota siirtomaksusta';

  @override
  String get lightningSpliceConfirm =>
      'Muutetaanko kanavan kokoa nyt? Kanava pysyy verkossa ja lohkoketjuun lähetetään yksi siirto.';

  @override
  String get lightningSpliceDone => 'Kanavan koko muutettu';

  @override
  String get lightningSpliceInvalidAmount => 'Anna nollaa suurempi summa';

  @override
  String get lightningSpliceUnavailable =>
      'Koon muuttaminen on mahdollista vain käytettävissä olevilla kanavilla, kun vertaisnoodi on verkossa.';

  @override
  String get lightningSpliceChannelFailed =>
      'Solmu hylkäsi splicen: vertaisnoodi ei ehkä tue sitä (vaatii CLN:n, jossa on yhtenäiset allekirjoitukset). Kanava pysyy ennallaan.';

  @override
  String get lightningSpliceBridgeOutdated =>
      'Tämän solmun bridge ei vielä tarjoa koon muuttamista: päivitä bridge palvelimella.';

  @override
  String lightningSpliceOnchainAvailable(String sats) {
    return 'Solmun on-chain-varat: $sats sat';
  }

  @override
  String get lightningSpliceInsufficientOnchain =>
      'Solmun on-chain-varat eivät riitä tähän summaan: lataa solmun lompakkoon varoja (Talleta) ja yritä uudelleen.';

  @override
  String get lightningReceiveModeInvoice => 'Kertaluonteinen lasku';

  @override
  String get lightningReceiveModeOffer => 'Uudelleenkäytettävä koodi';

  @override
  String get lightningOfferTitle => 'Uudelleenkäytettävä maksukoodi';

  @override
  String get lightningOfferReusableHint =>
      'Jaa tämä koodi: kuka tahansa voi maksaa sen ja valita summan, jos jätit sen avoimeksi. Se ei vanhene kuten lasku.';

  @override
  String get lightningOfferAmountOptional => 'Summa (sat) — valinnainen';

  @override
  String get lightningOfferAmountLabel => 'Summa (sat)';

  @override
  String get lightningOfferAmountRequired =>
      'Anna summa tämän tarjouksen maksamiseksi';

  @override
  String lightningOfferFixedAmount(String sats) {
    return 'Tarjouksen summa: $sats sat';
  }

  @override
  String get lightningOfferDefaultDescription => 'Maksu';

  @override
  String get lightningPayOffer => 'Maksa tarjous';

  @override
  String get lightningCrossChainEntry => 'Maksa BTC-lasku (SHA-256)';

  @override
  String get lightningCrossChainTitle => 'Ketjujen välinen maksu';

  @override
  String get lightningCrossChainHint =>
      'Maksaa SHA-256-ketjun Lightning-laskun BLAKE2b-varoillasi ulkoisen, varoja säilyttämättömän sillan kautta. Silta saa rahat vasta maksettuaan laskun; muuten maksu palaa sinulle.';

  @override
  String get lightningCrossChainCheck => 'Tarkista kustannus';

  @override
  String lightningCrossChainCost(String sats) {
    return 'Maksat: $sats sat';
  }

  @override
  String lightningCrossChainInvoiceAmount(String sats) {
    return 'Laskun summa: $sats sat';
  }

  @override
  String lightningCrossChainRate(String rate) {
    return 'Vaihtokurssi: 1 XBT = $rate BTC';
  }

  @override
  String lightningCrossChainSpread(String percent) {
    return 'Bridgen kate: $percent %';
  }

  @override
  String lightningCrossChainWait(int seconds) {
    return 'Arvioitu odotus: noin $seconds s';
  }

  @override
  String get lightningCrossChainPay => 'Maksa sillan kautta';

  @override
  String get lightningCrossChainConfirmTitle => 'Maksetaanko sillan kautta?';

  @override
  String lightningCrossChainConfirmBody(String sats) {
    return 'Maksat $sats sat tässä ketjussa. Varat pysyvät lukittuina, kunnes silta maksaa kohdelaskun; jos se ei onnistu, maksu palaa sinulle.';
  }

  @override
  String get lightningCrossChainDone => 'Maksu valmis';

  @override
  String lightningCrossChainState(String state) {
    return 'Sillan tila: $state';
  }

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

  @override
  String get walletAddressesTitle => 'Osoitteet ja UTXO';

  @override
  String get walletAddressesTabAddresses => 'Osoitteet';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Vastaanotto (/0)';

  @override
  String get walletAddressesChangeBranch => 'Vaihtoraha (/1)';

  @override
  String get walletAddressesStatusUnused => 'Ei koskaan käytetty';

  @override
  String get walletAddressesStatusUsed => 'Käytetty';

  @override
  String get walletAddressesStatusFunds => 'Saldollinen';

  @override
  String walletAddressesTxCount(int count) {
    return '$count tapahtumaa';
  }

  @override
  String get walletAddressesEmpty => 'Ei näytettäviä osoitteita';

  @override
  String get walletAddressesHintTap => 'Napauta osoitetta kopioidaksesi';

  @override
  String get lightningPeeringGateTitle =>
      'Peering rajoitettu bit 68 -julkaisuihin';

  @override
  String get lightningPeeringGateBody =>
      'Tämä solmu vaatii option_blake2b-bitin (bit 68) kättelyssä: vanhempien julkaisujen solmut eivät voi muodostaa yhteyttä. Kyse on solmun valinnasta, ei sovelluksen tai bridgen ongelmasta. Käytä .4 tai uudempaa julkaisua olevia vertaisia tai odota, että yhteisö muuttaa bitin valinnaiseksi.';

  @override
  String get lightningPeeringGateLink => 'Yhteensopivuusmatriisi';

  @override
  String get lightningPeeringGateNewTitle =>
      'Peering rajoitettu uuden protokollan julkaisuihin';

  @override
  String get lightningPeeringGateNewBody =>
      'Tämä solmu käyttää lopullisia feature-bittejä (option_blake2b 512, option_unified_sigs 514): solmut, joita ei ole päivitetty — julkaisu .4 ja vanhemmat — eivät voi muodostaa yhteyttä. Kyse on verkon valinnasta, ei sovelluksen tai bridgen ongelmasta. Vertaisten on päivitettävä julkaisuun .5 tai uudempaan.';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count rekisteröityä vertaista, ei yhtään yhdistetty';
  }

  @override
  String get lightningSwapOpen => 'Maksa lasku ilman solmua (swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'Verkkosovellus: Lightning-maksut käyttävät swap-palveluntarjoajaa (solmua ei tarvita). Oman solmun yhdistäminen on Android-sovelluksessa.';

  @override
  String get lightningSwapTitle => 'Lightning-maksu palveluntarjoajan kautta';

  @override
  String get lightningSwapIntro =>
      'Varat pysyvät hallussasi: ne menevät ketjun HTLC:hen (P2WSH) ja vapautuvat vasta, kun palveluntarjoaja maksaa laskusi. Jos maksu epäonnistuu, voit palauttaa varat aikarajan jälkeen.';

  @override
  String get lightningSwapProviderUriHint =>
      'Palveluntarjoajan URI (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Yhdistä palveluntarjoaja';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Palveluntarjoaja yhdistetty: $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Katkaise yhteys';

  @override
  String get lightningSwapProviderDefaultLabel => 'btcblake2b-solmu (suositus)';

  @override
  String get lightningSwapProviderChecking => 'Tarkistetaan oletussolmua...';

  @override
  String get lightningSwapProviderReachable => 'Oletussolmu tavoitettavissa';

  @override
  String get lightningSwapProviderDown => 'Oletussolmu ei vastaa juuri nyt.';

  @override
  String lightningSwapProviderSendLimit(String min, String max) {
    return 'Voit nyt lähettää $min-$max sat';
  }

  @override
  String lightningSwapProviderLiquidity(String amount) {
    return 'Käytettävissä oleva likviditeetti nyt: $amount sat';
  }

  @override
  String get lightningSwapPeerCheck => 'Tarkista vastaanottaja';

  @override
  String lightningSwapPeerReachable(String amount) {
    return 'Vastaanottaja tavoitettavissa: maksettavaa $amount sat';
  }

  @override
  String get lightningSwapErrorPeerUnreachable =>
      'Vastaanottaja ei ole tavoitettavissa palveluntarjoajan kautta: reittiä hänen solmuunsa ei ole. Tarkista lasku tai yritä myöhemmin uudelleen.';

  @override
  String get lightningSwapInvoiceHint => 'Lightning-lasku (lnbc...)';

  @override
  String get lightningSwapStart => 'Jatka';

  @override
  String get lightningSwapAmount => 'Laskun summa';

  @override
  String get lightningSwapFees => 'Kulut (claim + palvelu)';

  @override
  String get lightningSwapTotal => 'Lukittava kokonaissumma';

  @override
  String get lightningSwapFund => 'Lähetä varat ja aloita swap';

  @override
  String get lightningSwapFundHint =>
      'Varat menevät yllä näkyvään HTLC-osoitteeseen. Maksu alkaa 1 vahvistuksen jälkeen.';

  @override
  String get lightningSwapStateLabel => 'Tila';

  @override
  String get lightningSwapHtlc => 'HTLC-osoite';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund saatavilla lohkosta $height';
  }

  @override
  String get swapStateAwaitingFunding => 'Odotetaan ketjun varoja';

  @override
  String get swapStateConfirming => 'Odotetaan vahvistuksia';

  @override
  String get swapStatePaying => 'Lightning-maksu käynnissä';

  @override
  String get swapStatePaid => 'Lasku maksettu, claim käynnissä';

  @override
  String get swapStateClaiming => 'Claim käynnissä';

  @override
  String get swapStateCompleted => 'Valmis';

  @override
  String get swapStatePaymentFailed =>
      'Maksu epäonnistui — varat palautettavissa';

  @override
  String get swapStateExpired => 'Vanhentunut — varat palautettavissa';

  @override
  String get swapStateRefunded => 'Palautettu';

  @override
  String get lightningSwapRecoveryTitle => 'Varojen palautus';

  @override
  String get lightningSwapRecoveryHint => 'Palautus-blob (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Tuo istunto';

  @override
  String get lightningSwapRefund => 'Palauta varat (refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Palautus ei ole vielä mahdollinen: avautuu lohkosta $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Kopioi palautus-blob';

  @override
  String get lightningSwapBlobCopied => 'Palautus-blob kopioitu';

  @override
  String get lightningSwapHistoryTitle => 'Swappien historia';

  @override
  String get lightningSwapHistoryEmpty =>
      'Ei vielä swappeja: palveluntarjoajan kautta tehdyt maksut näkyvät täällä.';

  @override
  String get lightningSwapDetailTitle => 'Swapin tiedot';

  @override
  String get lightningSwapDetailCreated => 'Luotu';

  @override
  String get lightningSwapDetailSummary => 'Yhteenveto';

  @override
  String get lightningSwapDetailProtocol => 'Protokollatiedot';

  @override
  String get lightningSwapDetailSwapId => 'Swap-tunnus';

  @override
  String get lightningSwapDetailInvoice => 'Lasku';

  @override
  String get lightningSwapDetailPaymentHash => 'Payment hash';

  @override
  String get lightningSwapDetailProvider => 'Palveluntarjoaja';

  @override
  String get lightningSwapDetailFundingTx => 'Rahoitustapahtuma';

  @override
  String get lightningSwapOpenInExplorer => 'Avaa lohkoselaimessa';

  @override
  String lightningSwapRefundSent(String txid) {
    return 'Hyvitys lähetetty: $txid';
  }

  @override
  String get lightningSwapClaimTxid => 'Claim-txid';

  @override
  String get lightningSwapClaimHint =>
      'Claim on ketjutransaktio: vahvistus tulee seuraavassa lohkossa (~12 min). Napauta linkkiä tarkistaaksesi sen.';

  @override
  String get lightningSwapInvalidInvoice => 'Tämä ei näytä Lightning-laskulta';

  @override
  String get lightningSwapWatchOnly =>
      'Swap vaatii lompakon, jossa on seed (ei watch-only)';

  @override
  String get lightningSwapNoUtxos => 'Ei käytettäviä varoja tässä lompakossa';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Virhe: $message';
  }

  @override
  String get lightningSwapKnownUris => 'Tallennetut palveluntarjoajan URI:t';

  @override
  String get lightningSwapWalletLabel => 'Lompakko';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Saldo: $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Riittämättömät varat: tarvitaan $needed sat, saatavilla $available sat';
  }

  @override
  String lightningSwapInsufficientFundsWaiting(
      String needed, String available, String waiting) {
    return 'Riittämättömät varat: tarvitaan $needed sat, saatavilla $available sat ($waiting sat odotusajassa)';
  }

  @override
  String get lightningSwapCancel => 'Peruuta swap';

  @override
  String get lightningSwapErrorConnectFailed =>
      'Tarjoajaan ei saatu yhteyttä. Tarkista yhteys ja yritä uudelleen.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Yhteys tarjoajaan katkesi. Yritä yhdistää uudelleen.';

  @override
  String get lightningSwapErrorNotConnected => 'Tarjoaja ei ole yhdistetty.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'Tämä tarjoaja käyttää relettä, jota verkkoversio ei tavoita. Käytä mobiiliversiota puhelimessa maksaaksesi tämän tarjoajan kanssa.';

  @override
  String get lightningSwapErrorPaymentFailed =>
      'Palveluntarjoaja ei pystynyt maksamaan tätä laskua. Varasi ovat edelleen HTLC:ssä: voit palauttaa ne hyvityksellä (katso lohko alta).';

  @override
  String get lightningSwapErrorProviderUnavailable =>
      'Palveluntarjoaja ei voi maksaa juuri nyt (ei reittiä tai likviditeetti ei riitä). Yritä myöhemmin uudelleen.';

  @override
  String get lightningSwapErrorRateLimited =>
      'Palveluntarjoaja on tilapäisesti täydessä kapasiteetissa. Yritä myöhemmin uudelleen.';

  @override
  String get lightningSwapErrorDuplicateSwap =>
      'Tätä laskua on jo käytetty toisessa swapissa.';

  @override
  String get lightningSwapErrorQuoteExpired =>
      'Tarjous vanheni. Aloita swappi uudelleen.';

  @override
  String get lightningSwapErrorInvoiceInvalid =>
      'Palveluntarjoaja hylkäsi tämän laskun: se ei ole kelvollinen.';

  @override
  String get lightningSwapErrorInvoiceExpired =>
      'Tämä lasku on vanhentunut. Pyydä uusi.';

  @override
  String get lightningSwapErrorAmountOutOfRange =>
      'Palveluntarjoaja ei hyväksy tätä summaa (sallitun vaihteluvälin ulkopuolella).';

  @override
  String get lightningSwapErrorFundingTimeout =>
      'Rahoitusta ei vahvistettu ajoissa: swappi vanheni ilman maksua.';

  @override
  String get lightningSwapErrorTooLate =>
      'Maksu peruutettiin, koska se oli liian lähellä aikarajaa. Varasi voidaan palauttaa.';

  @override
  String get lightningSwapRefundHint =>
      'Nämä varat ovat edelleen sinun: hyvitys avautuu automaattisesti aikarajalla, vaikka palveluntarjoaja katoaisi.';

  @override
  String get lightningSwapCancelTitle => 'Peruutetaanko tämä swappi?';

  @override
  String get lightningSwapCancelBody =>
      'Sovellus unohtaa tämän swapin. Palveluntarjoaja hylkää sen itsestään ennen määräaikaa eikä varoja ole lukittu. Saman laskun uudelleenyritys onnistuu vasta sen vanhennuttua — muuten luo uusi lasku.';

  @override
  String get lightningSwapCancelConfirm => 'Kyllä, peruuta';

  @override
  String get lightningSwapWalletMissing =>
      'Tähän swappiin liitetty lompakko ei ole enää saatavilla';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Liitetty lompakko: $name';
  }

  @override
  String get lightningInvoiceDelete => 'Poista lasku';

  @override
  String get lightningInvoiceDeleteTitle => 'Poistetaanko tämä lasku?';

  @override
  String get lightningInvoiceDeleteBody =>
      'Lasku poistetaan solmusta. Jos se on maksamaton, sitä ei voi enää maksaa.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Kyllä, poista';

  @override
  String get lightningInvoiceDeleted => 'Lasku poistettu';

  @override
  String get lightningChannelPeerAddress => 'Vertaisen osoite';

  @override
  String get lightningSpliceNodeTooOld =>
      'Kanavan koon muuttaminen vaatii solmun versiosta .6 alkaen (suositus .9). Tämä solmu on vanhempi, joten toiminto on piilotettu. Päivitä solmu ottaaksesi sen käyttöön.';

  @override
  String get lightningSpliceNodeOutdated =>
      'Tämä solmu on versiota .9 vanhempi: päivitykset .8:sta lähtien sulkevat splice-haavoittuvuuden, jonka kautta solmu voi menettää kanavan varat. Koon muuttaminen toimii edelleen, mutta päivitä .9:ään heti kun voit.';

  @override
  String get lightningDiscoveryTitle => 'Löydä vertaiset ja likviditeetti';

  @override
  String get lightningDiscoveryBody =>
      'Tässä verkossa ei ole keskitettyä luetteloa. Nämä ovat aktiivisia lähteitä, joihin yhteisö listaa solmuja, kanavia ja saapuvaa likviditeettiä.';

  @override
  String get lightningDiscoveryNetworkTitle => 'Verkkoselain (Paperclip)';

  @override
  String get lightningDiscoveryNetworkBody =>
      'Julkiset solmut, kanavat ja ilmoitettu kapasiteetti.';

  @override
  String get lightningDiscoveryLspTitle =>
      'Saapuva likviditeetti (Paperclip LSP)';

  @override
  String get lightningDiscoveryLspBody =>
      'Kanava solmuusi, maksettuna ketjussa XBT:nä.';

  @override
  String get lightningDiscoveryNodexTitle => 'Nodex - kanavat ja maksut';

  @override
  String get lightningDiscoveryNodexBody =>
      'Kanavaselain, jossa maksut molempiin suuntiin ja uptime.';

  @override
  String get lightningDiscoverySwapTitle => 'Lightning Fork Swap';

  @override
  String get lightningDiscoverySwapBody =>
      'Ei-säilyttävä swap Lightningin ja ketjun välillä likviditeetin siirtämiseen.';

  @override
  String get lightningDiscoveryWatchtowerTitle =>
      'Watchtowerit (vain lnd-solmut)';

  @override
  String get lightningDiscoveryWatchtowerBody =>
      'Watchtower valvoo ketjua, kun solmusi on offline, ja rankaisee vertaista, joka julkaisee vanhan tilan. Käytä useampaa kuin yhtä: lnd vaatii wtclient.active=true ja Torin. CLN-solmut puhuvat sen sijaan BOLT 13:ta (TEOS), jota sovellus ei vielä määritä. Lisää ne komennolla lncli wtclient add <uri>.';

  @override
  String get lightningDiscoveryOpenFailed => 'Selain ei avannut linkkiä.';

  @override
  String get lightningInboundMissingTitle => 'Et voi vielä vastaanottaa';

  @override
  String get lightningInboundMissingBody =>
      'Tässä solmussa ei ole saapuvaa likviditeettiä: toisen solmun on avattava kanava siihen ennen kuin kukaan voi maksaa sinulle. Siihen asti jaetut laskut eivät ole maksettavissa.';

  @override
  String get lightningInboundMissingCta => 'Hanki saapuvaa likviditeettiä';

  @override
  String get lightningInboundMissingRefresh => 'Tarkista uudelleen';

  @override
  String get webVaultNoticeTitle => 'Käytät selainversiota';

  @override
  String get webVaultNoticeBody =>
      'Täällä salattu seed tallennetaan selaimeen (localStorage, varmuuskopio IndexedDB:ssä) ja avain on kääritty salasanallasi. Holvi lukittuu 10 minuutin käyttämättömyyden jälkeen ja kun sivu piilotetaan, mutta sivulla holvin ollessa auki suoritettava koodi voi lukea avaimet: selain ei voi suojautua siltä. Käytä todellisille summille Android-sovellusta, jossa avaimet pysyvät järjestelmän avainnipussa.';

  @override
  String get webVaultNoticeDownload => 'Hanki Android-sovellus';

  @override
  String get splashStartupError => 'Sovelluksen käynnistys epäonnistui';

  @override
  String get splashRetry => 'Yritä uudelleen';

  @override
  String webVaultOriginOfficial(Object origin) {
    return 'Vahvistettu verkkotunnus: $origin';
  }

  @override
  String webVaultOriginDev(Object origin) {
    return 'Paikallinen testiympäristö: $origin';
  }

  @override
  String webVaultOriginUnofficial(Object origin) {
    return 'VAROITUS: tämä ei ole virallinen verkkotunnus. Olet osoitteessa $origin — oikea on app.btcblake2b.org. Älä syötä tänne seediä tai salasanaa.';
  }

  @override
  String get receiveNeedsBackupTitle => 'Varmuuskopioi seed ensin';

  @override
  String get receiveNeedsBackupBody =>
      'Selaimessa salattu seed on tämän sivuston tallennustilassa: PWA-päivitys tai «tyhjennä sivuston tiedot» poistaa sen, ja nyt jaettu osoite vastaanottaisi varoja, joita et voisi enää käyttää. Vahvista seedin varmuuskopio (tai siirrä lompakko sovellukseen) ennen vastaanottamista.';

  @override
  String get receiveNeedsBackupAction => 'Tee varmuuskopio';

  @override
  String get merchantChargeTitle => 'Periytä maksu';

  @override
  String get merchantChargeAmount => 'Summa';

  @override
  String get merchantChargeAmountInvalid =>
      'Anna summa, joka on suurempi kuin nolla.';

  @override
  String get merchantChargeLabel => 'Kuvaus (valinnainen)';

  @override
  String get merchantChargeModeLightning => 'Lightning';

  @override
  String get merchantChargeModeOnchain => 'On-chain';

  @override
  String get merchantChargeLightningHint =>
      'Asiakas maksaa Lightning-laskun: hyvitetään heti, kun solmu vastaanottaa sen.';

  @override
  String get merchantChargeOnchainHint =>
      'Asiakas lukee QR-koodin: summa on jo mukana, hän vain vahvistaa.';

  @override
  String get merchantChargeLightningUnavailable =>
      'Lightning-solmua ei ole yhdistetty: toistaiseksi voit periä on-chain. Yhdistä solmu Lightning-välilehdeltä hyväksyäksesi myös Lightning-maksuja.';

  @override
  String get merchantChargeCreate => 'Luo maksupyyntö';

  @override
  String get merchantChargeInvoiceTitle => 'Lightning-lasku';

  @override
  String get merchantChargeUriTitle => 'Bitcoin-URI (BIP21)';

  @override
  String get merchantChargeWaiting => 'Odotetaan maksua…';

  @override
  String get merchantChargePaid => 'Maksu vastaanotettu';

  @override
  String get merchantChargeNew => 'Uusi pyyntö';

  @override
  String get merchantConvertTitle => 'Vaihda BTC:hen';

  @override
  String get merchantConvertIntro =>
      'XBT elää bitcoin-blake2b-verkossa, joka on erillinen Bitcoinista: XBT:n vaihtaminen BTC:hen (tai päinvastoin) on ketjujen välinen swap. Tämä sovellus ei tee sitä eikä voi tehdä sitä: ei vaihtoa, ei säilytystä. Vaihto tapahtuu kolmannen osapuolen ei-säilyttävissä palveluissa, jotka sinä valitset.';

  @override
  String get merchantConvertAddressTitle => 'XBT-osoitteesi';

  @override
  String get merchantConvertAddressBody =>
      'Kopioi lompakon osoite, jota haluat käyttää siellä, tai vastaanota ensin XBT täällä ja vaihda myöhemmin. Älä koskaan lähetä varoja palveluun, joka pyytää seediäsi.';

  @override
  String get merchantConvertUnnamedWallet => 'Lompakko';

  @override
  String get merchantConvertPaperclipTitle => 'Paperclip Bridge (beta)';

  @override
  String get merchantConvertPaperclipBody =>
      'Yhteisön ei-säilyttävä bridge: se vastaanottaa vain, kun lasku on todella maksettu. Beta, ei kolmannen osapuolen auditoima.';

  @override
  String get merchantConvertForkTitle => 'Lightning Fork Swap';

  @override
  String get merchantConvertForkBody =>
      'Yhteisön swap, jonka on-chain-lahjoitukset käytetään vain sen omaan likviditeettiin. Tarkista kulut ja rajat ennen lähettämistä.';

  @override
  String get merchantConvertWarningTitle => 'Ennen vaihtoa';

  @override
  String get merchantConvertWarningBody =>
      '1) Vertaa saatavaa ja lähetettävää summaa: pienissä summisa kulut voivat syödä erotuksen. 2) Swap ei ole peruutettavissa: tarkista osoite ja ketju. 3) Emme vastaanota, säilytä emmekä takaa mitään: jos palvelu jumittuu, vain se palvelu voi vastata. 4) Todellisilla summilla tee ensin pieni kokeilu.';

  @override
  String get merchantConvertOpen => 'Vaihda';

  @override
  String get fiatPriceShow => 'Näytä arvo dollareina';

  @override
  String get fiatPriceNotSet =>
      'Hintaa ei ole asetettu: lisää se nähdäksesi arvon';

  @override
  String fiatPriceCurrent(Object cents) {
    return '1 XBT = $cents';
  }

  @override
  String get fiatPriceSet => 'Aseta XBT:n hinta';

  @override
  String get fiatPriceSetDesc =>
      'Vastineen hinta: syötä se itse tai anna sovelluksen lukea se NeoXEX:stä.';

  @override
  String get fiatPriceDialogBody =>
      'Syötä 1 XBT:n hinta USD:nä. Voit halutessasi ottaa automaattisen hinnan käyttöön asetuksissa: sovellus lukee tällöin viimeisimmän XBT/USDC-kaupan pyynnöstä NeoXEX:stä (ja valitun valuutan USDT-kurssin). Näytetty arvo on viitteellinen, ei noteeraus.';

  @override
  String get fiatPriceFieldLabel => '1 XBT:n hinta';

  @override
  String get fiatPriceSave => 'Tallenna';

  @override
  String get fiatPriceInvalid =>
      'Virheellinen hinta: nollaa suurempi luku, enintään 2 desimaalia.';

  @override
  String get fiatPriceManualNote => 'oma hinta, ei markkinanoteeraus';

  @override
  String get fiatPriceMarketNote => 'markkinahinta, viimeisin NeoXEX-kauppa';

  @override
  String get fiatPriceCurrency => 'Vastineen valuutta';

  @override
  String get fiatPriceCurrencyDesc => 'Muunnettu USDT-kurssilla';

  @override
  String get fiatPriceFxFailed =>
      'Valuuttakurssi ei saatavilla: yhdistä internetiin ja yritä uudelleen.';

  @override
  String get fiatPriceAuto => 'Hae hinta NeoXEX:stä';

  @override
  String get fiatPriceAutoDesc =>
      'Lukee viimeisimmän XBT/USDC-kaupan pyynnöstä. Ei pollausta, ei taustakyselyjä.';

  @override
  String get fiatPriceAutoUpdated => 'Hinta päivitetty NeoXEX:stä';

  @override
  String get fiatPriceAutoFailed => 'NeoXEX ei vastaa: edellinen hinta säilyy.';

  @override
  String get balanceChangeUnitHint =>
      'Napauta vaihtaaksesi saldon XBT:n, satoshien ja dollarien välillä';

  @override
  String get psbtSpendTitle => 'Käytä PSBT:llä';

  @override
  String get psbtSpendIntro =>
      'Watch-only-lompakko ei voi allekirjoittaa. Luo PSBT täällä, allekirjoita se laitteella jossa siemen on ja lähetä se sieltä.';

  @override
  String get psbtCreate => 'Luo PSBT';

  @override
  String get psbtCreating => 'Luodaan PSBT…';

  @override
  String psbtDraftReady(Object change, Object fee) {
    return 'PSBT valmis · maksu $fee sat · vaihtoraha $change sat';
  }

  @override
  String get psbtQrTitle => 'Skannaa tämä PSBT';

  @override
  String psbtQrFrames(Object count) {
    return '$count kehystä — pidä kamera paikallaan, kun QR pyörii';
  }

  @override
  String get psbtCopyBase64 => 'Kopioi PSBT (base64)';

  @override
  String get psbtSignTitle => 'Allekirjoita PSBT';

  @override
  String get psbtSignIntro =>
      'Liitä tai skannaa toisella laitteella luotu PSBT. Tarkista vastaanottajat ja maksu ennen allekirjoitusta.';

  @override
  String get psbtPasteLabel => 'PSBT (base64)';

  @override
  String get psbtScan => 'Skannaa QR';

  @override
  String get psbtReviewTitle => 'Yhteenveto';

  @override
  String psbtReviewFee(Object fee) {
    return 'Maksu: $fee sat';
  }

  @override
  String psbtReviewInputs(Object count) {
    return 'Syötteet: $count';
  }

  @override
  String psbtReviewOutputs(Object count) {
    return 'Vastaanottajat: $count';
  }

  @override
  String get psbtSign => 'Allekirjoita';

  @override
  String get psbtSignedTitle => 'Allekirjoitettu PSBT';

  @override
  String get psbtBroadcast => 'Lähetä';

  @override
  String get psbtBroadcasting => 'Lähetetään…';

  @override
  String psbtBroadcastDone(Object txid) {
    return 'Lähetetty: $txid';
  }

  @override
  String get psbtInvalid => 'PSBT ei ole kelvollinen';

  @override
  String get psbtNoFrames => 'PSBT-kehystä ei tunnistettu';

  @override
  String psbtScanProgress(Object received, Object total) {
    return 'Kehyksiä luettu: $received/$total';
  }

  @override
  String get psbtSigning => 'Allekirjoitetaan…';

  @override
  String get psbtNeedsSeed =>
      'Tässä lompakossa ei ole siementä: allekirjoita laitteella, jossa se on.';
}
