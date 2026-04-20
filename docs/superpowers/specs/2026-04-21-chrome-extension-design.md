# Clib Chrome Extension — 설계 스펙

**작성일:** 2026-04-21  
**상태:** 승인 완료 (브레인스토밍 후 사용자 확인)  
**레포 위치:** `/Users/jaehyun/Documents/workspace/clib-extension/` (별도 레포)

---

## 1. 개요

clib 앱의 보조 도구로서, PC Chrome 브라우저에서 현재 탭의 링크를 빠르게 저장하고 최근 저장 목록을 확인할 수 있는 Chrome Extension.

**핵심 가치:** 모바일 앱에서만 가능하던 링크 수집을 PC 브라우징 중에도 마찰 없이 수행.

---

## 2. 스코프 (v1)

### 포함
- **Quick Add**: 현재 탭 URL + 제목 자동 채움, 라벨 선택(+ 즉석 생성), 저장
- **Recent Glance**: 최근 저장 10개 목록, 외부 브라우저 열기, 삭제(soft delete)
- **Google 로그인 / 로그아웃**
- **Firestore 동기화**: 크롬이 Firestore에 쓰기 → 앱 SyncService snapshot listener가 실시간 수신

### 제외 (v2 이후)
- Safari Extension
- Apple 로그인
- 읽음 처리 (앱 스와이프 UX 고유 기능으로 유지)
- 라벨 색상 편집 (앱에서만)
- 라벨 삭제 (앱에서만)
- 전체 라이브러리 탐색 / 검색

---

## 3. 기술 스택

| 영역 | 선택 | 이유 |
|------|------|------|
| 빌드 도구 | Vite + `@crxjs/vite-plugin` | 표준 Vite 생태계, 투명한 빌드, 디버깅 용이 |
| UI | React 18 + TypeScript | 상태 관리 필요, 생태계 표준 |
| 스타일 | TailwindCSS | 빠른 UI 개발 |
| Auth | Firebase JS SDK v10 (modular) | 앱과 동일 Firebase 프로젝트 공유 |
| DB | Firebase Firestore SDK v10 | 앱과 동일 컬렉션 구조 직접 접근 |
| 테스트 | Vitest (unit) + Playwright (E2E) | MV3 extension 테스팅 지원 |

---

## 4. 시스템 아키텍처

```
Chrome Extension
├── popup (React 앱)          ─┐
│   ├── AuthView               │   chrome.identity
│   ├── AddView                ├─▶  launchWebAuthFlow ─▶ Google OAuth
│   └── RecentView             │
└── background (service worker)┘

        │  Firebase JS SDK (Web App)
        ▼
Firebase (기존 clib 프로젝트 공유)
├── Auth  ─▶  signInWithCredential(GoogleAuthProvider)
└── Firestore
    └── users/{uid}/
        ├── articles   ◀─▶  (읽기/쓰기/soft delete)
        └── labels     ◀─▶  (읽기 + 즉석 생성)

        │  Firestore snapshot listener
        ▼
clib Flutter 앱 (기존 SyncService)
└── 크롬 저장/삭제 → 앱 자동 반영 (코드 변경 없음)
```

**핵심:** Extension은 별도 서버 없이 Firebase SDK로 Firestore에 직접 접근. 기존 앱 코드 변경 불필요. Firestore Security Rules 변경 불필요.

---

## 5. 폴더 구조

```
/Users/jaehyun/Documents/workspace/clib-extension/
├── manifest.json          # MV3, CRXJS 참조
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── src/
│   ├── popup/
│   │   ├── main.tsx           # React 진입점
│   │   ├── App.tsx            # 뷰 라우팅: AuthView | MainView
│   │   ├── views/
│   │   │   ├── AuthView.tsx   # Google 로그인 버튼
│   │   │   ├── AddView.tsx    # 저장 폼
│   │   │   └── RecentView.tsx # 최근 10개 목록
│   │   └── components/
│   │       ├── LabelChips.tsx     # 라벨 선택 + 새 라벨 인라인 입력
│   │       └── RecentItem.tsx     # 아이템 (열기/삭제)
│   ├── background/
│   │   └── service-worker.ts  # chrome.identity 토큰 관리
│   └── lib/
│       ├── firebase.ts        # Firebase 초기화 (Web App config)
│       ├── auth.ts            # Google 로그인 흐름
│       ├── firestore.ts       # articles/labels CRUD
│       └── scraper.ts         # chrome.scripting.executeScript 래퍼
└── public/
    └── icons/                 # 16/48/128px 아이콘
```

---

## 6. 3개 뷰 상세

### AuthView
- clib 로고 + 설명 문구
- "Google로 계속하기" 버튼
- 하단 안내: "앱에서 같은 계정으로 로그인하면 저장한 링크를 확인할 수 있어요"

