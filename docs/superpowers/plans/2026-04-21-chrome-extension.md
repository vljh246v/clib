# Clib Chrome Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/Users/jaehyun/Documents/workspace/clib-extension/` 에 Chrome Extension 신규 레포를 생성하고, Google 로그인 → 현재 탭 링크 저장(라벨 선택/즉석 생성) → 최근 10개 목록(열기/삭제) 기능을 구현한다.

**Architecture:** Vite + @crxjs/vite-plugin MV3 Extension. React 18 팝업 UI에서 Firebase JS SDK로 기존 clib Firebase 프로젝트 Firestore에 직접 접근한다. 별도 서버 없음. 앱의 SyncService snapshot listener가 Extension 저장/삭제를 자동 수신한다.

**Tech Stack:** Vite 5, @crxjs/vite-plugin@beta, React 18, TypeScript, TailwindCSS v3, Firebase JS SDK v10 (modular), Vitest (unit), chrome.identity.launchWebAuthFlow (Google OAuth)

---

## 파일 맵

```
/Users/jaehyun/Documents/workspace/clib-extension/
├── manifest.json
├── vite.config.ts
├── vitest.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── tsconfig.json
├── tsconfig.node.json
├── .env                         # 실제 Firebase 값 (gitignore)
├── .env.example                 # 빈 템플릿
├── .gitignore
├── public/
│   └── icons/
│       ├── icon16.png
│       ├── icon48.png
│       └── icon128.png
└── src/
    ├── popup/
    │   ├── index.html
    │   ├── main.tsx
    │   ├── index.css
    │   ├── App.tsx
    │   ├── views/
    │   │   ├── AuthView.tsx
    │   │   ├── AddView.tsx
    │   │   └── RecentView.tsx
    │   └── components/
    │       ├── LabelChips.tsx
    │       └── RecentItem.tsx
    ├── background/
    │   └── service-worker.ts
    ├── lib/
    │   ├── firebase.ts
    │   ├── auth.ts
    │   ├── firestore.ts
    │   ├── scraper.ts
    │   └── platform.ts
    └── test/
        ├── setup.ts
        └── lib/
            ├── platform.test.ts
            └── auth.test.ts
```

---

## Task 0: Prerequisites — Firebase Console 수동 설정

> **코드 없음. 수동 작업.** 이 작업 없이는 Task 6 이후가 동작하지 않는다.

- [ ] **Step 1: Firebase Console에서 Web App 추가**
  1. https://console.firebase.google.com → clib 프로젝트 선택
  2. 프로젝트 설정 → 일반 → "앱 추가" → 웹(`</>`)
  3. 앱 닉네임: `clib-extension`
  4. Firebase Hosting 체크 **해제**
  5. "앱 등록" → `firebaseConfig` 객체 복사 (apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId)

- [ ] **Step 2: Google OAuth 클라이언트 ID 확인**
  1. https://console.cloud.google.com → clib 프로젝트 선택
  2. API 및 서비스 → 사용자 인증 정보
  3. 기존 OAuth 2.0 클라이언트 ID 목록에서 Web application 유형 클라이언트 찾기 (Firebase가 자동 생성)
  4. 없으면 "+ 사용자 인증 정보 만들기" → OAuth 클라이언트 ID → 웹 애플리케이션
  5. 클라이언트 ID 복사 (`xxxx.apps.googleusercontent.com` 형태)

- [ ] **Step 3: Extension ID 확인 및 Redirect URI 등록**
  1. Task 1 완료 후 `npm run build` 실행
  2. Chrome: `chrome://extensions` → 개발자 모드 ON → "압축 해제된 확장 프로그램 로드" → `dist/` 폴더 선택
  3. 표시된 Extension ID 복사 (예: `abcdefghijklmnopabcdefghijklmnop`)
  4. Google Cloud Console → OAuth 클라이언트 수정 → 승인된 리디렉션 URI에 추가:
     `https://<EXTENSION_ID>.chromiumapp.org/`
  5. 저장

- [ ] **Step 4: Firestore 복합 인덱스 생성**
  1. https://console.firebase.google.com → clib 프로젝트 → Firestore Database → 인덱스
  2. "인덱스 추가" → 컬렉션 그룹: `articles`
  3. 필드:
     - `deletedAt` — 오름차순
     - `createdAt` — 내림차순
  4. "저장" (빌드 완료까지 1~2분 소요)

---

## Task 1: 프로젝트 초기화

**Files:**
- Create: `/Users/jaehyun/Documents/workspace/clib-extension/` (신규 디렉토리)

- [ ] **Step 1: Vite + React + TypeScript 프로젝트 생성**

```bash
cd /Users/jaehyun/Documents/workspace
npm create vite@latest clib-extension -- --template react-ts
cd clib-extension
npm install
```

Expected: `node_modules/` 생성, `src/` 아래 Vite 기본 파일들 있음.

- [ ] **Step 2: 의존성 설치**

```bash
npm install firebase
npm install -D @crxjs/vite-plugin@beta tailwindcss postcss autoprefixer @types/chrome
npm install -D vitest @vitest/ui jsdom @testing-library/react @testing-library/jest-dom
npx tailwindcss init -p
```

Expected: `node_modules/` 갱신, `tailwind.config.js`와 `postcss.config.js` 생성.

- [ ] **Step 3: `tailwind.config.js` → `tailwind.config.ts` 로 교체**

`tailwind.config.js` 삭제 후 `tailwind.config.ts` 생성:

```typescript
import type { Config } from 'tailwindcss'

export default {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
} satisfies Config
```

- [ ] **Step 4: `tsconfig.json` 교체**

