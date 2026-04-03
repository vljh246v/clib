# Clib (클립)

> 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관

## 프로젝트 개요

Clib은 링크를 저장만 하고 읽지 않는 습관을 개선하기 위한 모바일 앱이다. 스와이프 기반의 카드 UI로 콘텐츠 소비를 게임화하고, 로컬 푸시 알림으로 재방문을 유도한다.

- 핵심 가치: 무마찰 수집(Zero-friction Scraping), 게임화된 소비(Swiping), 능동적 재방문(Scheduled Push)
- 상세 기획: `doc/product.md`, `doc/uiux.md` 참조

## 기술 스택

- **프레임워크**: Flutter (Dart) — iOS & Android
- **로컬 DB**: Hive (hive_flutter)
- **알림**: flutter_local_notifications
- **스크래핑**: http / html 패키지 (OpenGraph 메타데이터 추출)

## 아키텍처

### Local-first

- 회원가입 없음, 모든 데이터는 기기 내부 DB에 저장
- 서버 의존성 없음

### 데이터 모델 (Article)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| url | String | 원본 링크 |
| title | String | og:title (실패 시 URL 대체) |
| thumbnailUrl | String | og:image (실패 시 기본 이미지) |
| platform | String | 도메인 기반 자동 분류 (Youtube, Instagram, Blog, Etc) |
| topicLabels | List<String> | 사용자 지정 라벨 |
| isRead | bool | 읽음 여부 |
| createdAt | DateTime | 생성 일시 |

### 스크래핑

- og:title, og:image, og:description 추출
- 동적 렌더링 사이트(Instagram 등) 실패 시 예외 처리 필요

## 핵심 기능

| 기능 | 설명 |
|------|------|
| A. 수집 | OS 공유 시트로 URL 수신 → 백그라운드 스크래핑 → 저장 알림 |
| B. 소비 | 카드 스택 UI, 오른쪽 스와이프(읽음), 왼쪽 스와이프(나중에) |
| C. 알림 | 라벨별 미완독 개수 포함 로컬 푸시, 요일/시간 스케줄링 |
| D. 통계 | 라벨별 읽음/전체 비율 시각화 |

## UI/UX 가이드

### 디자인 톤

- 생산성 도구의 깔끔함 + 게임 같은 경쾌함
- 다크 모드(Primary), 라이트 모드(Secondary), 시스템 설정 연동

### 컬러 시스템

- **Main**: Deep Indigo (신뢰감)
- **Point**: Neon Green (완료/긍정), Soft Coral (보류/부정)

### 화면 구성

- **화면 0 (공유 확장 팝업)**: 썸네일 + 제목 + 라벨 선택 칩, 0.5초 내 노출
- **화면 1 (홈 - 스와이프)**: 화면 70% 대형 카드, 썸네일 배경 + 제목/플랫폼 뱃지 오버레이
- **화면 2 (보관함 - 그리드)**: 2열 그리드, 라벨별 원형 프로그레스 바, 읽음/안읽음 필터
- **화면 3 (설정)**: 라벨별 푸시 스케줄링(요일 다중선택 + 시간), 테마 설정

### 인터랙션

- 스와이프 완료 시 햅틱 피드백
- 카드 전환 시 부드러운 가속도 커브 애니메이션

## 개발 컨벤션

- 언어: 한국어 (주석, 커밋 메시지)
- Flutter 표준 프로젝트 구조 준수
