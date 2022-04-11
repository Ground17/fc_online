# fifa
FIFA Online 4 전용 전적검색 어플리케이션
Flutter application 입니다.

## 다운로드 링크 (추후 작성)

## 화면 구성
- main.dart
    - 어플을 실행했을 때의 초기 화면이다. 오른쪽 위에 최근 검색한 라이더를 한 눈에 볼 수 있도록 하여 이용자의 편의성을 조금 높였다.

- detail.dart
    - 실제 상세정보 페이지이다.

## (고급) API 이용법
[NEXON 개발자 센터](https://developers.nexon.com/fifaonline4)

## (고급) API json 응답 상세 구조 (추후 작성)
### 메타데이터의 경우는 별도 API key 인증과정이 필요없다.

- Response Headers에서 이 서비스에 사용하는 데이터
    - Content-Length: 112721304 -> 메타데이터 다운로드 받을 때 전체 크기 추정