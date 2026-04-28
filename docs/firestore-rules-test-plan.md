# Firestore Rules 수동 에뮬레이터 테스트 플랜 (M-6)

## 배경

`firestore.rules` 에 `isValidArticle` / `isValidLabel` 헬퍼를 추가해 필드 타입·크기
상한을 강제하도록 변경하였다. 이 파일은 에뮬레이터를 이용한 수동 검증 절차를 기술한다.

> **중요**: 배포 전 반드시 staging 프로젝트에서 아래 절차를 수행하고 통과 여부를
> 확인한다. 특히 구버전 앱이 쓴 레거시 doc (필수 필드 누락 가능) 이 있는 경우
> `update` 가 실패할 수 있으므로, 실제 프로덕션 데이터 스냅샷으로도 검증한다.

---

## 1. 환경 설정

```bash
# 1-a. Firebase CLI 설치 (미설치 시)
npm install -g firebase-tools

# 1-b. 로그인
firebase login

# 1-c. Firebase 프로젝트 초기화 (Firestore rules 선택)
#      프로젝트 루트에서 실행
firebase init firestore

# 1-d. 에뮬레이터 시작 (Firestore 전용)
firebase emulators:start --only firestore
# 기본 포트: http://localhost:8080
```

---

## 2. 테스트 도구

단순 검증에는 Firebase Console Emulator UI 또는 `firebase-admin` SDK를 사용한다.
자동화 단위 테스트는 `@firebase/rules-unit-testing` 라이브러리를 활용할 수 있다.

참조: https://firebase.google.com/docs/rules/unit-tests

```bash
npm install --save-dev @firebase/rules-unit-testing
```

---

## 3. Article 테스트 케이스

### TC-A01 (Positive) 정상 create

- **입력**: `{url: "https://example.com", title: "테스트", platform: "youtube", isRead: false, createdAt: <timestamp>}`
- **기대**: `allow` (규칙 통과)

### TC-A02 (Negative) url 필드 누락 create

- **입력**: `{title: "테스트", platform: "youtube", isRead: false, createdAt: <timestamp>}`
- **기대**: `deny` — `keys().hasAll` 실패

### TC-A03 (Negative) url 크기 초과 (2049자)

- **입력**: url = "https://" + "a".repeat(2041) + ".com" (>2048자)
- **기대**: `deny` — `d.url.size() <= 2048` 실패

### TC-A04 (Negative) title 크기 초과 (1025자)

- **입력**: title = "a".repeat(1025)
- **기대**: `deny` — `d.title.size() <= 1024` 실패

### TC-A05 (Negative) memo 크기 초과 (101자)

- **입력**: memo = "a".repeat(101)
- **기대**: `deny` — `d.memo.size() <= 100` 실패

### TC-A06 (Positive) memo null 허용

- **입력**: 정상 필드 + `memo: null`
- **기대**: `allow`

### TC-A07 (Negative) topicLabels 크기 초과 (51개)

- **입력**: topicLabels = Array(51).fill("label")
- **기대**: `deny` — `topicLabels.size() <= 50` 실패

### TC-A08 (Positive) topicLabels 50개

- **입력**: topicLabels = Array(50).fill("label")
- **기대**: `allow`

### TC-A09 (Negative) isRead 타입 오류 (string)

- **입력**: `isRead: "false"` (string)
- **기대**: `deny` — `d.isRead is bool` 실패

### TC-A10 (Negative) createdAt 타입 오류 (string)

- **입력**: `createdAt: "2024-01-01"` (string)
- **기대**: `deny` — `d.createdAt is timestamp` 실패

### TC-A11 (Positive) thumbnailUrl null 허용

- **입력**: 정상 필드 + `thumbnailUrl: null`
- **기대**: `allow`

### TC-A12 (Negative) thumbnailUrl 크기 초과 (2049자)

- **입력**: thumbnailUrl = "https://" + "a".repeat(2041) + ".jpg"
- **기대**: `deny`

### TC-A13 (Positive) softDelete (부분 update — deletedAt 설정)

- **전제**: TC-A01 으로 생성된 완전한 doc 존재
- **입력**: `{deletedAt: <timestamp>, updatedAt: <timestamp>}` 부분 update
- **기대**: `allow` — 병합 결과 doc 이 isValidArticle 통과

### TC-A14 (Positive) isBookmarked update

- **전제**: 완전한 doc 존재
- **입력**: `{isBookmarked: true, updatedAt: <timestamp>}` 부분 update
- **기대**: `allow`

### TC-A15 (Negative) 다른 uid 쓰기 시도

- **전제**: uid "user-A" 로 인증
- **경로**: `users/user-B/articles/xxx`
- **기대**: `deny` — `uid != userId`

### TC-A16 (Positive) delete (인증 일치)

- **기대**: `allow`

### TC-A17 (Negative) 미인증 read

- **기대**: `deny`

---

## 4. Label 테스트 케이스

### TC-L01 (Positive) 정상 create

- **입력**: `{name: "독서", colorValue: 4284955319, createdAt: <timestamp>}`
- **기대**: `allow`

### TC-L02 (Negative) name 누락

- **입력**: `{colorValue: 4284955319, createdAt: <timestamp>}`
- **기대**: `deny`

### TC-L03 (Negative) name 크기 초과 (65자)

- **입력**: name = "a".repeat(65)
- **기대**: `deny`

### TC-L04 (Negative) colorValue 타입 오류 (string)

- **입력**: `colorValue: "#FF0000"` (string)
- **기대**: `deny`

### TC-L05 (Positive) deletedAt null 허용

- **입력**: 정상 필드 + `deletedAt: null`
- **기대**: `allow`

### TC-L06 (Positive) softDelete (부분 update)

- **전제**: TC-L01 으로 생성된 완전한 doc 존재
- **입력**: `{deletedAt: <timestamp>, updatedAt: <timestamp>}` 부분 update
- **기대**: `allow`

### TC-L07 (Negative) 다른 uid 쓰기 시도

- **기대**: `deny`

---

## 5. 레거시 doc 확인 (Staging 전용)

> 구버전 앱(isBookmarked 또는 topicLabels 미포함 버전)이 쓴 doc 이 있을 경우,
> `update` rules 에서 병합 결과에 필수 필드가 없어 실패할 수 있다.

1. Firebase Console → Firestore → 임의 사용자 articles 서브컬렉션에서 문서 샘플링
2. `url`, `title`, `platform`, `isRead`, `createdAt` 5개 필드가 모두 있는지 확인
3. 누락 문서가 있으면 마이그레이션 스크립트로 기본값 채운 후 배포

---

## 6. 배포 명령

```bash
# staging 프로젝트
firebase use staging
firebase deploy --only firestore:rules

# production 프로젝트 (staging 검증 완료 후)
firebase use production
firebase deploy --only firestore:rules
```

---

## 7. 참조

- Firebase Rules 공식 문서: https://firebase.google.com/docs/firestore/security/get-started
- Rules 단위 테스트: https://firebase.google.com/docs/rules/unit-tests
- Firestore Rules 언어 레퍼런스: https://firebase.google.com/docs/reference/rules/rules
