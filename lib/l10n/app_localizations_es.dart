// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get save => 'Guardar';

  @override
  String get saveFailed => 'Error al guardar. Inténtalo de nuevo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Aceptar';

  @override
  String get add => 'Añadir';

  @override
  String get edit => 'Editar';

  @override
  String get select => 'Seleccionar';

  @override
  String get bookmark => 'Marcador';

  @override
  String get removeBookmark => 'Quitar marcador';

  @override
  String get memo => 'Nota';

  @override
  String get editMemo => 'Editar nota';

  @override
  String get addMemo => 'Añadir nota';

  @override
  String get memoHint => 'Escribe una nota breve';

  @override
  String get label => 'Etiqueta';

  @override
  String get editLabelAction => 'Editar etiquetas';

  @override
  String get labelManagement => 'Gestionar etiquetas';

  @override
  String get labelManagementSubtitle =>
      'Añadir, editar, eliminar etiquetas y configurar notificaciones';

  @override
  String get addNewLabel => 'Añadir nueva etiqueta';

  @override
  String get newLabel => 'Nueva etiqueta';

  @override
  String get addNewLabelTitle => 'Añadir nueva etiqueta';

  @override
  String get addLabelTitle => 'Añadir etiqueta';

  @override
  String get editLabelTitle => 'Editar etiqueta';

  @override
  String get labelName => 'Nombre de etiqueta';

  @override
  String get labelNameHint => 'Ej. Flutter, Diseño';

  @override
  String get color => 'Color';

  @override
  String get createLabelPrompt => 'Crea etiquetas para organizar tus artículos';

  @override
  String get addLabelsFirst => 'Primero añade etiquetas en Ajustes';

  @override
  String get deleteLabel => 'Eliminar etiqueta';

  @override
  String deleteLabelConfirm(String name, int count) {
    return '¿Eliminar la etiqueta \'\'$name\'\'?\nEsta etiqueta se eliminará de $count artículos.';
  }

  @override
  String get allArticles => 'Todos los artículos';

  @override
  String articleCountText(int count) {
    return '$count artículos';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count artículos';
  }

  @override
  String get noArticles => 'No hay artículos.';

  @override
  String get noReadArticles => 'No hay artículos leídos.';

  @override
  String get noUnreadArticles => 'No hay artículos sin leer.';

  @override
  String get deleteArticle => 'Eliminar artículo';

  @override
  String get deleteArticleConfirm => '¿Eliminar este artículo?';

  @override
  String deleteSelectedConfirm(int count) {
    return '¿Eliminar $count artículos seleccionados?';
  }

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get read => 'Leído';

  @override
  String get unread => 'Sin leer';

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get markAsUnread => 'Marcar como no leído';

  @override
  String tabAll(int count) {
    return 'Todo ($count)';
  }

  @override
  String tabUnread(int count) {
    return 'Sin leer ($count)';
  }

  @override
  String tabRead(int count) {
    return 'Leído ($count)';
  }

  @override
  String totalAll(int count) {
    return 'Total $count';
  }

  @override
  String totalUnread(int count) {
    return 'Sin leer $count';
  }

  @override
  String get library => 'Biblioteca';

  @override
  String get labelStatus => 'Etiquetas';

  @override
  String get overallReadingStatus => 'Progreso general';

  @override
  String articlesRead(int read, int total) {
    return '$read / $total artículos leídos';
  }

  @override
  String labelCount(int count) {
    return '$count etiquetas';
  }

  @override
  String get all => 'Todo';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get noBookmarks => 'No hay artículos marcados.';

  @override
  String get noReadBookmarks => 'No hay marcadores leídos.';

  @override
  String get noUnreadBookmarks => 'No hay marcadores sin leer.';

  @override
  String get noArticlesToSwipe => 'No hay artículos para deslizar';

  @override
  String get addLinksHint =>
      '¡Comparte enlaces desde otras apps para añadirlos!';

  @override
  String get noUnreadInLabel =>
      'No hay artículos sin leer en las etiquetas seleccionadas';

  @override
  String get openInBrowser => 'Abrir en navegador';

  @override
  String get settings => 'Ajustes';

  @override
  String get theme => 'Tema';

  @override
  String get howToUse => 'Cómo usar';

  @override
  String get howToUseSubtitle => 'Revisa cómo usar Clib';

  @override
  String get systemSettings => 'Predeterminado del sistema';

  @override
  String get systemSettingsSubtitle =>
      'Sigue automáticamente los ajustes del dispositivo';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get onboardingSaveTitle => 'Guarda tus enlaces';

  @override
  String get onboardingSaveSubtitle =>
      'Recopila artículos de cualquier lugar\ncon un solo botón de compartir';

  @override
  String get onboardingSaveHint =>
      'Comparte desde el navegador, redes sociales, YouTube → Clib';

  @override
  String get onboardingSwipeTitle => 'Desliza para leer';

  @override
  String get onboardingSwipeSubtitle =>
      'Pasa las tarjetas para decidir qué leer';

  @override
  String get onboardingSwipeHint =>
      'Derecha → Leído  ·  Izquierda → Leer después';

  @override
  String get onboardingLibraryTitle => 'Tu biblioteca personal';

  @override
  String get onboardingLibrarySubtitle =>
      'Organiza con etiquetas, revisita con recordatorios';

  @override
  String get onboardingLibraryHint => 'De solo guardar a realmente leer';

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get start => 'Comenzar';

  @override
  String labelNotification(String name) {
    return 'Notificaciones de $name';
  }

  @override
  String get receiveNotification => 'Activar notificaciones';

  @override
  String get daysOfWeek => 'Días';

  @override
  String get selectTime => 'Seleccionar hora';

  @override
  String get time => 'Hora';

  @override
  String get notificationChannelName => 'Notificaciones de etiquetas de Clib';

  @override
  String get notificationChannelDesc =>
      'Notificaciones de artículos no leídos por etiqueta';

  @override
  String unreadNotification(int count) {
    return '¡Tienes $count artículos sin leer!';
  }

  @override
  String get allReadNotification => '¡Todo leído! 🎉';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mié';

  @override
  String get dayThu => 'Jue';

  @override
  String get dayFri => 'Vie';

  @override
  String get daySat => 'Sáb';

  @override
  String get daySun => 'Dom';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get saveToClib => 'Guardar en Clib';

  @override
  String get editArticle => 'Editar artículo';

  @override
  String get platform => 'Plataforma';

  @override
  String articleStats(int total, int read) {
    return '$total artículos · $read leídos';
  }

  @override
  String get account => 'Cuenta';

  @override
  String get loginSubtitle =>
      'Inicia sesión para sincronizar entre dispositivos';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Cerrar sesión?';

  @override
  String get signOutDescription =>
      'Los datos en este dispositivo se conservarán.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirm => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountDescription =>
      'Se eliminarán todos los datos en la nube. Los datos en este dispositivo se conservarán.';

  @override
  String get loginFailed => 'Error al iniciar sesión';

  @override
  String get notificationDeviceOnly =>
      'Las notificaciones solo suenan en este dispositivo. Configúralas por separado en otros dispositivos.';

  @override
  String get addArticle => 'Añadir artículo';

  @override
  String get urlHint => 'Introduce la URL';

  @override
  String get invalidUrl => 'URL no válida';

  @override
  String get pasteFromClipboard => 'Pegar';

  @override
  String get swipeRead => 'LEÍDO';

  @override
  String get swipeLater => 'DESPUÉS';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicySubtitle => 'Recopilación y gestión de datos';

  @override
  String get loginPolicyAgreement =>
      'Al iniciar sesión, aceptas la Política de privacidad.';

  @override
  String get guideSwipeTitle => 'Desliza para leer';

  @override
  String get guideSwipeDesc =>
      'Desliza a la derecha para marcar como leído, a la izquierda para después';

  @override
  String get guideAddTitle => 'También puedes añadir enlaces';

  @override
  String get guideAddDesc =>
      'Introduce una URL para añadir un artículo directamente';

  @override
  String get guideLibraryTitle => 'Gestiona tu biblioteca';

  @override
  String get guideLibraryDesc =>
      'Consulta y organiza tus artículos por etiqueta';

  @override
  String get guideSettingsTitle => 'Ajusta a tu gusto';

  @override
  String get guideSettingsDesc =>
      'Gestiona etiquetas, cambia el tema y configura recordatorios';

  @override
  String get guideTapToContinue => 'Toca para continuar';
}
