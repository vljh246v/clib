# Clib App Store 로케일별 메타데이터 가이드

> 작성일: 2026-04-28
> 적용 위치: App Store Connect → My Apps → Clib → App Information / 각 로케일 탭
> 현재 점수: 38/100 (D). 본 문서 적용 후 재감사 권장.

## 공통 규칙 (전 로케일 적용)

| 필드 | 한도 | 인덱싱 | 비고 |
|------|------|--------|------|
| Title | **30 chars** | O | 가장 강력한 검색 신호 |
| Subtitle | **30 chars** | O | 두 번째 검색 신호 |
| Promotional Text | 170 chars | X | 검색 영향 X, 컨버전 영향 O. 릴리즈 없이 갱신 가능 |
| Keywords | **100 bytes** | O (숨김) | 쉼표만 구분, 공백 금지, CJK = 3 byte/char |
| Description | 4,000 chars | X (Apple) | 컨버전 전용 |
| What's New | 4,000 chars | X | 신규 변경점 |

**중요 원칙**:
1. Title + Subtitle + Keywords 사이 **단어 중복 금지** (Apple 한 번만 인덱싱). 중복 = 슬롯 낭비.
2. 브랜드명 `Clib`은 Title에만 한 번. Keywords field 빼라.
3. Keywords 공백 절대 금지 → `pocket,readlater` (X `pocket, readlater`).
4. Promotional Text는 컨버전·이벤트 알림용. 키워드 X.

**byte 카운터**: 입력 후 ASO 도구(AppFollow, AppTweak, Sensor Tower) 또는 https://mothereff.in/byte-counter 로 검증.

---

## 1. 한국어 (ko) — 기본 로케일

### Title (30 chars)
```
클립 Clib: 링크 저장 나중에 읽기
```
인덱싱 단어: `클립`, `Clib`, `링크`, `저장`, `나중에`, `읽기`

### Subtitle (30 chars)
```
북마크 카드 스와이프로 읽는 습관
```
인덱싱 추가: `북마크`, `카드`, `스와이프`, `습관`

### Keywords (100 bytes 이내)
```
pocket,readlater,raindrop,goodlinks,bookmark,reading,save,article,유튜브,인스타,틱톡,블로그,라벨
```
의도: 영문 경쟁 앱명 + 검색어 + 한국 플랫폼명. Title/Subtitle 단어 일체 미포함.

### Promotional Text (170 chars)
```
저장만 하던 링크, 이제 카드 한 장씩 스와이프로 읽어보세요. 회원가입 없이 30초, 라벨별 주간 푸시가 잊은 링크를 다시 꺼내드립니다.
```

### Description
```
유튜브, 인스타그램, 블로그… 저장만 하고 안 읽는 링크가 100개 쌓였나요?

클립(Clib)은 흩어진 링크를 카드 한 장씩 스와이프로 읽게 만드는 지식 도서관입니다.
주간 알림이 잊은 링크를 다시 꺼내, 저장 습관을 읽는 습관으로 바꿉니다.

■ 핵심 기능
- 회원가입 없이 시작 — 로컬 저장(Hive)으로 즉시 사용
- 카드 스와이프 — 오른쪽으로 읽음, 왼쪽으로 나중에
- 라벨로 정리 — 라벨별 주간 푸시 알림 설정
- 한 줄 메모 — 100자 이내 핵심만 기록
- 북마크 — 다시 보고 싶은 카드 별도 모음
- 자동 분류 — 유튜브·인스타그램·X·틱톡·페이스북·링크드인·깃허브·레딧·스레드·네이버 블로그
- 클라우드 동기화(선택) — Google 로그인 시 기기 간 자동 sync
- 다크모드, 다국어(10개) 지원

■ 이런 분께 추천
- Pocket·Raindrop·GoodLinks 대안을 찾는 분
- 저장 폴더가 무덤이 된 분
- 짧게 끊어 읽는 습관을 만들고 싶은 분

■ 개인정보
계정 없이 100% 로컬 저장. Google 로그인은 선택이며, 동기화 외 데이터 수집 없음.

지금 무료로 시작하세요. 저장만 하던 링크를 다시 만나는 가장 빠른 방법.
```

### What's New (예시 — 1.1.2)
```
- Google 로그인 오류 수정
- 홈 가이드 오버레이 안정화
- 라벨 알림 다국어 메시지 개선
```