Vite 기본값을 아래로 교체:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "types": ["chrome", "vitest/globals"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

- [ ] **Step 5: `tsconfig.node.json` 확인**

파일이 없으면 생성:

```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts", "tailwind.config.ts", "vitest.config.ts"]
}
```

- [ ] **Step 6: `.gitignore` 생성**

```
node_modules/
dist/
.env
*.local
```

- [ ] **Step 7: `.env.example` 생성**

```
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
VITE_GOOGLE_OAUTH_CLIENT_ID=
```

- [ ] **Step 8: `.env` 파일 생성 (Task 0에서 복사한 실제 값 입력)**

```
VITE_FIREBASE_API_KEY=<Task 0에서 복사한 값>
VITE_FIREBASE_AUTH_DOMAIN=<your-project>.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=<your-project>
VITE_FIREBASE_STORAGE_BUCKET=<your-project>.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=<값>
VITE_FIREBASE_APP_ID=<값>
VITE_GOOGLE_OAUTH_CLIENT_ID=<값>.apps.googleusercontent.com
```

- [ ] **Step 9: Vite 기본 파일 정리**

`src/` 아래 Vite가 생성한 `App.tsx`, `App.css`, `assets/`, `main.tsx`, `index.css`, `vite-env.d.ts` 삭제.

```bash
rm -rf src/App.tsx src/App.css src/assets src/main.tsx src/index.css src/vite-env.d.ts
```

- [ ] **Step 10: Git 초기화 및 첫 커밋**

```bash
git init
git add -A
git commit -m "chore: 프로젝트 초기화 (Vite + React + TS + TailwindCSS + Firebase + CRXJS)"
```

---

## Task 2: Manifest & Build Configuration

**Files:**
- Create: `manifest.json`
- Create: `vite.config.ts`

- [ ] **Step 1: `manifest.json` 생성**

```json
{
  "manifest_version": 3,
  "name": "clib",
  "version": "1.0.0",
  "description": "현재 탭 링크를 clib에 저장하세요",
  "action": {
    "default_popup": "src/popup/index.html",
    "default_icon": {
      "16": "icons/icon16.png",
      "48": "icons/icon48.png",
      "128": "icons/icon128.png"
    }
  },
  "background": {
    "service_worker": "src/background/service-worker.ts",
    "type": "module"
  },
  "permissions": [
    "identity",
    "activeTab",
    "scripting",
    "storage",
    "tabs"
  ],
  "host_permissions": [
    "https://*.firebaseio.com/*",
    "https://*.googleapis.com/*",
    "https://accounts.google.com/*"
  ],
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  }
}
```

- [ ] **Step 2: `vite.config.ts` 생성**

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { crx } from '@crxjs/vite-plugin'
import manifest from './manifest.json'

export default defineConfig({
  plugins: [
    react(),
    crx({ manifest }),
  ],
})
```

- [ ] **Step 3: 빌드 확인**

```bash
npm run build
```

Expected: `dist/` 폴더 생성. 오류 없이 완료. 아이콘 파일 경고는 Task 17에서 해결.

- [ ] **Step 4: 커밋**

```bash
git add manifest.json vite.config.ts
git commit -m "chore: manifest.json + vite.config.ts (CRXJS MV3)"
```

---

## Task 3: Vitest 테스트 인프라

**Files:**
- Create: `vitest.config.ts`
- Create: `src/test/setup.ts`

- [ ] **Step 1: `vitest.config.ts` 생성**

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
})
```

- [ ] **Step 2: `src/test/setup.ts` 생성**

```typescript
import '@testing-library/jest-dom'
```

- [ ] **Step 3: `package.json`에 test 스크립트 확인/추가**

```bash
npm pkg set scripts.test="vitest run" scripts.test:ui="vitest --ui"
```

- [ ] **Step 4: 빈 테스트 실행 확인**

```bash
npm test
```

Expected: `No test files found` 또는 테스트 0개 통과.

- [ ] **Step 5: 커밋**

```bash
git add vitest.config.ts src/test/setup.ts package.json
git commit -m "chore: Vitest 테스트 인프라 설정"
```

---

## Task 4: lib/platform.ts — URL 플랫폼 분류 (TDD)

> clib Flutter 앱 `classifyPlatform()` 로직을 TypeScript로 포팅.

**Files:**
- Create: `src/lib/platform.ts`
- Create: `src/test/lib/platform.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

`src/test/lib/platform.test.ts`:

```typescript
import { describe, it, expect } from 'vitest'
import { classifyPlatform } from '../../lib/platform'

describe('classifyPlatform', () => {
  it.each([
    ['https://www.youtube.com/watch?v=abc', 'youtube'],
    ['https://youtu.be/abc123', 'youtube'],
    ['https://instagram.com/p/abc', 'instagram'],
    ['https://x.com/user/status/123', 'x'],
    ['https://twitter.com/user', 'x'],
    ['https://www.tiktok.com/@user/video/123', 'tiktok'],
    ['https://facebook.com/user', 'facebook'],
    ['https://fb.com/user', 'facebook'],
    ['https://linkedin.com/in/user', 'linkedin'],
    ['https://github.com/user/repo', 'github'],
    ['https://user.github.io/repo', 'github'],
    ['https://reddit.com/r/flutter', 'reddit'],
    ['https://threads.net/@user', 'threads'],
    ['https://blog.naver.com/user/123', 'naverBlog'],
    ['https://m.blog.naver.com/user/123', 'naverBlog'],
    ['https://velog.io/@user/post', 'blog'],
    ['https://tistory.com/entry/abc', 'blog'],
    ['https://medium.com/user/article', 'blog'],
    ['https://brunch.co.kr/@user/1', 'blog'],
    ['https://example.com/some/page', 'etc'],
    ['not-a-url', 'etc'],
    ['', 'etc'],
  ] as const)('classifies %s as %s', (url, expected) => {
    expect(classifyPlatform(url)).toBe(expected)
  })
})
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
npm test
```

Expected: `FAIL src/test/lib/platform.test.ts` — `classifyPlatform` not found.

- [ ] **Step 3: `src/lib/platform.ts` 구현**

```typescript
export type Platform =
  | 'youtube' | 'instagram' | 'x' | 'tiktok' | 'facebook'
  | 'linkedin' | 'github' | 'reddit' | 'threads' | 'naverBlog'
  | 'blog' | 'etc'

export function classifyPlatform(url: string): Platform {
  let host: string
  try {
    host = new URL(url).hostname.toLowerCase()
  } catch {
    return 'etc'
  }

  if (host.includes('youtube.com') || host.includes('youtu.be')) return 'youtube'
  if (host.includes('instagram.com')) return 'instagram'
  if (host.includes('x.com') || host.includes('twitter.com')) return 'x'
  if (host.includes('tiktok.com')) return 'tiktok'
  if (host.includes('facebook.com') || host.includes('fb.com')) return 'facebook'
  if (host.includes('linkedin.com')) return 'linkedin'
  if (host.includes('github.com') || host.includes('github.io')) return 'github'
  if (host.includes('reddit.com')) return 'reddit'
  if (host.includes('threads.net')) return 'threads'
  if (host.includes('blog.naver.com') || host.includes('m.blog.naver.com')) return 'naverBlog'
  if (
    host.includes('tistory.com') ||
    host.includes('velog.io') ||
    host.includes('medium.com') ||
    host.includes('brunch.co.kr')
  ) return 'blog'
  return 'etc'
}
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
npm test
```

Expected: `PASS src/test/lib/platform.test.ts` — 23개 테스트 모두 통과.

- [ ] **Step 5: 커밋**

```bash
git add src/lib/platform.ts src/test/lib/platform.test.ts
git commit -m "feat: lib/platform.ts — classifyPlatform URL 분류 (테스트 통과)"
```

---

## Task 5: lib/firebase.ts — Firebase 초기화

**Files:**
- Create: `src/lib/firebase.ts`

- [ ] **Step 1: `src/lib/firebase.ts` 생성**

```typescript
import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY as string,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN as string,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID as string,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET as string,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID as string,
  appId: import.meta.env.VITE_FIREBASE_APP_ID as string,
}

