# Project State

> **용도**: normalized-growth-skill의 세션 영속 상태 파일.
> **규칙**: 스킬이 자동 관리. 사용자 직접 편집 시 이전 단계 완료 여부 재검증 가능.

---

## 기본 정보

```yaml
project_name: clib
created_at: 2026-04-20
last_updated: 2026-04-20

project_type: existing
stage: growth          # 사용자가 명시적으로 growth 선언 (iOS 출시 직후)

platform: app          # Flutter iOS+Android, 다만 Android는 미출시
tech_stack:
  - Flutter (앱)
  - Hive (로컬 DB)
  - Firebase Auth + Firestore (선택적 동기화)
  - AdMob
  - Vanilla HTML/CSS/JS + GitHub Pages (랜딩 — 별도 레포 clib-support)

app_type: tool
app_type_reasoning: 스와이프 카드 UI로 저장된 링크를 소비하는 개인 지식 큐레이션 도구. SaaS도 커뮤니티도 아님.
```

---

## 진행 상황

```yaml
current_playbook: playbooks/40_growth.md (마이크로 사이클 — 랜딩 리뉴얼)
completed_steps: []
next_step: "landing-renewal.1 (자산 수집 → HTML 골격 → 콘텐츠 이식 → QA)"
current_cycle: 1
```

> **참고**: 정공이라면 50_existing_audit를 먼저 거쳐야 하지만, 이번 세션은 사용자 명시 결정으로 우회. DECISION_LOG `D-001` 참조.

---

## 생성된 산출물 위치

> **크로스 레포 주의**: 랜딩 산출물은 `clib-support/docs/`에 위치. 이 PROJECT_STATE는 clib/ 루트에 있음.

```yaml
artifacts:
  marketing_context: not_created
  positioning: not_created
  battlecard: not_created
  design_system_master: not_created  # 사실상 lib/theme/design_tokens.dart 가 baseline
  design_system_pages: []
  landing_page: ../clib-support/docs/index.html  # 기존 베이스라인, 리뉴얼 대상
  aso: not_created
  tracking_plan: not_created
  launch_content_dir: not_created
  uiux_checklist: not_created
  marketing_checklist: not_created
  audit_findings_dir: not_created
  decision_log: ./DECISION_LOG.md
```

---

## 중요 결정 (요약)

```yaml
key_decisions:
  - "2026-04-20: existing+growth 정공 audit 우회. 사용자 명시 결정으로 단일 산출물(랜딩 리뉴얼)만 진행 (D-001)"
  - "2026-04-20: 랜딩 위치는 기존 GitHub Pages (clib-support 레포 docs/) 유지. 신규 도메인 미정 (D-002 대기)"
  - "2026-04-20: Android 미출시 — 다운로드 버튼은 iOS만 표시, '곧 출시 예정' 캡션 1줄 (D-003)"
  - "2026-04-20: clib 메인 레포 기준 브랜치는 develop. clib-support는 main"
```

---

## 현재 차단 상황

```yaml
blockers:
  - description: "iOS App Store URL 미확보 — 다운로드 버튼 hrefs를 채울 수 없음"
    step: "landing-renewal.1"
    resolution_needed: "사용자가 apps.apple.com/... 전체 URL 제공"
  - description: "앱 스크린샷 5종 미확보 — Hero/feature 이미지 placeholder 상태"
    step: "landing-renewal.2"
    resolution_needed: "사용자가 5장 캡처 제공 (hero 1, feature 4)"
```

---

## 버전 이력

```yaml
history:
  - date: 2026-04-20
    change: "PROJECT_STATE 신규 생성. existing+growth 확정"
  - date: 2026-04-20
    change: "DECISION_LOG D-001 audit 우회 결정"
```

---

## 사용자 메모 (자유 형식)

```
- 랜딩 톤: Apple-style 풀-블리드 스크롤
- 9개 언어 다국어 (T 객체) 100% 재활용
- 프레임워크 금지 (GH Pages 정적 호스팅)
```
