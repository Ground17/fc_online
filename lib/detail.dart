import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
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
  bool adding = false;

  int index = 1;

  late Map<int, dynamic> spid;
  late Map<int, dynamic> seasonid;

  String title = ""; // 최종 등급

  DateTime now = DateTime.now();

  final cells = [];
  late ScrollController controller;
  bool end = false; // 끝이 나면 lazy 로딩 더 이상 못 하도록...

  int win = 0;
  int draw = 0;
  int lose = 0;


  int scoringPoint = 0;
  int losingPoint = 0;

  late File recent;
  late List<dynamic> players;

  late Widget playground = Image.asset(
    'assets/playground.png',
    fit: BoxFit.cover, // Fixes border issues
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.width / 640 * 406,
  );
  BannerAd bannerAd = Ads.createBannerAd();

  void _init() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    final spid_json = jsonDecode(File('$dir/spid.json').readAsStringSync());
    final seasonid_json = jsonDecode(File('$dir/seasonid.json').readAsStringSync());

    spid = <int, dynamic>{};
    seasonid = <int, dynamic>{};

    for (int i = 0; i < spid_json.length; i++) {
      spid[spid_json[i]['id']] = {'name': spid_json[i]['name']};
    }

    for (int i = 0; i < seasonid_json.length; i++) {
      seasonid[seasonid_json[i]['seasonId']] = {'className': seasonid_json[i]['className'], 'seasonImg': seasonid_json[i]['seasonImg']};
    }

    recent = File('$dir/recent.txt');
    players = jsonDecode(recent.readAsStringSync());

    await update();
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController()..addListener(_scrollListener);
    bannerAd = Ads.createBannerAd();
    Ads.showBannerAd(bannerAd);

    now = DateTime.now();

    _init();
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() async {
    if (!end && !adding && controller.position.extentAfter < 500) {
      adding = true;
      await addCells();
      setState(() {
        cells;
      });
      adding = false;
    }
  }

  Future<void> addCells({number = 10}) async {
    List<dynamic> matchIds = await API.matchIds(widget.id, matchtype: widget.matchtype, offset: cells.length, limit: number);

    if (matchIds.length < number) {
      end = true;
    }

    for (final matchId in matchIds) {
      final details = await API.match(matchId);
      int matchResult = 0; // 0: win, 1: draw, 2: lose

      List<Player> players = [];

      for (int i = 0; i < 2; i++) {

        final matchInfo = details['matchInfo'][details['matchInfo']!.length < 2 ? 0 : i]; // 상대 데이터가 존재하지 않는 경우 임시조치

        List<NPC> npcs = [];
        for (int j = 0; j < matchInfo['player']!.length; j++) {
          npcs.add(NPC(
            spId: matchInfo['player'][j]['spId'],
            grade: matchInfo['player'][j]['spGrade'],
            position: matchInfo['player'][j]['spPosition'],
            goal: matchInfo['player'][j]['status']['goal'],
            assist: matchInfo['player'][j]['status']['assist'],
            rating: matchInfo['player'][j]['status']['spRating'],
            shoot: matchInfo['player'][j]['status']['shoot'],
            effectiveShoot: matchInfo['player'][j]['status']['effectiveShoot'],
            passTry: matchInfo['player'][j]['status']['dribbleTry'],
            passSuccess: matchInfo['player'][j]['status']['passSuccess'],
            dribbleTry: matchInfo['player'][j]['status']['dribbleTry'],
            dribbleSuccess: matchInfo['player'][j]['status']['dribbleSuccess'],
            ballPossesionTry: matchInfo['player'][j]['status']['ballPossesionTry'],
            ballPossesionSuccess: matchInfo['player'][j]['status']['ballPossesionSuccess'],
            aerialTry: matchInfo['player'][j]['status']['aerialTry'],
            aerialSuccess: matchInfo['player'][j]['status']['aerialSuccess'],
            blockTry: matchInfo['player'][j]['status']['blockTry'],
            block: matchInfo['player'][j]['status']['block'],
            tackleTry: matchInfo['player'][j]['status']['tackleTry'],
            tackle: matchInfo['player'][j]['status']['tackle'],
            intercept: matchInfo['player'][j]['status']['intercept'],
            defending: matchInfo['player'][j]['status']['defending'],
            yellowCards: matchInfo['player'][j]['status']['yellowCards'],
            redCards: matchInfo['player'][j]['status']['redCards'],
          ));
        }

        List<Shoot> shootings = [];
        for (int j = 0; j < matchInfo['shootDetail']!.length; j++) {
          shootings.add(Shoot(
            assist: matchInfo['shootDetail'][j]['assist'],
            result: matchInfo['shootDetail'][j]['result'],
            assistX: i == 0 ? matchInfo['shootDetail'][j]['assistX'] : 1 - matchInfo['shootDetail'][j]['assistX'],
            assistY: i == 0 ? matchInfo['shootDetail'][j]['assistY'] : 1 - matchInfo['shootDetail'][j]['assistY'],
            x: i == 0 ? matchInfo['shootDetail'][j]['x'] : 1 - matchInfo['shootDetail'][j]['x'],
            y: i == 0 ? matchInfo['shootDetail'][j]['y'] : 1 - matchInfo['shootDetail'][j]['y'],
          ));
        }

        players.add(Player(
          accessId: matchInfo['accessId'],
          nickname: matchInfo['nickname'],
          npcs: npcs,
          shootings: shootings,
          goal: matchInfo['shoot']!['goalTotal'],
          shootTotal: matchInfo['shoot']!['shootTotal'],
          effectiveShootTotal: matchInfo['shoot']!['effectiveShootTotal'],
          possession: matchInfo['matchDetail']!['possession'],
          passSuccessRate: matchInfo['pass']!['passTry'] == 0 ? 0 : (matchInfo['pass']!['passSuccess'] / matchInfo['pass']!['passTry']).round(),
          tackleSuccess: matchInfo['defence']!['tackleSuccess'],
          cornerKick: matchInfo['matchDetail']!['cornerKick'],
          foul: matchInfo['matchDetail']!['foul'],
          card: matchInfo['matchDetail']!['redCards'] + matchInfo['matchDetail']!['yellowCards'],
        ));

        if (matchInfo['accessId'] == widget.id) {
          if (matchInfo['matchDetail']['matchResult'] == "승") {
            win++;
            matchResult = 0;
          } else if (matchInfo['matchDetail']['matchResult'] == "무") {
            draw++;
            matchResult = 1;
          } else {
            lose++;
            matchResult = 2;
          }
          scoringPoint += matchInfo['shoot']!['goalTotal'] as int;
        } else {
          losingPoint += matchInfo['shoot']!['goalTotal'] as int;
        }
      }

      cells.add(Match(
        matchId: details['matchId'],
        matchDate: details['matchDate'],
        result: matchResult,
        players: players,
        screen: 0,
      ));
    }
  }

  Future<void> update() async {
    setState(() {
      loading = true;
      cells.clear();
      title = "";
      win = 0;
      draw = 0;
      lose = 0;
      end = false;
      scoringPoint = 0;
      losingPoint = 0;
    });

    List<MaxDivision> maxdivisions = await API.maxdivision(widget.id);
    for (final maxdivision in maxdivisions) {
      if (maxdivision.matchType == widget.matchtype) {
        setState(() {
          title = division[maxdivision.division]!["divisionName"]!;
        });
        break;
      }
    }

    await addCells(number: 20);

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
            preferredSize: const Size.fromHeight(120.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Lv." + widget.level.toString(), style: const TextStyle(color: Colors.white),),
                    Text(title, style: const TextStyle(color: Colors.white),),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                ),
                Text(
                  "최근 ${cells.length}경기 기준",
                  textAlign: TextAlign.center,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                ),
                barChart(
                    win, lose,
                    message: "$win승 $draw무 $lose패",
                    center: draw,
                    width: MediaQuery.of(context).size.width * 0.8
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                ),
                barChart(
                    scoringPoint, losingPoint,
                    message: "최근 경기 득/실점 - $scoringPoint/$losingPoint",
                    width: MediaQuery.of(context).size.width * 0.8
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            loading
                ? ListView(children: const <Widget>[
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
                      controller: controller,
                      children: cells.isNotEmpty
                          ? <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                            ),
                            ListView.builder(
                              physics: const ScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: cells.length + 1,
                              itemBuilder: (BuildContext _context, int i) {
                                if (i == cells.length) {
                                  return const ListTile(
                                    subtitle: Text(""),
                                  );
                                }
                                return _buildRow(cells[i]);
                            })
                          ]
                          : const <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                        ),
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
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

  Widget _buildRow(Match cells) {
    DateTime matchDate = DateFormat('yyyy-MM-dd HH:mm:ss')
        .parse(cells.matchDate.replaceFirst("T", " "))
        .add(const Duration(hours: 9)); // 한국 시간 기준

    String scores = "";

    if (cells.players[0].accessId == widget.id) {
      scores += cells.players[0].nickname + " ";
      scores += cells.players[0].goal.toString();
      scores += " : ";
      scores += cells.players[1].goal.toString();
      scores += " " + cells.players[1].nickname;
    } else {
      scores += cells.players[1].nickname + " ";
      scores += cells.players[1].goal.toString();
      scores += " : ";
      scores += cells.players[0].goal.toString();
      scores += " " + cells.players[0].nickname;
    }

    final List<Widget> formations = [
      playground
    ];
    for (int k = 0; k < cells.players.length; k++) {
      for (int i = 0; i < cells.players[k].npcs.length; i++) {
        final item = cells.players[k].npcs[i];

        if (position.containsKey(item.position)) {
          final x = position[item.position]!['x'] as num;
          final y = position[item.position]!['y'] as num;
          formations.add(
              Positioned(
                left: MediaQuery.of(context).size.width * (k == 0 ? x : (2 - x)) * 0.5 - 16,
                top: MediaQuery.of(context).size.width / 640 * 406 * (k == 0 ? y : (1 - y)) - 16 - 5,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await alertNPC(item);
                      }, // Image tapped
                      child: Image.network(
                        'https://fo4.dn.nexoncdn.co.kr/live/externalAssets/common/players/p${item.spId % 1000000}.png',
                        fit: BoxFit.cover, // Fixes border issues
                        width: 32,
                        height: 32,
                      ),
                    ),
                    Text("${position[item.position]?['desc'] as String} (${item.rating})",
                      style: const TextStyle(fontSize: 10),),
                  ],
                ),
              )
          );
        }
      }
    }


    final List<Widget> shootlines = [
      playground,
      CustomPaint(
        size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.width / 640 * 406),
        painter: MyPainter(
          shootingsMe: cells.players[0].shootings,
          shootingsOther: cells.players[1].shootings,
          width: MediaQuery.of(context).size.width
        ),
      ),
    ];

    return ExpansionTile(
      key: PageStorageKey<Match>(cells),
      leading: SizedBox(
        width: 65,
        child: Center(
          child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: now.difference(matchDate).inDays != 0
                      ? "${now.difference(matchDate).inDays}일 전"
                      : (now.difference(matchDate).inHours != 0
                      ? "${now.difference(matchDate).inHours}시간 전"
                      : (now.difference(matchDate).inMinutes != 0
                      ? "${now.difference(matchDate).inMinutes}분 전"
                      : "${now.difference(matchDate).inSeconds}초 전")),
                  style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                          ? Colors.white
                          : Colors.black),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      alert("상세 시간", cells.matchDate.replaceFirst("T", " "));
                    },
              ),
          ),
        ),
      ),
      title: Text(scores),
      trailing: Text(cells.result == 0 ? "승" : (cells.result == 1 ? "무" : "패"),
        style: TextStyle(
            color: cells.result == 0 ? Colors.blueAccent : (cells.result == 1 ? Colors.blueGrey : Colors.redAccent),
            fontWeight: FontWeight.bold,
        ),
      ),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                  text: "${cells.players[cells.players[0].accessId == widget.id ? 1 : 0].nickname}의 전적 검색하기",
                  style: const TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchOther(cells.players[cells.players[0].accessId == widget.id ? 1 : 0]);
                    }
              ),
            ),
            IconButton(
              onPressed: () {
                launchOther(cells.players[cells.players[0].accessId == widget.id ? 1 : 0]);
              },
              icon: const Icon(Icons.launch, color: Colors.blue,),
            ),
          ],
        ),
        GestureDetector(
          key: PageStorageKey<Match>(cells),
          onTap: () { /// 포메이션, 어시스트/슛 (터치 시 화면 바꾸기)
            setState(() {
              cells.screen = (cells.screen + 1) % 2;
            });
          },
          child: Stack(
            children: cells.screen == 0 ? formations : shootlines,
          ),
        ),
        Container( /// 슈팅, 유효슈팅, 점유율, 패스 성공률, 태클, 코너킥, 파울, 경고
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ScrollPhysics(),
            key: PageStorageKey<Match>(cells),
            shrinkWrap: true,
            children: [
              barChart(cells.players[0].shootTotal, cells.players[1].shootTotal, message: "슈팅\n${cells.players[0].shootTotal} : ${cells.players[1].shootTotal}",),
              const VerticalDivider(),
              barChart(cells.players[0].effectiveShootTotal, cells.players[1].effectiveShootTotal, message: "유효슈팅\n${cells.players[0].effectiveShootTotal} : ${cells.players[1].effectiveShootTotal}",),
              const VerticalDivider(),
              barChart(cells.players[0].possession, cells.players[1].possession, message: "점유율\n${cells.players[0].possession} : ${cells.players[1].possession}",),
              const VerticalDivider(),
              barChart(cells.players[0].passSuccessRate, cells.players[1].passSuccessRate, message: "패스 성공률\n${cells.players[0].passSuccessRate} : ${cells.players[1].passSuccessRate}",),
              const VerticalDivider(),
              barChart(cells.players[0].tackleSuccess, cells.players[1].tackleSuccess, message: "태클\n${cells.players[0].tackleSuccess} : ${cells.players[1].tackleSuccess}",),
              const VerticalDivider(),
              barChart(cells.players[0].cornerKick, cells.players[1].cornerKick, message: "코너킥\n${cells.players[0].cornerKick} : ${cells.players[1].cornerKick}",),
              const VerticalDivider(),
              barChart(cells.players[0].foul, cells.players[1].foul, message: "파울\n${cells.players[0].foul} : ${cells.players[1].foul}",),
              const VerticalDivider(),
              barChart(cells.players[0].card, cells.players[1].card, message: "경고\n${cells.players[0].card} : ${cells.players[1].card}",),
            ],
          ),
        ),
      ],
    );
  }

  void launchOther(Player player) async {
    if (player.accessId != widget.id) {
      await API.infoFromAccessId(player.accessId).then((get) async {
        if (get.accessId != null) {
          for (int i = 0; i < players.length; i++) {
            if (players[i][0] == get.accessId) {
              players.remove(players[i]);
            }
          }
          players.insert(0, [get.accessId, get.nickname]);
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
  }

  Widget barChart(int left, int right, {String message = "", int center = 0, double width = 100, align = 0}) { /// TODO: 바 차트 구현, target/total
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        Padding(padding: EdgeInsets.all(2)),
        SizedBox(
          width: width,
          height: width / 50,
          child: Row(
            children: [
              Expanded(
                flex: left,
                child: Container(
                  color: Colors.blueAccent,
                ),
              ),
              Expanded(
                flex: center,
                child: Container(
                  color: Colors.purpleAccent,
                ),
              ),
              Expanded(
                flex: right,
                child: Container(
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> alertNPC(NPC npc) async { /// TODO: 선수 세부정보 표시
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(spid[npc.spId]['name']),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Image.network(
                      "https://fo4.dn.nexoncdn.co.kr/live/externalAssets/common/playersAction/p${npc.spId}.png",
                        fit: BoxFit.contain, // Fixes border issues
                        width: 100,
                        height: 100,
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 5)),
                      Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(5.0))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("선수 시즌"),
                                  seasonid.containsKey(npc.spId ~/ 1000000) ? Image.network(
                                    seasonid[npc.spId ~/ 1000000]['seasonImg'],
                                    fit: BoxFit.cover, // Fixes border issues
                                    width: 20,
                                    height: 16,
                                  ) : Container(),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("강화 등급"),
                                  Text(npc.grade.toString()),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("포지션"),
                                  Text(position[npc.position]!['desc'] as String),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(5.0))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("골"),
                                  Text(npc.goal.toString()),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("도움"),
                                  Text(npc.assist.toString()),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text("평점"),
                                  Text(npc.rating.toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5, left: 5, right: 5),
                        padding: EdgeInsets.all(5),
                        child: Text("상세 지표")
                      ),
                      Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(5.0))
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.effectiveShoot, npc.shoot - npc.effectiveShoot,
                                  message: "유효 슈팅/슈팅 - ${npc.effectiveShoot}/${npc.shoot}",
                                  width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.passSuccess, npc.passTry - npc.passSuccess,
                                  message: "패스 성공/시도 - ${npc.passSuccess}/${npc.passTry}",
                                  width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.dribbleSuccess, npc.dribbleTry - npc.dribbleSuccess,
                                  message: "드리블 성공/시도 - ${npc.dribbleSuccess}/${npc.dribbleTry}",
                                  width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.ballPossesionSuccess, npc.ballPossesionTry - npc.ballPossesionSuccess,
                                  message: "볼 점유 성공/시도 - ${npc.ballPossesionSuccess}/${npc.ballPossesionTry}",
                                  width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.aerialSuccess, npc.aerialTry - npc.aerialSuccess,
                                  message: "공중볼 경합 성공/시도 - ${npc.aerialSuccess}/${npc.aerialTry}",
                                  width: MediaQuery.of(context).size.width * 0.8),
                            ),
                          ]
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(5.0))
                        ),
                        child: Column(
                          children: [
                            Container(
                            padding: EdgeInsets.all(5),
                              child: barChart(npc.block, npc.blockTry - npc.block,
                                message: "블락 성공/시도 - ${npc.block}/${npc.blockTry}",
                                width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: barChart(npc.tackle, npc.tackleTry - npc.tackle,
                                message: "태클 성공/시도 - ${npc.tackle}/${npc.tackleTry}",
                                width: MediaQuery.of(context).size.width * 0.8),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("인터셉트"),
                                  Text(npc.intercept.toString()),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("디펜딩"),
                                  Text(npc.defending.toString()),
                                ],
                              ),
                            ),
                          ]
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(5.0))
                        ),
                        child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("옐로카드"),
                                    Text(npc.yellowCards.toString()),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("레드카드"),
                                    Text(npc.redCards.toString()),
                                  ],
                                ),
                              ),
                            ]
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> alert(String title, String content) async { // 날짜 세부정보 등 표시
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('닫기'),
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

class MyPainter extends CustomPainter { //         <-- CustomPainter class
  MyPainter({required this.shootingsMe, required this.shootingsOther, required this.width})
      : super();

  final List<Shoot> shootingsMe;
  final List<Shoot> shootingsOther;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    var linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;

    var assist = Paint()
      ..color = Colors.greenAccent
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 10;

    var ontarget = Paint()
      ..color = Colors.orange
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 10;

    var offtarget = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 5;

    var goal = Paint()
      ..color = Colors.yellow
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 20;

    //list of points
    List<List<Offset>> lines = [];
    List<Offset> assistPoints = [];
    List<Offset> ontargetPoints = [];
    List<Offset> offtargetPoints = [];
    List<Offset> goalPoints = [];

    for (Shoot shooting in shootingsMe) {
      if (shooting.assist) {
        assistPoints.add(Offset(shooting.assistX * width, shooting.assistY * width / 640 * 406));
        List<Offset> assistGoal = [];
        assistGoal.add(Offset(shooting.assistX * width, shooting.assistY * width / 640 * 406));
        assistGoal.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
        lines.add(assistGoal);
      }

      switch (shooting.result) {
        case 1:
          ontargetPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
        case 3:
          goalPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
        default:
          offtargetPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
      }
    }

    for (Shoot shooting in shootingsOther) {
      if (shooting.assist) {
        assistPoints.add(Offset(shooting.assistX * width, shooting.assistY * width / 640 * 406));
        List<Offset> assistGoal = [];
        assistGoal.add(Offset(shooting.assistX * width, shooting.assistY * width / 640 * 406));
        assistGoal.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
        lines.add(assistGoal);
      }

      switch (shooting.result) {
        case 1:
          ontargetPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
        case 3:
          goalPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
        default:
          offtargetPoints.add(Offset(shooting.x * width, shooting.y * width / 640 * 406));
          break;
      }
    }

    //draw points on canvas
    canvas.drawPoints(PointMode.points, assistPoints, assist);
    canvas.drawPoints(PointMode.points, ontargetPoints, ontarget);
    canvas.drawPoints(PointMode.points, offtargetPoints, offtarget);
    canvas.drawPoints(PointMode.points, goalPoints, goal);

    for (List<Offset> line in lines) {
      canvas.drawLine(line.first, line.last, linePaint);
      /// 화살표 그리기
      // canvas.drawLine(line.first, line.last, linePaint);
      // canvas.drawLine(line.first, line.last, linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
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
  // 28: {'x': 13/16, 'y': 0.5, 'desc': "SUB"},
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