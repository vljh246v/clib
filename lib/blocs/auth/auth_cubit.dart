import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/auth/auth_state.dart';
import 'package:clib/services/auth_service.dart';
import 'package:clib/services/sync_service.dart';

/// `FirebaseAuth.authStateChanges` 구독을 소유하고, 로그인/로그아웃 전이 시
/// `SyncService.init/dispose` 사이드이펙트까지 일괄 관리한다.
///
/// 첫 구독 시 Firebase가 현재 사용자를 즉시 재발행하므로, main에서
/// 별도 currentUser 초기화 로직은 필요 없다. 단, `lazy: false`로
/// MultiBlocProvider에 등록해 UI 첫 참조 전에 구독이 시작되어야 한다.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState()) {
    _sub = AuthService.authStateChanges.listen(_onAuthChanged);
  }

  late final StreamSubscription<User?> _sub;

  Future<void> _onAuthChanged(User? user) async {
    // SyncService.init 내부 Hive/Firestore 예외가 Stream.listen으로 삼켜지지 않도록
    // 명시적으로 로깅하고, 예외 여부와 무관하게 isInitialized=true를 emit해
    // UI가 로그인/로그아웃 분기를 보류하는 상태에 영구히 머물지 않도록 한다.
    try {
      if (user != null) {
        await SyncService.init(user);
      } else {
        SyncService.dispose();
      }
    } catch (e, st) {
      debugPrint('AuthCubit SyncService 전이 실패: $e');
      debugPrint('$st');
    }
    emit(state.copyWith(
      user: user,
      setUserNull: user == null,
      isInitialized: true,
    ));
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.signInWithGoogle();
    } finally {
      if (!isClosed) emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.signInWithApple();
    } finally {
      if (!isClosed) emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.signOut();
    } finally {
      if (!isClosed) emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.deleteAccount();
    } finally {
      if (!isClosed) emit(state.copyWith(isBusy: false));
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    SyncService.dispose();
    return super.close();
  }
}
