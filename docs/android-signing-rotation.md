# Android Keystore 비밀번호 로테이션 (M-9)

## 배경

`android/key.properties`의 `storePassword=123456`, `keyPassword=123456`은 brute-force 즉시 해제 가능. 파일 자체는 `android/.gitignore`로 추적 제외되어 있으나, 개발자 머신 백업/유출 시 즉시 무력화된다.

**위협 등급**:
- Play App Signing **활성**: upload key만 영향 — Play Console에서 교체 가능 (다운타임 없음).
- Play App Signing **비활성** (직접 .apk 사이드로딩): app signing key가 유출되면 멀웨어 업데이트 배포 가능 — **즉시 로테이션 필수**.

## 사전 확인 (필수)

1. **Play App Signing 활성화 여부 확인**
   - Google Play Console → 앱 선택 → Setup → App integrity → App signing
   - "Play app signing is enabled" 표시 확인
   - 비활성이면 Play Console에서 enable (1회성, 비가역)

2. 현재 keystore 위치 확인: `~/upload-keystore.jks` (key.properties의 `storeFile`)

## 로테이션 절차

### Play App Signing 활성 (권장 경로)

```bash
# 1. 새 upload keystore 생성 (강력 비번)
NEW_PASS=$(openssl rand -base64 24)   # 32+ 문자
NEW_KEYSTORE=~/upload-keystore-new.jks
KEY_ALIAS=upload

keytool -genkey -v \
  -keystore "$NEW_KEYSTORE" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -storepass "$NEW_PASS" \
  -keypass "$NEW_PASS" \
  -dname "CN=clib, OU=Mobile, O=Personal, L=Seoul, ST=Seoul, C=KR"

# 2. 1Password / macOS Keychain에 비번 저장
echo "$NEW_PASS" | pbcopy   # 클립보드 → 1Password
# 또는: security add-generic-password -a "$USER" -s "clib-upload-keystore" -w "$NEW_PASS"

# 3. PEM 추출 (Play Console 업로드용)
keytool -export -rfc \
  -keystore "$NEW_KEYSTORE" \
  -alias "$KEY_ALIAS" \
  -file ~/upload-cert-new.pem \
  -storepass "$NEW_PASS"

# 4. Play Console에서 upload key 교체 요청
#    Setup → App integrity → App signing → "Request upload key reset"
#    → ~/upload-cert-new.pem 업로드
#    → Google 승인 (수 분 ~ 24시간)

# 5. 승인 후 key.properties 업데이트
cat > android/key.properties <<EOL
storePassword=$NEW_PASS
keyPassword=$NEW_PASS
keyAlias=$KEY_ALIAS
storeFile=$NEW_KEYSTORE
EOL

# 6. 빌드 검증
flutter build appbundle --release
# bundletool 또는 Play Console에서 서명 확인

# 7. 기존 keystore 안전 삭제 (백업 후)
mv ~/upload-keystore.jks ~/upload-keystore.jks.archive
chmod 000 ~/upload-keystore.jks.archive
```

### Play App Signing 비활성 (긴급 마이그레이션)

비활성 상태이면 우선 활성화부터 진행:

1. 현재 release keystore로 마지막 빌드 후 Play Console 업로드
2. Play Console → "Use Play app signing" enable
3. 기존 keystore를 Google에 업로드 (한 번만 가능)
4. 이후 위 "Play App Signing 활성" 절차 따라 upload key 교체

## CI/CD 시크릿 (옵션)

GitHub Actions 등에서 자동 빌드 사용 시:
- `KEYSTORE_BASE64`: `base64 -i upload-keystore-new.jks | pbcopy`
- `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
- 워크플로우에서 `echo "$KEYSTORE_BASE64" | base64 -d > /tmp/key.jks`
- `key.properties` 동적 생성 후 빌드

## 검증 체크리스트

- [ ] 새 keystore 비번 = 24+ 자 random (예: `openssl rand -base64 24`)
- [ ] 비번을 1Password / Keychain / CI 시크릿에 저장
- [ ] Play Console에서 upload key 교체 승인 완료
- [ ] `flutter build appbundle --release` 통과
- [ ] 새 .aab Play Console internal testing 트랙에 업로드 → 배포 성공 확인
- [ ] 기존 keystore 파일 chmod 000 또는 안전 삭제

## 예상 영향

- 정상: Play App Signing 활성 시 사용자에게 영향 없음 (Google이 동일 app signing key로 재서명)
- 비활성 시: 새 키로 서명한 .apk는 기존 사용자 기기에 설치 불가 (앱 재설치 필요) — 반드시 Play App Signing 활성화 후 진행
