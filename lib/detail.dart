import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'classes.dart';

class DetailApp extends StatefulWidget {
  DetailApp({Key? key, required this.id, required this.nickname, this.level = 0, this.matchtype = 50})
      : super(key: key);

  String id;
  String nickname;
  int level;
  int matchtype;

  @override
  _MyChangeState createState() => _MyChangeState();
}

class _MyChangeState extends State<DetailApp> {
  late String dir;

  bool loading = true;

  int index = 1;

  late List<dynamic> spid;
  late List<dynamic> seasonid;
  late List<dynamic> spposition;
  late List<dynamic> division;

  String title = ""; // 최종 등급

  DateTime now = DateTime.now();

  DateTime endDate = DateTime.now();

  final cells = [];

  int win = 0;
  int draw = 0;
  int lose = 0;

  late File recent;
  late List<dynamic> players;

  BannerAd bannerAd = Ads.createBannerAd();

  void _init() async { /// TODO: 등급도 추가하기
    dir = (await getApplicationDocumentsDirectory()).path;
    spid = jsonDecode(File('$dir/spid.json').readAsStringSync());
    seasonid = jsonDecode(File('$dir/seasonid.json').readAsStringSync());
    spposition =
        jsonDecode(File('$dir/spposition.json').readAsStringSync());
    division = jsonDecode(File('$dir/division.json').readAsStringSync());
    recent = File('$dir/recent.txt');
    players = jsonDecode(recent.readAsStringSync());

    await update();
  }