const app = initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const db = getFirestore(app)
```

- [ ] **Step 2: 커밋**

```bash
git add src/lib/firebase.ts
git commit -m "feat: lib/firebase.ts — Firebase 초기화 (auth + db export)"
```

---

## Task 6: lib/auth.ts — Google 로그인 흐름 (TDD)

**Files:**
- Create: `src/lib/auth.ts`
- Create: `src/test/lib/auth.test.ts`

- [ ] **Step 1: parseIdTokenFromUrl 실패 테스트 작성**

`src/test/lib/auth.test.ts`:

```typescript
import { describe, it, expect } from 'vitest'
import { parseIdTokenFromUrl } from '../../lib/auth'

describe('parseIdTokenFromUrl', () => {
  it('extracts id_token from URL fragment', () => {
    const url =
      'https://abcdef.chromiumapp.org/#access_token=AT&id_token=MY_ID_TOKEN&token_type=Bearer'
    expect(parseIdTokenFromUrl(url)).toBe('MY_ID_TOKEN')
  })

  it('returns null when id_token is absent', () => {
    const url = 'https://abcdef.chromiumapp.org/#access_token=AT&token_type=Bearer'
    expect(parseIdTokenFromUrl(url)).toBeNull()
  })

  it('returns null for malformed URL', () => {
    expect(parseIdTokenFromUrl('not-a-url')).toBeNull()
  })

  it('returns null for empty string', () => {
    expect(parseIdTokenFromUrl('')).toBeNull()
  })
})
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
npm test
```

Expected: `FAIL src/test/lib/auth.test.ts` — `parseIdTokenFromUrl` not found.

- [ ] **Step 3: `src/lib/auth.ts` 전체 구현**

```typescript
import {
  GoogleAuthProvider,
  signInWithCredential,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  type User,
} from 'firebase/auth'
import { auth } from './firebase'

const OAUTH_CLIENT_ID = import.meta.env.VITE_GOOGLE_OAUTH_CLIENT_ID as string

export function parseIdTokenFromUrl(url: string): string | null {
  try {
    const fragment = new URL(url).hash.slice(1)
    return new URLSearchParams(fragment).get('id_token')
  } catch {
    return null
  }
}

export async function signInWithGoogle(): Promise<User> {
  const redirectUri = `https://${chrome.runtime.id}.chromiumapp.org/`

  const authUrl = new URL('https://accounts.google.com/o/oauth2/auth')
  authUrl.searchParams.set('client_id', OAUTH_CLIENT_ID)
  authUrl.searchParams.set('redirect_uri', redirectUri)
  authUrl.searchParams.set('response_type', 'token id_token')
  authUrl.searchParams.set('scope', 'openid email profile')
  authUrl.searchParams.set('nonce', crypto.randomUUID())

  return new Promise((resolve, reject) => {
    chrome.identity.launchWebAuthFlow(
      { url: authUrl.toString(), interactive: true },
      (responseUrl) => {
        if (chrome.runtime.lastError || !responseUrl) {
          reject(new Error(chrome.runtime.lastError?.message ?? '인증에 실패했습니다'))
          return
        }
        const idToken = parseIdTokenFromUrl(responseUrl)
        if (!idToken) {
          reject(new Error('응답에서 id_token을 찾을 수 없습니다'))
          return
        }
        const credential = GoogleAuthProvider.credential(idToken)
        signInWithCredential(auth, credential).then(resolve).catch(reject)
      },
    )
  })
}

export async function signOut(): Promise<void> {
  await firebaseSignOut(auth)
}

export function onAuthChanged(callback: (user: User | null) => void): () => void {
  return onAuthStateChanged(auth, callback)
}
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
npm test
```

Expected: `PASS src/test/lib/auth.test.ts` — 4개 테스트 통과.

- [ ] **Step 5: 커밋**

```bash
git add src/lib/auth.ts src/test/lib/auth.test.ts
git commit -m "feat: lib/auth.ts — Google 로그인 (launchWebAuthFlow → id_token → signInWithCredential)"
```

---

## Task 7: lib/firestore.ts — Firestore CRUD

**Files:**
- Create: `src/lib/firestore.ts`

- [ ] **Step 1: `src/lib/firestore.ts` 생성**

```typescript
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  addDoc,
  updateDoc,
  doc,
  serverTimestamp,
  type Timestamp,
  type DocumentData,
} from 'firebase/firestore'
import { auth, db } from './firebase'

