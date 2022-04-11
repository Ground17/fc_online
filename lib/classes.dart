import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'keys.dart';

class API {
  // 유저 닉네임으로 유저 정보 조회
  static infoFromNickname(String nickname) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/users?nickname=$nickname"),
      headers: headers, // in keys.dart
    );

    return User.fromJson(json.decode(response.body));
  }

  // 유저 고유 식별자로 유저 정보 조회
  static infoFromAccessId(String accessId) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/users/$accessId"),
      headers: headers, // in keys.dart
    );

    return User.fromJson(json.decode(response.body));
  }

  // 유저 고유 식별자로 역대 최고 등급 조회
  static maxdivision(String accessId) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/users/$accessId/maxdivision"),
      headers: headers, // in keys.dart
    );

    final List<MaxDivision> result = [];
    final list = json.decode(response.body);
    for (int i = 0; i < list.length; i++) {
      result.add(MaxDivision.fromJson(list[i]));
    }

    return result;
  }

  // 유저 고유 식별자로 유저의 매치 기록 조회
  static matchIds(String accessId, {int matchtype = 50, int offset = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/users/$accessId/matches?matchtype=$matchtype&offset=$offset&limit=$limit"),
      headers: headers, // in keys.dart
    );

    return json.decode(response.body); // matchid(String)가 array 형태로 나타남
  }

  // 유저 고유 식별자로 유저의 거래 기록 조회
  static trades(String accessId, {bool buy = true, int offset = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/users/$accessId/markets?tradetype=${buy ? "buy" : "sell"}&offset=$offset&limit=$limit"),
      headers: headers, // in keys.dart
    );

    // "tradeDate": "2022-04-01T21:50:52",
    // "saleSn": "6246f50e8689c100992907c8", // 거래 고유 식별자
    // "spid": 506212198,
    // "grade": 10, // 선수 강화 등급
    // "value": 289000000000 // 거래 선수 가치
    return json.decode(response.body); // array 형태로 나타남
  }

  // 매치 상세 기록 조회
  static match(String matchid) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/matches/$matchid"),
      headers: headers, // in keys.dart
    );

    return json.decode(response.body); // array 형태로 나타남
  }

  // TOP 10,000 랭커 유저가 사용한 선수의 20경기
  static topRanker(int matchtype, List<dynamic> players) async {
    final response = await http.get(
      Uri.parse("https://api.nexon.co.kr/fifaonline4/v1.0/rankers/status?matchtype=$matchtype&players=$players"),
      headers: headers, // in keys.dart
    );

    return json.decode(response.body); // array 형태로 나타남
  }

  // 모든 매치 기록 조회
  // static allMatches(String matchtype, {int offset = 0, int limit = 100, bool asc = true,}) async {
  //   final response = await http.get(
  //     "https://api.nexon.co.kr/fifaonline4/v1.0/matches?matchtype=$matchtype&offset=$offset&limit=$limit&orderby=${asc ? "asc" : "desc"}",
  //     headers: headers,
  //   );
  //
  //   return json.decode(response.body); // array 형태로 나타남
  // }
}

class User {
  final String accessId;
  final String nickname;
  final int level;

  User({
    required this.accessId,
    required this.nickname,
    required this.level,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      accessId: json['accessId'],
      nickname: json['nickname'],
      level: json['level']
    );
  }
}

class MaxDivision {
  final int matchType;
  final int division;
  final String achievementDate;

  MaxDivision({
    required this.matchType,
    required this.division,
    required this.achievementDate,
  });

  factory MaxDivision.fromJson(Map<String, dynamic> json) {
    return MaxDivision(
        matchType: json['matchType'],
        division: json['division'],
        achievementDate: json['achievementDate']
    );
  }
}

class Match {
  final String matchId;
  final String matchDate;
  final int result; // (0 : win , 1 : draw , 2 : lose)

  final List<Player> players;

  int screen; // 포메이션 보기(0, 기본), 어시스트/슛 보기(1), 터치 시 화면 바꾸가

  Match({
    required this.matchId,
    required this.matchDate,
    required this.result,
    required this.players,
    required this.screen
  });
}

class Player { // 실제 유저의 매치 정보
  final String accessId;
  final String nickname;
  final List<NPC> npcs;
  final List<Shoot> shootings;
  final int goal;
  final int shootTotal; // 슈팅
  final int effectiveShootTotal; // 유효슈팅
  final int possession; // 점유율
  final int passSuccessRate; // 패스 성공률
  final int tackleSuccess; // 태클
  final int cornerKick; // 코너킥
  final int foul; // 파울
  final int card; // 경고

