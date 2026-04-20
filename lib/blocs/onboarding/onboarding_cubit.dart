import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/services/database_service.dart';

/// 온보딩 페이지 인덱스(0~2) 상태.
///
/// state가 단순 `int`라 별도 state 클래스 없이 `Cubit<int>` 패턴 사용
/// (ThemeCubit과 동일).
class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  void setPage(int page) {
    if (state != page) emit(page);
  }

  Future<void> complete() async {
    await DatabaseService.setOnboardingComplete();
  }
}
