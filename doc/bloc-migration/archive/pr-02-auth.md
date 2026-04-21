# PR 2 — AuthCubit

> `FirebaseAuth.authStateChanges`를 AuthCubit 내부로 이동하고, 로그인/로그아웃에 따른 `SyncService.init/dispose()` 사이드이펙트도 Cubit이 관리하도록 한다. `authStateNotifier`를 제거한다.

**의존성**: PR 1 (flutter_bloc 도입됨)
**브랜치**: `feature/bloc-02-auth`
**예상 작업 시간**: 2~3시간
**난이도**: ⭐⭐

---

## 1. 목표

- `lib/blocs/auth/auth_cubit.dart` + `auth_state.dart` 신규
- `AuthService.authStateChanges` 구독 → `User?` 상태 emit
- 로그인/로그아웃 시 `SyncService.init(user)` / `SyncService.dispose()` 호출 책임 이동
- `authStateNotifier` 전역 변수 제거
- `main.dart`의 직접 `FirebaseAuth.authStateChanges().listen(...)` 제거
- `SettingsScreen`의 `ValueListenableBuilder<User?>` → `BlocBuilder<AuthCubit, AuthState>` 교체
- AuthCubit 유닛 테스트

---

## 2. 사전 요건

| 파일 | 용도 | 범위 |
|------|------|------|
| `lib/main.dart` | L32 `authStateNotifier` 제거, L62-73 authStateChanges listen 제거, MultiBlocProvider에 AuthCubit 추가 | 전체 |
| `lib/services/auth_service.dart` | 기존 메서드 시그니처 확인 (97 LOC) | 전체 |
| `lib/services/sync_service.dart:28-60` | init/dispose 시그니처 | |
| `lib/screens/settings_screen.dart` | ValueListenableBuilder 대체 | 전체 (439 LOC) |

**핵심 사실**:
- `AuthService.authStateChanges`는 `Stream<User?>` (Firebase Auth 래핑).
- `AuthService.signInWithGoogle/Apple/signOut/deleteAccount` 모두 Future.
- `SyncService.init(User)`은 로그인된 사용자 필요, `dispose()`는 파라미터 없음.

---

## 3. AuthState 설계

`lib/blocs/auth/auth_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState extends Equatable {
  final User? user;
  final bool isInitialized;   // authStateChanges의 첫 이벤트 수신 여부
  final bool isBusy;          // 로그인/로그아웃/삭제 진행 중

  const AuthState({
    this.user,
    this.isInitialized = false,
    this.isBusy = false,
  });

  bool get isLoggedIn => user != null;

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
```

**주의**: `User`는 nullable이라 `copyWith`에서 null로 초기화하려면 `setUserNull` 플래그 사용. props에는 `user?.uid`만 포함(User 객체 전체는 equatable 비교 불가).

## 4. AuthCubit 구현

`lib/blocs/auth/auth_cubit.dart`:

```dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState()) {
    _sub = AuthService.authStateChanges.listen(_onAuthChanged);
  }

  late final StreamSubscription<User?> _sub;

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await SyncService.init(user);
    } else {
      SyncService.dispose();
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
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.signInWithApple();
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.signOut();
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(isBusy: true));
    try {
      await AuthService.deleteAccount();
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    SyncService.dispose();
    return super.close();
  }
}
```

**중요**:
- `_onAuthChanged`에서 `SyncService.init(user)`이 Firestore listener를 등록하므로 await 필요.
- `signIn*`은 실제 UI 업데이트가 `authStateChanges` 스트림에서 일어난다. busy 플래그는 버튼 로딩 표시용.

---

## 5. main.dart 수정

### 5.1 제거할 것

- L29 또는 L32 근방: `final authStateNotifier = ValueNotifier<User?>(...)` **제거**
- L62-73 근방: `FirebaseAuth.authStateChanges().listen(...)` 블록 **전체 제거**
  - 단, 이 블록에서 `DemoDataService.seed()` 호출이 있는지 확인. 있다면 Cubit으로 이동 또는 main()에 남김.
  - `lastLoginUid` 계정 전환 감지 로직도 이 블록에 있을 수 있음 → 그대로 `SyncService.init` 내부에 이미 있는지 확인하고 중복 제거.

### 5.2 추가할 것