---

## 2. 영어 (en-US) — 글로벌 fallback

### Title (30 chars)
```
Clib: Read Later & Bookmarks
```
28 chars. 인덱싱: `Clib`, `Read`, `Later`, `Bookmarks`.

### Subtitle (30 chars)
```
Swipe to revisit saved links
```
27 chars. 인덱싱: `Swipe`, `revisit`, `saved`, `links`.

### Keywords (100 bytes)
```
pocket,raindrop,matter,goodlinks,instapaper,article,reading,list,youtube,instagram,tiktok,reddit,blog,label
```

### Promotional Text (170 chars)
```
Stop hoarding links. Swipe through saved articles like cards, set weekly reminders per label, and finally read what you saved. Local-first, no signup needed.
```

### Description
```
Saved 100 links you never read?

Clib turns your link graveyard into a swipe-card library. Read articles one card at a time, set weekly reminders per label, and turn saving into reading.

■ Features
- Start with no signup — instant local storage
- Swipe right to read, left for later
- Organize with labels and weekly push reminders
- One-line memos (100 chars)
- Bookmark cards you want to revisit
- Auto-detect: YouTube, Instagram, X, TikTok, Facebook, LinkedIn, GitHub, Reddit, Threads, blogs
- Optional cloud sync via Google sign-in
- Dark mode, 10 languages

■ Built for
- Pocket / Raindrop / GoodLinks users looking for an alternative
- Anyone with a "save for later" folder that became a graveyard
- Readers who want bite-sized, daily reading habits

■ Privacy
100% local by default. Google sign-in is optional and only used for sync — no data collection.

Free to start. Make peace with your saved links.
```

### What's New
```
- Fixed Google sign-in error
- Stabilized home guide overlay
- Improved localized notifications
```

---

## 3. 일본어 (ja)

### Title (30 chars)
```
Clib: 後で読む リンク保存アプリ
```
인덱싱: `Clib`, `後で読む`, `リンク`, `保存`, `アプリ`.

### Subtitle (30 chars)
```
スワイプで読むブックマーク習慣
```
인덱싱: `スワイプ`, `読む`, `ブックマーク`, `習慣`.

### Keywords (100 bytes)
```
pocket,readlater,raindrop,bookmark,article,reading,youtube,instagram,tiktok,ブログ,ラベル,メモ,記事
```

### Promotional Text (170 chars)
```
保存だけして読まないリンク、もうありませんか？カードをスワイプして1日1本ずつ。ラベル別の週次プッシュで忘れたリンクをもう一度。登録不要、ローカル保存。
```

### Description
```
保存したまま読んでいないリンクが100件たまっていませんか？

Clib（クリブ）は、散らばったリンクをカード1枚ずつスワイプで読むナレッジライブラリです。週次プッシュ通知が忘れたリンクをもう一度呼び出し、「保存する習慣」を「読む習慣」に変えます。

■ 主な機能
- 登録不要 — ローカル保存で即利用
- カードスワイプ — 右で既読、左で後で
- ラベルで整理 — ラベル別の週次プッシュ通知
- 1行メモ — 100文字以内
- ブックマーク — お気に入りカードを別途保存
- 自動分類 — YouTube、Instagram、X、TikTok、Facebook、LinkedIn、GitHub、Reddit、Threads、ブログ
- クラウド同期（任意） — Googleログインでデバイス間同期
- ダークモード、10言語対応

■ こんな方に
- Pocket、Raindrop、GoodLinksの代替を探している方
- 「あとで読む」フォルダが墓場になっている方
- 短く区切って毎日読む習慣を作りたい方

■ プライバシー
デフォルトで100%ローカル保存。Googleログインは任意、同期以外のデータ収集なし。

無料ではじめる。保存したリンクともう一度出会う、いちばん早い方法。
```

### What's New
```
- Googleログインエラーを修正
- ホームガイドオーバーレイの安定化
- 多言語通知メッセージの改善
```

---

## 4. 중국어 간체 (zh-Hans)

### Title (30 chars)
```
Clib：稍后阅读 链接收藏书签
```
인덱싱: `Clib`, `稍后阅读`, `链接`, `收藏`, `书签`.

### Subtitle (30 chars)
```
滑动卡片养成阅读习惯
```
인덱싱: `滑动`, `卡片`, `阅读`, `习惯`.

