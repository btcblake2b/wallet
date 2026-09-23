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
  String get settingsExplorerMirrors => 'Exploradores de reserva';

  @override
  String get settingsExplorerMirrorsDesc =>
      'Si mempool.guide no responde, la app consulta dos réplicas comunitarias. Desactívalo para usar solo mempool.guide.';

  @override
  String get settingsSectionInterface => 'Interfaz';

  @override
  String get settingsInfoDots => 'Pistas informativas';

  @override
  String get settingsInfoDotsDesc =>
      'Mostrar los pequeños botones de información que explican cada función';

  @override
  String get infoCoinControlTitle => 'Control de monedas (selección UTXO)';

  @override
  String get infoCoinControlBody =>
      'Tu saldo está formado por UTXOs, las piezas que recibiste. Aquí puedes elegir cuáles gastar: la transacción usará solo esas, permitiéndote dejar apartadas las pequeñas o inactivas.';

  @override
  String get infoDustLimitTitle => 'Monto mínimo (dust)';

  @override
  String get infoDustLimitBody =>
      'Los outputs menores a 546 sat son rechazados por la red como dust. Los montos bajo ese límite no pueden enviarse.';

  @override
  String get infoFeeRateTitle => 'Tarifa de transacción';

  @override
  String get infoFeeRateBody =>
      'La tarifa se paga por unidad de tamaño de transacción (sat/vB): cuanto más rápido quieras la confirmación, más pagas. Económica puede tardar horas, Prioritaria unos minutos. Personalizada es cuando conoces la tarifa actual del mempool.';

  @override
  String get infoBatchSendTitle => 'Múltiples destinatarios (lote)';

  @override
  String get infoBatchSendBody =>
      'En una sola transacción puedes pagar hasta 5 direcciones, compartiendo la tarifa en lugar de pagarla una vez por transferencia. Todos los destinatarios se muestran en la confirmación antes de firmar.';

  @override
  String get infoBumpFeeTitle => 'Aumentar tarifa (RBF)';

  @override
  String get infoBumpFeeBody =>
      'Una transacción pendiente puede ser reemplazada por una nueva con mayor tarifa (BIP125). La original se cancela y solo la reemplazante puede confirmar — la dirección de destino y el monto permanecen iguales.';

  @override
  String get infoXpubTitle => 'Clave pública de la cuenta (xpub)';

  @override
  String get infoXpubBody =>
      'El xpub genera todas tus direcciones de recepción. No puede mover fondos, pero revela el saldo e historial completo: compártela solo con apps de confianza (ej. un wallet de solo lectura).';

  @override
  String get infoReceiveAddressTitle => 'Dirección de recepción';

  @override
  String get infoReceiveAddressBody =>
      'Cada Recibir muestra una dirección fresca, elegida de las nunca usadas: esto mantiene los pagos no correlacionables. Reutilizar una dirección no es un error, solo hace tus transacciones más fáciles de rastrear.';

  @override
  String get infoWatchOnlyTitle => 'Wallet de solo lectura';

  @override
  String get infoWatchOnlyBody =>
      'Importaste solo el xpub: la app ve el saldo e historial pero no tiene clave privada, así que no puede firmar. Para gastar desde esta wallet necesitas el dispositivo que contiene la seed.';

  @override
  String get infoSignVerifyTitle => 'Firmar / verificar mensaje';

  @override
  String get infoSignVerifyBody =>
      'Firmar prueba que una dirección es tuya sin mover fondos. Cualquiera puede luego verificar la firma contra esa dirección y el mismo mensaje.';

  @override
  String get infoChannelCapacityTitle => 'Capacidad del canal';

  @override
  String get infoChannelCapacityBody =>
      'El monto total de satoshis en el canal, dividido entre tú y tu peer. Más capacidad significa poder manejar pagos más grandes. Capacidad = saldo local + saldo remoto.';

  @override
  String get infoChannelReserveTitle => 'Reserva del canal';

  @override
  String get infoChannelReserveBody =>
      'Una pequeña parte de tus fondos debe permanecer bloqueada como depósito de seguridad (la \'reserva\'). Garantiza que ambas partes tienen algo que perder — si la otra parte se desconecta maliciosamente, la reserva puede usarse para penalizarla on-chain.';

  @override
  String get infoToSelfDelayTitle => 'Retardo hacia uno mismo';

  @override
  String get infoToSelfDelayBody =>
      'En caso de cierre forzado, tu salida on-chain se retrasa por esta cantidad de bloques (típicamente 144 = ~1 día). Esto le da a tu peer tiempo de reclamar sus fondos primero, previniendo ataques de doble gasto en el estado del canal.';

  @override
  String get infoHtlcTitle => 'HTLC (Contrato Bloqueado por Hash y Tiempo)';

  @override
  String get infoHtlcBody =>
      'Un HTLC es un pago condicional: los fondos están bloqueados hasta que el destinatario revele un preimage hash. En Lightning, los HTLC permiten enrutamiento instantáneo off-chain — tu pago salta a través de múltiples canales sin confiar en ningún intermediario.';

  @override
  String get infoOpenChannelPrivateTitle => 'Canal privado';

  @override
  String get infoOpenChannelPrivateBody =>
      'Un canal privado no es anunciado a la red. Solo tú y tu peer saben que existe. Úsalo cuando no quieres que otros enruten a través de él (privacidad) o cuando el canal es demasiado pequeño para ser útil para enrutamiento.';

  @override
  String get infoRoutingFeesTitle => 'Tarifas de enrutamiento';

  @override
  String get infoRoutingFeesBody =>
      'Cuando otros nodos enrutan pagos a través de tu canal, ganas tarifas. Tarifa base (sat) cobrada por pago; tasa (ppm) proporcional al monto. El delta CLTV limita cuánto tiempo un HTLC reenviado puede tardar en liquidarse.';

  @override
  String get infoForceCloseTitle => 'Cierre forzado';

  @override
  String get infoForceCloseBody =>
      'Transmite tu último estado de canal on-chain. Es irreversible y requiere esperar el retardo hacia uno mismo antes de poder gastar tus fondos. Úsalo solo si tu peer no responde o es malicioso — el cierre cooperativo es siempre más rápido y económico.';

  @override
  String get infoPeersTitle => 'Peers conectados';

  @override
  String get infoPeersBody =>
      'Los peers son otros nodos Lightning con los que estás directamente conectado vía TCP/Tor. Cada peer puede tener uno o más canales. Puedes conectarte a nuevos peers para abrir canales y aumentar la liquidez y capacidad de enrutamiento de tu nodo.';

  @override
  String get infoNodeManagementTitle => 'Gestión del nodo';

  @override
  String get infoNodeManagementBody =>
      'La identidad de tu nodo Lightning: pubkey, versión, número de canales y peers activos/pendientes. Esta pantalla muestra datos contables del plugin bookkeeper del nodo y estadísticas de forwarding.';

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
  String get walletDetailAddress => 'Dirección';

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
  String get walletDetailTxExport => 'Exportar';

  @override
  String get walletDetailTxExportCsv => 'CSV (hoja de cálculo)';

  @override
  String walletDetailTxExportCopied(String fileName) {
    return 'Copiado al portapapeles ($fileName)';
  }

  @override
  String walletDetailTxExportDownloaded(String fileName) {
    return 'Descarga iniciada ($fileName)';
  }

  @override
  String get walletDetailTxExportFailed => 'No se pudo exportar';

  @override
  String get walletDetailTxExportJson => 'JSON (completo)';

  @override
  String get walletDetailTxFee => 'Comisión';

  @override
  String get walletDetailTxIncoming => 'Recibidos';

  @override
  String get walletDetailTxNote => 'Nota';

  @override
  String get walletDetailTxNoteAdd => 'Añadir nota';

  @override
  String get walletDetailTxNoteEdit => 'Editar nota';

  @override
  String get walletDetailTxNoteHint =>
      'Nota privada, guardada solo en este dispositivo';

  @override
  String get walletDetailTxNoteRemove => 'Quitar';

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
  String get sendScreenTitle => 'Enviar BTC';

  @override
  String get sendScreenAddressLabel => 'Dirección del destinatario';

  @override
  String get sendScreenAmountLabel => 'Cantidad (BTC)';

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
    return 'Esta Política de Privacidad es provisional y será sustituida por la versión definitiva publicada en el sitio web oficial cuando esté disponible.\n\n1) DATOS EN EL DISPOSITIVO. La aplicación no requiere una cuenta y no guarda datos personales en servidores del autor. La semilla cifrada (AES-256-GCM), las preferencias y los consentimientos permanecen SOLO en tu dispositivo.\n\n2) DATOS TRANSMITIDOS A TERCEROS PARA EL FUNCIONAMIENTO. Para mostrar el saldo y las comisiones, la aplicación consulta API públicas de terceros:\n• mempool.guide (explorador de blockchain).\n• Si mempool.guide no está disponible, la app puede consultar dos réplicas comunitarias compatibles con Esplora (mempool.kilombino.com, mempool.maveth.ca). Esta opción se puede desactivar en Ajustes.\nEn cada solicitud se transmiten tu dirección IP y la dirección pública del monedero consultado. Las claves privadas y la semilla NUNCA se transmiten.\n\n3) SIN RASTREADORES. Ninguna analítica, ninguna publicidad, ninguna cookie dentro de la aplicación.\n\n4) DERECHOS (GDPR arts. 13-14). Tienes derecho de acceso, rectificación, supresión y oposición escribiendo al responsable del tratamiento: $holder — $email. Dado que no almacenamos datos personales, estos derechos ya están garantizados en gran parte por el hecho de que los datos permanecen en tu dispositivo.';
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
  String get importScreenImport => 'Importar';

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
  String get passwordDialogCreateTitle => 'Crear contraseña de seguridad';

  @override
  String get passwordDialogCreateHint => 'Introduce una contraseña segura';

  @override
  String get passwordDialogCreateConfirm => 'Confirmar contraseña';

  @override
  String get passwordDialogCreate => 'Crear';

  @override
  String get passwordDialogCancel => 'Cancelar';

  @override
  String get passwordDialogEnterTitle => 'Introducir contraseña';

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
  String get lightningConnectRecentNodes => 'Nodos recientes';

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

  @override
  String get walletAddressesTitle => 'Direcciones y UTXO';

  @override
  String get walletAddressesTabAddresses => 'Direcciones';

  @override
  String get walletAddressesTabUtxos => 'UTXO';

  @override
  String get walletAddressesReceiveBranch => 'Recepción (/0)';

  @override
  String get walletAddressesChangeBranch => 'Cambio (/1)';

  @override
  String get walletAddressesStatusUnused => 'Nunca usada';

  @override
  String get walletAddressesStatusUsed => 'Usada';

  @override
  String get walletAddressesStatusFunds => 'Con saldo';

  @override
  String walletAddressesTxCount(int count) {
    return '$count transacciones';
  }

  @override
  String get walletAddressesEmpty => 'No hay direcciones que mostrar';

  @override
  String get walletAddressesHintTap => 'Toca una dirección para copiarla';

  @override
  String get lightningPeeringGateTitle =>
      'Peering limitado a las versiones con bit 68';

  @override
  String get lightningPeeringGateBody =>
      'Este nodo exige option_blake2b (bit 68) en el handshake: los nodos con versiones anteriores no pueden conectarse. Es una decisión del nodo, no un problema de la app ni del bridge. Usa pares con versión .4 o posterior, o espera a que la comunidad haga el bit opcional.';

  @override
  String get lightningPeeringGateLink => 'Matriz de compatibilidad';

  @override
  String lightningPeersRegisteredOnly(int count) {
    return '$count pares registrados, ninguno conectado';
  }

  @override
  String get lightningSwapOpen => 'Paga una factura sin nodo (swap)';

  @override
  String get lightningSwapWebOnlyNote =>
      'App web: los pagos Lightning usan un proveedor de swap (sin nodo). La conexión a tu propio nodo está disponible en la app de Android.';

  @override
  String get lightningSwapTitle => 'Pago Lightning vía proveedor';

  @override
  String get lightningSwapIntro =>
      'Los fondos siguen en tu custodia: van a un HTLC on-chain (P2WSH) y se liberan solo cuando el proveedor paga tu factura. Si el pago falla, puedes recuperar los fondos tras el time lock.';

  @override
  String get lightningSwapProviderUriHint =>
      'URI del proveedor (nostr+swap://...)';

  @override
  String get lightningSwapProviderConnect => 'Conectar proveedor';

  @override
  String lightningSwapProviderConnected(String pubkey) {
    return 'Proveedor conectado: $pubkey';
  }

  @override
  String get lightningSwapProviderDisconnect => 'Desconectar';

  @override
  String get lightningSwapInvoiceHint => 'Factura Lightning (lnbc...)';

  @override
  String get lightningSwapStart => 'Continuar';

  @override
  String get lightningSwapAmount => 'Importe de la factura';

  @override
  String get lightningSwapFees => 'Comisiones (claim + servicio)';

  @override
  String get lightningSwapTotal => 'Total a bloquear';

  @override
  String get lightningSwapFund => 'Enviar fondos e iniciar el swap';

  @override
  String get lightningSwapFundHint =>
      'Los fondos van a la dirección HTLC de arriba. El pago comienza tras 1 confirmación.';

  @override
  String get lightningSwapStateLabel => 'Estado';

  @override
  String get lightningSwapHtlc => 'Dirección HTLC';

  @override
  String lightningSwapCltv(int height) {
    return 'Refund disponible desde el bloque $height';
  }

  @override
  String get swapStateAwaitingFunding => 'Esperando fondos on-chain';

  @override
  String get swapStateConfirming => 'Esperando confirmaciones';

  @override
  String get swapStatePaying => 'Pago Lightning en curso';

  @override
  String get swapStatePaid => 'Factura pagada, claim en curso';

  @override
  String get swapStateClaiming => 'Claim en curso';

  @override
  String get swapStateCompleted => 'Completado';

  @override
  String get swapStatePaymentFailed => 'Pago fallido — fondos recuperables';

  @override
  String get swapStateExpired => 'Expirado — fondos recuperables';

  @override
  String get swapStateRefunded => 'Reembolsado';

  @override
  String get lightningSwapRecoveryTitle => 'Recuperación de fondos';

  @override
  String get lightningSwapRecoveryHint =>
      'Blob de recuperación (swaprecover1....)';

  @override
  String get lightningSwapRecoveryImport => 'Importar sesión';

  @override
  String get lightningSwapRefund => 'Recuperar fondos (refund)';

  @override
  String lightningSwapRefundNotYet(int height) {
    return 'Reembolso aún no disponible: se habilita desde el bloque $height';
  }

  @override
  String get lightningSwapCopyBlob => 'Copiar blob de recuperación';

  @override
  String get lightningSwapBlobCopied => 'Blob de recuperación copiado';

  @override
  String get lightningSwapClaimTxid => 'Txid del claim';

  @override
  String get lightningSwapClaimHint =>
      'El claim es una transacción on-chain: se confirma con el bloque siguiente (~12 min). Toca el enlace para verificarla.';

  @override
  String get lightningSwapInvalidInvoice =>
      'Esto no parece una factura Lightning';

  @override
  String get lightningSwapWatchOnly =>
      'El swap necesita una cartera con seed (no watch-only)';

  @override
  String get lightningSwapNoUtxos => 'Sin fondos gastables en esta cartera';

  @override
  String lightningSwapErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get lightningSwapKnownUris => 'URIs de proveedor guardadas';

  @override
  String get lightningSwapWalletLabel => 'Cartera';

  @override
  String lightningSwapWalletBalance(String balance) {
    return 'Saldo: $balance sat';
  }

  @override
  String lightningSwapInsufficientFunds(String needed, String available) {
    return 'Fondos insuficientes: se necesitan $needed sat, disponibles $available sat';
  }

  @override
  String get lightningSwapCancel => 'Cancelar swap';

  @override
  String get lightningSwapErrorConnectFailed =>
      'No se pudo contactar con el proveedor. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get lightningSwapErrorDisconnected =>
      'Se perdió la conexión con el proveedor. Vuelve a conectarte.';

  @override
  String get lightningSwapErrorNotConnected => 'Proveedor no conectado.';

  @override
  String get lightningSwapErrorRelayNotAllowed =>
      'Este proveedor usa un relé que la versión web no puede alcanzar. Usa la versión móvil en el teléfono para pagar con este proveedor.';

  @override
  String get lightningSwapCancelTitle => '¿Cancelar este swap?';

  @override
  String get lightningSwapCancelBody =>
      'La app olvidará este swap. El proveedor lo descarta solo antes del vencimiento y no hay fondos bloqueados. Para reintentar con la misma factura necesitas una sesión nueva solo tras expirar; si no, genera una factura nueva.';

  @override
  String get lightningSwapCancelConfirm => 'Sí, cancelar';

  @override
  String get lightningSwapWalletMissing =>
      'La cartera ligada a este swap ya no está disponible';

  @override
  String lightningSwapBoundWallet(String name) {
    return 'Cartera ligada: $name';
  }

  @override
  String get lightningInvoiceDelete => 'Eliminar factura';

  @override
  String get lightningInvoiceDeleteTitle => '¿Eliminar esta factura?';

  @override
  String get lightningInvoiceDeleteBody =>
      'La factura se eliminará del nodo. Si no está pagada, ya no podrá pagarse.';

  @override
  String get lightningInvoiceDeleteConfirm => 'Sí, eliminar';

  @override
  String get lightningInvoiceDeleted => 'Factura eliminada';

  @override
  String get lightningChannelPeerAddress => 'Dirección del par';
}
