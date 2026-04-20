# PR 11 — Cleanup + 문서화

> 모든 화면 전환 완료 후 정리. 미사용 코드 제거, CLAUDE.md 갱신, 최종 회귀 테스트.

**의존성**: PR 2~9 모두 완료
**브랜치**: `feature/bloc-11-cleanup`
**예상 작업 시간**: 2~3시간
**난이도**: ⭐⭐

---

## 1. 목표

- 미사용 코드 / 주석 / import 제거
- 전역 notifier 유지 여부 최종 결정 (기본: 유지)
- `CLAUDE.md` 갱신 — 새 구조 문서화
- `doc/bloc-migration/README.md` 최종 상태 기록
- 최종 회귀 테스트

---

## 2. 체크리스트

### 2.1 코드 클린업

- [ ] `lib/main.dart`에 더 이상 쓰이지 않는 전역 변수/함수 제거
- [ ] 각 화면의 미사용 import 제거 (`dart fix --apply` 후 수동 검토)
- [ ] 각 Cubit/Bloc의 디버그 print 제거
- [ ] 미사용 ARB 키 `arb-sync-checker` 서브에이전트로 점검
- [ ] `flutter analyze` — 경고 포함 0건

### 2.2 Notifier 유지 여부 결정

현재 계획상 `articlesChangedNotifier`, `labelsChangedNotifier`는 **유지**(라이트 스코프).

**재평가 기준**:
- 모든 Cubit이 notifier에서 pull → `load()`로 재조회 → 비용은 있으나 correctness 보장
- 만약 성능 이슈가 있다면 `DatabaseService`가 `Stream<ArticlesChanged>`를 직접 제공하도록 개선 (별도 PR)

**결정**:
- [ ] 유지 → SESSION_LOG.md에 결정 사유 기록
- [ ] 제거 → 이 PR에서 별도 리팩터 수행 (범위 큼)

### 2.3 문서 업데이트

`CLAUDE.md` 수정:
- **전역 상태** 섹션: `ValueNotifier` 4개 → `ThemeCubit`, `AuthCubit` + 남은 notifier 2개
- **화면별 주요 로직** 섹션: BLoC 사용 명시 (Cubit 기본, HomeBloc 예외)
- **프로젝트 구조** 섹션: `lib/blocs/` 추가
- **기술 스택** 표에 `flutter_bloc`, `equatable` 추가
- **개발 컨벤션** 섹션에 새 규칙 추가:
  - 상태 관리는 flutter_bloc 기반
  - 기본은 Cubit, 복잡한 화면만 Bloc
  - 전역은 ThemeCubit + AuthCubit, 나머지는 화면 로컬 BlocProvider
  - 상태 클래스는 equatable + copyWith 필수

`doc/bloc-migration/README.md`의 진행 현황 트래커 모두 🟢으로 업데이트.

### 2.4 최종 회귀 테스트

- [ ] 앱 첫 실행(Hive 초기화) → 온보딩 → 메인
- [ ] 아티클 저장(공유 시트)
- [ ] 홈 스와이프 흐름
- [ ] 라이브러리 탭 이동 + 라벨/북마크 카드 진입
- [ ] 다중선택 일괄 액션
- [ ] 롱프레스 액션
- [ ] 라벨 CRUD + 알림 설정
- [ ] 테마 전환 + 재시작 유지
- [ ] Google/Apple 로그인 + 동기화
- [ ] 로그아웃 → 다시 로그인 → 동기화 정상
- [ ] 계정 삭제
- [ ] `flutter run --release` 크래시 없이 동작

### 2.5 성과 측정

| 항목 | PR 0 (시작 전) | PR 11 (종료 후) |
|------|---------------|----------------|
| 총 LOC (`lib/`) | ~8,705 | ? |
| 화면 LOC 합 | ~3,749 | ? |
| widget_test 개수 | 1 | ? |
| Bloc 유닛 테스트 | 0 | ? |
| setState 호출 지점 | ? | ? (grep으로 측정) |
| ValueNotifier 전역 | 4 | 2 (유지 시) |

측정 명령:
```bash
# setState 카운트
grep -rn "setState" lib/ | wc -l

# ValueNotifier 카운트
grep -rn "ValueNotifier" lib/ | wc -l
```

---

## 3. PR 메시지

```
BLoC PR11: 전환 마무리 — 클린업 + 문서 갱신

- 미사용 코드/import 제거
- CLAUDE.md 갱신: flutter_bloc 기반 상태 관리 문서화
- doc/bloc-migration 진행 현황 최종 기록
- 최종 회귀 테스트 통과

성과:
- 화면 LOC N% 감소
- setState 호출 N개 → N개
- 유닛 테스트 N개 추가
```

---

## 4. 핸드오프 노트

### 전환 완료 상태
- (작성)

### 남은 부채 / 후속 작업
- (작성: 예 — Repository 계층 도입, Hive Stream 전환, 테스트 커버리지 보강)

### 배운 점
- (작성)

### 검증 결과
- (작성)