### Keywords (100 bytes)
```
pocket,readlater,raindrop,bookmark,reading,article,youtube,instagram,tiktok,博客,标签,笔记,文章
```

### Promotional Text (170 chars)
```
保存了却从不阅读的链接，从今天开始改变。卡片式滑动，每天读一篇；按标签设置每周提醒，让被遗忘的链接重新回到视线。无需注册，本地优先。
```

### Description
```
是否囤了100条链接却从未阅读？

Clib 把你的"稍后阅读"墓地变成可滑动的卡片图书馆。一次一张卡片，按标签设置每周提醒，把"收藏的习惯"变成"阅读的习惯"。

■ 核心功能
- 无需注册 — 本地存储即开即用
- 卡片滑动 — 右滑已读，左滑稍后
- 标签整理 — 按标签设置每周推送提醒
- 一行笔记 — 100字以内
- 书签收藏 — 单独保存重要卡片
- 自动识别 — YouTube、Instagram、X、TikTok、Facebook、LinkedIn、GitHub、Reddit、Threads、博客
- 云同步（可选） — Google 登录后跨设备同步
- 深色模式、10 种语言

■ 适合人群
- 寻找 Pocket、Raindrop、GoodLinks 替代品的用户
- 收藏夹已经变成"链接墓地"的人
- 想培养每日短篇阅读习惯的人

■ 隐私
默认 100% 本地存储。Google 登录可选，仅用于同步，不收集其他数据。

免费使用。重新遇见你保存过的链接，从今天开始。
```

### What's New
```
- 修复 Google 登录错误
- 稳定首页引导浮层
- 改进多语言通知文案
```

---

## 5. 중국어 번체 (zh-Hant)

### Title (30 chars)
```
Clib：稍後閱讀 連結收藏書籤
```

### Subtitle (30 chars)
```
滑動卡片養成閱讀習慣
```

### Keywords (100 bytes)
```
pocket,readlater,raindrop,bookmark,reading,article,youtube,instagram,tiktok,部落格,標籤,筆記,文章
```

### Promotional Text (170 chars)
```
儲存了卻從不閱讀的連結，從今天開始改變。卡片式滑動，每天讀一篇；依標籤設定每週提醒，讓被遺忘的連結重新回到視線。無需註冊，本機優先。
```

### Description
```
是否囤了 100 條連結卻從未閱讀？

Clib 把你的「稍後閱讀」墓地變成可滑動的卡片圖書館。一次一張卡片，依標籤設定每週提醒，把「收藏的習慣」變成「閱讀的習慣」。

■ 核心功能
- 無需註冊 — 本機儲存即開即用
- 卡片滑動 — 右滑已讀，左滑稍後
- 標籤整理 — 依標籤設定每週推播提醒
- 一行筆記 — 100 字以內
- 書籤收藏 — 單獨儲存重要卡片
- 自動辨識 — YouTube、Instagram、X、TikTok、Facebook、LinkedIn、GitHub、Reddit、Threads、部落格
- 雲端同步（選用） — Google 登入後跨裝置同步
- 深色模式、10 種語言

■ 適合對象
- 尋找 Pocket、Raindrop、GoodLinks 替代品的使用者
- 收藏夾已經變成「連結墓地」的人
- 想培養每日短篇閱讀習慣的人

■ 隱私
預設 100% 本機儲存。Google 登入為選用功能，僅用於同步，不收集其他資料。

免費使用。重新遇見你儲存過的連結，從今天開始。
```

### What's New
```
- 修復 Google 登入錯誤
- 穩定首頁引導浮層
- 改進多語言通知文案
```

---

## 6. 독일어 (de)

### Title (30 chars)
```
Clib: Später Lesen & Lesezeichen
```
32 chars — **1자 초과**. 줄임안: `Clib: Später Lesen Bookmarks` (28).

### Subtitle (30 chars)
```
Wische zu deinen Links zurück
```
29 chars.

### Keywords (100 bytes)
```
pocket,readlater,raindrop,merkliste,artikel,lesen,liste,youtube,instagram,tiktok,blog,label,notiz
```

### Promotional Text (170 chars)
```
Schluss mit Links, die nur gespeichert werden. Wische durch deine Sammlung wie Karten, setze wöchentliche Erinnerungen pro Label und lies endlich, was du speicherst.
```

