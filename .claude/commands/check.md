AGENTS.md의 "검증" 단계를 수행해줘.

1. `flutter analyze` 실행 — warning/error 0건 확인
2. 변경된 파일에서 하드코딩된 한국어/영어 UI 문자열이 있는지 확인 (ARB 미사용)
3. `app_ko.arb`와 `app_en.arb`에 누락된 키가 없는지 비교
4. 모델(Article, Label) 변경이 있었다면 `dart run build_runner build` 실행
5. 결과를 한 줄로 요약 보고
