import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'classes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'detail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Ads.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: key,
      title: '피파4 전적 검색 17%',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        primaryColor: Colors.teal[800],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        primaryColor: Colors.teal[800],
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: '피파4 전적 검색 17%',),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _email = "";
  bool _isLoading = false;
  String dir = "";

  late File recent;
  late http.Response r;
  late int total = 0;
  late int current = 0;
  late List<dynamic> players;

  late File spid;

  List<dynamic> dropdownValues = [
    {
      "matchtype": 30,
      "desc": "리그 친선"
    },
    {
      "matchtype": 40,
      "desc": "클래식 1on1"
    },
    {
      "matchtype": 50,
      "desc": "공식경기"
    },
    {
      "matchtype": 52,
      "desc": "감독모드"
    },
    {
      "matchtype": 60,
      "desc": "공식 친선"
    }
  ];

  String dropdownValue = "공식경기";

  BannerAd bannerAd = Ads.createBannerAd();

  @override
  void initState() {
    super.initState();
    AppTrackingTransparency.requestTrackingAuthorization();
    _initFile();
    Ads.showBannerAd(bannerAd);
  }

  @override
  void dispose() {
    Ads.hideBannerAd(bannerAd);
    super.dispose();
  }

  Future<int> getTotal() async {
    r = await http
        .head(Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/spid.json"));
    int t = int.parse(r.headers['content-length']!);
    r = await http
        .head(Uri.parse("https://static.api.nexon.co.kr/fifaonline4/latest/seasonid.json"));
    t += int.parse(r.headers['content-length']!);

    return t;
  }

  void _initFile() async {
    dir = (await getApplicationDocumentsDirectory()).path;


    recent = File('$dir/recent.txt');

    spid = File('$dir/spid.json');

    if (!await recent.exists()) {
      players = [];
      recent.writeAsStringSync(jsonEncode(players));
    }

    players = jsonDecode(recent.readAsStringSync());

    if (!await spid.exists()) {
      total = await getTotal();
      setState(() {
        _isLoading = true;
      });
      await checkMetaInit();
    }
  }

  Widget _showDropDown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
      child: DropdownButton<String>(
        value: dropdownValue,
        icon: Icon(
          Platform.isAndroid
              ? Icons.arrow_downward
              : CupertinoIcons.down_arrow,
          color: Colors.white,
        ),
        iconSize: 24,
        elevation: 16,
        onChanged: (String? newValue) async {
          setState(() {
            dropdownValue = newValue!;
          });
        },
        items: dropdownValues
            .map<DropdownMenuItem<String>>((dynamic value) {
          return DropdownMenuItem<String>(
            value: value["desc"],
            child: Text(
              value["desc"],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: true,
        decoration: InputDecoration(
            hintText: '닉네임',
            icon: Icon(
              Icons.account_box,
              color: Colors.teal[800],
            )),
        validator: (value) => value!.isEmpty ? '닉네임을 입력해주세요.' : null,
        onSaved: (value) => _email = value!,
      ),
    );
  }

  Widget _submit() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(primary: Colors.teal[800]),
        onPressed: _validateAndSubmit,
        child: const Text('검색',
            style: TextStyle(fontSize: 20.0, color: Colors.white)),
      ),
    );
  }

  void _validateAndSubmit() async {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      await API.infoFromNickname(_email).then((get) async {
        if (get.nickname != null) {
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

          int _matchtype = 0;

          for (int i = 0; i < dropdownValues.length; i++) {
            if (dropdownValues[i]["desc"] == dropdownValue) {
              _matchtype = dropdownValues[i]["matchtype"];
              break;
            }
          }

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DetailApp(
                  id: get.accessId,
                  nickname: get.nickname,
                  level: get.level,
                  matchtype: _matchtype,
                )),
          );
        } else {
          alert("구단주 정보가 없습니다. 닉네임을 다시 확인해주세요.");
        }
      }).catchError((e) {
        alert("닉네임을 다시 확인해주세요.");
      });
    }
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  "서버에서 새 메타데이터를 다운로드 받는 중입니다. 몇 분 정도 소요될 수 있습니다. "
                      "더 나은 어플 사용을 위해 반드시 필요한 작업이므로 양해 부탁드립니다.\n"
                      "다운로드가 너무 오래 걸리는 경우엔 네트워크 환경이 안정적인지 확인해주신 후, 어플을 재부팅해주시면 감사하겠습니다.\n"
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("${(current / 1048576).toStringAsFixed(2)}MB / ${(total / 1048576).toStringAsFixed(2)}MB (${current * 100 ~/ total}%)"),
            ),
            Divider(),
            mailDeveloper(),
          ]);
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget mailDeveloper() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("버그 발생 시 문의 메일 주소"),
        TextButton(
          child: const Text('ground171717@gmail.com (클릭 시 메일주소 복사)'),
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: "ground171717@gmail.com"));
          },
        ),
      ],
    );
  }

  Widget _showBody() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Center(
              child: _showDropDown(),
            ),
            _showEmailInput(),
            _submit(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: "개인정보처리방침",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                'https://ground171717.blogspot.com/2021/10/privacy.html';
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          }),
                  ),
                ),
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: "축구장 사진 출처",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                'https://blog.stockclub.kr/entry/%EC%B6%95%EA%B5%AC%EC%9E%A5%EC%9D%98-%ED%81%AC%EA%B8%B0%EB%8A%94-%EB%AA%A8%EB%91%90-%EB%8B%A4%EB%A5%B4%EB%8B%A4-EPL-%EB%B9%856%EB%A1%9C-%EC%95%8C%EC%95%84%EB%B3%B8-%EC%B6%95%EA%B5%AC-%EA%B2%BD%EA%B8%B0%EC%9E%A5';
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          }),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              "Data based on NEXON DEVELOPERS\n\n"
                  "이 어플은 NEXON 공식이 아닌 제3자가 개발/배포한 어플입니다.",
              textAlign: TextAlign.center,
            ),
            const Divider(),
            mailDeveloper(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(widget.title),
          actions: <Widget>[
            !_isLoading
                ? IconButton(
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              tooltip: "메타데이터 업데이트",
              onPressed: () async {

                total = await getTotal();
                checkMetaInit(option: true);
              },
            )
                : Container(),
            !_isLoading
                ? IconButton(
              icon: const Icon(
                Icons.recent_actors,
                color: Colors.white,
              ),
              tooltip: "최근 검색 구단주",
              onPressed: () async {
                setState(() {
                  players = jsonDecode(recent.readAsStringSync());
                });
                await showRecent();
              },
            )
                : Container(),
          ],
        ),
        body:
        _isLoading ? Center(child: _showCircularProgress()) : _showBody());
  }

  Future<void> showRecent() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (_context, setState) {
            return AlertDialog(
              title: const Text("최근 검색 구단주"),
              actions: <Widget>[
                TextButton(
                  child: const Text('닫기'),
                  onPressed: () {
                    Navigator.of(_context).pop();
                  },
                ),
              ],
              content: SizedBox(
                width: MediaQuery.of(_context).size.width * 0.9,
                height: MediaQuery.of(_context).size.height * 0.3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: players.length,
                        itemBuilder: (BuildContext _context2, int i) {
                          return _buildRow(players[i], _context, setState);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(List<dynamic> cells, _context, _setState) {
    return ListTile(
      dense: true,
      title: Text(cells[1].toString()),
      trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _setState(() {
              players.remove(cells);
              recent.writeAsStringSync(jsonEncode(players));
            });
          }),
      onTap: () async {
        await API.infoFromAccessId(cells[0]).then((get) async {
          if (get.nickname != null) {
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
            Navigator.of(_context).pop();

            int _matchtype = 0;

            for (int i = 0; i < dropdownValues.length; i++) {
              if (dropdownValues[i]["desc"] == dropdownValue) {
                _matchtype = dropdownValues[i]["matchtype"];
                break;
              }
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailApp(
                    id: cells[0],
                    nickname: get.nickname,
                    level: get.level,
                    matchtype: _matchtype,
                  )),
            );
          }
        });
      },
    );
  }

  Future<void> alert(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> checkMetaInit({bool option = false}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: option, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(option ? "메타데이터를 업데이트하시겠습니까? 크기는 약 ${(total / 1048576).toStringAsFixed(2)}MB입니다." :
          "더 나은 어플리케이션 사용을 위해 메타데이터를 다운로드하겠습니다. 크기는 약 ${(total / 1048576).toStringAsFixed(2)}MB이며, "
              "다운로드하지 않을 시 어플을 이용할 수 없습니다."),
          actions: <Widget>[
            option
                ? TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
                : Container(),
            TextButton(
              child: const Text('다운로드'),
              onPressed: () {
                Navigator.of(context).pop();
                download1();
              },
            ),
          ],
        );
      },
    );
  }

  download1() async {
    setState(() {
      current = 0;
      _isLoading = true;
    });

    final file = File('$dir/spid.json');

    try {
      await file.delete();
    } catch (e) {
      print(e);
    } finally {
      HttpClient _client = HttpClient();
      final response = await _client
          .getUrl(Uri.parse(
          "https://static.api.nexon.co.kr/fifaonline4/latest/spid.json"))
          .then((HttpClientRequest request) {
        return request.close();
      });

      response.listen((d) {
        file.writeAsBytesSync(d, mode: FileMode.append);
        setState(() {
          current += d.length;
        });
      }, onDone: () async {
        download2();
      }, onError: (e) async {
        print(e);
        alert("다운로드 중 오류가 발생했습니다. 네트워크, 저장공간 등을 확인해주세요.");
      });
    }
  }
  download2() async {
    final file = File('$dir/seasonid.json');

    try {
      await file.delete();
    } catch (e) {
      print(e);
    } finally {
      HttpClient _client = HttpClient();
      final response = await _client
          .getUrl(Uri.parse(
          "https://static.api.nexon.co.kr/fifaonline4/latest/seasonid.json"))
          .then((HttpClientRequest request) {
        return request.close();
      });

      response.listen((d) {
        file.writeAsBytesSync(d, mode: FileMode.append);
        setState(() {
          current += d.length;
        });
      }, onDone: () async {
        _isLoading = false;
      }, onError: (e) async {
        print(e);
        alert("다운로드 중 오류가 발생했습니다. 네트워크, 저장공간 등을 확인해주세요.");
      });
    }
  }
}