### Description
```
Hast du 100 Links gespeichert und nie gelesen?

Clib verwandelt deinen Link-Friedhof in eine Karten-Bibliothek. Lies Artikel Karte für Karte, setze wöchentliche Erinnerungen pro Label und mache aus dem Speichern echtes Lesen.

■ Funktionen
- Kein Konto nötig — sofortiger lokaler Speicher
- Karten wischen — rechts zum Lesen, links für später
- Labels mit wöchentlichen Push-Erinnerungen
- Einzeilige Notizen (max. 100 Zeichen)
- Lesezeichen für wichtige Karten
- Automatische Erkennung: YouTube, Instagram, X, TikTok, Facebook, LinkedIn, GitHub, Reddit, Threads, Blogs
- Optionale Cloud-Sync via Google-Login
- Dark Mode, 10 Sprachen

■ Für dich, wenn
- Du eine Alternative zu Pocket / Raindrop / GoodLinks suchst
- Dein "Später lesen"-Ordner zum Friedhof wurde
- Du eine tägliche Lesegewohnheit aufbauen willst

■ Datenschutz
Standardmäßig 100% lokal. Google-Login ist optional und nur für die Synchronisierung — keine sonstige Datenerfassung.

Kostenlos starten.
```

### What's New
```
- Google-Login-Fehler behoben
- Home-Guide-Overlay stabilisiert
- Mehrsprachige Benachrichtigungen verbessert
```

---

## 7. 스페인어 (es-ES)

### Title (30 chars)
```
Clib: Leer Después y Marcadores
```
31 chars — **1자 초과**. 줄임: `Clib: Leer Después · Marcador` (29).

### Subtitle (30 chars)
```
Desliza tarjetas y lee tus links
```
32 → 줄임: `Desliza tarjetas, lee tus links` (31) → `Desliza tarjetas y lee links` (28).

### Keywords (100 bytes)
```
pocket,readlater,raindrop,marcador,articulo,lectura,lista,youtube,instagram,tiktok,blog,etiqueta,nota
```

### Promotional Text (170 chars)
```
Deja de acumular enlaces. Desliza tu colección como tarjetas, recibe recordatorios semanales por etiqueta y por fin lee lo que guardas. Sin registro, local primero.
```

### Description
```
¿Tienes 100 enlaces guardados que nunca leíste?

Clib convierte tu cementerio de enlaces en una biblioteca de tarjetas deslizables. Lee artículos tarjeta por tarjeta, configura recordatorios semanales por etiqueta y transforma el guardar en leer.

■ Funciones
- Sin registro — almacenamiento local instantáneo
- Desliza tarjetas — derecha para leer, izquierda para después
- Organiza con etiquetas y notificaciones semanales
- Notas de una línea (máx. 100 caracteres)
- Marcadores para tarjetas favoritas
- Detección automática: YouTube, Instagram, X, TikTok, Facebook, LinkedIn, GitHub, Reddit, Threads, blogs
- Sincronización en la nube opcional con Google
- Modo oscuro, 10 idiomas

■ Ideal para
- Usuarios buscando alternativa a Pocket / Raindrop / GoodLinks
- Cualquiera con una carpeta "para después" abandonada
- Lectores que quieren un hábito diario de lectura corta

■ Privacidad
100% local por defecto. El inicio de sesión con Google es opcional y solo para sincronización — sin recopilación de datos.

Gratis para empezar.
```

### What's New
```
- Corregido error de inicio de sesión con Google
- Estabilizada la guía superpuesta de inicio
- Mejoradas las notificaciones multilingües
```

---

## 8. 프랑스어 (fr-FR)

### Title (30 chars)
```
Clib : Lire Plus Tard, Favoris
```
30 chars exact.

### Subtitle (30 chars)
```
Glisser pour lire vos liens
```
27 chars.

### Keywords (100 bytes)
```
pocket,readlater,raindrop,favori,article,lecture,liste,youtube,instagram,tiktok,blog,label,note
```

### Promotional Text (170 chars)
```
Arrêtez d'accumuler des liens. Faites glisser votre collection comme des cartes, recevez des rappels hebdomadaires par label, et lisez enfin ce que vous sauvegardez.
```