  @override
  void initState() {
    bannerAd = Ads.createBannerAd();
    Ads.showBannerAd(bannerAd);

    now = DateTime.now();

    _init();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> update() async {
    setState(() {
      loading = true;
      cells.clear();
      title = "";
      win = 0;
      draw = 0;
      lose = 0;
    });

    List<MaxDivision> maxdivisions = await API.maxdivision(widget.id);
    for (final maxdivision in maxdivisions) {
      if (maxdivision.matchType == widget.matchtype) {
        for (final div in division) {
          if (maxdivision.division == div["divisionId"]) {
            setState(() {
              title = div["divisionName"];
            });
            break;
          }
        }
        break;
      }
    }

    List<String> matchIds = await API.matchIds(widget.id, matchtype: widget.matchtype);

    for (final matchId in matchIds) {
      var shortcut = await API.match(matchId);

      // cells.add(Cells(
      //   clicked: false,
      //   matchId: shortcut[i]["matchId"],
      //   trackId: shortcut[i]["trackId"],
      //   trackName: trackName,
      //   startTime: DateFormat('yyyy-MM-dd HH:mm:ss')
      //       .parse(shortcut[i]["startTime"].toString().replaceFirst("T", " "))
      //       .add(Duration(hours: 9)),
      //   endTime: DateFormat('yyyy-MM-dd HH:mm:ss')
      //       .parse(shortcut[i]["endTime"].toString().replaceFirst("T", " "))
      //       .add(Duration(hours: 9)),
      //   matchTime: shortcut[i]["player"]["matchTime"] != ""
      //       ? int.parse(shortcut[i]["player"]["matchTime"])
      //       : 0,
      //   playerCount: shortcut[i]["playerCount"],
      //   rank: shortcut[i]["player"]["matchRank"] != "" && shortcut[i]["player"]["matchRank"] != "0"
      //       ? int.parse(shortcut[i]["player"]["matchRank"])
      //       : 99,
      // ));
      // if (shortcut[i]["player"]["matchWin"] != "0") {
      //   win++;
      // }
    }

    setState(() {
      now = DateTime.now();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
            icon: Icon(
                Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.nickname,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  tooltip: "새로고침",
                  onPressed: () async {
                    await update();
                  },
                )
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Lv." + widget.level.toString(), style: TextStyle(color: Colors.white),),
                Text(title, style: TextStyle(color: Colors.white),),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            loading
                ? ListView(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 16),
              ),
              Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '잠시만 기다려주세요...',
                  textAlign: TextAlign.center,
                ),
              )
            ])
                : RefreshIndicator(
              child: ListView(
                children: cells.length > 0
                    ? <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                  ),
                  Text(
                    "최근 ${cells.length}경기 기준",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      /// 최근 경기 승, 무, 패 / 최근 경기 득점 / 최근 경기 실점 / 레벨, 시즌 최고 등급
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                  ),
                  ListView.builder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: cells.length + 1,
                      itemBuilder: (BuildContext _context, int i) {
                        if (i == cells.length) {
                          return ListTile(
                            isThreeLine: true,
                            subtitle: Text(""),
                          );
                        }
                        return _buildRow(cells[i]);
                      })
                ]
                    : <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                  ),
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Error: 정보가 없습니다.\n새로고침을 눌러 다시 시도해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              onRefresh: update,
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).backgroundColor,
                ),
                alignment: Alignment.center,
                child: AdWidget(ad: bannerAd),
                width: double.infinity,
                height: bannerAd.size.height.toDouble(),
              ),
            ),
          ],
        ));
  }

  Widget _buildRow(dynamic cells) {
    return ExpansionTile(
      /// alert()로 endTime을 알 수 있도록
      key: PageStorageKey<dynamic>(cells),
      leading: Container(
        width: 65,
        child: Center(
          child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: now.difference(cells.endTime).inDays != 0
                      ? "${now.difference(cells.endTime).inDays}일 전"
                      : (now.difference(cells.endTime).inHours != 0
                      ? "${now.difference(cells.endTime).inHours}시간 전"
                      : (now.difference(cells.endTime).inMinutes != 0
                      ? "${now.difference(cells.endTime).inMinutes}분 전"
                      : "${now.difference(cells.endTime).inSeconds}초 전")),
                  style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                          ? Colors.white
                          : Colors.black),
                  // recognizer: TapGestureRecognizer()
                  //   ..onTap = () {
                  //     /// print(cells.matchId);
                  //   })),
              ),
          ),
        ),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(cells.trackName),
          ),
          Text(
            cells.matchTime != 0
                ? "${cells.matchTime ~/ 60000}:${((cells.matchTime ~/ 1000) % 60).toString().padLeft(2, "0")}:${(cells.matchTime % 1000).toString().padLeft(3, "0")}"
                : "-:--:---",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      trailing: Text(
        cells.rank > 8 || cells.rank < 1
            ? "리타/${cells.playerCount}"
            : "#${cells.rank}/${cells.playerCount}",
        style: TextStyle(
            color: cells.rank > 8 || cells.rank < 1 ? Colors.redAccent : Colors.blueAccent),
      ),
      children: <Widget>[
        Container(), /// 포메이션, 어시스트/슛 (터치 시 화면 바꾸기)
        Container(
          margin: EdgeInsets.symmetric(vertical: 5.0),
          height: 120.0,
          child: ListView( /// 슈팅, 유효슈팅, 점유율, 패스 성공률, 태클, 코너킥, 파울, 경고
              scrollDirection: Axis.horizontal,
              physics: const ScrollPhysics(),
              key: PageStorageKey<dynamic>(cells),
              shrinkWrap: true,
              children: [

              ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(dynamic cells) {
    return InkResponse(
      enableFeedback: true,
      child: Container(
        width: 160.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(cells.rank > 8 || cells.rank < 1 ? "- " : cells.rank.toString() + " "),
                cells.win != 0
                    ? Icon(
                  Icons.thumb_up,
                  color: Colors.yellow,
                  size: 10,
                )
                    : Container(),
                Expanded(
                  child: Text(
                    cells.trackName,
                    style: TextStyle(
                      color: index > 0 || cells.rank == 1 || cells.rank == 3
                          ? Colors.white
                          : Colors.black,
                      backgroundColor: index > 0
                          ? (cells.clicked ? Colors.blueAccent : Colors.red)
                          : (cells.rank == 1
                          ? Colors.amber[800]
                          : (cells.rank == 2
                          ? Colors.grey
                          : (cells.rank == 3
                          ? Colors.brown
                          : Colors.white))),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                File("$dir/out/character/${cells.trackId}.png").existsSync()
                    ? Image.file(
                  File("$dir/out/character/${cells.trackId}.png"),
                  scale: 6,
                )
                    : Container(),
                File("$dir/out/kart/${cells.matchId}.png").existsSync()
                    ? Image.file(
                  File("$dir/out/kart/${cells.matchId}.png"),
                  scale: 7,
                )
                    : Container(),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(cells.matchTime != 0
                      ? "${cells.matchTime ~/ 60000}:${((cells.matchTime ~/ 1000) % 60).toString().padLeft(2, "0")}:${(cells.matchTime % 1000).toString().padLeft(3, "0")}"
                      : "-:--:---"),
                ),
                cells.playerCount != 6
                    ? Text(
                  cells.playerCount == 1
                      ? "초보"
                      : (cells.playerCount == 2
                      ? "루키"
                      : (cells.playerCount == 3
                      ? "L3"
                      : (cells.playerCount == 4
                      ? "L2"
                      : (cells.playerCount == 5
                      ? "L1"
                      : (" "))))),
                  style: TextStyle(
                    color: cells.playerCount == 3
                        ? Colors.blue
                        : (cells.playerCount == 4
                        ? Colors.red
                        : (cells.playerCount == 5
                        ? Colors.deepPurple
                        : Colors.white)),
                    backgroundColor: cells.playerCount == 3 || cells.playerCount == 4 || cells.playerCount == 5
                        ? Colors.white
                        : (cells.playerCount == 1
                        ? Colors.amber[700]
                        : (cells.playerCount == 2
                        ? Colors.green
                        : null)),
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : ShaderMask(
                  shaderCallback: (bounds) => RadialGradient(
                    colors: <Color>[
                      Colors.red,
                      Colors.deepOrange,
                      Colors.orange,
                      Colors.amber,
                      Colors.yellow,
                      Colors.lime,
                      Colors.lightGreen,
                      Colors.green,
                      Colors.teal,
                      Colors.cyan,
                      Colors.lightBlue,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.deepPurple,
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    "Pro",
                    style: TextStyle(
                      // The color must be set to white for this to work
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () async {
        if (cells.accountNo != widget.id) {
          await API.infoFromAccessId(cells.accountNo).then((get) async {
            if (get.name != null) {
              for (int i = 0; i < players.length; i++) {
                if (players[i][0] == get.accessId) {
                  players.remove(players[i]);
                }
              }
              players.insert(0, [get.accessId, get.name]);
              if (players.length > 10) {
                players.removeRange(10, players.length);
              }
              recent.writeAsStringSync(jsonEncode(players));
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailApp(
                        id: get.accessId,
                        nickname: get.nickname,
                        level: get.level,
                        matchtype: widget.matchtype,
                      )));
            }
          });
        }
      },
      onLongPress: () async {
        await alert(cells);
      },
    );
  }

  Future<void> alert(dynamic message) async { // 선수 세부정보 표시
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message.trackName),
          content: Text("라이센스: "),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

const position = {
  0: {'x': 1/8, 'y': 0.5, 'desc': "GK"},
  1: {'x': 3/16, 'y': 0.5, 'desc': "SW"},
  2: {'x': 3/8, 'y': 0.5 + 2/6, 'desc': "RWB"},
  3: {'x': 2/8, 'y': 0.5 + 2/6, 'desc': "RB"},
  4: {'x': 2/8, 'y': 0.5 + 1/6, 'desc': "RCB"},
  5: {'x': 2/8, 'y': 0.5, 'desc': "CB"},
  6: {'x': 2/8, 'y': 0.5 - 1/6, 'desc': "LCB"},
  7: {'x': 2/8, 'y': 0.5 - 2/6, 'desc': "LB"},
  8: {'x': 3/8, 'y': 0.5 - 2/6, 'desc': "LWB"},
  9: {'x': 3/8, 'y': 0.5 + 1/6, 'desc': "RDM"},
  10: {'x': 3/8, 'y': 0.5, 'desc': "CDM"},
  11: {'x': 3/8, 'y': 0.5 - 1/6, 'desc': "LDM"},
  12: {'x': 4/8, 'y': 0.5 + 2/6, 'desc': "RM"},
  13: {'x': 4/8, 'y': 0.5 + 1/6, 'desc': "RCM"},
  14: {'x': 4/8, 'y': 0.5, 'desc': "CM"},
  15: {'x': 4/8, 'y': 0.5 - 1/6, 'desc': "LCM"},
  16: {'x': 4/8, 'y': 0.5 - 2/6, 'desc': "LM"},
  17: {'x': 5/8, 'y': 0.5 + 1/6, 'desc': "RAM"},
  18: {'x': 5/8, 'y': 0.5, 'desc': "CAM"},
  19: {'x': 5/8, 'y': 0.5 - 1/6, 'desc': "LAM"},
  20: {'x': 6/8, 'y': 0.5 + 1/6, 'desc': "RF"},
  21: {'x': 6/8, 'y': 0.5, 'desc': "CF"},
  22: {'x': 6/8, 'y': 0.5 - 1/6, 'desc': "LF"},
  23: {'x': 13/16, 'y': 0.5 + 2/6, 'desc': "RW"},
  24: {'x': 7/8, 'y': 0.5 + 1/6, 'desc': "RS"},
  25: {'x': 7/8, 'y': 0.5, 'desc': "ST"},
  26: {'x': 7/8, 'y': 0.5 - 1/6, 'desc': "LS"},
  27: {'x': 13/16, 'y': 0.5 - 2/6, 'desc': "LW"},
  28: {'x': 0, 'y': 0, 'desc': "SUB"},
};

const division = {
  800: {'divisionName': "슈퍼챔피언스"},
  900: {'divisionName': "챔피언스"},
  1000: {'divisionName': "슈퍼챌린지"},
  1100: {'divisionName': "챌린지1"},
  1200: {'divisionName': "챌린지2"},
  1300: {'divisionName': "챌린지3"},
  2000: {'divisionName': "월드클래스1"},
  2100: {'divisionName': "월드클래스2"},
  2200: {'divisionName': "월드클래스3"},
  2300: {'divisionName': "프로1"},
  2400: {'divisionName': "프로2"},
  2500: {'divisionName': "프로3"},
  2600: {'divisionName': "세미프로1"},
  2700: {'divisionName': "세미프로2"},
  2800: {'divisionName': "세미프로3"},
  2900: {'divisionName': "유망주1"},
  3000: {'divisionName': "유망주2"},
  3100: {'divisionName': "유망주3"},
};