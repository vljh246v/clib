릴리즈 빌드를 준비해줘.

대상 플랫폼: $ARGUMENTS

1. `flutter analyze` — 0 issues 확인
2. `flutter test` — 테스트 통과 확인 (있는 경우)
3. 대상 플랫폼에 맞게 빌드:
   - `ios`: `flutter build ios --release`
   - `android`: `flutter build appbundle --release`
   - `both`: 양쪽 모두
4. 빌드 결과 보고 (성공 여부, 산출물 경로)
