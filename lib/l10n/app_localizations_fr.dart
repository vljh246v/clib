// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get save => 'Enregistrer';

  @override
  String get saveFailed => 'Échec de l\'enregistrement. Réessayez.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'OK';

  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get select => 'Sélectionner';

  @override
  String get bookmark => 'Favori';

  @override
  String get removeBookmark => 'Retirer des favoris';

  @override
  String get memo => 'Note';

  @override
  String get editMemo => 'Modifier la note';

  @override
  String get addMemo => 'Ajouter une note';

  @override
  String get memoHint => 'Rédigez une courte note';

  @override
  String get label => 'Étiquette';

  @override
  String get editLabelAction => 'Modifier les étiquettes';

  @override
  String get labelManagement => 'Gérer les étiquettes';

  @override
  String get labelManagementSubtitle =>
      'Ajoutez, modifiez, supprimez des étiquettes et configurez les rappels';

  @override
  String get addNewLabel => 'Nouvelle étiquette';

  @override
  String get newLabel => 'Nouvelle étiquette';

  @override
  String get addNewLabelTitle => 'Nouvelle étiquette';

  @override
  String get addLabelTitle => 'Ajouter une étiquette';

  @override
  String get editLabelTitle => 'Modifier l\'étiquette';

  @override
  String get labelName => 'Nom de l\'étiquette';

  @override
  String get labelNameHint => 'Ex. : Flutter, Design';

  @override
  String get color => 'Couleur';

  @override
  String get createLabelPrompt =>
      'Créez des étiquettes pour classer vos articles';

  @override
  String get addLabelsFirst =>
      'Ajoutez d\'abord des étiquettes dans les réglages';

  @override
  String get deleteLabel => 'Supprimer l\'étiquette';

  @override
  String deleteLabelConfirm(String name, int count) {
    return 'Supprimer l\'étiquette « $name » ?\nElle sera retirée de $count articles.';
  }

  @override
  String get allArticles => 'Tous les articles';

  @override
  String articleCountText(int count) {
    return '$count articles';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count articles';
  }

  @override
  String get noArticles => 'Aucun article pour le moment.';

  @override
  String get noReadArticles => 'Aucun article lu.';

  @override
  String get noUnreadArticles => 'Aucun article non lu.';

  @override
  String get deleteArticle => 'Supprimer l\'article';

  @override
  String get deleteArticleConfirm => 'Supprimer cet article ?';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Supprimer les $count articles sélectionnés ?';
  }

  @override
  String selectedCount(int count) {
    return '$count sélectionnés';
  }

  @override
  String get read => 'Lu';

  @override
  String get unread => 'Non lu';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get markAsUnread => 'Marquer comme non lu';

  @override
  String tabAll(int count) {
    return 'Tout ($count)';
  }

  @override
  String tabUnread(int count) {
    return 'Non lus ($count)';
  }

  @override
  String tabRead(int count) {
    return 'Lus ($count)';
  }

  @override
  String totalAll(int count) {
    return 'Total $count';
  }

  @override
  String totalUnread(int count) {
    return 'Non lus $count';
  }

  @override
  String get library => 'Bibliothèque';

  @override
  String get labelStatus => 'Étiquettes';

  @override
  String get overallReadingStatus => 'Progression';

  @override
  String articlesRead(int read, int total) {
    return '$read / $total articles lus';
  }

  @override
  String labelCount(int count) {
    return '$count étiquettes';
  }

  @override
  String get all => 'Tout';

  @override
  String get bookmarks => 'Favoris';

  @override
  String get noBookmarks => 'Aucun article en favoris.';

  @override
  String get noReadBookmarks => 'Aucun favori lu.';

  @override
  String get noUnreadBookmarks => 'Aucun favori non lu.';

  @override
  String get noArticlesToSwipe => 'Plus d\'articles à parcourir';

  @override
  String get addLinksHint =>
      'Partagez des liens depuis d\'autres apps pour les ajouter !';

  @override
  String get noUnreadInLabel =>
      'Aucun article non lu dans les étiquettes sélectionnées';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get settings => 'Réglages';

  @override
  String get theme => 'Thème';

  @override
  String get howToUse => 'Mode d\'emploi';

  @override
  String get howToUseSubtitle => 'Découvrez comment utiliser Clib';

  @override
  String get systemSettings => 'Réglage système';

  @override
  String get systemSettingsSubtitle =>
      'S\'adapte automatiquement au thème de l\'appareil';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get onboardingSaveTitle => 'Sauvegardez vos liens';

  @override
  String get onboardingSaveSubtitle =>
      'Collectez des articles de partout\nen un seul geste';

  @override
  String get onboardingSaveHint =>
      'Depuis le navigateur, les réseaux sociaux, YouTube → Clib';

  @override
  String get onboardingSwipeTitle => 'Balayez pour lire';

  @override
  String get onboardingSwipeSubtitle =>
      'Faites défiler les cartes pour choisir quoi lire';

  @override
  String get onboardingSwipeHint => 'Droite → Lu  ·  Gauche → Plus tard';

  @override
  String get onboardingLibraryTitle => 'Votre bibliothèque perso';

  @override
  String get onboardingLibrarySubtitle =>
      'Classez avec des étiquettes, revenez grâce aux rappels';

  @override
  String get onboardingLibraryHint =>
      'Passez du simple enregistrement à la lecture';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get start => 'C\'est parti';

  @override
  String labelNotification(String name) {
    return 'Rappels pour $name';
  }

  @override
  String get receiveNotification => 'Activer les rappels';

  @override
  String get daysOfWeek => 'Jours';

  @override
  String get selectTime => 'Choisir l\'heure';

  @override
  String get time => 'Heure';

  @override
  String get notificationChannelName => 'Rappels Clib';

  @override
  String get notificationChannelDesc =>
      'Rappels d\'articles non lus par étiquette';

  @override
  String unreadNotification(int count) {
    return 'Il vous reste $count articles à lire !';
  }

  @override
  String get allReadNotification => 'Tout est lu ! 🎉';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mer';

  @override
  String get dayThu => 'Jeu';

  @override
  String get dayFri => 'Ven';

  @override
  String get daySat => 'Sam';

  @override
  String get daySun => 'Dim';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String daysAgo(int count) {
    return 'Il y a $count j';
  }

  @override
  String get saveToClib => 'Enregistrer dans Clib';

  @override
  String get editArticle => 'Modifier l\'article';

  @override
  String get platform => 'Plateforme';

  @override
  String articleStats(int total, int read) {
    return '$total articles · $read lus';
  }

  @override
  String get account => 'Compte';

  @override
  String get loginSubtitle => 'Connectez-vous pour synchroniser vos appareils';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Vous déconnecter ?';

  @override
  String get signOutDescription =>
      'Vos données sur cet appareil seront conservées.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirm => 'Supprimer votre compte ?';

  @override
  String get deleteAccountDescription =>
      'Toutes les données dans le cloud seront supprimées. Les données sur cet appareil seront conservées.';

  @override
  String get syncComplete => 'Synchronisé';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get notificationDeviceOnly =>
      'Les rappels ne sonnent que sur cet appareil. Configurez-les séparément sur vos autres appareils.';

  @override
  String get addArticle => 'Ajouter un article';

  @override
  String get urlHint => 'Collez le lien ici';

  @override
  String get invalidUrl => 'Lien invalide';

  @override
  String get pasteFromClipboard => 'Coller';

  @override
  String get swipeRead => 'LU';

  @override
  String get swipeLater => 'PLUS TARD';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicySubtitle => 'Collecte et gestion des données';

  @override
  String get loginPolicyAgreement =>
      'En vous connectant, vous acceptez la politique de confidentialité.';
}
