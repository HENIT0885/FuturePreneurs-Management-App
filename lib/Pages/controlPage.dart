import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:peerdoor/Pages/RoundOneStatus.dart';
import 'package:peerdoor/Pages/RoundTwoStatus.dart';
import 'package:peerdoor/Pages/landingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:loading/loading.dart';
import 'package:loading/indicator/pacman_indicator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:syncfusion_flutter_charts/charts.dart';

class controlPage extends StatefulWidget {
  const controlPage({Key? key}) : super(key: key);

  @override
  _controlPageState createState() => _controlPageState();
}

class TeamControl {
  TeamControl(this.isHandRaised, this.speakerOn, this.micOn, this.team,
      this.connectedUsers, this.handraise);
  final bool isHandRaised;
  final bool speakerOn;
  List<User> connectedUsers;
  bool handraise;
  final bool micOn;
  final Team team;
}

class ConnectionStat {
  ConnectionStat(this.id, this.isConnected);
  String id;
  bool isConnected;
}

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final int y;
  final Color color;
}

class _controlPageState extends State<controlPage> {
  // List<RtcChannel> channels = [];
  var micOn = false;
  var speakerOn = true;
  List<ConnectionStat> connections = [];
  late RtcEngine engine;
  late RtcChannel channel;
  bool isTeamConnected = false;
  List<String> teamIDS = [];
  var APP_ID = "583e53c6739745739d20fbb11ac8f0ef";
  String Token = "";
  late io.Socket socket;
  String mentorsChannel = "fpecellvit72021";
  List<User> connectedMentors = [];
  List<int> analytics = [];
  ScrollController updateController = ScrollController();
  // final List<ChartData> chartData = [
  //   ChartData('David', 25, Color.fromRGBO(9, 0, 136, 1)),
  //   ChartData('Steve', 38, Color.fromRGBO(147, 0, 119, 1)),
  //   ChartData('Jack', 34, Color.fromRGBO(228, 0, 124, 1)),
  //   ChartData('Others', 52, Color.fromRGBO(255, 189, 57, 1))
  // ];

  List<String> updates = ["No Updates for now"];

  final List<ChartData> roundOneData = [];
  final List<ChartData> roundTwoData = [];

  String teamConnectionText() {
    if (isTeamConnected == true) {
      return "Leave";
    } else {
      return "Connect";
    }
  }

  void getAnalyticsData() async {
    var response = await http.get(Uri.parse(
        "https://futurepreneursbackend.herokuapp.com/api/management/getAnalytics"));
    dynamic decoded = jsonDecode(response.body);

    List<ChartData> roundOneData = [
      ChartData("Round One", decoded['roundOneCompleted'], Colors.redAccent),
      ChartData("Total", decoded['totalTeams'] - decoded['roundOneCompleted'],
          Colors.grey),
    ];
    List<ChartData> roundTwoData = [
      ChartData("Round One", decoded['roundTwoCompleted'], Colors.lightBlue),
      ChartData("Total", decoded['totalTeams'] - decoded['roundTwoCompleted'],
          Colors.grey),
    ];

    setState(() {
      roundOne = roundOneData;
      roundTwo = roundTwoData;
    });
  }

  Color teamBackground() {
    if (isTeamConnected == true) {
      return Colors.redAccent;
    } else {
      return Colors.green;
    }
  }

  List<ChartData> roundOne = [];
  List<ChartData> roundTwo = [];

