새 UI 문자열을 i18n으로 추가해줘.

추가할 내용: $ARGUMENTS

1. `lib/l10n/app_ko.arb`에 한국어 키-값 추가
2. `lib/l10n/app_en.arb`에 영어 키-값 추가
3. 파라미터가 있으면 ICU 메시지 포맷 사용 (예: `"{count}개 선택됨"`)
4. 키 네이밍은 기존 ARB 파일의 컨벤션을 따름
5. 추가 후 `flutter gen-l10n` 실행
6. 사용 예시 코드 제시: `AppLocalizations.of(context)!.keyName`
