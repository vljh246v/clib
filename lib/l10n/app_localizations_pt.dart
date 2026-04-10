// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get save => 'Salvar';

  @override
  String get saveFailed => 'Não foi possível salvar. Tente novamente.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get confirm => 'OK';

  @override
  String get add => 'Adicionar';

  @override
  String get edit => 'Editar';

  @override
  String get select => 'Selecionar';

  @override
  String get bookmark => 'Favorito';

  @override
  String get removeBookmark => 'Remover favorito';

  @override
  String get memo => 'Anotação';

  @override
  String get editMemo => 'Editar anotação';

  @override
  String get addMemo => 'Adicionar anotação';

  @override
  String get memoHint => 'Escreva uma anotação rápida';

  @override
  String get label => 'Etiqueta';

  @override
  String get editLabelAction => 'Editar etiquetas';

  @override
  String get labelManagement => 'Gerenciar etiquetas';

  @override
  String get labelManagementSubtitle =>
      'Adicione, edite, exclua etiquetas e configure lembretes';

  @override
  String get addNewLabel => 'Nova etiqueta';

  @override
  String get newLabel => 'Nova etiqueta';

  @override
  String get addNewLabelTitle => 'Nova etiqueta';

  @override
  String get addLabelTitle => 'Adicionar etiqueta';

  @override
  String get editLabelTitle => 'Editar etiqueta';

  @override
  String get labelName => 'Nome da etiqueta';

  @override
  String get labelNameHint => 'Ex.: Flutter, Design';

  @override
  String get color => 'Cor';

  @override
  String get createLabelPrompt => 'Crie etiquetas para organizar seus artigos';

  @override
  String get addLabelsFirst => 'Primeiro adicione etiquetas em Configurações';

  @override
  String get deleteLabel => 'Excluir etiqueta';

  @override
  String deleteLabelConfirm(String name, int count) {
    return 'Excluir a etiqueta \'\'$name\'\'?\nEla será removida de $count artigos.';
  }

  @override
  String get allArticles => 'Todos os artigos';

  @override
  String articleCountText(int count) {
    return '$count artigos';
  }

  @override
  String labelArticleCountText(String labels, int count) {
    return '$labels · $count artigos';
  }

  @override
  String get noArticles => 'Nenhum artigo por aqui.';

  @override
  String get noReadArticles => 'Nenhum artigo lido.';

  @override
  String get noUnreadArticles => 'Nenhum artigo pendente.';

  @override
  String get deleteArticle => 'Excluir artigo';

  @override
  String get deleteArticleConfirm =>
      'Tem certeza que quer excluir este artigo?';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Excluir os $count artigos selecionados?';
  }

  @override
  String selectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get read => 'Lido';

  @override
  String get unread => 'Não lido';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get markAsUnread => 'Marcar como não lido';

  @override
  String tabAll(int count) {
    return 'Todos ($count)';
  }

  @override
  String tabUnread(int count) {
    return 'Não lidos ($count)';
  }

  @override
  String tabRead(int count) {
    return 'Lidos ($count)';
  }

  @override
  String totalAll(int count) {
    return 'Total $count';
  }

  @override
  String totalUnread(int count) {
    return 'Não lidos $count';
  }

  @override
  String get library => 'Biblioteca';

  @override
  String get labelStatus => 'Etiquetas';

  @override
  String get overallReadingStatus => 'Progresso geral';

  @override
  String articlesRead(int read, int total) {
    return '$read de $total artigos lidos';
  }

  @override
  String labelCount(int count) {
    return '$count etiquetas';
  }

  @override
  String get all => 'Todos';

  @override
  String get bookmarks => 'Favoritos';

  @override
  String get noBookmarks => 'Nenhum artigo nos favoritos.';

  @override
  String get noReadBookmarks => 'Nenhum favorito lido.';

  @override
  String get noUnreadBookmarks => 'Nenhum favorito pendente.';

  @override
  String get noArticlesToSwipe => 'Sem artigos para deslizar';

  @override
  String get addLinksHint =>
      'Compartilhe links de outros apps para adicioná-los!';

  @override
  String get noUnreadInLabel =>
      'Nenhum artigo pendente nas etiquetas selecionadas';

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get settings => 'Configurações';

  @override
  String get theme => 'Tema';

  @override
  String get howToUse => 'Como usar';

  @override
  String get howToUseSubtitle => 'Veja como aproveitar o Clib';

  @override
  String get systemSettings => 'Padrão do sistema';

  @override
  String get systemSettingsSubtitle =>
      'Acompanha automaticamente o tema do dispositivo';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get onboardingSaveTitle => 'Salve seus links';

  @override
  String get onboardingSaveSubtitle =>
      'Colete artigos de qualquer lugar\ncom um toque no botão de compartilhar';

  @override
  String get onboardingSaveHint =>
      'Compartilhe do navegador, redes sociais, YouTube → Clib';

  @override
  String get onboardingSwipeTitle => 'Deslize para ler';

  @override
  String get onboardingSwipeSubtitle => 'Passe os cards para decidir o que ler';

  @override
  String get onboardingSwipeHint => 'Direita → Lido  ·  Esquerda → Ler depois';

  @override
  String get onboardingLibraryTitle => 'Sua biblioteca pessoal';

  @override
  String get onboardingLibrarySubtitle =>
      'Organize com etiquetas, revisite com lembretes';

  @override
  String get onboardingLibraryHint => 'De só salvar para realmente ler';

  @override
  String get skip => 'Pular';

  @override
  String get next => 'Próximo';

  @override
  String get start => 'Começar';

  @override
  String labelNotification(String name) {
    return 'Lembretes de $name';
  }

  @override
  String get receiveNotification => 'Ativar lembretes';

  @override
  String get daysOfWeek => 'Dias';

  @override
  String get selectTime => 'Escolher horário';

  @override
  String get time => 'Horário';

  @override
  String get notificationChannelName => 'Lembretes do Clib';

  @override
  String get notificationChannelDesc =>
      'Lembretes de artigos não lidos por etiqueta';

  @override
  String unreadNotification(int count) {
    return 'Você tem $count artigos esperando por você!';
  }

  @override
  String get allReadNotification => 'Tudo lido! 🎉';

  @override
  String get dayMon => 'Seg';

  @override
  String get dayTue => 'Ter';

  @override
  String get dayWed => 'Qua';

  @override
  String get dayThu => 'Qui';

  @override
  String get dayFri => 'Sex';

  @override
  String get daySat => 'Sáb';

  @override
  String get daySun => 'Dom';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String daysAgo(int count) {
    return '$count dias atrás';
  }

  @override
  String get saveToClib => 'Salvar no Clib';

  @override
  String get editArticle => 'Editar artigo';

  @override
  String get platform => 'Plataforma';

  @override
  String articleStats(int total, int read) {
    return '$total artigos · $read lidos';
  }

  @override
  String get account => 'Conta';

  @override
  String get loginSubtitle => 'Entre para sincronizar entre dispositivos';

  @override
  String get signInWithGoogle => 'Entrar com Google';

  @override
  String get signInWithApple => 'Entrar com Apple';

  @override
  String get signOut => 'Sair';

  @override
  String get signOutConfirm => 'Tem certeza que quer sair?';

  @override
  String get signOutDescription =>
      'Seus dados neste dispositivo serão mantidos.';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountConfirm => 'Tem certeza que quer excluir sua conta?';

  @override
  String get deleteAccountDescription =>
      'Todos os dados na nuvem serão apagados. Os dados neste dispositivo serão mantidos.';

  @override
  String get syncComplete => 'Sincronizado';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get loginFailed => 'Não foi possível entrar';

  @override
  String get notificationDeviceOnly =>
      'Os lembretes só funcionam neste dispositivo. Configure separadamente nos outros.';

  @override
  String get addArticle => 'Adicionar artigo';

  @override
  String get urlHint => 'Cole o link aqui';

  @override
  String get invalidUrl => 'Link inválido';

  @override
  String get pasteFromClipboard => 'Colar';

  @override
  String get swipeRead => 'LIDO';

  @override
  String get swipeLater => 'DEPOIS';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get privacyPolicySubtitle => 'Coleta e uso de dados';

  @override
  String get loginPolicyAgreement =>
      'Ao entrar, você concorda com a Política de Privacidade.';
}