### Description
```
100 liens enregistrés, jamais lus ?

Clib transforme votre cimetière de liens en bibliothèque de cartes à glisser. Lisez les articles carte par carte, programmez des rappels hebdomadaires par label, et faites de la sauvegarde une vraie lecture.

■ Fonctionnalités
- Sans inscription — stockage local instantané
- Glisser des cartes — droite pour lire, gauche pour plus tard
- Organisation par labels et notifications hebdomadaires
- Notes d'une ligne (100 caractères max)
- Favoris pour les cartes importantes
- Détection auto : YouTube, Instagram, X, TikTok, Facebook, LinkedIn, GitHub, Reddit, Threads, blogs
- Synchronisation cloud optionnelle via Google
- Mode sombre, 10 langues

■ Pour vous si
- Vous cherchez une alternative à Pocket / Raindrop / GoodLinks
- Votre dossier "à lire plus tard" est devenu un cimetière
- Vous voulez une habitude de lecture quotidienne courte

■ Confidentialité
100% local par défaut. La connexion Google est optionnelle et uniquement pour la synchronisation — aucune autre collecte de données.

Gratuit. Lancez-vous.
```

### What's New
```
- Correction de l'erreur de connexion Google
- Stabilisation de la superposition du guide d'accueil
- Amélioration des notifications multilingues
```

---

## 9. 포르투갈어 (pt-PT)

### Title (30 chars)
```
Clib: Ler Depois e Marcadores
```
29 chars.

### Subtitle (30 chars)
```
Deslize cartões e leia os links
```
31 → 줄임: `Deslize cartões para ler links` (30).

### Keywords (100 bytes)
```
pocket,readlater,raindrop,marcador,artigo,leitura,lista,youtube,instagram,tiktok,blog,etiqueta,nota
```

### Promotional Text (170 chars)
```
Pare de acumular links. Deslize a sua coleção como cartões, receba lembretes semanais por etiqueta e finalmente leia o que guarda. Sem registo, local em primeiro.
```

### Description
```
Tem 100 links guardados que nunca leu?

O Clib transforma o seu cemitério de links numa biblioteca de cartões deslizáveis. Leia artigos cartão a cartão, configure lembretes semanais por etiqueta e transforme guardar em ler.

■ Funcionalidades
- Sem registo — armazenamento local instantâneo
- Deslize cartões — direita para ler, esquerda para depois
- Organize com etiquetas e notificações semanais
- Notas de uma linha (máx. 100 caracteres)
- Marcadores para cartões favoritos
- Deteção automática: YouTube, Instagram, X, TikTok, Facebook, LinkedIn, GitHub, Reddit, Threads, blogs
- Sincronização na nuvem opcional via Google
- Modo escuro, 10 idiomas

■ Ideal para
- Quem procura uma alternativa ao Pocket / Raindrop / GoodLinks
- Quem tem uma pasta "para ler depois" abandonada
- Leitores que querem um hábito diário de leitura curta

■ Privacidade
100% local por predefinição. O início de sessão Google é opcional e só serve para sincronização — sem outra recolha de dados.

Grátis para começar.
```

### What's New
```
- Corrigido o erro de início de sessão Google
- Estabilizada a sobreposição do guia inicial
- Melhoradas as notificações multilíngues
```

---

## 작업 마스터 플랜

### Phase 0 — 사전 준비 (오늘, 30분)

- [ ] **0.1** App Store Connect 로그인 후 Clib 앱 → "App Store" 탭 → 현재 metadata 백업 (스크린샷 또는 텍스트 복사)
- [ ] **0.2** 현재 Subtitle 슬롯 비어있는지 확인 → 보고
- [ ] **0.3** 현재 Keywords field 내용 확인 → 보고
- [ ] **0.4** 현재 스크린샷 세트 (iPhone 6.5"/6.7", iPad, Mac) 개수·캡션 유무 확인
- [ ] **0.5** byte 카운터 북마크: https://mothereff.in/byte-counter

### Phase 1 — 메타데이터 텍스트 입력 (1-2일, 핵심)

각 로케일 9개를 다음 순서로 진행. **ko 우선, 그 외는 en-US 다음**:

#### 1.1 한국어 (ko) — 30분
- [ ] App Information → Subtitle 입력
- [ ] Version 1.1.x (또는 새 버전 1.1.3) → Promotional Text 입력
- [ ] Version → Title 변경 (`클립 Clib: 링크 저장 나중에 읽기`)
- [ ] Version → Description 교체
- [ ] Version → Keywords 입력 + byte 카운터로 100 이내 검증
- [ ] Version → What's New 입력
- [ ] Save & Verify (저장 시 빨간 카운터 없음 확인)