export interface Label {
  id: string
  name: string
  colorValue: number
}

export interface Article {
  id: string
  url: string
  title: string
  thumbnailUrl: string | null
  platform: string
  topicLabels: string[]
  createdAt: Date
}

// LabelColors.presets (clib design_tokens.dart 동일값)
const LABEL_COLOR_PRESETS = [
  0xFF5B9BD5, // Calm Blue
  0xFF6DAE72, // Forest Green
  0xFF7B84B8, // Lavender
  0xFFA672B0, // Soft Purple
  0xFFD9706E, // Dusty Rose
  0xFFE8BD4E, // Warm Amber
  0xFF4DB8C7, // Teal
  0xFFE08A6A, // Terracotta
  0xFF8D7B6E, // Warm Taupe
  0xFF8D9AA3, // Cool Slate
] as const

function requireUid(): string {
  const uid = auth.currentUser?.uid
  if (!uid) throw new Error('로그인이 필요합니다')
  return uid
}

export async function getLabels(): Promise<Label[]> {
  const uid = requireUid()
  const q = query(
    collection(db, 'users', uid, 'labels'),
    where('deletedAt', '==', null),
  )
  const snapshot = await getDocs(q)
  return snapshot.docs.map((d) => ({
    id: d.id,
    name: (d.data() as DocumentData).name as string,
    colorValue: (d.data() as DocumentData).colorValue as number,
  }))
}

export async function createLabel(name: string, existingCount: number): Promise<Label> {
  const uid = requireUid()
  const colorValue = LABEL_COLOR_PRESETS[existingCount % LABEL_COLOR_PRESETS.length]

  const docRef = await addDoc(collection(db, 'users', uid, 'labels'), {
    name,
    colorValue,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    deletedAt: null,
    notificationEnabled: false,
    notificationDays: [],
    notificationTime: '09:00',
  })
  return { id: docRef.id, name, colorValue }
}

export async function addArticle(data: {
  url: string
  title: string
  thumbnailUrl: string | null
  platform: string
  topicLabels: string[]
}): Promise<void> {
  const uid = requireUid()
  await addDoc(collection(db, 'users', uid, 'articles'), {
    ...data,
    isRead: false,
    isBookmarked: false,
    memo: null,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    deletedAt: null,
  })
}

export async function getRecentArticles(): Promise<Article[]> {
  const uid = requireUid()
  // 복합 인덱스 필요: deletedAt ASC + createdAt DESC (Task 0 Step 4에서 생성)
  const q = query(
    collection(db, 'users', uid, 'articles'),
    where('deletedAt', '==', null),
    orderBy('createdAt', 'desc'),
    limit(10),
  )
  const snapshot = await getDocs(q)
  return snapshot.docs.map((d) => {
    const data = d.data() as DocumentData
    return {
      id: d.id,
      url: data.url as string,
      title: data.title as string,
      thumbnailUrl: data.thumbnailUrl as string | null,
      platform: data.platform as string,
      topicLabels: data.topicLabels as string[],
      createdAt: (data.createdAt as Timestamp).toDate(),
    }
  })
}

export async function softDeleteArticle(id: string): Promise<void> {
  const uid = requireUid()
  await updateDoc(doc(db, 'users', uid, 'articles', id), {
    deletedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/lib/firestore.ts
git commit -m "feat: lib/firestore.ts — getLabels, createLabel, addArticle, getRecentArticles, softDeleteArticle"
```

---

## Task 8: lib/scraper.ts — 탭 DOM 스크래퍼

**Files:**
- Create: `src/lib/scraper.ts`

- [ ] **Step 1: `src/lib/scraper.ts` 생성**

```typescript
export interface TabMeta {
  url: string
  title: string
  thumbnailUrl: string | null
}

export async function getCurrentTabMeta(): Promise<TabMeta> {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true })

  if (!tab?.id || !tab.url) {
    return { url: tab?.url ?? '', title: tab?.title ?? '', thumbnailUrl: null }
  }

  // chrome://, pdf 등 특수 탭은 scripting 접근 불가 → fallback
  if (!tab.url.startsWith('http://') && !tab.url.startsWith('https://')) {
    return { url: tab.url, title: tab.title ?? tab.url, thumbnailUrl: null }
  }

  try {
    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => {
        const getMeta = (attr: string, value: string): string | null =>
          document.querySelector<HTMLMetaElement>(`meta[${attr}="${value}"]`)?.content ?? null

        const ogTitle = getMeta('property', 'og:title') ?? getMeta('name', 'og:title')
        const ogImage = getMeta('property', 'og:image') ?? getMeta('name', 'og:image')
        return {
          title: ogTitle ?? document.title ?? '',
          thumbnailUrl: ogImage,
        }
      },
    })
    const result = results[0]?.result as { title: string; thumbnailUrl: string | null } | undefined
    if (!result) return { url: tab.url, title: tab.title ?? '', thumbnailUrl: null }

    return {
      url: tab.url,
      title: result.title || tab.title || tab.url,
      thumbnailUrl: result.thumbnailUrl,
    }
  } catch {
    // 접근 거부 또는 Content Security Policy 등 — fallback
    return { url: tab.url, title: tab.title ?? '', thumbnailUrl: null }
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/lib/scraper.ts
git commit -m "feat: lib/scraper.ts — chrome.scripting으로 og:title/og:image 추출, 특수 탭 fallback"
```

---

## Task 9: background/service-worker.ts — 백그라운드 서비스 워커

**Files:**
- Create: `src/background/service-worker.ts`

- [ ] **Step 1: `src/background/service-worker.ts` 생성**

MV3 service worker. Firebase auth 상태는 popup의 IndexedDB에 영속화되므로 서비스 워커는 최소 구현.

```typescript
chrome.runtime.onInstalled.addListener(() => {
  console.log('[clib] Extension installed')
})
```

- [ ] **Step 2: 빌드 확인**

```bash
npm run build
```

Expected: 에러 없이 `dist/` 갱신.

- [ ] **Step 3: 커밋**

```bash
git add src/background/service-worker.ts
git commit -m "feat: background/service-worker.ts — MV3 최소 서비스 워커"
```

---

## Task 10: 팝업 진입점 (index.html, main.tsx, index.css)

**Files:**
- Create: `src/popup/index.html`
- Create: `src/popup/main.tsx`
- Create: `src/popup/index.css`

- [ ] **Step 1: `src/popup/index.html` 생성**

```html
<!DOCTYPE html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>clib</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="./main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 2: `src/popup/index.css` 생성**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: #F8F7F4;
}

