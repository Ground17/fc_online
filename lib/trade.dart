import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'classes.dart';

class TradeApp extends StatefulWidget {
  TradeApp({Key? key, required this.id, required this.nickname, required this.buy}) : super(key: key);

  String id;
  String nickname;
  bool buy;

  @override
  _MyChangeState createState() => _MyChangeState();
}

class _MyChangeState extends State<TradeApp> {
  final _formKey = GlobalKey<FormState>();

  late String dir;
  String _email = "";
  String _id = "";

  bool buy = true;

  bool loading = false;
  bool adding = false;

  late Map<int, dynamic> spid;
  late Map<int, dynamic> seasonid;

  DateTime now = DateTime.now();

  final cells = [];
  late ScrollController controller;
  bool end = false; // 끝이 나면 lazy 로딩 더 이상 못 하도록...

  BannerAd bannerAd = Ads.createBannerAd();

  void _init() async {
    dir = (await getApplicationDocumentsDirectory()).path;
    spid = <int, dynamic>{};
    seasonid = <int, dynamic>{};

    try {
      final spid_json = jsonDecode(File('$dir/spid.json').readAsStringSync());
      final seasonid_json = jsonDecode(File('$dir/seasonid.json').readAsStringSync());

      for (int i = 0; i < spid_json.length; i++) {
        spid[spid_json[i]['id']] = {'name': spid_json[i]['name']};
      }

      for (int i = 0; i < seasonid_json.length; i++) {
        seasonid[seasonid_json[i]['seasonId']] = {'className': seasonid_json[i]['className'], 'seasonImg': seasonid_json[i]['seasonImg']};
      }
    } catch (e) {
      print(e);
    } finally {
      _email = widget.nickname;
      _id = widget.id;
      buy = widget.buy;
      await update();
    }

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

  Widget _showSwitch() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          Text("모드: ${buy ? "구입" : "판매"}"),
          Switch(
            value: buy,
            onChanged: (value) async {
              await update();
              setState(() {
                cells;
                buy = value;
                loading = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> addCells({number = 20}) async {
    List<dynamic> trades = await API.trades(this._id, buy: this.buy, offset: this.cells.length, limit: number);

    if (trades.length < number) {
      end = true;
    }

    for (final trade in trades) {
      cells.add(Trade(
        tradeDate: trade['tradeDate'],
        saleSn: trade['saleSn'],
        spid: trade['spid'],
        grade: trade['grade'],
        value: trade['value'],
      ));
    }
  }

  Future<void> update() async {
    setState(() {
      loading = true;
      cells.clear();
      end = false;
    });

    await addCells(number: 100);

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
          title: const Text(
            "거래 내역 조회",
            style: TextStyle(
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
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                _showSwitch(),
                Expanded(
                  child: !loading ? RefreshIndicator(
                    child: ListView.builder(
                      physics: const ScrollPhysics(),
                      controller: controller,
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
                      }),
                    onRefresh: update,
                  ) : const Center(
                    child: CircularProgressIndicator()
                  ),
                ),
                const Divider(),
                Container(
                  alignment: Alignment.center,
                  child: AdWidget(ad: bannerAd),
                  width: bannerAd.size.width.toDouble(),
                  height: bannerAd.size.height.toDouble(),
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildRow(Trade cells) {
    DateTime tradeDate = DateFormat('yyyy-MM-dd HH:mm:ss')
        .parse(cells.tradeDate.replaceFirst("T", " ")); // 한국 시간 기준

    return ListTile(
      onTap: () => alert("상세 시간", tradeDate.toString() + "\n" +
          (now.difference(tradeDate).inDays != 0
          ? "${now.difference(tradeDate).inDays}일 전"
          : (now.difference(tradeDate).inHours != 0
          ? "${now.difference(tradeDate).inHours}시간 전"
          : (now.difference(tradeDate).inMinutes != 0
          ? "${now.difference(tradeDate).inMinutes}분 전"
          : "${now.difference(tradeDate).inSeconds}초 전")))
      ),
      key: PageStorageKey<Trade>(cells),
      leading: SizedBox(
        width: 64,
        height: 64,
        child: Image.network(
          "https://fo4.dn.nexoncdn.co.kr/live/externalAssets/common/playersAction/p${cells.spid}.png",
          fit: BoxFit.contain, // Fixes border issues
          width: 64,
          height: 64,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Image.asset(
              'assets/person.png',
              fit: BoxFit.contain, // Fixes border issues
              width: 64,
              height: 64,
            );
          },
        ),
      ),
      title: Text(spid.containsKey(cells.spid) ? spid[cells.spid]['name'] : "알 수 없음"),
      subtitle: Text(cells.value.toString() + " BP"),
      trailing: SizedBox(
        width: 32,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("+${cells.grade}"),
            seasonid.containsKey(cells.spid ~/ 1000000) ? Image.network(
              seasonid[cells.spid ~/ 1000000]['seasonImg'],
              fit: BoxFit.cover, // Fixes border issues
              width: 20,
              height: 16,
            ) : Container(),
          ],
        ),
      ),
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