  void _addAgoraEventHandlers() {
    engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        print("error ${code}");
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        print("joining succeed ${channel}");
      },
      leaveChannel: (stats) {
        print(stats);
      },
      userJoined: (uid, elapsed) {
        print("User Joined ${uid}");
      },
      userOffline: (uid, reason) {
        print("User Went Offline ${uid}");
      },
    ));
  }

  Future<void> connect(List<String> teams) async {
    await [Permission.microphone].request();
    // RtcEngineContext context = RtcEngineContext(APP_ID);

    engine = await RtcEngine.create(APP_ID);
    // var uid = Random().nextInt(100000);
    await engine.enableLocalAudio(true);
    await engine.setEnableSpeakerphone(true);
    await engine.setChannelProfile(ChannelProfile.Game);
    await engine.muteLocalAudioStream(true);
    _addAgoraEventHandlers();
    // String token1 = await fetchRtcToken("team", uid, 'publisher');
    // await engine.joinChannel(token1, "team", null, uid);
  }

  @override
  void initState() {
    getTeamData();
    connect([]);
    getAnalyticsData();
    super.initState();
  }

  @override
  void dispose() {
    print("disconnected");
    socket.disconnect();
    engine.leaveChannel();
    engine.destroy();
  }

  void refreshConenctions(String id) {
    print(id);
    for (int k = 0; k < connections.length; k++) {
      if (connections.elementAt(k).id.compareTo(id) != 0) {
        if (connections.elementAt(k).isConnected == true) {
          setState(() {
            connections.elementAt(k).isConnected = false;
          });
        }
      }
    }
  }

  Future<String> fetchRtcToken(String channel, int uid, String role) async {
    print('fetching token');
    var response = await http.get(Uri.parse(
        "https://futurepreneursbackend.herokuapp.com/api/voice/token?channel=${channel}&uid=${uid}&role=${role}"));
    var decoded = jsonDecode(response.body);
    Token = decoded['token'];
    var token = decoded['token'];
    return token;
  }

  var user;
  List<TeamControl> AllTeams = [];
  bool loading = false;
  List<String> pointLabels = ['Round 1.1', 'Round 1.2', 'Round 2'];

  String getTeamName(id) {
    List<TeamControl> filtered =
        AllTeams.where((element) => element.team.id == id).toList();
    return filtered.elementAt(0).team.teamName;
  }

  Future<void> getTeamData() async {
    getAnalyticsData();
    setState(() {
      loading = true;
    });
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    var userr = jsonDecode(sharedPreference.getString('user')!);
    setState(() {
      user = userr;
    });
    var teams = sharedPreference.getStringList('selectedteams')!;
    for (int k = 0; k < teams.length; k++) {
      print(teams.elementAt(k));
      var connection = ConnectionStat(teams.elementAt(k), false);
      connections.add(connection);
    }
    List<TeamControl> allTeams = [];
    for (int i = 0; i < teams.length; i++) {
      print(teams.elementAt(i));
      var response = await http.get(
          'https://futurepreneursbackend.herokuapp.com/api/public/getTeamById?teamID=${teams.elementAt(i)}');
      print(response.statusCode);
      var element = jsonDecode(response.body);
      var id = element['_id'];
      List<User> members = [];
      var teamName = element['TeamName'];
      var roundOnePoints = element['RoundOnePoints'];
      var roundTwoPoints = element['RoundTwoPoints'];

      for (int j = 0; j < element['Members'].length; j++) {
        var elem = element['Members'][j];
        var user = User(elem['isLeader'],
            name: elem['User']['name'],
            email: elem['User']['email'],
            photourl: elem['User']['photoURL']);
        members.add(user);
      }
      Team team = Team(
          isSelected: false,
          teamName: teamName,
          id: id,
          members: members,
          roundOnePoints: roundOnePoints,
          roundTwoPoints: roundTwoPoints);
      TeamControl control = TeamControl(false, false, false, team, [], false);

      allTeams.add(control);
    }
    AllTeams = allTeams;

    socket =
        // "https://futurepreneursbackend.herokuapp.com/"
        io.io("https://futurepreneursbackend.herokuapp.com/", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    socket.connect();

    socket.onConnect((data) => {
          socket.emit('joinRoom', {
            'name': user['name'],
            'email': user['email'],
            'photoURL': user['photourl'],
            'teamID': mentorsChannel,
            'type': "Mentor"
          }),
          for (int i = 0; i < AllTeams.length; i++)
            {
              socket.emit('joinRoom', {
                'name': user['name'],
                'email': user['email'],
                'photoURL': user['photourl'],
                'teamID': AllTeams.elementAt(i).team.id,
                'type': "Mentor"
              }),
            }
        });
    setState(() {
      loading = false;
    });
    socket.on('roundOneCompletion', (data) {
      var TeamName = getTeamName(data['teamID']);

      setState(() {
        updates.add("${TeamName} has completed Round Number 1");
        Timer(
          Duration(milliseconds: 500),
          () => updateController
              .jumpTo(updateController.position.maxScrollExtent),
        );
      });
    });

    socket.on('roundTwoCompletion', (data) {
      var TeamName = getTeamName(data['teamID']);
      setState(() {
        updates.add("${TeamName} has completed Round Number 2");
        Timer(
          Duration(milliseconds: 500),
          () => updateController
              .jumpTo(updateController.position.maxScrollExtent),
        );
      });
    });
    socket.on('receivedAttempts', (data) {
      var TeamName = getTeamName(data['teamID']);
      setState(() {
        updates.add(
            "${TeamName} has attempted Question Number ${data['currQuestion'] + 1}");
        Timer(
          Duration(milliseconds: 500),
          () => updateController
              .jumpTo(updateController.position.maxScrollExtent),
        );
      });
    });
    socket.on(
      'roomUsers',
      (data) {
        List<User> varUser = [];
        if (data['room'] == mentorsChannel) {
          for (int j = 0; j < data['users'].length; j++) {
            var element = data['users'][j];
            var name = element['username'];
            var email = element['email'];
            var photourl = element['photoURL'];
            var user =
                User(false, name: name, email: email, photourl: photourl);
            varUser.add(user);
          }
          setState(() {
            connectedMentors = varUser;
          });
        } else {
          List<User> varUser = [];
          List<TeamControl> teams =
              AllTeams.where((element) => element.team.id == data['room'])
                  .toList();
          for (int j = 0; j < data['users'].length; j++) {
            var element = data['users'][j];
            var name = element['username'];
            var email = element['email'];
            var photourl = element['photoURL'];
            var user =
                User(false, name: name, email: email, photourl: photourl);
            varUser.add(user);
          }
          setState(() {
            teams.elementAt(0).connectedUsers = varUser;
          });
        }
      },
    );
    socket.on('handup', (data) {
      print("handup");
      print(data['room']);
      List<TeamControl> team =
          AllTeams.where((element) => element.team.id == data['room']).toList();
      setState(() {
        team.elementAt(0).handraise = true;
        AllTeams.sort((a, b) {
          if (b.handraise) {
            return 1;
          } else {
            return -1;
          }
        });
      });
    });

    socket.on('handclose', (data) {
      List<TeamControl> team =
          AllTeams.where((element) => element.team.id == data['room']).toList();
      setState(() {
        team.elementAt(0).handraise = false;
        AllTeams.sort((a, b) {
          if (b.handraise) {
            return 1;
          } else {
            return -1;
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getAnalyticsData();
    return Scaffold(
        backgroundColor: Colors.white,
        body: loading == true
            ? myLoadingInd()
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.sp),
                  child: AllTeams.length == 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "No Team Selected\n Go back and hit the `+` button to select one for maintainance\n Thank You",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15.sp,
                                  fontStyle: FontStyle.italic),
                            ),
                            SizedBox(
                              height: 20.h,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 50.h,
                                width: 130.w,
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20.r)),
                                child: Center(
                                    child: Text(
                                  "Back",
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 16.sp),
                                )),
                              ),
                            )
                          ],
                        )
                      : Column(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Workspace',
                                  style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 25),
                                ),
                                Spacer(),
                                // GestureDetector(
                                //   onTap: () {
                                //     Navigator.push(
                                //         context,
                                //         MaterialPageRoute(
                                //             builder: (_) => RoundOneStatus()));
                                //   },
                                //   child: Text(
                                //     'R1',
                                //     style: TextStyle(
                                //         color: Colors.grey.shade600,
                                //         fontSize: 28.sp,
                                //         fontWeight: FontWeight.bold),
                                //   ),
                                // ),
                                // SizedBox(
                                //   width: 10.w,
                                // ),
                                // GestureDetector(
                                //   onTap: () {
                                //     Navigator.push(
                                //         context,
                                //         MaterialPageRoute(
                                //             builder: (_) => RoundTwoState()));
                                //   },
                                //   child: Text(
                                //     'R2',
                                //     style: TextStyle(
                                //         color: Colors.grey.shade600,
                                //         fontSize: 28.sp,
                                //         fontWeight: FontWeight.bold),
                                //   ),
                                // ),
                                SizedBox(
                                  width: 10.w,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (speakerOn == true) {
                                      await engine.enableLocalAudio(false);
                                      setState(() {
                                        speakerOn = false;
                                      });
                                    } else {
                                      await engine.enableLocalAudio(true);
                                      setState(() {
                                        speakerOn = true;
                                      });
                                    }
                                  },
                                  child: Icon(
                                    speakerOn == true
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    size: 35.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(
                                  width: 20.w,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: Image(
                                    image: NetworkImage(user['photourl']),
                                    height: 40.h,
                                    width: 40.w,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20.h,
                            ),
                            Container(
                                height: 250.h,
                                width: 400.w,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50.r)),
                                child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: AllTeams.length,
                                    itemBuilder: (_, index) => TeamManager(
                                        AllTeams.elementAt(index),
                                        index,
                                        connections
                                            .elementAt(index)
                                            .isConnected,
                                        engine,
                                        () async {
                                          var uid = Random().nextInt(100000);
                                          if (connections
                                                  .elementAt(index)
                                                  .isConnected ==
                                              true) {
                                            setState(() {
                                              isTeamConnected = false;
                                              connections
                                                  .elementAt(index)
                                                  .isConnected = false;
                                            });
                                            await engine.leaveChannel();
                                          } else {
                                            refreshConenctions(connections
                                                .elementAt(index)
                                                .id);
                                            setState(() {
                                              isTeamConnected = false;
                                              connections
                                                  .elementAt(index)
                                                  .isConnected = true;
                                            });
                                            await engine.leaveChannel();
                                            var token = await fetchRtcToken(
                                                connections.elementAt(index).id,
                                                uid,
                                                "publisher");
                                            await engine.joinChannel(
                                                token,
                                                connections.elementAt(index).id,
                                                null,
                                                uid);
                                          }
                                        },
                                        micOn,
                                        () async {
                                          if (micOn == true) {
                                            await engine
                                                .muteLocalAudioStream(true);
                                          } else {
                                            await engine
                                                .muteLocalAudioStream(false);
                                          }
                                          setState(() {
                                            micOn = !micOn;
                                          });
                                          ;
                                        },
                                        AllTeams.elementAt(index)
                                            .connectedUsers,
                                        AllTeams.elementAt(index).handraise))),
                            SizedBox(
                              height: 15.h,
                            ),
                            Container(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "Round 1 Status",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      width: 150.w,
                                      height: 150.h,
                                      child: SfCircularChart(
                                          margin: EdgeInsets.all(10),
                                          series: <CircularSeries>[
                                            PieSeries<ChartData, String>(
                                                dataSource: roundOne,
                                                dataLabelSettings:
                                                    DataLabelSettings(
                                                        isVisible: true,
                                                        // Avoid labels intersection
                                                        labelIntersectAction:
                                                            LabelIntersectAction
                                                                .none,
                                                        labelPosition:
                                                            ChartDataLabelPosition
                                                                .outside,
                                                        connectorLineSettings:
                                                            ConnectorLineSettings(
                                                                type:
                                                                    ConnectorType
                                                                        .curve,
                                                                length: '25%')),
                                                pointColorMapper:
                                                    (ChartData data, _) =>
                                                        data.color,
                                                enableSmartLabels: true,
                                                enableTooltip: true,
                                                explode: true,
                                                explodeAll: true,
                                                radius: '50%',
                                                xValueMapper:
                                                    (ChartData data, _) =>
                                                        data.x,
                                                yValueMapper:
                                                    (ChartData data, _) =>
                                                        data.y)
                                          ]),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 70,
                                  color: Colors.grey,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Round 2 Status",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      width: 190.w,
                                      height: 150.h,
                                      child: SfCircularChart(
                                          series: <CircularSeries>[
                                            PieSeries<ChartData, String>(
                                                dataSource: roundTwo,
                                                pointColorMapper:
                                                    (ChartData data, _) =>
                                                        data.color,
                                                dataLabelSettings:
                                                    DataLabelSettings(
                                                        isVisible: true,
                                                        // Avoid labels intersection
                                                        labelIntersectAction:
                                                            LabelIntersectAction
                                                                .none,
                                                        labelPosition:
                                                            ChartDataLabelPosition
                                                                .outside,
                                                        connectorLineSettings:
                                                            ConnectorLineSettings(
                                                                type:
                                                                    ConnectorType
                                                                        .curve,
                                                                length: '25%')),
                                                enableSmartLabels: true,
                                                enableTooltip: true,
                                                explode: true,
                                                explodeAll: true,
                                                radius: '50%',
                                                xValueMapper:
                                                    (ChartData data, _) =>
                                                        data.x,
                                                yValueMapper:
                                                    (ChartData data, _) =>
                                                        data.y)
                                          ]),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                            Expanded(
                              child: Container(
                                // height: 150.h,
                                width: double.maxFinite,
                                color: Colors.white,
                                child: ListView.builder(
                                    controller: updateController,
                                    itemCount: updates.length,
                                    itemBuilder: (_, index) => Padding(
                                          padding: EdgeInsets.only(
                                              left: 20.w,
                                              right: 10.w,
                                              top: 2.h,
                                              bottom: 2.w),
                                          child: Text(
                                            updates[index],
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14.sp,
                                                letterSpacing: 1),
                                          ),
                                        )),
                              ),
                            ),
                            Container(
                              height: 125.h,
                              width: double.maxFinite,
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                      color: Colors.grey.shade700,
                                      width: 1.sp)),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 30.w,
                                    right: 30.w,
                                    top: 5.h,
                                    bottom: 5.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Moderators',
                                          style: TextStyle(
                                              color: Colors.grey.shade300,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () async {
                                            var uid = Random().nextInt(100000);
                                            if (isTeamConnected == true) {
                                              setState(() {
                                                isTeamConnected = false;
                                              });
                                              await engine.leaveChannel();
                                            } else {
                                              setState(() {
                                                isTeamConnected = true;
                                              });
                                              await engine.leaveChannel();
                                              var token = await fetchRtcToken(
                                                  "fpecellvit72021",
                                                  uid,
                                                  "publisher");
                                              await engine.joinChannel(token,
                                                  "fpecellvit72021", null, uid);
                                              refreshConenctions(
                                                  "fpecellvit72021");
                                            }
                                          },
                                          child: Container(
                                            width: 100.w,
                                            height: 30.h,
                                            decoration: BoxDecoration(
                                                color: teamBackground(),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.r)),
                                            child: Center(
                                              child: Text(
                                                teamConnectionText(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.sp),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20.h,
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          height: 35.h,
                                          width: 280.w,
                                          child: ListView.builder(
                                              itemCount:
                                                  connectedMentors.length,
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (_, index) =>
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 7.w),
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.r),
                                                        child: Image(
                                                          image: NetworkImage(
                                                              connectedMentors
                                                                  .elementAt(
                                                                      index)
                                                                  .photourl),
                                                          height: 30.h,
                                                          width: 30.w,
                                                          fit: BoxFit.cover,
                                                        )),
                                                  )),
                                        ),
                                        Spacer(),
                                        Visibility(
                                          visible: isTeamConnected,
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (micOn == true) {
                                                await engine
                                                    .muteLocalAudioStream(true);
                                              } else {
                                                await engine
                                                    .muteLocalAudioStream(
                                                        false);
                                              }
                                              setState(() {
                                                micOn = !micOn;
                                              });
                                            },
                                            child: Icon(
                                              micOn == true
                                                  ? Icons.mic
                                                  : Icons.mic_off_outlined,
                                              size: 30.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 10.w,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                ),
              ));
  }
}