MultiBlocProvider:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => ThemeCubit()),
    BlocProvider(create: (_) => AuthCubit(), lazy: false),
  ],
  child: BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, mode) => MaterialApp(...),
  ),
)
```

**`lazy: false` 필수** — AuthCubit 생성자에서 authStateChanges 구독 시작해야 하므로 즉시 인스턴스화.

### 5.3 import

```dart
import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';
```

---

## 6. SettingsScreen 교체

`_AccountSection` 위젯이 `authStateNotifier`를 쓴다(`lib/screens/settings_screen.dart:L32-41`).

**Before**:
```dart
ValueListenableBuilder<User?>(
  valueListenable: authStateNotifier,
  builder: (context, user, _) {
    if (user == null) return _SignInButtons();
    return _LoggedInSection(user);
  },
)
```

**After**:
```dart
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (!state.isInitialized) {
      return const SizedBox.shrink(); // 또는 작은 progress
    }
    if (state.user == null) return _SignInButtons();
    return _LoggedInSection(state.user!);
  },
)
```

**로그인 버튼 onTap**:

**Before**:
```dart
onPressed: () => AuthService.signInWithGoogle(),
```

**After**:
```dart
onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
```

동일하게 Apple, signOut, deleteAccount 모두 `context.read<AuthCubit>()` 경유로 변경.

**선택**: `state.isBusy`를 `CircularProgressIndicator`로 표시.

---

## 7. 주의사항

### 7.1 `SyncService.init` 중복 호출 방지

- 기존 `main.dart`의 listen에서도, 새 AuthCubit에서도 `SyncService.init`를 호출하면 안 된다.
- **오직 AuthCubit에서만** 호출.

### 7.2 `DemoDataService.seed()` 위치

- 기존에는 `main()` 또는 listen 블록 안에 있었다. 로그인 안 된 상태 + debug일 때만.
- AuthCubit으로 옮길 필요 없음. `main()`에서 `await DatabaseService.init()` 직후에 `if (kDebugMode && !AuthService.isLoggedIn) await DemoDataService.seed();` 그대로 유지.

### 7.3 lastLoginUid 계정 전환 감지

- `SyncService.init` 내부에 이미 계정 전환 감지 로직이 있는지 확인 후 중복 로직이 있으면 제거.

---

## 8. 테스트

`test/blocs/auth_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

// 주의: Firebase 실제 초기화는 테스트에서 불가능.
// AuthService를 모킹하거나, 이 PR에서는 최소 테스트만 작성.
```

**현실**: Firebase Auth는 순수 테스트가 어렵다. 이 PR에서는:
- **상태 객체 단위 테스트** (copyWith, equality) 만 작성
- AuthCubit 자체의 통합 테스트는 수동 실기기 테스트로 대체
- PR 11 정리 단계에서 `firebase_auth_mocks` 도입 검토

상태 테스트 예:

```dart
test('AuthState copyWith setUserNull', () {
  final s1 = AuthState(user: fakeUser, isInitialized: true);
  final s2 = s1.copyWith(setUserNull: true);
  expect(s2.user, isNull);
  expect(s2.isInitialized, true);
});
```

---

## 9. 검증

### 9.1 정적/자동

```bash
flutter pub get
flutter analyze
flutter test
```

### 9.2 실기기 스모크

- [ ] 로그아웃 상태에서 앱 시작 → Settings에 "로그인" 버튼 표시
- [ ] Google 로그인 → 인증 플로우 완료 후 로그인 UI 전환
  - [ ] Firestore 스냅샷 수신 로그 확인 (SyncService 로그)
  - [ ] 아티클/라벨이 있으면 로컬에 머지되는지 확인
- [ ] Apple 로그인 (iOS 실기기 필수) → 동일 플로우
- [ ] 로그아웃 → 로그인 버튼 복귀, Firestore listener 해제 로그 확인
- [ ] 계정 삭제 → Firestore 데이터 삭제 + 로컬 firestoreId 초기화 확인
- [ ] 앱 재시작 → 로그인 유지

---

## 10. 커밋 메시지

```
BLoC PR2: AuthCubit 도입 — authStateNotifier 제거

