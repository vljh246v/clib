# Clib (클립)

> 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관.

링크를 저장만 하고 읽지 않는 습관을 개선하는 모바일 앱(Flutter, iOS+Android). 스와이프 카드 UI + 주간 로컬 푸시로 재방문을 유도한다.

- **Local-first**: 회원가입 없이 Hive 로컬 DB 동작.
- **선택적 클라우드 동기화**: Firebase 로그인 시 Firestore 양방향 sync.
- **핵심 가치**: 무마찰 수집(공유 시트 → 자동 스크래핑) / 게임화된 소비(스와이프) / 능동적 재방문(라벨별 weekly 푸시).

## Quick Start

```bash
flutter pub get
cd ios && pod install && cd ..

dart run build_runner build --delete-conflicting-outputs   # 모델 변경 시
flutter gen-l10n                                            # ARB 변경 시 (l10n.yaml 기반)
flutter analyze                                             # warning/error 0 유지
flutter test                                                # unit + bloc tests
flutter run                                                 # 디버그
flutter run --release                                       # 릴리즈 빌드 실기기 확인
```

`flutter: ">=3.32.0"` 필요(`RadioGroup<T>` 등 사용).

## 기술 스택

Flutter + Dart · Hive(local DB) · `flutter_bloc` + Equatable(상태 관리) · Firebase(Auth/Firestore/App Check) + Google Sign-In · `flutter_local_notifications` · AdMob · `flutter_card_swiper` · `flutter_secure_storage`. 정확한 버전은 `pubspec.yaml`.

## 문서

| 문서 | 내용 |
|------|------|
| [`AGENTS.md`](AGENTS.md) | 에이전트 작업 가이드 — 운영 규칙·핵심 주의사항·검증 |
| [`docs/architecture.md`](docs/architecture.md) | 데이터 모델 · 서비스 · 전역 상태 · 부팅 흐름 · 네이티브 설정 |
| [`docs/conventions.md`](docs/conventions.md) | 코딩 · 상태관리 · 디자인 시스템 · i18n 워크플로 |
| [`docs/security.md`](docs/security.md) | 보안 가드 시리즈(M-1~M-10 / H-1~H-3) + 운영 절차 |
| [`docs/android-signing-rotation.md`](docs/android-signing-rotation.md) | Android keystore 로테이션 |
| [`docs/firestore-rules-test-plan.md`](docs/firestore-rules-test-plan.md) | Firestore rules 에뮬레이터 검증 |
| [`docs/aso-listing.md`](docs/aso-listing.md) | 앱스토어 리스팅(ASO) |
| [`docs/archive/`](docs/archive/) | 종료된 작업(BLoC 마이그레이션 등) 기록 |

## 관련 레포

| 프로젝트 | 경로 |
|----------|------|
| Chrome Extension (저장 진입점) | `~/Documents/workspace/clib-extension` |
| 랜딩 + 개인정보처리방침 | `~/Documents/workspace/clib-support` (GitHub Pages) |

## 기준 브랜치

`develop`. PR 머지 대상은 `main` 아니다.

## 라이선스 / 배포

- iOS App Store: 출시됨.
- Google Play: 추후 출시.