class myLoadingInd extends StatelessWidget {
  const myLoadingInd({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: Loading(
        color: Colors.green,
        size: 70.sp,
        indicator: PacmanIndicator(),
      ),
    ));
  }
}

class TeamManager extends StatefulWidget {
  TeamManager(
      this.control,
      this.index,
      this.isConnected,
      this.engine,
      this.onTap,
      this.micOn,
      this.onTapMic,
      this.connectedUsers,
      this.handRaise);

  final TeamControl control;
  final int index;
  final RtcEngine engine;
  final onTap;
  final onTapMic;
  bool micOn;
  bool isConnected;
  bool handRaise;
  List<User> connectedUsers = [];

  @override
  _TeamManagerState createState() => _TeamManagerState();
}

class _TeamManagerState extends State<TeamManager> {
  List<String> pointLabels = ['Round 1.1', 'Round 1.2', 'Round 2'];

  Color connectionTextColor() {
    if (widget.handRaise == true) {
      return Colors.white;
    } else {
      return Colors.white;
    }
  }

  Color backgroundColorConenction() {
    if (widget.isConnected == true) {
      if (widget.handRaise == true) {
        return Colors.black;
      }
      return Colors.red;
    } else {
      if (widget.handRaise == true) {
        return Colors.black;
      }
      return Colors.green;
    }
  }