### AddView (기본 뷰, 로그인 후)
- **상단 헤더**: 로그인 계정 표시 + 로그아웃
- **탭바**: 저장 | 최근 목록
- **썸네일 + 제목 입력**: `chrome.scripting.executeScript`로 `og:image` + `og:title` 자동 채움. 제목은 수정 가능.
- **URL**: 자동 채움 (수정 불가)
- **라벨 선택**: Firestore labels 읽어서 칩 렌더링. 다중 선택. "새 라벨" 칩 클릭 → 인라인 텍스트 입력 확장 → Enter 시 Firestore 생성 + 색상 자동 배정(preset 순환, 앱의 `LabelColors.presets`와 동일 10색)
- **저장 버튼**: Firestore `articles` 추가 → 성공 토스트 → 팝업 닫힘

### RecentView
- **탭바**: 저장 | 최근 목록 (활성)
- Firestore 쿼리: `where('deletedAt', '==', null).orderBy('createdAt', 'desc').limit(10)` — **복합 인덱스 필요** (Firebase 콘솔에서 `deletedAt ASC, createdAt DESC` 인덱스 생성)
- 각 아이템: 썸네일(플랫폼 아이콘 fallback) + 제목 + 플랫폼·시간 메타 + 열기(↗) + 삭제(🗑)
- **열기**: `chrome.tabs.create({ url })` 새 탭
- **삭제**: Firestore `deletedAt: serverTimestamp()` soft delete → 목록에서 즉시 제거

---

## 7. Auth 흐름 (구현 핵심)

Chrome Extension MV3에서 Firebase Google 로그인은 `chrome.identity.getAuthToken()`이 아닌 `launchWebAuthFlow`를 사용해야 합니다. `getAuthToken()`은 access token만 반환하지만 Firebase는 **id_token**이 필요하기 때문입니다.

```
1. chrome.identity.launchWebAuthFlow({
     url: `https://accounts.google.com/o/oauth2/auth?
           client_id=<OAUTH_CLIENT_ID>
           &redirect_uri=https://<EXTENSION_ID>.chromiumapp.org/
           &response_type=token id_token
           &scope=openid email profile`,
     interactive: true
   })

2. 반환된 URL에서 id_token 파싱

3. const credential = GoogleAuthProvider.credential(id_token)
   await signInWithCredential(auth, credential)

4. Firebase User 획득 → uid로 Firestore 접근
```

**Firebase 콘솔 설정 필요:**
- clib 프로젝트에 Web App 신규 추가 → `firebaseConfig` 발급
- OAuth 2.0 클라이언트에 `https://<EXTENSION_ID>.chromiumapp.org/` redirect URI 등록

---

## 8. 데이터 모델 (Firestore, 기존 구조 그대로)

### Article 저장 시 필드
```typescript
{
  url: string,
  title: string,
  thumbnailUrl: string | null,   // og:image (없으면 null)
  platform: string,              // classifyPlatform(url) 결과
  topicLabels: string[],         // 선택한 라벨 이름 배열
  isRead: false,
  isBookmarked: false,
  memo: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  deletedAt: null,
}
```

### Label 즉석 생성 시 필드
```typescript
{
  name: string,
  colorValue: number,            // presets 순환 배정 (기존 라벨 수 % 10)
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  deletedAt: null,
  // 앱 Label 모델 호환을 위한 알림 기본값
  notificationEnabled: false,
  notificationDays: [],
  notificationTime: '09:00',
}
```

`platform` 분류 로직은 앱의 `classifyPlatform(url)` 동일 규칙을 TypeScript로 포팅.

---

## 9. 에러 처리

| 상황 | 처리 |
|------|------|
| 저장 실패 (네트워크) | 인라인 에러 메시지, 재시도 버튼 |
| 오프라인 | "오프라인 상태입니다" 배너 |
| DOM 읽기 실패 (chrome://, pdf 등 특수 탭) | 제목/URL 수동 입력 fallback |
| Auth 토큰 만료 | 자동 갱신 시도 → 실패 시 AuthView 리셋 |
| 라벨 이름 중복 | "이미 있는 라벨 이름입니다" 인라인 에러 |

---

## 10. 테스트 전략

- **Unit (Vitest)**: `firestore.ts` CRUD 함수, `scraper.ts` og 파싱, `auth.ts` token 파싱
- **E2E (Playwright)**: Chrome Extension 로드 → 로그인 → 저장 → Recent 확인 → 삭제 골든패스
- **수동 검증**: 실제 브라우저 + 실기기 앱에서 양방향 동기화 확인

---

## 11. 배포

- **Chrome Web Store** 등록 (별도 개발자 계정 or 기존 계정)
- `manifest.json` 권한: `identity`, `activeTab`, `scripting`, `storage`
- CSP: Firebase SDK 도메인 허용 필요 (`*.firebaseio.com`, `*.googleapis.com`)
- 아이콘: 16/48/128px (clib 브랜드 컬러 Warm Charcoal `#2C2C3A` 배경)