- lib/blocs/auth/auth_cubit.dart, auth_state.dart 신규
- AuthService.authStateChanges 구독을 AuthCubit으로 이전
- SyncService.init/dispose 사이드이펙트 책임을 Cubit으로 이동
- main.dart에서 authStateNotifier 및 직접 listen 제거
- MultiBlocProvider에 AuthCubit 추가 (lazy: false)
- SettingsScreen을 BlocBuilder로 교체
```

---

## 11. 흔한 실수

- `lazy: false`를 빼먹어서 AuthCubit이 UI 첫 참조 전까지 생성 안 됨 → `SyncService` 초기화 지연
- `SyncService.init` 중복 호출 (main에서 한 번, AuthCubit에서 또) → 두 번 listener 등록됨
- `copyWith(user: null)`로 로그아웃을 표현하려 하면 null이 "변경 없음"으로 해석됨 → `setUserNull` 플래그 꼭 사용

---

## 12. 핸드오프 노트 (2026-04-20 완료)

### 계획대로 된 점
- `lib/blocs/auth/auth_cubit.dart` + `auth_state.dart` 신규 (플랜 스니펫과 거의 동일)
- `authStateChanges` 구독 + `SyncService.init/dispose` 책임을 Cubit으로 이관
- `main.dart`에서 `authStateNotifier` + 직접 listen 블록 + 초기 currentUser 처리까지 전부 제거
- `MultiBlocProvider`에 `AuthCubit(lazy: false)` 추가
- `SettingsScreen`의 `ValueListenableBuilder<User?>` → `BlocBuilder<AuthCubit, AuthState>` + 로그인/로그아웃/삭제 4개 핸들러를 `context.read<AuthCubit>()` 경유로 교체
- `AuthState` copyWith + equality 유닛 테스트 10개 PASS

### 계획과 다르게 된 점
- **AuthCubit 유닛 테스트 미작성**: 플랜 9.1 허용. AuthService.authStateChanges가 Firebase 의존(`FirebaseAuth.instance.authStateChanges()`)이라 테스트 초기화 불가. PR 11에서 `firebase_auth_mocks` 도입 검토.
- **nit 반영 2건** (opus flutter-code-reviewer): (1) `close()`에서 `await _sub.cancel()`로 변경. (2) `_onAuthChanged`에서 `SyncService.init/dispose`를 try/catch로 래핑 — 예외 발생 시에도 `isInitialized=true` emit이 보장되어 `SettingsScreen`이 `SizedBox.shrink()`에 영구히 머물지 않도록 방어.
- **`main.dart`에서 `firebase_auth` import 제거**: `AuthService.isLoggedIn`으로 치환해 직접 의존성 정리.
- **초기 currentUser 처리 블록 제거**: AuthCubit 생성자가 `authStateChanges`를 구독하면 Firebase가 첫 이벤트로 currentUser를 재발행하므로 main에서의 동기 await 불필요. 다만 runApp 이전 vs 이후로 `SyncService.init` 타이밍이 약간 지연된다 — 초기 HomeScreen은 Hive 데이터로 먼저 렌더되고 이후 Firestore 스냅샷이 덮어쓴다. 치명적 레이스 없음.

### 새로 발견한 이슈 / TODO
- **`AuthState.copyWith(setUserNull:true)` 패턴**: 기능적으론 문제 없으나, sentinel / Optional wrapper 대비 덜 명시적. 현재 주석으로 의도 명시. PR 11 cleanup에서 재고려 가능.
- **seed() 타이밍**: `AuthService.isLoggedIn` 체크는 `FirebaseAuth.instance.currentUser`를 그대로 리턴하므로 기존과 동일 분기. 그대로 유지.
- **(공통 컨벤션 재확인)** cubit 테스트는 AuthState 예시처럼 Firebase 의존 없을 때만 full coverage, 의존 있을 때는 상태 객체만 테스트 → PR 11 mocks 도입 전까지 유효.

### 참고한 링크
- flutter_bloc: https://bloclibrary.dev/bloc-concepts/#cubit-vs-bloc
- equatable: https://pub.dev/packages/equatable
- `FirebaseAuth.authStateChanges()` 첫 이벤트 시멘틱: Firebase 공식 문서 "emits the current user upon subscription"

### 다음 세션 유의사항
- **PR 3(OnboardingCubit)**: 난이도 ⭐, 가장 단순. state가 `int` 하나라 ThemeCubit처럼 별도 state 클래스 없이 `Cubit<int>` 패턴.
- **전역 BlocProvider 규칙**: README.md L104 "전역: ThemeCubit, AuthCubit / 화면 로컬: 나머지 모두". OnboardingCubit은 화면 로컬.
- **Hive 테스트 격리 path 컨벤션** 그대로: `.dart_tool/test_hive_<name>`.
- **기존 `test/widget_test.dart`**: 여전히 broken. PR 11에서 헬퍼 + 재작성.
- **CLAUDE.md/플랜 문서의 `themeModeNotifier`/`authStateNotifier` 잔존 언급**: PR 11 cleanup으로 위임 확정, 무시.

### 검증 결과
- `flutter analyze`: ✅ No issues
- `flutter test test/blocs/`: ✅ 13/13 passed (AuthState 10 + ThemeCubit 3)
- `flutter test`(전체): ⚠️ +13 / -1, 실패 1건은 pre-existing `test/widget_test.dart` (PR 11 위임, 회귀 아님)
- 실기기/시뮬레이터 스모크: 미실행 (사용자 요청 시 진행)
- opus `flutter-code-reviewer`: PASS, 0 must-fix, nit 2건 반영

### 머지 / 배포
- Feature 커밋: `22e3702` (`BLoC PR2: AuthCubit 도입 — authStateNotifier 제거`)
- `develop` 머지(--no-ff): `ce44d23` (`Merge feature/bloc-02-auth: BLoC PR 2 — AuthCubit 도입`)
- `origin/develop` push 완료 (`bd0e45b..ce44d23`)
- `feature/bloc-02-auth` 브랜치 보존