#### 1.2 영어 (en-US) — 30분
- [ ] 동일 항목 6개 입력
- [ ] 글로벌 fallback이므로 **품질 최우선**. 영어 카피라이팅 다시 한 번 검수

#### 1.3 일본어 (ja) — 20분
- [ ] 동일 항목 6개. CJK byte 주의 (한자/카나 = 3 byte)

#### 1.4 중국어 간체 (zh-Hans) — 20분
- [ ] 동일 항목 6개

#### 1.5 중국어 번체 (zh-Hant) — 15분
- [ ] 동일 항목 6개. zh-Hans 복붙 후 번체화 검수

#### 1.6 독일어 (de) — 20분
- [ ] **Title 30자 검증**. 초과 시 줄임안 적용
- [ ] 동일 항목 6개

#### 1.7 스페인어 (es-ES) — 20분
- [ ] **Title 30자 검증**. 줄임안 적용 가능성 큼
- [ ] 동일 항목 6개

#### 1.8 프랑스어 (fr-FR) — 20분
- [ ] 동일 항목 6개

#### 1.9 포르투갈어 (pt-PT) — 20분
- [ ] **Subtitle 30자 검증** (`Deslize cartões para ler links` = 30자 경계)
- [ ] 동일 항목 6개

### Phase 2 — 스크린샷 캡션 (3-5일)

App Store Connect 스크린샷에 텍스트 오버레이 박는 작업. June 2025부터 OCR 인덱싱.

- [ ] **2.1** 스크린샷 컨셉 5컷 결정 (제안: 저장→스와이프→라벨 필터→메모→sync)
- [ ] **2.2** Figma/Sketch에서 9 로케일 × 5컷 = 45 이미지 제작
  - iPhone 6.7": 1290 × 2796 px
  - iPhone 6.5": 1242 × 2688 px
  - iPad 12.9": 2048 × 2732 px
  - Mac: 1280 × 800 px (Apple Silicon)
- [ ] **2.3** 첫 3컷 캡션은 각 로케일 P0 키워드 박기 (ko: "링크 저장", "스와이프", "라벨 알림")
- [ ] **2.4** App Store Connect 업로드, 순서 검증 (첫 3장이 검색 결과에서 미리 보임)

### Phase 3 — App Preview Video (1주)

가장 큰 컨버전 레버. 자동재생 무음, +20-40%.

- [ ] **3.1** 스토리보드 5컷 작성 (15-30s)
  - 0-3s: 페인 포인트 (저장만 하고 안 읽는 폴더)
  - 3-7s: 공유시트 → Clib 저장
  - 7-15s: 카드 스와이프 (오른쪽 읽음 / 왼쪽 나중에)
  - 15-22s: 라벨 필터 + 주간 알림 설정
  - 22-30s: 클라우드 sync + 클로징 로고
- [ ] **3.2** iOS 시뮬레이터 + QuickTime 스크린 레코딩 (60fps)
  - 또는 ScreenStudio / Rotato 사용
- [ ] **3.3** Final Cut / iMovie / DaVinci 컷 + 자막 (각 로케일별 자막 트랙)
- [ ] **3.4** Apple 영상 사양 검증
  - .mov / .m4v / .mp4
  - 30fps 또는 60fps
  - 첫 프레임이 포스터 프레임 (정지 이미지로도 매력적이게)
- [ ] **3.5** 9 로케일 자막 트랙 또는 로케일별 영상 업로드

### Phase 4 — 리뷰 부트스트랩 (1-2주, 병행 가능)

리뷰 1 → 50+ 만들기. 별점 < 4.0 디부스트 위험 회피.

- [ ] **4.1** 코드: in-app review prompt 추가
  - 패키지: `in_app_review` ^2.0
  - 트리거 조건: 누적 읽음 카드 ≥ 10, 마지막 prompt 후 90일 경과, 365일 3회 한도
  - 위치: `HomeBloc` `SwipeRead` 핸들러 내 카운터 + `lib/services/review_prompt_service.dart` 신설
