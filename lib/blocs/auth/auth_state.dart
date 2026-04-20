import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Auth 전역 상태.
///
/// - [user]: 현재 로그인된 Firebase User. null이면 로그아웃 상태.
/// - [isInitialized]: `authStateChanges`의 첫 이벤트 수신 여부.
///   초기값(false) 동안에는 UI에서 로그인/로그아웃 분기를 보류해야 한다.
/// - [isBusy]: 로그인/로그아웃/계정 삭제 진행 중 플래그. 버튼 로딩 표시용.
class AuthState extends Equatable {
  final User? user;
  final bool isInitialized;
  final bool isBusy;

  const AuthState({
    this.user,
    this.isInitialized = false,
    this.isBusy = false,
  });

  bool get isLoggedIn => user != null;

  /// [setUserNull]=true 이면 user를 명시적으로 null로 설정한다.
  /// `User?` 파라미터만으로는 "변경 없음"과 "null로 설정"을 구분할 수 없어서 필요.
  AuthState copyWith({
    User? user,
    bool setUserNull = false,
    bool? isInitialized,
    bool? isBusy,
  }) {
    return AuthState(
      user: setUserNull ? null : (user ?? this.user),
      isInitialized: isInitialized ?? this.isInitialized,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [user?.uid, isInitialized, isBusy];
}