#root {
  width: 320px;
}
```

- [ ] **Step 3: `src/popup/main.tsx` 생성**

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

- [ ] **Step 4: 커밋**

```bash
git add src/popup/index.html src/popup/main.tsx src/popup/index.css
git commit -m "feat: 팝업 진입점 (index.html, main.tsx, index.css)"
```

---

## Task 11: popup/views/AuthView.tsx — 로그인 화면

**Files:**
- Create: `src/popup/views/AuthView.tsx`

- [ ] **Step 1: `src/popup/views/AuthView.tsx` 생성**

```typescript
import { useState } from 'react'
import { signInWithGoogle } from '../../lib/auth'

export default function AuthView() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleLogin = async () => {
    setLoading(true)
    setError(null)
    try {
      await signInWithGoogle()
    } catch {
      setError('로그인에 실패했습니다. 다시 시도해 주세요.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-96 bg-[#F8F7F4]">
      <header className="bg-[#2C2C3A] px-4 py-3">
        <span className="text-white font-bold text-sm tracking-wide">📎 clib</span>
      </header>

      <div className="flex flex-col items-center px-4 py-8 gap-3">
        <div className="text-4xl mb-2">📎</div>
        <div className="text-base font-bold text-[#2C2C3A]">clib에 오신 것을 환영해요</div>
        <div className="text-xs text-gray-400 text-center leading-relaxed">
          로그인 후 현재 탭의 링크를
          <br />
          clib에 저장할 수 있어요.
        </div>

        {error && (
          <div className="text-xs text-red-500 text-center">{error}</div>
        )}

        <button
          onClick={handleLogin}
          disabled={loading}
          className="flex items-center gap-2 bg-white border border-gray-200 rounded-xl px-5 py-2.5 text-sm font-semibold text-gray-700 w-full justify-center mt-2 hover:bg-gray-50 disabled:opacity-50 transition-colors"
        >
          <span className="text-base font-bold text-[#4285F4]">G</span>
          {loading ? '로그인 중...' : 'Google로 계속하기'}
        </button>

        <div className="text-xs text-gray-300 text-center mt-2 leading-relaxed">
          앱에서 같은 계정으로 로그인하면
          <br />
          저장한 링크를 확인할 수 있어요
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/popup/views/AuthView.tsx
git commit -m "feat: AuthView — Google 로그인 버튼 + 에러 표시"
```

---

## Task 12: popup/components/LabelChips.tsx — 라벨 선택 컴포넌트

**Files:**
- Create: `src/popup/components/LabelChips.tsx`

- [ ] **Step 1: `src/popup/components/LabelChips.tsx` 생성**

```typescript
import { useRef, useState } from 'react'
import { type Label, createLabel } from '../../lib/firestore'

interface Props {
  labels: Label[]
  selected: string[]
  onChange: (selected: string[]) => void
  onLabelCreated: (label: Label) => void
}

export default function LabelChips({ labels, selected, onChange, onLabelCreated }: Props) {
  const [isCreating, setIsCreating] = useState(false)
  const [newName, setNewName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  const toggle = (name: string) =>
    onChange(
      selected.includes(name) ? selected.filter((s) => s !== name) : [...selected, name],
    )

  const openInput = () => {
    setIsCreating(true)
    setError(null)
    setTimeout(() => inputRef.current?.focus(), 50)
  }

  const handleCreate = async () => {
    const name = newName.trim()
    if (!name) return
    if (labels.some((l) => l.name === name)) {
      setError('이미 있는 라벨 이름입니다')
      return
    }
    setCreating(true)
    try {
      const label = await createLabel(name, labels.length)
      onLabelCreated(label)
      onChange([...selected, label.name])
      setNewName('')
      setIsCreating(false)
      setError(null)
    } catch {
      setError('라벨 생성에 실패했습니다')
    } finally {
      setCreating(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') void handleCreate()
    if (e.key === 'Escape') {
      setIsCreating(false)
      setNewName('')
      setError(null)
    }
  }

  return (
    <div>
      <div className="flex flex-wrap gap-1.5">
        {labels.map((label) => (
          <button
            key={label.id}
            onClick={() => toggle(label.name)}
            className={`px-2.5 py-1 rounded-full text-xs font-semibold border transition-colors ${
              selected.includes(label.name)
                ? 'border-[#5BA67D] text-[#2e7d52] bg-[#e8f5e9]'
                : 'border-transparent bg-gray-100 text-gray-500 hover:bg-gray-200'
            }`}
          >
            {label.name}
          </button>
        ))}

        {isCreating ? (
          <input
            ref={inputRef}
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            onKeyDown={handleKeyDown}
            onBlur={() => {
              if (!newName.trim()) {
                setIsCreating(false)
                setError(null)
              }
            }}
            disabled={creating}
            placeholder="라벨 이름 입력 후 Enter"
            className="px-2.5 py-1 rounded-full text-xs border border-dashed border-[#5BA67D] outline-none min-w-0 w-32 focus:border-[#2e7d52]"
          />
        ) : (
          <button
            onClick={openInput}
            className="px-2.5 py-1 rounded-full text-xs font-semibold bg-white border border-dashed border-gray-300 text-gray-400 hover:border-gray-400 transition-colors"
          >
            + 새 라벨
          </button>
        )}
      </div>

      {error && <div className="text-xs text-red-500 mt-1">{error}</div>}
    </div>
  )
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/popup/components/LabelChips.tsx
git commit -m "feat: LabelChips — 다중 라벨 선택 + 즉석 생성 (Enter/Escape, 중복 검사)"
```

---

## Task 13: popup/views/AddView.tsx — 링크 저장 화면

**Files:**
- Create: `src/popup/views/AddView.tsx`

- [ ] **Step 1: `src/popup/views/AddView.tsx` 생성**

```typescript
import { useEffect, useState } from 'react'
import { type User } from 'firebase/auth'
import { getCurrentTabMeta, type TabMeta } from '../../lib/scraper'
import { classifyPlatform } from '../../lib/platform'
import { getLabels, addArticle, type Label } from '../../lib/firestore'
import { signOut } from '../../lib/auth'
import LabelChips from '../components/LabelChips'

interface Props {
  user: User
}

export default function AddView({ user: _ }: Props) {
  const [meta, setMeta] = useState<TabMeta | null>(null)
  const [title, setTitle] = useState('')
  const [labels, setLabels] = useState<Label[]>([])
  const [selected, setSelected] = useState<string[]>([])
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void Promise.all([getCurrentTabMeta(), getLabels()]).then(([tabMeta, fetchedLabels]) => {
      setMeta(tabMeta)
      setTitle(tabMeta.title)
      setLabels(fetchedLabels)
    })
  }, [])

  const handleSave = async () => {
    if (!meta) return
    setSaving(true)
    setError(null)
    try {
      await addArticle({
        url: meta.url,
        title: title.trim() || meta.url,
        thumbnailUrl: meta.thumbnailUrl,
        platform: classifyPlatform(meta.url),
        topicLabels: selected,
      })
      setSaved(true)
      setTimeout(() => window.close(), 1200)
    } catch {
      setError('저장에 실패했습니다. 다시 시도해 주세요.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="p-4">
      {/* 썸네일 + 제목 */}
      <div className="flex gap-2.5 items-center mb-3">
        <div className="w-14 h-10 rounded-md flex-shrink-0 overflow-hidden bg-gray-100 flex items-center justify-center">
          {meta?.thumbnailUrl ? (
            <img
              src={meta.thumbnailUrl}
              alt=""
              className="w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.style.display = 'none'
              }}
            />
          ) : (
            <span className="text-xl">🌐</span>
          )}
        </div>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="flex-1 text-xs px-2 py-1.5 border border-gray-200 rounded-md bg-white text-gray-800 outline-none focus:border-[#5BA67D] transition-colors"
          placeholder="제목"
        />
      </div>

      {/* URL */}
      <div className="mb-3">
        <div className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">URL</div>
        <div className="text-xs text-gray-400 truncate px-2.5 py-2 border border-gray-100 rounded-lg bg-white">
          {meta?.url ?? '탭 정보 로딩 중...'}
        </div>
      </div>

      {/* 라벨 */}
      <div className="mb-4">
        <div className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1.5">
          라벨
        </div>
        <LabelChips
          labels={labels}
          selected={selected}
          onChange={setSelected}
          onLabelCreated={(label) => setLabels((prev) => [...prev, label])}
        />
      </div>

      {error && <div className="text-xs text-red-500 mb-2">{error}</div>}
      {saved && (
        <div className="text-xs text-[#5BA67D] mb-2 text-center font-semibold">
          저장되었습니다 ✓
        </div>
      )}

      <button
        onClick={() => void handleSave()}
        disabled={saving || saved || !meta}
        className="w-full py-2.5 rounded-xl bg-[#2C2C3A] text-white text-sm font-bold disabled:opacity-50 hover:bg-[#3a3a4a] transition-colors"
      >
        {saving ? '저장 중...' : '저장하기'}
      </button>

      <button
        onClick={() => void signOut()}
        className="w-full py-2 mt-2 rounded-xl bg-gray-100 text-[#2C2C3A] text-xs font-medium hover:bg-gray-200 transition-colors"
      >
        로그아웃
      </button>
    </div>
  )
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/popup/views/AddView.tsx
git commit -m "feat: AddView — 현재 탭 자동 채움, 라벨 선택, 저장 버튼, 저장 성공 후 팝업 닫기"
```

---

## Task 14: popup/components/RecentItem.tsx — 최근 저장 아이템

**Files:**
- Create: `src/popup/components/RecentItem.tsx`

- [ ] **Step 1: `src/popup/components/RecentItem.tsx` 생성**

```typescript
import { softDeleteArticle, type Article } from '../../lib/firestore'

interface Props {
  article: Article
  onDeleted: (id: string) => void
}

const PLATFORM_ICONS: Record<string, string> = {
  youtube: '🎬',
  instagram: '📸',
  x: '🐦',
  tiktok: '🎵',
  facebook: '📘',
  linkedin: '💼',
  github: '🐙',
  reddit: '🤖',
  threads: '🧵',
  naverBlog: '📝',
  blog: '📝',
  etc: '📄',
}

const PLATFORM_LABELS: Record<string, string> = {
  youtube: 'YouTube',
  instagram: 'Instagram',
  x: 'X',
  tiktok: 'TikTok',
  facebook: 'Facebook',
  linkedin: 'LinkedIn',
  github: 'GitHub',
  reddit: 'Reddit',
  threads: 'Threads',
  naverBlog: '네이버 블로그',
  blog: '블로그',
  etc: '웹',
}

function formatRelativeTime(date: Date): string {
  const diffSec = (Date.now() - date.getTime()) / 1000
  if (diffSec < 60) return '방금 전'
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}분 전`
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}시간 전`
  if (diffSec < 172800) return '어제'
  return `${Math.floor(diffSec / 86400)}일 전`
}

export default function RecentItem({ article, onDeleted }: Props) {
  const handleOpen = () => {
    void chrome.tabs.create({ url: article.url })
  }

  const handleDelete = async () => {
    await softDeleteArticle(article.id)
    onDeleted(article.id)
  }

  return (
    <div className="flex items-center gap-2.5 py-2.5 border-b border-gray-100 last:border-0">
      {/* 썸네일 */}
      <div className="w-10 h-10 rounded-md flex-shrink-0 overflow-hidden bg-gray-100 flex items-center justify-center text-base">
        {article.thumbnailUrl ? (
          <img
            src={article.thumbnailUrl}
            alt=""
            className="w-full h-full object-cover"
            onError={(e) => {
              e.currentTarget.style.display = 'none'
              e.currentTarget.parentElement!.textContent =
                PLATFORM_ICONS[article.platform] ?? '📄'
            }}
          />
        ) : (
          <span>{PLATFORM_ICONS[article.platform] ?? '📄'}</span>
        )}
      </div>

      {/* 정보 */}
      <div className="flex-1 min-w-0">
        <div className="text-xs font-semibold text-gray-800 truncate">{article.title}</div>
        <div className="text-xs text-gray-400 mt-0.5">
          {PLATFORM_LABELS[article.platform] ?? article.platform} ·{' '}
          {formatRelativeTime(article.createdAt)}
        </div>
      </div>

      {/* 액션 버튼 */}
      <div className="flex gap-1 flex-shrink-0">
        <button
          onClick={handleOpen}
          title="새 탭으로 열기"
          className="w-7 h-7 rounded-md bg-gray-100 flex items-center justify-center text-xs hover:bg-gray-200 transition-colors"
        >
          ↗
        </button>
        <button
          onClick={() => void handleDelete()}
          title="삭제"
          className="w-7 h-7 rounded-md bg-red-50 flex items-center justify-center text-xs hover:bg-red-100 transition-colors"
        >
          🗑
        </button>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/popup/components/RecentItem.tsx
git commit -m "feat: RecentItem — 썸네일, 플랫폼 아이콘, 상대 시간, 열기/삭제 버튼"
```

---

## Task 15: popup/views/RecentView.tsx — 최근 저장 목록

**Files:**
- Create: `src/popup/views/RecentView.tsx`

- [ ] **Step 1: `src/popup/views/RecentView.tsx` 생성**

```typescript
import { useEffect, useState } from 'react'
import { getRecentArticles, type Article } from '../../lib/firestore'
import RecentItem from '../components/RecentItem'

export default function RecentView() {
  const [articles, setArticles] = useState<Article[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    getRecentArticles()
      .then(setArticles)
      .catch(() => setError('목록을 불러오지 못했습니다.'))
      .finally(() => setLoading(false))
  }, [])

  const handleDeleted = (id: string) => {
    setArticles((prev) => prev.filter((a) => a.id !== id))
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12 text-xs text-gray-400">
        로딩 중...
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-2">
        <div className="text-xs text-red-500">{error}</div>
        <button
          onClick={() => {
            setLoading(true)
            setError(null)
            getRecentArticles()
              .then(setArticles)
              .catch(() => setError('목록을 불러오지 못했습니다.'))
              .finally(() => setLoading(false))
          }}
          className="text-xs text-[#5BA67D] underline"
        >
          다시 시도
        </button>
      </div>
    )
  }

  if (articles.length === 0) {
    return (
      <div className="flex items-center justify-center py-12 text-xs text-gray-400 text-center leading-relaxed">
        아직 저장된 링크가 없어요.
        <br />
        첫 번째 링크를 저장해보세요!
      </div>
    )
  }

  return (
    <div className="px-4 pt-2 pb-4">
      <div className="text-xs text-gray-300 mb-1">최근 저장 {articles.length}개</div>
      {articles.map((article) => (
        <RecentItem key={article.id} article={article} onDeleted={handleDeleted} />
      ))}
    </div>
  )
}
```

- [ ] **Step 2: 커밋**

```bash
git add src/popup/views/RecentView.tsx
git commit -m "feat: RecentView — 최근 10개 목록, 에러 재시도, 빈 상태 표시"
```

---

## Task 16: popup/App.tsx — 루트 컴포넌트

**Files:**
- Create: `src/popup/App.tsx`

- [ ] **Step 1: `src/popup/App.tsx` 생성**

```typescript
import { useEffect, useState } from 'react'
import { type User } from 'firebase/auth'
import { onAuthChanged } from '../lib/auth'
import AuthView from './views/AuthView'
import AddView from './views/AddView'
import RecentView from './views/RecentView'

type Tab = 'add' | 'recent'

export default function App() {
  const [user, setUser] = useState<User | null | 'loading'>('loading')
  const [activeTab, setActiveTab] = useState<Tab>('add')

  useEffect(() => {
    return onAuthChanged(setUser)
  }, [])

  if (user === 'loading') {
    return (
      <div className="flex items-center justify-center min-h-40 bg-[#F8F7F4] text-xs text-gray-400">
        로딩 중...
      </div>
    )
  }

  if (!user) return <AuthView />

  return (
    <div className="bg-[#F8F7F4]" style={{ minHeight: 420 }}>
      {/* 헤더 */}
      <header className="bg-[#2C2C3A] px-4 py-3 flex items-center justify-between">
        <span className="text-white font-bold text-sm tracking-wide">📎 clib</span>
        <div className="flex items-center gap-2">
          <div className="w-6 h-6 rounded-full bg-[#5BA67D] flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
            {user.displayName?.[0]?.toUpperCase() ?? user.email?.[0]?.toUpperCase() ?? 'U'}
          </div>
          <span className="text-[#aaa] text-xs truncate max-w-32">{user.email}</span>
        </div>
      </header>

      {/* 탭바 */}
      <div className="flex border-b border-gray-200 bg-white">
        {(['add', 'recent'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`flex-1 py-2.5 text-xs font-medium transition-colors ${
              activeTab === tab
                ? 'text-[#2C2C3A] font-bold border-b-2 border-[#5BA67D] -mb-px'
                : 'text-gray-400 hover:text-gray-600'
            }`}
          >
            {tab === 'add' ? '저장' : '최근 목록'}
          </button>
        ))}
      </div>

      {/* 뷰 */}
      {activeTab === 'add' ? <AddView user={user} /> : <RecentView />}
    </div>
  )
}
```

- [ ] **Step 2: TypeScript 빌드 확인**

```bash
npm run build
```

Expected: 에러 없이 `dist/` 생성. 타입 오류 없음.

- [ ] **Step 3: 커밋**

```bash
git add src/popup/App.tsx
git commit -m "feat: App.tsx — 인증 상태 라우팅 (AuthView ↔ 헤더 + 탭바 + AddView/RecentView)"
```

---

## Task 17: 아이콘 생성

**Files:**
- Create: `public/icons/icon16.png`
- Create: `public/icons/icon48.png`
- Create: `public/icons/icon128.png`

- [ ] **Step 1: 아이콘 디렉토리 생성**

```bash
mkdir -p public/icons
```

- [ ] **Step 2: 임시 아이콘 생성 (ImageMagick 사용)**

ImageMagick이 없으면 `brew install imagemagick` 먼저 실행.

```bash
# Warm Charcoal (#2C2C3A) 배경 + 흰색 C 텍스트
convert -size 128x128 xc:"#2C2C3A" \
  -fill white -font Helvetica-Bold -pointsize 70 \
  -gravity center -annotate 0 "c" \
  public/icons/icon128.png

convert -resize 48x48 public/icons/icon128.png public/icons/icon48.png
convert -resize 16x16 public/icons/icon128.png public/icons/icon16.png
```

ImageMagick이 없는 경우 대안: `public/icons/` 에 임의의 PNG 3개를 수동으로 배치.

- [ ] **Step 3: 빌드 확인**

```bash
npm run build
```

Expected: 아이콘 경고 없이 빌드 성공.

- [ ] **Step 4: 커밋**

```bash
git add public/icons/
git commit -m "chore: Extension 아이콘 (16/48/128px, Warm Charcoal 배경)"
```

---

## Task 18: Chrome에 로드 및 수동 검증

> **코드 작업 없음. 수동 확인 체크리스트.**

- [ ] **Step 1: Extension 로드**

1. `npm run build`
2. `chrome://extensions` → 개발자 모드 ON
3. "압축 해제된 확장 프로그램 로드" → `dist/` 폴더 선택
4. Extension ID 확인 (Task 0 Step 3에서 redirect URI 등록에 사용)

- [ ] **Step 2: AuthView 검증**

1. Extension 아이콘 클릭
2. "clib에 오신 것을 환영해요" 화면 표시 확인
3. "Google로 계속하기" 클릭 → Google 로그인 팝업 오픈 확인
4. 계정 선택 → 로그인 성공 → 저장 화면(AddView)으로 전환 확인

- [ ] **Step 3: AddView 검증**

1. 현재 탭 URL이 자동 입력됨 확인
2. `og:title`이 있는 페이지(예: https://github.com)에서: 제목 자동 채움 확인
3. 라벨 목록이 Firestore에서 로드되어 칩으로 표시 확인
4. 라벨 선택(토글) 동작 확인
5. "+ 새 라벨" 클릭 → 인라인 입력 필드 확장 확인
6. 라벨 이름 입력 후 Enter → Firestore에 생성 + 칩 추가 + 자동 선택 확인
7. 중복 라벨 이름 입력 시 "이미 있는 라벨 이름입니다" 에러 확인
8. "저장하기" 클릭 → "저장되었습니다 ✓" 토스트 → 팝업 자동 닫힘 확인
9. Firebase Console → Firestore → `users/{uid}/articles` 에 문서 생성 확인

- [ ] **Step 4: RecentView 검증**

1. Extension 다시 열기 → "최근 목록" 탭 클릭
2. Step 3에서 저장한 링크가 목록 첫 번째에 표시 확인
3. ↗ 버튼 클릭 → 새 탭에서 해당 URL 열림 확인
4. 🗑 버튼 클릭 → 목록에서 즉시 제거 확인
5. Firebase Console에서 해당 문서의 `deletedAt` 필드 설정 확인

- [ ] **Step 5: clib 앱 동기화 확인**

1. 같은 계정으로 clib 앱 로그인
2. Extension에서 저장한 링크가 앱 HomeScreen 덱에 표시 확인
3. Extension에서 soft delete한 링크가 앱에서도 제거 확인 (SyncService가 tombstone 수신)

- [ ] **Step 6: 특수 탭 fallback 확인**

1. `chrome://settings` 탭에서 Extension 열기
2. URL 필드에 `chrome://settings` 표시, 제목 수동 입력 가능 확인 (스크래핑 오류 없이 graceful fallback)

- [ ] **Step 7: 오프라인 확인**

1. DevTools → Network → Offline 체크
2. "저장하기" 클릭 → "저장에 실패했습니다. 다시 시도해 주세요." 에러 메시지 표시 확인

---

## 완료 기준

| 항목 | 확인 |
|------|------|
| Google 로그인 / 로그아웃 동작 | ☐ |
| 현재 탭 URL + 제목 자동 채움 | ☐ |
| 라벨 선택 + 즉석 생성 | ☐ |
| Firestore articles 저장 | ☐ |
| 최근 10개 목록 표시 | ☐ |
| 열기(새 탭) / 삭제(soft delete) | ☐ |
| clib 앱에서 Extension 저장 링크 확인 | ☐ |
| TypeScript 빌드 오류 없음 | ☐ |
| Vitest 테스트 전체 통과 | ☐ |
