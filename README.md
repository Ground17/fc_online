# 피온4 전적검색 17%
FIFA Online 4 전용 전적검색 어플리케이션
Flutter application 입니다.

## 다운로드 링크
- [Android Play Store](https://play.google.com/store/apps/details?id=com.hyla981020.fifaonline)
- [Apple App Store](https://apps.apple.com/us/app/%ED%94%BC%EC%98%A84-%EC%A0%84%EC%A0%81%EA%B2%80%EC%83%89-17/id1618941272)

## 화면 구성
- main.dart
    - 어플을 실행했을 때의 초기 화면이다. 오른쪽 위에 최근 검색한 라이더를 한 눈에 볼 수 있도록 하여 이용자의 편의성을 조금 높였다.

- detail.dart
    - 실제 상세정보 페이지이다.

- classes.dart
  - API, Google Admob 등을 처리할 수 있는 class들을 만들었다.

- trade.dart
  - 거래 정보 내역 페이지이다. 

## (고급) API 이용법
[NEXON 개발자 센터](https://developers.nexon.com/fifaonline4)

### 메타데이터의 경우는 별도 API key 인증과정이 필요없다.

- Response Headers에서 이 서비스에 사용하는 데이터
    - Content-Length: 112721304 -> 메타데이터 다운로드 받을 때 전체 크기 추정, byte 단위이므로 1048576(=2^20)으로 나눠 메가바이트(MB) 단위로 바꿔줄 수 있음.
    - last-modified: Thu, 26 May 2022 06:00:23 GMT -> 메타데이터가 최근 다운받은 버전으로부터 변경되었는지 확인하여 변경될 때만 다운로드 체크