  String getTextStatus() {
    if (widget.isConnected == true) {
      return "Leave";
    } else {
      return "Connect";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> score = [
      widget.control.team.roundOnePoints.toString(),
      widget.control.team.roundTwoPoints.toString(),
      "0"
    ];
    return Padding(
      padding: EdgeInsets.only(right: 5.w),
      child: Container(
        height: 250.h,
        width: 380.w,
        decoration: BoxDecoration(
            color: widget.handRaise ? Colors.red : Colors.black,
            borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 20.h,
                    width: 210.w,
                    child: Text(
                      widget.control.team.teamName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 120.w,
                    height: 40.h,
                    color: Colors.transparent,
                    child: ListView.builder(
                        itemCount: widget.connectedUsers.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) => Padding(
                              padding: EdgeInsets.all(3.sp),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: Image(
                                    image: NetworkImage(widget.connectedUsers
                                        .elementAt(index)
                                        .photourl),
                                    height: 30.h,
                                    width: 30.w,
                                    fit: BoxFit.cover,
                                  )),
                            )),
                  )
                ],
              ),
              SizedBox(
                height: 20.h,
              ),
              Row(
                children: [
                  Text(
                    ' Lead',
                    style:
                        TextStyle(color: Colors.grey.shade300, fontSize: 15.sp),
                  ),
                  Spacer(),
                  Text(
                    widget.control.team.members
                        .where((element) => element.isLeader == true)
                        .elementAt(0)
                        .name,
                    style: TextStyle(
                        color: widget.handRaise
                            ? Colors.black
                            : Colors.greenAccent.shade700,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(
                height: 20.h,
              ),
              Container(
                height: 40.h,
                width: double.maxFinite,
                child: ListView.builder(
                    itemCount: pointLabels.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) => Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Container(
                            height: 40.h,
                            width: 150.w,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r)),
                            child: Center(
                              child: Text(
                                '${pointLabels.elementAt(index)} - ${score.elementAt(index)}',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )),
              ),
              SizedBox(
                height: 30.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 13.w,
                  ),
                  GestureDetector(
                    onTap: widget.onTapMic,
                    child: Visibility(
                      visible: widget.isConnected,
                      child: Icon(
                        widget.micOn == true
                            ? Icons.mic
                            : Icons.mic_off_outlined,
                        size: 30.sp,
                        color: widget.handRaise ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Container(
                        height: 30.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: backgroundColorConenction(),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            getTextStatus(),
                            style: TextStyle(
                              color: connectionTextColor(),
                              fontSize: 15.sp,
                            ),
                          ),
                        )),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