- [ ] **4.2** TDD: `test/services/review_prompt_service_test.dart` 작성 (Cubit 패턴)
- [ ] **4.3** 빌드 후 1.1.3 릴리즈 → TestFlight 검증 → App Store 제출
- [ ] **4.4** 외부 채널 발사 (리뷰 유도)
  - [ ] Product Hunt 등록 (영문 카피)
  - [ ] r/iosapps, r/productivity 게시
  - [ ] 한국 커뮤니티: 클리앙 모팬, 디시 앱 갤, 브런치 발행
  - [ ] 트위터 / 스레드 런칭 트윗
  - [ ] 친구·지인 베타 테스터 풀 (15-20명) → 정직한 리뷰 요청

### Phase 5 — 카테고리·이벤트 최적화 (1주)

- [ ] **5.1** App Store Connect → 보조 카테고리 추가
  - 후보: "참고자료(Reference)" 또는 "도서(Books)"
  - "참고자료"가 경쟁 적고 본 앱 핏 OK
- [ ] **5.2** In-App Events 등록 (Apple 검색 결과에 노출, 31일 max)
  - 이벤트 1: "이번 주 읽기 챌린지 — 카드 7장"
  - 이벤트 2: "라벨별 주간 알림 가이드"
  - 위치: App Store Connect → Features → In-App Events
- [ ] **5.3** Custom Product Page 1개 생성 (Title/Subtitle A/B 테스트용)
  - Variant A: 현재 적용한 Title
  - Variant B: 다른 키워드 조합
  - organic search 라우팅 비교

### Phase 6 — 모니터링·재감사 (적용 후 2주차)

- [ ] **6.1** ASO 도구 무료 트라이얼 가입
  - AppTweak 14일 무료
  - 또는 AppFollow 14일 무료
- [ ] **6.2** 키워드 순위 추적 등록 (한국·미국 스토어 각 30 키워드)
- [ ] **6.3** App Store Connect → Analytics
  - Impressions, Product Page Views, Conversion Rate 베이스라인 기록
  - 적용 전 데이터 vs 적용 후 14일 데이터 비교
- [ ] **6.4** 재감사: 본 문서의 점수표 다시 매겨 38 → 70+ 진입 확인
- [ ] **6.5** 실패 가설 발견 시 Custom Product Page B 안으로 전환

### Phase 7 — 장기 최적화 (월 단위 반복)

- [ ] **7.1** 매주 What's New 갱신 (작은 업데이트라도 freshness 신호)
- [ ] **7.2** Promotional Text 월 1회 갱신 (이벤트·시즌 반영, 빌드 없이 가능)
- [ ] **7.3** 부정 리뷰 100% 응답 (developer reply)
- [ ] **7.4** 6주마다 Store Listing Experiments 실행 (Google Play 출시 시)

---

## 우선순위 요약

| 순위 | 작업 | 임팩트 | 노력 | 시작 시점 |
|------|------|--------|------|----------|
| ★★★ 1 | Phase 1 — 9 로케일 메타데이터 | 검색 + 컨버전 | 4시간 | 즉시 |
| ★★★ 2 | Phase 4.1-4.3 — in-app review prompt | 컨버전 | 1일 | 1.1.3 릴리즈 |
| ★★★ 3 | Phase 3 — App Preview 영상 | 컨버전 +20-40% | 1주 | Phase 1 직후 |
| ★★ 4 | Phase 2 — 스크린샷 캡션 | 검색 + 컨버전 | 3-5일 | Phase 3 병행 |
| ★★ 5 | Phase 4.4 — 외부 채널 발사 | 리뷰 볼륨 | 2일 | Phase 4.3 후 |
| ★ 6 | Phase 5 — 카테고리 + 이벤트 | 검색 | 2시간 | 1주차 |
| ★ 7 | Phase 6 — 재감사 | 학습 | 1일 | 2-3주차 |

**총 예상 기간**: 3주 (Phase 0-5). 1인 작업 기준.

**14일 핵심 KPI**:
- Impressions: 베이스라인 대비 +200%
- Conversion Rate: 베이스라인 대비 +30%
- Ratings: 1 → 30+
- Average rating: 4.5+ 유지

## 참고

- Apple 공식 한도: https://developer.apple.com/app-store/product-page/
- Keywords field byte 규칙: CJK = 3 byte, 라틴 = 1 byte, 쉼표 = 1 byte, 공백 = 1 byte (낭비)
- 현재 점수 38/100 → 본 메타데이터 + 영상 + 리뷰 부트스트랩 적용 시 70+ 도달 예상
