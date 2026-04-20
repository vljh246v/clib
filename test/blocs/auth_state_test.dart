import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clib/blocs/auth/auth_state.dart';

/// `props`가 `user?.uid`만 사용하므로 uid만 구현한 최소 fake로 충분.
/// 다른 User 메서드가 호출되면 noSuchMethod에서 즉시 실패시켜 의도치 않은 접근을 잡는다.
class _FakeUser implements User {
  @override
  final String uid;
  _FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fake User: ${invocation.memberName}');
}

void main() {
  test('기본 상태는 user=null, isInitialized=false, isBusy=false', () {
    const state = AuthState();
    expect(state.user, isNull);
    expect(state.isInitialized, false);
    expect(state.isBusy, false);
    expect(state.isLoggedIn, false);
  });

  test('copyWith(isInitialized: true)는 isInitialized만 바꾼다', () {
    const s1 = AuthState();
    final s2 = s1.copyWith(isInitialized: true);
    expect(s2.isInitialized, true);
    expect(s2.user, isNull);
    expect(s2.isBusy, false);
  });

  test('copyWith(isBusy: true)는 isBusy만 바꾼다', () {
    const s1 = AuthState(isInitialized: true);
    final s2 = s1.copyWith(isBusy: true);
    expect(s2.isBusy, true);
    expect(s2.isInitialized, true);
    expect(s2.user, isNull);
  });

  test('copyWith(user: ...)는 user를 설정하고 isLoggedIn이 true가 된다', () {
    const s1 = AuthState(isInitialized: true);
    final user = _FakeUser('uid-1');
    final s2 = s1.copyWith(user: user);
    expect(s2.user, same(user));
    expect(s2.isLoggedIn, true);
    expect(s2.isInitialized, true);
  });

  test('copyWith(setUserNull: true)는 기존 user를 null로 명시적으로 지운다', () {
    final s1 = AuthState(user: _FakeUser('uid-1'), isInitialized: true);
    final s2 = s1.copyWith(setUserNull: true);
    expect(s2.user, isNull);
    expect(s2.isLoggedIn, false);
    expect(s2.isInitialized, true);
  });

  test('setUserNull 없이 user 파라미터를 생략하면 기존 user가 유지된다', () {
    final s1 = AuthState(user: _FakeUser('uid-1'), isInitialized: true);
    final s2 = s1.copyWith(isBusy: true);
    expect(s2.user, same(s1.user));
    expect(s2.isBusy, true);
  });

  test('같은 uid를 가진 user 두 상태는 equal (User 객체 자체가 아닌 uid로 비교)', () {
    final s1 = AuthState(user: _FakeUser('uid-1'), isInitialized: true);
    final s2 = AuthState(user: _FakeUser('uid-1'), isInitialized: true);
    expect(s1, equals(s2));
    expect(s1.hashCode, s2.hashCode);
  });

  test('다른 uid면 not equal', () {
    final s1 = AuthState(user: _FakeUser('uid-1'), isInitialized: true);
    final s2 = AuthState(user: _FakeUser('uid-2'), isInitialized: true);
    expect(s1, isNot(equals(s2)));
  });

  test('isInitialized만 다르면 not equal', () {
    const s1 = AuthState();
    const s2 = AuthState(isInitialized: true);
    expect(s1, isNot(equals(s2)));
  });

  test('isBusy만 다르면 not equal', () {
    const s1 = AuthState(isInitialized: true);
    const s2 = AuthState(isInitialized: true, isBusy: true);
    expect(s1, isNot(equals(s2)));
  });
}
