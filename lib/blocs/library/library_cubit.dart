import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/state/app_notifiers.dart'
    show articlesChangedNotifier, labelsChangedNotifier;
import 'package:clib/services/database_service.dart';
import 'library_state.dart';

/// 라이브러리 화면 Cubit.
///
/// 두 전역 notifier(`articlesChangedNotifier`, `labelsChangedNotifier`)를 구독해
/// 외부에서 아티클/라벨이 바뀌면(공유 시트 저장, Firestore 스냅샷 머지 등)
/// 자동으로 재로드한다.
///
/// notifier는 로컬 DB 변경(`markAsRead`, `toggleBookmark`, `deleteArticle`,
/// 라벨 CRUD 등)을 트리거하지 않으므로, Navigator.push 후 pop 시점에는
/// 화면 측에서 명시적으로 [load]를 호출해야 stale 상태가 되지 않는다.
///
/// PR 11에서 notifier를 제거하면 이 브릿지도 걷어낸다.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState()) {
    articlesChangedNotifier.addListener(_onChanged);
    labelsChangedNotifier.addListener(_onChanged);
    load();
  }

  void _onChanged() => unawaited(load());

  Future<void> load() async {
    final labels = DatabaseService.getAllLabelObjects();
    final overall = DatabaseService.getOverallStats();
    final bookmark = DatabaseService.getBookmarkStats();
    final stats = <String, ({int total, int read})>{
      for (final l in labels) l.name: DatabaseService.getLabelStats(l.name),
    };
    emit(LibraryState(
      labels: labels,
      overall: overall,
      bookmark: bookmark,
      labelStats: stats,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() {
    articlesChangedNotifier.removeListener(_onChanged);
    labelsChangedNotifier.removeListener(_onChanged);
    return super.close();
  }
}
