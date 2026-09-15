// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Btc Blake2b Wallet';

  @override
  String get appErrorTitle => 'No se puede iniciar la aplicación';

  @override
  String get appReload => 'Recargar página';

  @override
  String get homeScreenTitle => 'Btc Blake2b Wallet';

  @override
  String get homeNoConnectionTitle => 'Sin conexión';

  @override
  String get homeNoConnectionCreate =>
      'No se puede crear el monedero sin conexión a internet. La dirección debe verificarse en la red. Inténtalo de nuevo cuando se restablezca la conexión.';

  @override
  String get homeNoConnectionImport =>
      'No se puede importar el monedero sin conexión a internet.';

  @override
  String get homeOk => 'OK';

  @override
  String get homeWalletCreated => 'Monedero creado con éxito.';

  @override
  String homeWalletCreateError(Object error) {
    return 'Error al crear el monedero: $error';
  }

  @override
  String get homeImportWallet => 'Importar monedero';

  @override
  String get homeCreateWallet => 'Crear monedero';

  @override
  String get homeReceiveWallet => 'Recibir';

  @override
  String get homeMultiTransfer => 'Multi-envío';

  @override
  String get homeSelected => 'seleccionados';

  @override
  String get homeDeleteSelected => 'Eliminar seleccionados';

  @override
  String homeDeleteConfirm(int count) {
    return '¿Eliminar $count monederos? Esta acción es irreversible.';
  }

  @override
  String homeDeleted(Object count) {
    return '$count monederos eliminados con éxito.';
  }

  @override
  String homeDeleteMultiError(Object message) {
    return '$message';
  }

  @override
  String get homeWalletImported => 'Monedero importado con éxito.';

  @override
  String get homeSecurityWarning =>
      'Este software se proporciona \"tal cual\" sin garantía alguna. El fabricante no es responsable por pérdida de fondos, robo, hacking, errores de transacción o daños derivados del uso de la app. El monedero no garantiza protección contra copias anteriores de la seed. Usar solo para pequeñas cantidades.';

  @override
  String get homeDisclaimerAccept => 'Acepto';

  @override
  String get legalInfoTitle => 'Info legal';

  @override
  String get homeLocalWallets => 'Monederos locales';

  @override
  String homeErrorLoading(Object error) {
    return 'Error al cargar monedero: $error';
  }

  @override
  String get homeEmptyTitle => 'Sin monederos';

  @override
  String get homeEmptySubtitle =>
      'Crea tu primer monedero Bitcoin para empezar.';

  @override
  String get homeBalanceTitle => 'SALDO ACTIVO';

  @override
  String get balanceUnavailable => 'Saldo no disponible';

  @override
  String get homeBackupVerified => 'Copia verificada';

  @override
  String get homeBackupNotVerified => 'Copia no verificada';

  @override
  String get homeMoreOptions => 'Más opciones';

  @override
  String get homeLockVault => 'Bloquear la bóveda';

  @override
  String get homeVaultLocked => 'Bóveda bloqueada';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionSecurity => 'Seguridad';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionTools => 'Herramientas';

  @override
  String get settingsSectionInfo => 'Información';

  @override
  String get settingsTheme => 'Tema oscuro';

  @override
  String get settingsAppLock => 'Bloqueo de la app';

  @override
  String get settingsAppLockDesc =>
      'Solicitar biometría o el PIN del teléfono en cada apertura';

  @override
  String get settingsAppLockUnavailable =>
      'No hay biometría registrada en este dispositivo';

  @override
  String get settingsAppLockEnableFailed =>
      'Verificación fallida: bloqueo no activado';

  @override
  String get settingsAppLockEnabled => 'Bloqueo activado';

  @override
  String get settingsAppLockDisabled => 'Bloqueo desactivado';

  @override
  String get appLockTitle => 'App bloqueada';

  @override
  String get appLockSubtitle =>
      'Desbloquea con biometría o el PIN del teléfono';

  @override
  String get appLockUnlock => 'Desbloquear';

  @override
  String get appLockReason => 'Desbloquear el wallet';

  @override
  String get appLockNoticeDeviceAuthRemoved =>
      'Bloqueo desactivado: la protección de pantalla (biometría/PIN) ya no está disponible. Reactívala en los ajustes del sistema para volver a usar el bloqueo.';

  @override
  String get appLockNoticeContinue => 'Continuar';

  @override
  String get appLockPromptTitle => '¿Activar el bloqueo?';

  @override
  String get appLockPromptMessage =>
      'Al abrir la app se pedirá biometría o el PIN del teléfono.';

  @override
  String get appLockPromptEnable => 'Activar';

  @override
  String get appLockPromptLater => 'Más tarde';

  @override
  String get aboutLicensesOpenOnline => 'Abrir en línea';

  @override
  String homeCreated(Object date) {
    return 'Creado: $date';
  }

  @override
  String homeLastTransfer(Object date) {
    return 'Última transferencia: $date';
  }

  @override
  String homeWalletSemantics(Object balance, Object name) {
    return 'Monedero $name$balance';
  }

  @override
  String get walletDetailTitle => 'Monedero';

  @override
  String walletDetailCopied(Object label) {
    return '$label copiado. Se eliminará después de 60s.';
  }

  @override
  String get walletDetailNoConnection => 'Sin conexión';

  @override
  String get walletDetailTransferSuccess =>
      'Monedero transferido con éxito. Semilla local eliminada.';

  @override
  String walletDetailTransferError(Object error) {
    return 'Error de transferencia: $error';
  }

  @override
  String get walletDetailSeedCopied =>
      'Frase semilla copiada. Se eliminará después de 60s.';

  @override
  String get walletDetailSeedWarning =>
      '¡Guárdala segura! Es la ÚNICA forma de recuperar tus fondos.';

  @override
  String get walletDetailAddress => 'Dirección';

  @override
  String get walletDetailName => 'Nombre';

  @override
  String get walletDetailBalance => 'Saldo';

  @override
  String get walletDetailTransactions => 'Transacciones';

  @override
  String get walletDetailTxBlockHeight => 'Altura de bloque';

  @override
  String get walletDetailTxConfirmations => 'Confirmaciones';

  @override
  String get walletDetailTxDate => 'Fecha';

  @override
  String get walletDetailTxDetails => 'Detalles de la transacción';

  @override
  String get walletDetailTxEmpty => 'Sin transacciones';

  @override
  String get walletDetailTxError => 'No se pudieron cargar las transacciones';

  @override
  String get walletDetailTxFee => 'Comisión';

  @override
  String get walletDetailTxIncoming => 'Recibidos';

  @override
  String get walletDetailTxOrphan => 'Huérfana (bloque perdido)';

  @override
  String get walletDetailTxOutgoing => 'Enviados';

  @override
  String get walletDetailTxPending => 'Pendiente';

  @override
  String get walletDetailTxReplaced => 'Reemplazada (expulsada del mempool)';

  @override
  String get walletDetailTxRetry => 'Reintentar';

  @override
  String get themeToggle => 'Cambiar tema';

  @override
  String get backupSeedTitle => 'Copia de seguridad de la semilla';

  @override
  String get backupSeedIntro =>
      'Escribe tu frase semilla en papel y guárdala en un lugar seguro. Es la única forma de recuperar tus fondos.';

  @override
  String get backupSeedStart => 'Iniciar copia';

  @override
  String get backupSeedLater => 'Más tarde';

  @override
  String get backupSeedSavedContinue => 'He guardado la semilla';

  @override
  String get backupSeedVerifyTitle => 'Verifica tu copia';

  @override
  String get backupSeedVerifyHint =>
      'Introduce las 3 palabras resaltadas para confirmar que las has guardado.';

  @override
  String backupSeedWordLabel(Object number) {
    return 'Palabra $number';
  }

  @override
  String get backupSeedVerifyError =>
      'Palabras incorrectas. Inténtalo de nuevo.';

  @override
  String get backupSeedDone => 'Copia completada';

  @override
  String get backupSeedDoneDesc =>
      'Tu semilla está segura. Recuerda: quien posee la semilla controla los fondos.';

  @override
  String get backupSeedFinish => 'Finalizar';

  @override
  String get backupSeedSkipWarning =>
      'Si lo omites, arriesgas perder tus fondos si pierdes este dispositivo. Puedes hacerlo después desde los detalles del wallet.';

  @override
  String get walletDetailSend => 'Enviar';

  @override
  String get walletDetailReceive => 'Recibir';

  @override
  String get walletDetailTransfer => 'Transferir';

  @override
  String get walletDetailTransferred => 'TRANSFERIDO';

  @override
  String get walletDetailPending => 'TRANSFERENCIA PENDIENTE';

  @override
  String get walletDetailNoName => 'Monedero sin nombre';

  @override
  String get walletDetailTransferredDesc =>
      'Este monedero ha sido transferido. Modo solo lectura.';

  @override
  String get sendScreenTitle => 'Enviar BTC';

  @override
  String get sendScreenAddressLabel => 'Dirección del destinatario';

  @override
  String get sendScreenAddressHint => 'bc1...';

  @override
  String get sendScreenAmountLabel => 'Cantidad (BTC)';

  @override
  String get sendScreenAmountHint => '0.00';

  @override
  String get sendScreenFeeLabel => 'Comisión';

  @override
  String get sendScreenFeeLow => 'Baja';

  @override
  String get sendScreenFeeNormal => 'Normal';

  @override
  String get sendScreenFeeHigh => 'Alta';

  @override
  String get sendScreenFeeCustom => 'Personalizada';

  @override
  String get sendScreenFeeCustomHint => 'sat/vB';

  @override
  String sendScreenBalance(Object balance, Object ticker) {
    return 'Disponible: $balance $ticker';
  }

  @override
  String sendScreenFeeEstimated(Object fee) {
    return 'Comisión estimada: $fee sat';
  }

  @override
  String get sendScreenUtxoControl => 'Selección de UTXO';

  @override
  String get sendScreenUtxoSelectAll => 'Seleccionar todos';

  @override
  String get sendScreenUtxoNoneSelected =>
      'Selecciona al menos un UTXO para enviar';

  @override
  String sendScreenTotal(Object ticker, Object total) {
    return 'Total: $total $ticker';
  }

  @override
  String get sendScreenMax => 'Máx';

  @override
  String get sendScreenSend => 'Enviar';

  @override
  String get sendScreenSending => 'Enviando...';

  @override
  String homeDeleteMultiSummary(int deleted, int errors, Object error) {
    return '$deleted monederos eliminados, $errors errores: $error';
  }

  @override
  String get walletDetailBalanceLabel => 'SALDO';

  @override
  String get walletDetailMasterFingerprint => 'HUELLA MAESTRA';

  @override
  String get walletDetailDerivationPath => 'RUTA DE DERIVACIÓN';

  @override
  String get walletDetailSettings => 'AJUSTES';

  @override
  String get walletDetailAdvancedTools => 'Herramientas Avanzadas';

  @override
  String get walletDetailUtxos => 'UTXO';

  @override
  String get walletDetailUtxoEmpty => 'No se encontraron UTXO gastables';

  @override
  String walletDetailUtxoConfirmations(int count) {
    return '$count confirmaciones';
  }

  @override
  String walletDetailUtxoSelected(int count, int sats) {
    return '$count seleccionados · $sats sat';
  }

  @override
  String get walletDetailUtxoSendSelected => 'Enviar seleccionados';

  @override
  String get walletDetailUtxoClearSelection => 'Borrar selección';

  @override
  String get walletDetailFirst100Addresses => 'Primeras 100 direcciones';

  @override
  String get walletDetailPasswordSeedReason =>
      'Confirma la contraseña para ver la frase semilla';

  @override
  String get walletDetailBiometricSeedReason =>
      'Confirmación biométrica para ver la frase semilla';

  @override
  String get walletDetailPasswordBumpReason =>
      'Confirma la contraseña para aumentar la comisión';

  @override
  String get walletDetailBiometricBumpReason =>
      'Confirmación biométrica para aumentar la comisión';

  @override
  String get walletDetailTxBumpFee => 'Aumentar comisión';

  @override
  String get walletDetailBumpFeeTitle =>
      'Aumentar la comisión de la transacción';

  @override
  String walletDetailBumpFeeCurrent(int fee) {
    return 'Comisión actual: $fee sat/vB';
  }

  @override
  String get walletDetailBumpFeeUnavailable =>
      'Comisiones recomendadas no disponibles: introduce una tarifa personalizada';

  @override
  String get walletDetailBumpFeeWarning =>
      'La transacción original podría no confirmarse nunca si se mina el reemplazo.';

  @override
  String walletDetailBumpFeeSuccess(Object txid) {
    return 'Comisión aumentada: nueva transacción $txid';
  }

  @override
  String get walletDetailBumpFeeErrorFee =>
      'La nueva comisión debe ser mayor que la actual';

  @override
  String get sendScreenSigning => 'Firmando transacción...';

  @override
  String get sendScreenBroadcasting => 'Transmitiendo a la red...';

  @override
  String get sendScreenBiometricReason =>
      'Confirmación biométrica para autorizar la transacción';

  @override
  String get sendScreenPasswordReason =>
      'Introduce tu contraseña para autorizar la transacción';

  @override
  String get sendScreenBiometricRequired =>
      'Se requiere biometría para enviar. Activa la huella o el reconocimiento facial en los ajustes del dispositivo.';

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
    return 'Máx: $amount';
  }

  @override
  String sendScreenUtxoSummary(int sats, int count) {
    return '$sats sat · $count UTXO';
  }

  @override
  String get importScreenHintText =>
      'La frase semilla consta de 12, 15, 18, 21 o 24 palabras separadas por espacios. Puedes pegarla directamente.';

  @override
  String onboardingSubmitError(Object error) {
    return 'Error: $error';
  }

  @override
  String get legalMitLicense => 'Licencia MIT';

  @override
  String get legalSecurityTitle => 'Seguridad';

  @override
  String get legalTermsContent =>
      'Estos Términos de Servicio son provisionales y serán sustituidos por la versión definitiva cuando el sitio web oficial esté disponible.\n\nBtc Blake2b Wallet es un monedero Bitcoin autocustodiado para la red experimental \"bitcoin-blake2b\" (un fork de Bitcoin). Las claves privadas y la frase semilla permanecen exclusivamente en tu dispositivo: no custodiamos, no transferimos y no tenemos acceso a tus fondos.\n\nLa aplicación se ofrece gratuitamente, \"tal cual\", sin garantías de ningún tipo. La usas bajo tu exclusivo riesgo. La red bitcoin-blake2b es una red experimental derivada de Bitcoin: sus monedas podrían no tener valor de mercado, no ser reconocidas por los exchanges y sufrir reorganizaciones. Ningún contenido de la aplicación constituye asesoramiento financiero o de inversión.\n\nEres el único responsable de la custodia de la frase semilla y de tus fondos: cualquiera que la posea puede gastar las monedas. La aplicación no puede recuperar una semilla perdida. Está prohibido el uso para actividades ilegales. Declaras tener al menos 16 años.\n\nBtc Blake2b Wallet no está afiliado, patrocinado ni aprobado por Bitcoin, Bitcoin Core o bitcoin.org.';

  @override
  String legalPrivacyContent(String holder, String email) {
    return 'Esta Política de Privacidad es provisional y será sustituida por la versión definitiva publicada en el sitio web oficial cuando esté disponible.\n\n1) DATOS EN EL DISPOSITIVO. La aplicación no requiere una cuenta y no guarda datos personales en servidores del autor. La semilla cifrada (AES-256-GCM), las preferencias y los consentimientos permanecen SOLO en tu dispositivo.\n\n2) DATOS TRANSMITIDOS A TERCEROS PARA EL FUNCIONAMIENTO. Para mostrar el saldo y las comisiones, la aplicación consulta API públicas de terceros:\n• mempool.guide (explorador de blockchain).\nEn cada solicitud se transmiten tu dirección IP y la dirección pública del monedero consultado. Las claves privadas y la semilla NUNCA se transmiten.\n\n3) SIN RASTREADORES. Ninguna analítica, ninguna publicidad, ninguna cookie dentro de la aplicación.\n\n4) DERECHOS (GDPR arts. 13-14). Tienes derecho de acceso, rectificación, supresión y oposición escribiendo al responsable del tratamiento: $holder — $email. Dado que no almacenamos datos personales, estos derechos ya están garantizados en gran parte por el hecho de que los datos permanecen en tu dispositivo.';
  }

  @override
  String legalSecurityContact(String email) {
    return 'Para informar de vulnerabilidades de seguridad usa la notificación privada \"Report a vulnerability\" del repositorio de GitHub (pestaña Security) o escribe a:\n$email\n\nNo abras issues públicas para problemas de seguridad. Tiempo de respuesta: 72 horas. Política de divulgación: 90 días.';
  }

  @override
  String get sendScreenSuccess => '¡Transacción enviada!';

  @override
  String sendScreenSuccessTxid(Object txid) {
    return 'TXID: $txid';
  }

  @override
  String sendScreenError(Object error) {
    return 'Error de envío: $error';
  }

  @override
  String get sendScreenValidateAddress => 'Introduce una dirección';

  @override
  String sendScreenValidateInvalidAddress(Object network, Object prefix) {
    return 'Dirección no válida para $network (usa $prefix)';
  }

  @override
  String get sendScreenValidateLength => 'Longitud de dirección no válida';

  @override
  String get sendScreenValidateSelf => 'No puedes enviarte a ti mismo';

  @override
  String get sendScreenValidateAmount => 'Introduce una cantidad';

  @override
  String get sendScreenValidateInvalidAmount => 'Cantidad no válida';

  @override
  String sendScreenValidateDust(Object dust, Object dustBtc) {
    return 'Cantidad demasiado baja (mínimo $dust satoshis / $dustBtc)';
  }

  @override
  String sendScreenValidateInsufficient(Object balance, Object fee) {
    return 'Fondos insuficientes (saldo: $balance, comisión estimada: $fee sat)';
  }

  @override
  String get sendScreenLoadingUtxos => 'Cargando UTXOs...';

  @override
  String sendScreenUtxoError(Object error) {
    return 'No se pueden cargar UTXOs: $error';
  }

  @override
  String get scanQrTitle => 'Escanear código QR';

  @override
  String get scanQrError =>
      'No se puede acceder a la cámara. Concede el permiso e inténtalo de nuevo.';

  @override
  String get scanQrInvalid =>
      'El código escaneado no es una dirección Bitcoin válida.';

  @override
  String get scanQrInvalidInvoice =>
      'El código escaneado no es una factura Lightning válida.';

  @override
  String get scanQrTorch => 'Alternar linterna';

  @override
  String get sendConfirmTitle => 'Confirmar transacción';

  @override
  String get sendConfirmWarning =>
      'Esta transacción es irreversible. Verifica los detalles antes de confirmar.';

  @override
  String get sendConfirmSend => 'Confirmar y Enviar';

  @override
  String get importScreenTitle => 'Importar Monedero';

  @override
  String get importScreenHeading => 'Introduce la frase semilla';

  @override
  String get importScreenSubtitle =>
      'Introduce la frase mnemotécnica (12, 15, 18, 21 o 24 palabras) separada por espacios y elige el tipo de cuenta que corresponde a la cartera original.';

  @override
  String get importScriptTypeLabel => 'Tipo de cuenta';

  @override
  String get importScriptTypeNativeSegwit => 'SegWit nativo (BIP84)';

  @override
  String get importScriptTypeNestedSegwit => 'SegWit anidado (BIP49)';

  @override
  String get importScriptTypeLegacy => 'Legacy (BIP44)';

  @override
  String get createWalletTypeTitle => 'Tipo de cartera a crear';

  @override
  String importScriptTypeHint(String prefix) {
    return 'Las direcciones empiezan por $prefix';
  }

  @override
  String get importScreenHint => 'palabra1 palabra2 palabra3 ...';

  @override
  String get importScreenValidateEmpty => 'Introduce la frase mnemotécnica.';

  @override
  String importScreenValidateCount(Object count) {
    return 'La frase debe contener 12, 15, 18, 21 o 24 palabras (detectadas: $count).';
  }

  @override
  String get importScreenValidateInvalid =>
      'Frase mnemotécnica no válida. Comprueba la ortografía.';

  @override
  String get importScreenImporting => 'Importando...';

  @override
  String get importScreenImport => 'Importar';

  @override
  String importScreenError(Object error) {
    return 'Error al importar: $error';
  }

  @override
  String get importModeSeed => 'Frase semilla';

  @override
  String get importModeWatchOnly => 'Solo lectura (xpub)';

  @override
  String get importWatchOnlySubtitle =>
      'Supervisa un monedero externo (saldo e historial) usando solo su clave pública extendida. Sin clave privada involucrada: el envío nunca es posible.';

  @override
  String get importWatchOnlyXpubLabel => 'Xpub de la cuenta';

  @override
  String get importWatchOnlyXpubHint =>
      'Pega el xpub de la cuenta (empieza por \"xpub\"). Solo claves públicas: nunca pegues un xprv.';

  @override
  String get importWatchOnlyValidateEmpty => 'Introduce el xpub de la cuenta.';

  @override
  String get importWatchOnlyValidatePrefix =>
      'El xpub debe empezar por \"xpub\" (red principal).';

  @override
  String get watchOnlyBadge => 'Solo lectura';

  @override
  String get transferScreenTitle => 'Transferir Monedero';

  @override
  String get transferScreenScanning => 'Escanear el código QR del receptor.';

  @override
  String get transferScreenProcessing => 'Procesando y cifrando datos...';

  @override
  String transferScreenScanError(Object error) {
    return 'Error al escanear o cifrar: $error';
  }

  @override
  String get transferScreenNearbyTitle => 'Escanear para recibir';

  @override
  String get transferScreenNearbySubtitle =>
      'Haz que el receptor escanee este código QR.';

  @override
  String transferScreenNearbyCode(Object code) {
    return 'Código manual: $code';
  }

  @override
  String get transferScreenNearbyCancel => 'Cancelar';

  @override
  String get transferScreenNearbySuccess =>
      'Monedero transferido con éxito por Bluetooth. Semilla local eliminada.';

  @override
  String transferScreenNearbyError(Object error) {
    return 'Error de transferencia: $error';
  }

  @override
  String get transferScreenWebRtcConnecting => 'Iniciando conexión WebRTC...';

  @override
  String get transferScreenWebRtcTransferring => 'Transfiriendo por WebRTC...';

  @override
  String get transferScreenTransferComplete => '¡Transferencia completada!';

  @override
  String get transferScreenMethodTitle => 'Elegir método de transferencia';

  @override
  String get transferScreenMethodQr => 'Código QR (2 fases)';

  @override
  String get transferScreenMethodQrDesc =>
      'Escanea el QR del receptor, luego genera un QR con la semilla cifrada.';

  @override
  String get transferScreenMethodNearby => 'Bluetooth P2P';

  @override
  String get transferScreenMethodNearbyDesc =>
      'Transferencia directa entre dispositivos. Requiere Bluetooth.';

  @override
  String get transferScreenMethodWebRtc => 'WebRTC (Internet)';

  @override
  String get transferScreenMethodWebRtcDesc =>
      'P2P por navegador. Requiere internet en ambos dispositivos.';

  @override
  String get transferScreenWebRtcQrDescription =>
      'El receptor debe escanear este QR. La transferencia se realizará via WebRTC (sin límite de tamaño).';

  @override
  String get transferScreenEncryptedQrDescription =>
      'Muestra este código QR al dispositivo receptor. Una vez escaneado y completada la recepción, el wallet se eliminará automáticamente de este dispositivo.';

  @override
  String get transferScreenWebRtcTimeout =>
      'Conexión WebRTC fallida después de 30 segundos. Intenta de nuevo o usa el método de código QR de 2 fases.';

  @override
  String get receiveScreenTitle => 'Recibir Monedero';

  @override
  String get receiveScreenInit => 'Inicializando clave asimétrica...';

  @override
  String get receiveScreenShowQr => 'Mostrar este código QR al remitente.';

  @override
  String get receiveScreenScanSender =>
      'Escanear el código QR en el dispositivo del remitente.';

  @override
  String get receiveScreenAutoDetectMethod =>
      'El sistema detecta automáticamente el método de transferencia usado por el remitente.';

  @override
  String receiveScreenKeyError(Object error) {
    return 'Error de generación de clave: $error';
  }

  @override
  String get receiveScreenDecrypting =>
      'Datos recibidos. Descifrando y validando en el servidor...';

  @override
  String get receiveScreenSuccess => 'Monedero recibido e importado con éxito.';

  @override
  String get receiveScreenQrSuccess => 'Monedero recibido por código QR.';

  @override
  String receiveScreenNearbyConnecting(Object code) {
    return 'Código $code leído. Conectando...';
  }

  @override
  String get receiveScreenNearbySuccess =>
      'Monedero recibido por Bluetooth P2P.';

  @override
  String receiveScreenError(Object error) {
    return 'Error: $error';
  }

  @override
  String get receiveScreenWebRtcTitle => 'Sala WebRTC';

  @override
  String get receiveScreenWebRtcConnect => 'Conectar a la sala';

  @override
  String get receiveScreenWebRtcShareQr => 'Compartir este QR con el remitente';

  @override
  String get receiveScreenWebRtcScanQr =>
      'Escanear el QR de la sala del remitente';

  @override
  String get receiveScreenWebRtcWait => 'Esperando conexión del remitente...';

  @override
  String receiveScreenRoomId(Object roomId) {
    return 'ID de sala: $roomId';
  }

  @override
  String get passwordDialogCreateTitle => 'Crear contraseña de seguridad';

  @override
  String get passwordDialogCreateContent =>
      'Establece una contraseña para proteger operaciones sensibles en este navegador.';

  @override
  String get passwordDialogCreateHint => 'Introduce una contraseña segura';

  @override
  String get passwordDialogCreateConfirm => 'Confirmar contraseña';

  @override
  String get passwordDialogCreateConfirmHint =>
      'Vuelve a introducir la contraseña';

  @override
  String get passwordDialogCreateMismatch => 'Las contraseñas no coinciden';

  @override
  String get passwordDialogCreateTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordDialogCreate => 'Crear';

  @override
  String get passwordDialogCancel => 'Cancelar';

  @override
  String get passwordDialogEnterTitle => 'Introducir contraseña';

  @override
  String get passwordDialogEnterContent =>
      'Introduce tu contraseña de seguridad para continuar.';

  @override
  String get passwordDialogEnterHint => 'Introduce tu contraseña';

  @override
  String get passwordDialogEnter => 'Confirmar';

  @override
  String get passwordDialogWrong => 'Contraseña incorrecta';

  @override
  String get languageSelector => 'Idioma';

  @override
  String get languageSelectorAuto => '🌐 Automática (sistema)';

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
  String get walletDetailRefresh => 'Actualizar';

  @override
  String get walletDetailDeleteTitle => '¿Eliminar monedero?';

  @override
  String get walletDetailDeleteConfirm => 'Eliminar definitivamente';

  @override
  String get walletDetailDeleteWarning =>
      'Esta acción es irreversible. Asegúrate de tener una copia de la frase semilla si hay fondos en el monedero.';

  @override
  String get walletDetailInfo => 'Información del monedero';

  @override
  String get walletDetailNameLabel => 'Nombre del monedero';

  @override
  String get walletDetailNameHint => 'ej. Ahorros Casa';

  @override
  String get walletDetailType => 'Tipo';

  @override
  String get walletDetailTypeValue => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNativeSegwit => 'HD SegWit (BIP84 Bech32 Native)';

  @override
  String get walletTypeNestedSegwit => 'SegWit anidado (BIP49 P2SH)';

  @override
  String get walletTypeLegacy => 'Legacy P2PKH (BIP44)';

  @override
  String get walletDetailUpdating => 'ACTUALIZANDO...';

  @override
  String walletDetailNTransactions(Object count) {
    return '$count TRANSACCIONES';
  }

  @override
  String get walletDetailReceiveQr => 'Recibir Bitcoin';

  @override
  String get walletDetailSignVerify => 'Firmar/Verificar mensaje';

  @override
  String get walletDetailShowAddresses => 'Mostrar direcciones';

  @override
  String get walletDetailWalletAddress => 'Dirección del monedero';

  @override
  String get walletDetailExportSeed => 'Exportar/Respaldar semilla';

  @override
  String get walletDetailShowSeedTitle => '¿Ver semilla?';

  @override
  String get walletDetailShowSeedContent =>
      'La frase semilla permite acceder a todos los fondos. Asegúrate de estar en un lugar seguro.';

  @override
  String get walletDetailShowSeedConfirm => 'Sí, mostrar';

  @override
  String get walletDetailSeedVerifyPrompt =>
      '¿Quieres verificar que has guardado la semilla?';

  @override
  String get walletDetailSeedVerifyYes => 'Sí, verificar';

  @override
  String get walletDetailSeedVerifyNotNow => 'Ahora no';

  @override
  String get walletDetailSeedVerified => 'Copia de seguridad verificada';

  @override
  String get walletDetailSeedHidden => 'Semilla oculta por seguridad';

  @override
  String get walletDetailSeedShowAgain => 'Mostrar semilla';

  @override
  String get walletDetailHideSeed => 'Ocultar';

  @override
  String get walletDetailBackupNotConfirmed =>
      'Copia de seguridad no confirmada';

  @override
  String get walletDetailBackupNotConfirmedDesc =>
      'Aún no has guardado la frase semilla. Si pierdes el dispositivo o reinstalas la app, perderás permanentemente el acceso a tus fondos.';

  @override
  String get walletDetailShowXpub => 'Mostrar XPUB del monedero';

  @override
  String get walletDetailDisplayHome => 'Mostrar valor en inicio';

  @override
  String get walletDetailUtxoRename => 'Renombrar';

  @override
  String get walletDetailUtxoRenameTitle => 'Renombrar UTXO';

  @override
  String get walletDetailSave => 'Guardar';

  @override
  String get walletDetailId => 'ID';

  @override
  String get walletDetailCreated => 'Creado';

  @override
  String get walletDetailTransferredOn => 'Transferido el';

  @override
  String get walletDetailClose => 'Cerrar';

  @override
  String get walletDetailSign => 'Firmar';

  @override
  String get walletDetailVerify => 'Verificar';

  @override
  String get walletDetailSignMessage => 'Firmar mensaje';

  @override
  String get walletDetailVerifyMessage => 'Verificar mensaje';

  @override
  String get walletDetailMessage => 'Mensaje';

  @override
  String get walletDetailBitcoinAddress => 'Dirección Bitcoin';

  @override
  String get walletDetailSignature => 'Firma (Base64)';

  @override
  String get walletDetailResult => 'Resultado:';

  @override
  String get walletDetailSignatureLabel => 'Firma:';

  @override
  String get walletDetailCopy => 'Copiar';

  @override
  String get walletDetailAddressCopied => 'Dirección copiada al portapapeles';

  @override
  String get walletDetailXpubTitle => 'XPUB del monedero';

  @override
  String get walletDetailXpubDesc =>
      'Este XPUB permite ver todas las direcciones y saldos futuros pero no puede gastar fondos.';

  @override
  String get walletDetailXpubCopied => 'XPUB copiado';

  @override
  String walletDetailErrorXpub(Object error) {
    return 'Error al derivar XPUB: $error';
  }

  @override
  String walletDetailErrorAddresses(Object error) {
    return 'Error al derivar direcciones: $error';
  }

  @override
  String get walletDetailFirst100 => 'Primeras 100 direcciones';

  @override
  String get walletDetailValidSig => 'FIRMA VÁLIDA ✓';

  @override
  String get walletDetailInvalidSig => 'FIRMA NO VÁLIDA ✗';

  @override
  String get donateTitle => 'Apoya el proyecto ❤️';

  @override
  String get donatePhrase =>
      '☕ \"Si el proyecto te resulta útil, invítanos a un café virtual\"';

  @override
  String get donateAddressLabel => 'Dirección Bitcoin para donaciones:';

  @override
  String get donateCopy => 'Copiar';

  @override
  String get donateCopied => '¡Copiado! ✓';

  @override
  String get donateNote =>
      'Donación voluntaria: no se ofrece ningún servicio ni beneficio a cambio. Cualquier importe es bienvenido, incluso unos pocos satoshis. ¡Gracias! 🧡';

  @override
  String get donateNoWalletTitle => 'No se encontró ningún monedero';

  @override
  String get donateNoWalletMessage =>
      'No se encontró ninguna app de monedero Bitcoin en tu dispositivo. Aun así puedes copiar la dirección y pegarla en tu monedero favorito.';

  @override
  String get donateOpenWallet => 'Abrir en el monedero';

  @override
  String get donateButton => 'Apoya el proyecto ❤️';

  @override
  String get multiTransferTitle => 'Envío Multi-Monedero';

  @override
  String get multiTransferSelectWallets => 'Seleccionar monederos para enviar';

  @override
  String multiTransferSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monederos seleccionados',
      one: '1 monedero seleccionado',
    );
    return '$_temp0';
  }

  @override
  String multiTransferTotalValue(Object amount, Object ticker) {
    return 'Valor total: $amount $ticker';
  }

  @override
  String get multiTransferMethodLabel => 'Método de transferencia:';

  @override
  String multiTransferMethodWebRtc(Object max) {
    return 'WebRTC (máx. $max)';
  }

  @override
  String multiTransferMethodBluetooth(Object max) {
    return 'Bluetooth (máx. $max)';
  }

  @override
  String multiTransferMethodQr(Object max) {
    return 'Código QR 2 fases (máx. $max)';
  }

  @override
  String multiTransferSendButton(Object amount, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar $count Monederos',
      one: 'Enviar 1 Monedero',
    );
    return '$_temp0 · $amount BTC';
  }

  @override
  String get multiTransferProgressTitle => 'Enviando...';

  @override
  String multiTransferProgressWallet(Object current, Object total) {
    return 'Monedero $current de $total';
  }

  @override
  String multiTransferSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monederos enviados con éxito',
      one: '1 monedero enviado con éxito',
    );
    return '$_temp0';
  }

  @override
  String multiTransferPartialSuccess(Object failed, Object success) {
    return '$success enviados, $failed fallidos';
  }

  @override
  String get multiTransferNoLockedWallets =>
      'No hay monederos disponibles para transferir. Solo los monederos bloqueados pueden transferirse.';

  @override
  String multiTransferLimitExceeded(
      Object max, Object method, Object selected) {
    return 'Has seleccionado $selected monederos. El máximo para $method es $max.';
  }

  @override
  String get multiTransferReceivingTitle => 'Recepción Multi-Monedero';

  @override
  String multiTransferReceivingProgress(Object received, Object total) {
    return 'Recibidos $received de $total monederos';
  }

  @override
  String get multiTransferMethodUnavailable =>
      'No disponible en esta plataforma';

  @override
  String multiTransferSendingWallet(Object current, Object total) {
    return 'Enviando monedero $current de $total...';
  }

  @override
  String get multiTransferPreparing => 'Preparando monedero...';

  @override
  String get multiTransferWaitingReceiver => 'Esperando al receptor...';

  @override
  String get multiTransferCompleted => 'Completado';

  @override
  String get multiTransferFailed => 'Fallido';

  @override
  String multiTransferMethodQrDesc(Object max) {
    return 'Transferencia manual en 2 fases por código QR. Máx. $max monederos.';
  }

  @override
  String multiTransferMethodWebRtcDesc(Object max) {
    return 'Transferencia P2P rápida por internet. Máx. $max monederos.';
  }

  @override
  String multiTransferMethodBluetoothDesc(Object max) {
    return 'Transferencia directa entre dispositivos. Máx. $max monederos.';
  }

  @override
  String get multiTransferNoBalance => 'Saldo no disponible';

  @override
  String get multiTransferConfirmTitle => 'Confirmar envío';

  @override
  String multiTransferConfirmMessage(Object amount, num count, Object ticker) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monederos',
      one: '1 monedero',
    );
    return 'Vas a enviar $_temp0 por un total de $amount $ticker. ¿Continuar?';
  }

  @override
  String get onboardingTitle => 'Bienvenido a Btc Blake2b Wallet';

  @override
  String get onboardingSubtitle =>
      'Monedero Bitcoin de código abierto. Auto-custodia. Sin KYC.';

  @override
  String get onboardingResidenceLabel => 'País de residencia fiscal';

  @override
  String get onboardingResidenceHint => 'Selecciona tu país';

  @override
  String get onboardingReverseSolicitation =>
      'Declaro que utilizo Btc Blake2b Wallet por mi propia iniciativa (\"reverse solicitation\") y que resido fiscalmente en el país seleccionado.';

  @override
  String get onboardingTermsAccept => 'Acepto los ';

  @override
  String get onboardingPrivacyAccept => 'He leído la ';

  @override
  String get onboardingAgeConfirm => 'Declaro que tengo al menos 16 años';

  @override
  String get onboardingAgeSubtitle =>
      'Requerido por el Art. 8 del RGPD para el consentimiento de tratamiento de datos';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingStepNext => 'Siguiente';

  @override
  String get onboardingStepBack => 'Atrás';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingTermsTitle => 'Términos y Privacidad';

  @override
  String get onboardingValidationResidence =>
      'Selecciona tu país de residencia fiscal';

  @override
  String get onboardingValidationCheckbox =>
      'Debes aceptar todas las declaraciones';

  @override
  String get onboardingLinkTerms => 'Términos de Servicio';

  @override
  String get onboardingLinkPrivacy => 'Política de Privacidad';

  @override
  String get aboutTitle => 'Acerca de Btc Blake2b Wallet';

  @override
  String get aboutDescription =>
      'Btc Blake2b Wallet es un monedero Bitcoin open-source de auto-custodia. Sin registro, sin KYC, sin rastreo. Tus llaves, tus bitcoins.';

  @override
  String get aboutLicenseTitle => 'Licencia';

  @override
  String get aboutThirdPartyLicenses => 'Licencias de terceros';

  @override
  String get aboutThirdPartyLicensesDesc =>
      'Ver la lista completa de licencias open-source';

  @override
  String get aboutBuiltWith => 'Construido con';

  @override
  String get aboutDisclaimer =>
      'Este software se proporciona \"TAL CUAL\" sin garantía de ningún tipo.';

  @override
  String get explorerTitle => 'Explorador';

  @override
  String get explorerAddressLabel => 'Dirección';

  @override
  String get explorerRefresh => 'Actualizar';

  @override
  String get explorerBalanceLabel => 'Saldo';

  @override
  String get explorerTxCount => 'Transacciones';

  @override
  String get explorerTipHeight => 'Altura del nodo';

  @override
  String get explorerErrorInvalidAddress =>
      'Dirección no válida. Comprueba el formato para esta red.';

  @override
  String get explorerErrorRateLimited =>
      'Límite de solicitudes superado. Inténtalo de nuevo en un minuto.';

  @override
  String get explorerErrorNodeUnavailable =>
      'Servicio temporalmente no disponible. Inténtalo de nuevo más tarde.';

  @override
  String get explorerErrorNotFound => 'Dirección o transacción no encontrada.';

  @override
  String get explorerErrorTimeout =>
      'Solicitud agotada. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get explorerErrorNetwork =>
      'Red no disponible. Comprueba la conexión.';

  @override
  String get explorerRetry => 'Reintentar';

  @override
  String explorerErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get walletLayerOnchain => 'On-chain';

  @override
  String get walletLayerLightning => 'Lightning';

  @override
  String get lightningDisconnectedTitle => 'Ningún nodo Lightning conectado';

  @override
  String get lightningDisconnectedBody =>
      'Conecta tu nodo Lightning blake2b para enviar y recibir pagos. La app nunca custodia tus fondos ni claves.';

  @override
  String get lightningConnectButton => 'Conectar nodo';

  @override
  String get lightningConnectTitle => 'Conectar nodo Lightning';

  @override
  String get lightningConnectHint =>
      'Pega la cadena de conexión (nostr+walletconnect://…)';

  @override
  String get lightningConnectInvalidUri => 'Cadena de conexión no válida';

  @override
  String get lightningConnectInfo =>
      'El nodo debe autorizar esta app (grant): revisa el panel de control de tu nodo.';

  @override
  String get lightningConnecting => 'Conectando…';

  @override
  String get lightningConnected => 'Conectado';

  @override
  String get lightningDisconnect => 'Desconectar';

  @override
  String get lightningBalance => 'Saldo Lightning';

  @override
  String get lightningChannels => 'Canales';

  @override
  String get lightningNoChannels => 'Sin canales abiertos';

  @override
  String get lightningChannelPeer => 'Par';

  @override
  String get lightningChannelCapacity => 'Capacidad';

  @override
  String get lightningChannelLocal => 'Local';

  @override
  String get lightningChannelRemote => 'Remoto';

  @override
  String get lightningOpenChannel => 'Abrir canal';

  @override
  String get lightningOpenChannelNodeId => 'Node ID (pubkey)';

  @override
  String get lightningOpenChannelHost => 'Host (opcional, ip:puerto)';

  @override
  String get lightningOpenChannelAmount => 'Importe (sat)';

  @override
  String get lightningOpenChannelPrivate => 'Canal privado';

  @override
  String get lightningChannelOpened => 'Apertura de canal solicitada';

  @override
  String get lightningCloseChannel => 'Cerrar canal';

  @override
  String get lightningCloseChannelForce => 'Cierre forzado';

  @override
  String get lightningCloseChannelForceWarning =>
      'El cierre forzado publica el último estado del canal on-chain. Pueden aplicarse comisiones y demoras. ¿Continuar?';

  @override
  String get lightningReceive => 'Recibir';

  @override
  String get lightningSend => 'Enviar';

  @override
  String get lightningInvoiceAmount => 'Importe (sat)';

  @override
  String get lightningInvoiceDescription => 'Descripción (opcional)';

  @override
  String get lightningInvoiceCreate => 'Crear factura';

  @override
  String get lightningInvoiceTitle => 'Factura Lightning';

  @override
  String get lightningPay => 'Pagar factura';

  @override
  String get lightningPayHint => 'Pega la factura (lnbc…)';

  @override
  String get lightningPayDialogTitle => 'Confirmar pago Lightning';

  @override
  String get lightningPayDialogBody => '¿Pagar esta factura?';

  @override
  String get lightningPaySuccess => 'Pago enviado';

  @override
  String get lightningCopied => 'Copiado';

  @override
  String get lightningErrorRestricted =>
      'El nodo no ha autorizado esta app. Crea un grant en tu nodo para esta conexión.';

  @override
  String lightningErrorGeneric(String error) {
    return 'Error de Lightning: $error';
  }

  @override
  String get lightningConfirm => 'Confirmar';

  @override
  String get lightningCancel => 'Cancelar';

  @override
  String get lightningNodeOnchain => 'On-chain del nodo';

  @override
  String get lightningDeposit => 'Depositar';

  @override
  String get lightningWithdraw => 'Enviar on-chain';

  @override
  String get lightningDepositTitle => 'Deposito on-chain';

  @override
  String get lightningDepositHint =>
      'Envía fondos blake2b a esta dirección del nodo.';

  @override
  String get lightningDepositNewAddress => 'Nueva dirección';

  @override
  String get lightningDepositWarning =>
      'Envía solo en la red blake2b. Los fondos enviados en la red incorrecta se pierden.';

  @override
  String get lightningOnchainSendTitle => 'Envío on-chain';

  @override
  String get lightningOnchainAddressLabel => 'Dirección destinataria';

  @override
  String get lightningOnchainAmountLabel => 'Importe (sat)';

  @override
  String get lightningOnchainFeeLabel => 'Comisión de red';

  @override
  String get lightningOnchainFeeMin => 'Mínima';

  @override
  String get lightningOnchainFeeEconomical => 'Económica';

  @override
  String get lightningOnchainFeePriority => 'Prioritaria';

  @override
  String get lightningOnchainConfirm => 'Confirmar envío';

  @override
  String get lightningOnchainConfirmTitle => 'Confirmar envío on-chain?';

  @override
  String get lightningOnchainWarning =>
      'Operación irreversible: los fondos saldrán del nodo.';

  @override
  String get lightningOnchainSuccess => 'Transacción enviada';

  @override
  String get lightningOnchainInvalidAddress => 'Dirección blake2b no válida';

  @override
  String get lightningOnchainInsufficient => 'Fondos on-chain insuficientes';

  @override
  String get lightningFeesUnavailable =>
      'Estimaciones de comisión no disponibles: el nodo elegirá la comisión';

  @override
  String get lightningOpenChannelHint =>
      'Pubkey o pubkey@host:port (onion necesita Tor en el nodo)';

  @override
  String get lightningOpenChannelInvalid =>
      'Node ID o host no válido (66 hex, host:port)';

  @override
  String get lightningActivityDetected => 'Actividad detectada en el nodo';

  @override
  String get lightningPeers => 'Peers';

  @override
  String get lightningPeersEmpty => 'Ningún peer conectado';

  @override
  String get lightningConnectPeer => 'Conectar peer';

  @override
  String get lightningDisconnectPeer => 'Desconectar';

  @override
  String get lightningPeerDisconnected => 'Desconectado';

  @override
  String get lightningPeerId => 'ID del peer';

  @override
  String get lightningPeerAddresses => 'Direcciones';

  @override
  String get lightningDisconnectPeerConfirm =>
      '¿Desconectar este peer? Los canales abiertos siguen activos.';

  @override
  String get lightningChannelDetail => 'Detalles del canal';

  @override
  String get lightningChannelShortId => 'Short channel ID';

  @override
  String get lightningChannelState => 'Estado del nodo';

  @override
  String get lightningChannelFee => 'Comisión';

  @override
  String get lightningChannelSpendable => 'Gastable';

  @override
  String get lightningChannelReceivable => 'Recibible';

  @override
  String get lightningChannelHtlcs => 'HTLC';

  @override
  String get lightningChannelFundingTxid => 'Txid de funding';

  @override
  String get lightningNodeManagement => 'Gestión del nodo';

  @override
  String lightningNodeManagementSubtitle(int peers, int channels) {
    return '$peers peers · $channels canales';
  }

  @override
  String get lightningNodeIdentity => 'Identidad del nodo';

  @override
  String get lightningNodePubkey => 'Clave pública';

  @override
  String get lightningNodeVersion => 'Versión';

  @override
  String get lightningNodePeersCount => 'Peers';

  @override
  String get lightningNodeChannelsActive => 'Canales activos';

  @override
  String get lightningNodeChannelsPending => 'Canales pendientes';

  @override
  String get lightningNodeLiquidityAdsUnsupported =>
      'No disponible en este nodo: para anunciar condiciones de lease se necesita el plugin liquidity-ads.';

  @override
  String get lightningLiquidity => 'Liquidez';

  @override
  String get lightningLiquidityTotal => 'Capacidad total';

  @override
  String get lightningLiquidityOutbound => 'Saliente';

  @override
  String get lightningLiquidityInbound => 'Entrante';

  @override
  String get lightningLiquidityWarning =>
      'Sin liquidez entrante: no se pueden recibir pagos hasta que un peer abra un canal hacia este nodo.';

  @override
  String get lightningMovements => 'Movimientos';

  @override
  String get lightningMovementsEmpty => 'Sin movimientos';

  @override
  String get lightningMovementsAll => 'Todos los movimientos';

  @override
  String get lightningMovementsLoadMore => 'Cargar más';

  @override
  String get lightningMovementDeposit => 'Depósito on-chain';

  @override
  String get lightningMovementWithdrawal => 'Envío on-chain';

  @override
  String get lightningMovementChannelOpen => 'Apertura de canal';

  @override
  String get lightningMovementChannelClose => 'Cierre de canal';

  @override
  String get lightningMovementInvoice => 'Pago Lightning';

  @override
  String get lightningMovementOnchainFee => 'Comisión on-chain';

  @override
  String get lightningMovementForward => 'Reenvío';

  @override
  String get lightningMovementOther => 'Movimiento';

  @override
  String lightningChannelsAll(int count) {
    return 'Todos los canales ($count)';
  }

  @override
  String get lightningOnchainNode => 'On-chain del nodo';

  @override
  String get lightningOnchainBalance => 'Saldo on-chain';

  @override
  String get lightningOnchainConfirmed => 'Confirmados';

  @override
  String get lightningOnchainPending => 'Pendientes';

  @override
  String get lightningOnchainUtxos => 'UTXO';

  @override
  String get lightningOnchainUtxosEmpty => 'Sin UTXO';

  @override
  String get lightningOnchainAddresses => 'Direcciones del nodo';

  @override
  String get lightningOnchainNewAddress => 'Nueva dirección';

  @override
  String get lightningOnchainAddressType => 'Tipo de dirección';

  @override
  String get lightningOnchainTypeBech32 => 'Bech32 (bc1q)';

  @override
  String get lightningOnchainTypeTaproot => 'Taproot (bc1p)';

  @override
  String get lightningOnchainHasFunds => 'Con saldo';

  @override
  String get lightningOnchainReserved => 'Reservado';

  @override
  String get lightningOnchainBlockHeight => 'Bloque';

  @override
  String get lightningPayments => 'Pagos';

  @override
  String get lightningInvoices => 'Facturas';

  @override
  String get lightningInvoicesEmpty => 'Sin facturas';

  @override
  String get lightningInvoiceStatusPaid => 'Pagada';

  @override
  String get lightningInvoiceStatusPending => 'Esperando pago';

  @override
  String get lightningInvoiceStatusExpired => 'Caducada';

  @override
  String lightningInvoicePaidOn(String date) {
    return 'Pagada el $date';
  }

  @override
  String lightningInvoiceExpiresOn(String date) {
    return 'Caduca el $date';
  }

  @override
  String get lightningReceivePaid => 'Factura pagada';

  @override
  String lightningPaymentsSummary(int total, int pending) {
    return '$total facturas · $pending en espera';
  }

  @override
  String get lightningPays => 'Pagos enviados';

  @override
  String get lightningPaysEmpty => 'Sin pagos';

  @override
  String get lightningPaymentFee => 'Comisión';

  @override
  String get lightningPaymentCompleted => 'Completado';

  @override
  String get lightningPaymentPending => 'En curso';

  @override
  String get lightningPaymentFailed => 'Fallido';

  @override
  String get lightningHtlcsEmpty => 'Sin HTLC';

  @override
  String get lightningHtlcInProgress => 'En curso';

  @override
  String get lightningHtlcIncoming => 'Entrante';

  @override
  String get lightningHtlcOutgoing => 'Saliente';

  @override
  String get lightningChannelFees => 'Comisiones de enrutado';

  @override
  String get lightningFeeEdit => 'Editar comisiones';

  @override
  String get lightningFeeBefore => 'Actuales';

  @override
  String get lightningFeeAfter => 'Nuevas';

  @override
  String get lightningFeeBaseLabel => 'Base (sat)';

  @override
  String get lightningFeePpmLabel => 'Tasa (ppm)';

  @override
  String get lightningHtlcMinLabel => 'HTLC mínimo (sat)';

  @override
  String get lightningHtlcMaxLabel => 'HTLC máximo (sat)';

  @override
  String get lightningCltvLabel => 'Delta CLTV';

  @override
  String get lightningChannelReserve => 'Nuestra reserva';

  @override
  String get lightningChannelToSelfDelay => 'Retardo to-self';

  @override
  String get lightningFeeConfirmTitle => '¿Aplicar estas comisiones?';

  @override
  String get lightningFeeWarning =>
      'Las comisiones afectan a los pagos enrutados. La red acepta pocos cambios al día y los peers pueden tardar en adoptarlas.';

  @override
  String get lightningFeeUpdated => 'Política de comisiones actualizada';

  @override
  String get lightningDiagnostics => 'Diagnóstico';

  @override
  String get lightningDiagnosticsSubtitle =>
      'Contabilidad, plugins y enrutamiento';

  @override
  String get lightningStatsEconomy => 'Economía';

  @override
  String get lightningStatsNet => 'Neto';

  @override
  String get lightningStatsSource =>
      'Según la contabilidad del nodo (bookkeeper)';

  @override
  String get lightningStatsEmpty => 'Aún no hay datos contables';

  @override
  String get lightningStatsTagDeposit => 'Depósitos';

  @override
  String get lightningStatsTagInvoice => 'Facturas';

  @override
  String get lightningStatsTagWithdrawal => 'Retiros';

  @override
  String get lightningStatsTagOnchainFee => 'Comisiones on-chain';

  @override
  String get lightningStatsTagChannelOpen => 'Aperturas de canales';

  @override
  String get lightningStatsTagChannelClose => 'Cierres de canales';

  @override
  String get lightningStatsTagRouted => 'Comisiones de enrutamiento ganadas';

  @override
  String lightningStatsEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String get lightningPluginsTitle => 'Plugins';

  @override
  String lightningPluginsActiveCount(int count) {
    return '$count activos';
  }

  @override
  String get lightningPluginInactive => 'inactivo';

  @override
  String get lightningForwardsTitle => 'Enrutamiento';

  @override
  String get lightningForwardsEmpty => 'Aún no hay pagos enrutados';

  @override
  String get lightningForwardSettled => 'Liquidado';

  @override
  String get lightningForwardFailed => 'Fallido';

  @override
  String get lightningForwardOffered => 'En curso';

  @override
  String get lightningKeysendTitle => 'Enviar a un nodo (keysend)';

  @override
  String get lightningKeysendHint => 'Pubkey del nodo destinatario (66 hex)';

  @override
  String get lightningKeysendAmountLabel => 'Importe (sat)';

  @override
  String get lightningKeysendMaxFeeLabel => 'Comisión máxima (sat)';

  @override
  String get lightningKeysendMaxFeeHelp =>
      'Deja vacío para usar el valor por defecto del nodo (0,5 %)';

  @override
  String get lightningKeysendWarning =>
      'Keysend paga a un nodo sin factura: los fondos se mueven de inmediato y no se pueden revertir.';

  @override
  String get lightningKeysendConfirmTitle => '¿Enviar este pago keysend?';

  @override
  String get lightningKeysendDestination => 'Destino';

  @override
  String get lightningKeysendSent => 'Keysend enviado';

  @override
  String get lightningKeysendInvalidPubkey => 'Pubkey de nodo no válida';

  @override
  String get lightningKeysendInvalidAmount =>
      'Introduce un importe mayor que cero';

  @override
  String get lightningKeysendSend => 'Enviar';
}
