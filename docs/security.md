# Security

> 보안 가드 현황(M-/H- 시리즈) 요약과 운영 절차 포인터.
> 위협 모델·세부 절차는 각 PR 본문과 아래 참고 문서.

## 1. 적용된 가드 (시리즈)

### High (H-1 ~ H-3)

| ID | 내용 | PR / 위치 |
|----|------|----------|
| H-1 | `syncDeleteArticle` 실패 시 로컬 삭제 차단 — 동기화 실패 시 데이터 사이펀 방지 | #2 / `SyncService` |
| H-2 | 원격 라벨 삭제 동기화 시 weekly 알림 cancel 누락 수정 | #3 / `SyncService`+`NotificationService` |
| H-3 | 계정 전환 시 Hive 박스 wipe — 데이터 사이펀 영구 차단 | #4 / `AuthCubit`+`SyncService` |

### Medium (M-1 ~ M-10)

| ID | 내용 | PR / 위치 |
|----|------|----------|
| M-1 | iOS 공유 JSON 파싱 실패 fallback에서 URL 검증 | #6 / `ShareService` (iOS) |
| M-2 | `deleteAccount` 부분 실패 시 `SyncService` 복원 + 에러 전파 | #7 / `AuthService` |
| M-3 | `articleFromMap`/`labelFromMap` 방어 캐스트 + null-skip | #5 / `FirestoreService` |
| M-4 | URL 스킴 화이트리스트 — `http`/`https`만 허용 | #9 / URL 검증 진입점 |
| M-5 | SSRF + OOM 방어 — IP literal·redirect 차단, 응답 크기 상한 | #10 / `ScrapingService` |
| M-6 | Firestore rules 필드/타입/크기 검증 강화 | #8 / `firestore.rules` |
| M-7 | Hive AES 암호화 + Android `allowBackup=false` | #13 / `HiveCipherService`, `AndroidManifest.xml` |
| M-8 | `debugPrint` 릴리즈 가드 + UID 마스킹 | #12 / 로그 유틸 |
| M-9 | Android keystore 비밀번호 로테이션 가이드 | #14 / `docs/android-signing-rotation.md` |
| M-10 | Firebase App Check — Play Integrity / App Attest | #11 / `main.dart` 부팅 |

`git log --grep='sec\\|fix(sync)\\|fix(auth)'`로 원본 PR/커밋 추적.

## 2. 운영 절차

| 절차 | 문서 |
|------|------|
| Android keystore 로테이션 | [`android-signing-rotation.md`](android-signing-rotation.md) |
| Firestore rules 에뮬레이터 검증 | [`firestore-rules-test-plan.md`](firestore-rules-test-plan.md) |

## 3. 비밀 관리

- `android/key.properties` — 추적 제외(`.gitignore`). 로테이션 절차 준수.
- `flutter_secure_storage` — Hive 암호화 키 보관(M-7). 디바이스 키체인/Keystore.
- Firebase 설정(`google-services.json`/`GoogleService-Info.plist`) — 추적 여부는 레포 정책 따름. 클라이언트 키는 공개해도 무방하나 Firestore rules + App Check로 보호.

## 4. 코드 작업 시 체크 포인트

- **새 URL 입력 경로 추가**: 스킴 화이트리스트(M-4) + IP literal/redirect 가드(M-5) 통과 확인.
- **새 Firestore 컬렉션/필드**: `firestore.rules`에 검증 규칙 추가 후 에뮬레이터 검증.
- **계정/세션 관련 변경**: H-3(박스 wipe)·M-2(롤백 경로) 영향 확인.
- **로그 추가**: 릴리즈에 노출되는 `print` 금지 — `debugPrint` 사용 + 식별자 마스킹(M-8).
- **공유 시트/Intent 변경**: 페이로드 파싱 후 즉시 URL 검증(M-1).

## 5. 알려진 트레이드오프 / 백로그

- App Check enforce 모드 전환 — 현재 활성화 단계, 실측 후 enforce 검토.
- Hive 암호화 키 회수(rotation) 전략 미정 — 키 노출 시 박스 wipe 후 재발급이 현 fallback.
- 백업 경로(iOS iCloud Drive 등) 제외 정책은 현재 Android `allowBackup=false`만 — iOS는 추후 검토.