  Player({
    required this.accessId,
    required this.nickname,
    required this.npcs,
    required this.shootings,
    required this.goal,
    required this.shootTotal,
    required this.effectiveShootTotal,
    required this.possession,
    required this.passSuccessRate,
    required this.tackleSuccess,
    required this.cornerKick,
    required this.foul,
    required this.card,
  });
}

class NPC {
  final int spId;
  final int grade;
  final int position;

  final int goal;
  final int assist;
  final double rating;

  // 아래부터는 대충 중요도순
  final int shoot; // 슈팅
  final int effectiveShoot; // 유효슈팅
  final int passTry; // 패스 시도
  final int passSuccess; // 패스 성공
  final int dribbleTry; // 드리블 시도
  final int dribbleSuccess; // 드리블 성공
  final int ballPossesionTry; // 볼 점유 시도
  final int ballPossesionSuccess; // 볼 점유 성공
  final int aerialTry; // 공중볼 경합 시도
  final int aerialSuccess; // 공중볼 경합 성공

  final int blockTry; // 블락 시도
  final int block; // 블락 성공
  final int tackleTry; // 태클 시도
  final int tackle; // 태클 성공
  final int intercept; // 인터셉트
  final int defending; // 디펜딩

  final int yellowCards; // 옐로카드
  final int redCards; // 레드카드

  NPC({
    required this.spId,
    required this.grade,
    required this.position,
    required this.goal,
    required this.assist,
    required this.rating,
    required this.shoot,
    required this.effectiveShoot,
    required this.passTry,
    required this.passSuccess,
    required this.dribbleTry,
    required this.dribbleSuccess,
    required this.ballPossesionTry,
    required this.ballPossesionSuccess,
    required this.aerialTry,
    required this.aerialSuccess,
    required this.blockTry,
    required this.block,
    required this.tackleTry,
    required this.tackle,
    required this.intercept,
    required this.defending,
    required this.yellowCards,
    required this.redCards,
  });
}

class Shoot {
  final bool assist;
  final int result; // (1 : ontarget , 2 : offtarget , 3 : goal)
  final double assistX; // (0 ~ 1)
  final double assistY; // (0 ~ 1)
  final double x; // (0 ~ 1)
  final double y; // (0 ~ 1)

  Shoot({
    required this.assist,
    required this.result,
    required this.assistX,
    required this.assistY,
    required this.x,
    required this.y,
  });
}

class Ads {
  static void initialize() {
    MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: adUnitId, // in keys.dart
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => print('Ad loaded.'),
        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad failed to load: $error');
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) => print('Ad opened.'),
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) => print('Ad closed.'),
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) => print('Ad impression.'),
      ),
    );
  }

  static void showBannerAd(BannerAd bannerAd) async {
    // bannerAd ??= createBannerAd();
    await bannerAd.load();
  }

  static void hideBannerAd(BannerAd bannerAd) async {
    await bannerAd.dispose();
  }
}

// [deprecated]
// class MetaData {
//   // 매치 종류(matchtype) 메타데이터 조회
//   static matchtype() async {
//     final response = await http.get(
//       Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/matchtype.json"),
//       headers: headers,
//     );
//
//     return json.decode(response.body);
//     // [
//     //   {
//     //   "matchtype": 30,
//     //   "desc": "리그 친선"
//     //   },
//     // ]
//   }
//
//   // 매치 종류(matchtype) 메타데이터 조회
//   static spid() async {
//     final response = await http.get(
//       Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/spid.json"),
//       headers: headers,
//     );
//
//     return json.decode(response.body);
//     // [
//     //   {
//     //     "id": 101000001,
//     //     "name": "데이비드 시먼"
//     //   },
//     // ]
//   }
//
//   static seasonId() async {
//     final response = await http.get(
//       Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/seasonid.json"),
//       headers: headers,
//     );
//
//     return json.decode(response.body);
//     // [
//     //   {
//     //     "seasonId": 101,
//     //     "className": "ICON (ICON)",
//     //     "seasonImg": "https://ssl.nexon.com/s2/game/fo4/obt/externalAssets/season/icon.png"
//     //   },
//     // ]
//   }
//
//   static spposition() async {
//     final response = await http.get(
//       Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/spposition.json"),
//       headers: headers,
//     );
//
//     return json.decode(response.body);
//     // [
//     //   {
//     //     "spposition": 0,
//     //     "desc": "GK"
//     //   },
//     // ]
//   }
//
//   static division() async {
//     final response = await http.get(
//       Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/division.json"),
//       headers: headers,
//     );
//
//     return json.decode(response.body);
//     // [
//     //   {
//     //     "divisionId": 800,
//     //     "divisionName": "슈퍼챔피언스"
//     //   },
//     // ]
//   }
// }