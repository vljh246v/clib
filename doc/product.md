📄 제1탄: [상세 기획서] 프로젝트 Clib (클립)
1. 프로젝트 개요

서비스명: Clib (클립)

슬로건: 저장만 하던 습관에서 읽는 습관으로, 스와이프 지식 도서관

핵심 가치: 무마찰 수집(Zero-friction Scraping), 게임화된 소비(Swiping Interaction), 능동적 재방문(Scheduled Push)

개발 환경: Flutter (Dart), iOS & Android

2. 서비스 로직 및 데이터 구조

Local-first 아키텍처: 초기 가입 절차 없이 모든 데이터는 기기 내부 DB(Isar 또는 Hive 추천)에 저장.

데이터 스키마 (Article Model):

id: 고유 식별자

url: 수집된 원본 링크

title: OpenGraph 제목 (실패 시 URL로 대체)

thumbnailUrl: OpenGraph 이미지 (실패 시 기본 이미지)

platform: URL 도메인 분석을 통한 자동 분류 (Youtube, Instagram, Blog, Etc)

topicLabels: 사용자 지정 라벨 리스트

isRead: 읽음 상태 여부 (Boolean)

createdAt: 생성 일시

스크래핑 로직:

http 또는 html 패키지를 활용해 og:title, og:image, og:description 추출.

인스타그램 등 동적 렌더링 사이트의 경우, 기본 메타데이터 추출 실패 시에 대한 예외 처리 로직 포함.

3. 핵심 기능 명세

기능 A (수집): OS 공유 시트 연동을 통해 앱 외부에서 URL 수신. 백그라운드에서 스크래핑 진행 후 저장 알림 제공.

기능 B (소비): 스택 구조의 카드 인터페이스. 오른쪽(읽음), 왼쪽(나중에) 스와이프 처리.

기능 C (알림): flutter_local_notifications를 사용한 기기 내 스케줄링. 특정 라벨의 '미완독' 데이터 개수를 포함한 푸시 발송.

기능 D (통계): 라벨별 (isRead == true 인 개수) / (전체 개수) 계산 및 시각화.