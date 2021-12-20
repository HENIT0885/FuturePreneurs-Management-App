import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:peerdoor/Pages/controlPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class landingPage extends StatefulWidget {
  const landingPage({Key? key}) : super(key: key);

  @override
  _landingPageState createState() => _landingPageState();
}

class Count {
  Count({required this.users, required this.teams, required this.members});

  final String users;
  final String teams;
  final String members;
}

class Team {
  Team(
      {required this.teamName,
      required this.isSelected,
      required this.id,
      required this.members,
      required this.roundOnePoints,
      required this.roundTwoPoints});

  final String teamName;
  final String id;
  final List<User> members;
  final int roundOnePoints;
  final int roundTwoPoints;
  final bool isSelected;
}

class _landingPageState extends State<landingPage> {
  void refresh() {
    setState(() {});
  }

  List<String> selectedIDs = [];

  Future<List<Team>> getTeams() async {
    var response = await http.get(Uri.parse(
        "https://futurepreneursbackend.herokuapp.com/api/public/getAllTeams"));
    var data = jsonDecode(response.body);
    List<Team> teams = [];
    for (int i = 0; i < data.length; i++) {
      var element = data[i];
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
      bool isSelected = selectedIDs.contains(id);
      Team team = Team(
          isSelected: isSelected,
          teamName: teamName,
          id: id,
          members: members,
          roundOnePoints: roundOnePoints,
          roundTwoPoints: roundTwoPoints);
      teams.add(team);
    }
    return teams;
  }

  void loadSavedTeams() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove('selectedteams');
    var IDs = sharedPreferences.getStringList('selectedteams')!;
    if (IDs != null) {
      selectedIDs = IDs;
    }
  }

  Future<String> getUser() async {
    loadSavedTeams();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var user = await sharedPreferences.getString('user')!;
    return user;
  }

  Future<Count> getCounts() async {
    var response = await http.get(Uri.parse(
        "https://futurepreneursbackend.herokuapp.com/api/management/get"));
    var data = jsonDecode(response.body);
    var counts = Count(
        users: data['userCount'],
        teams: data['teamCount'],
        members: data['memberCount']);
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
          future: getUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Text('Loading',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15.sp)),
              );
            } else {
              var user = jsonDecode(snapshot.data!);
              return Padding(
                padding: EdgeInsets.only(top: 55.h, left: 16.w, right: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image(
                            height: 40.h,
                            width: 40.w,
                            image: NetworkImage(user['photourl']),
                          ),
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user['email'],
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13.sp),
                            )
                          ],
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: refresh,
                          child: Icon(
                            CupertinoIcons.refresh,
                            size: 30.sp,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          width: 15.w,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => controlPage())),
                          child: Image(
                            image: AssetImage('images/fplogo.png'),
                            height: 30.h,
                            width: 30.w,
                          ),
                        ),
                        SizedBox(
                          width: 20.w,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 30.h,
                    ),
                    FutureBuilder<Count>(
                        future: getCounts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.only(top: 63.h, bottom: 60.h),
                              child: Center(
                                  child: Text(
                                "Loading Stats...",
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14.sp),
                              )),
                            );
                          } else {
                            var data = snapshot.data!;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "Users",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 20.h,
                                    ),
                                    Text(
                                      data.users,
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 40.sp),
                                    )
                                  ],
                                ),
                                Container(
                                  width: 1.w,
                                  height: 100.h,
                                  color: Colors.grey,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Teams",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 20.h,
                                    ),
                                    Text(
                                      data.teams,
                                      style: TextStyle(
                                          color: Colors.greenAccent.shade700,
                                          fontSize: 80.sp),
                                    )
                                  ],
                                ),
                                Container(
                                  width: 1.w,
                                  height: 100.h,
                                  color: Colors.grey,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Members",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 20.h,
                                    ),
                                    Text(
                                      data.members,
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 40.sp),
                                    )
                                  ],
                                ),
                              ],
                            );
                          }
                        }),
                    SizedBox(
                      height: 10.h,
                    ),
                    // Container(
                    //   width: double.maxFinite,
                    //   height: 70.h,
                    //   decoration: BoxDecoration(
                    //     color: Colors.black,
                    //     borderRadius: BorderRadius.circular(20.r),
                    //   ),
                    //   child: Padding(
                    //     padding: EdgeInsets.only(left: 25.w, right: 20.w),
                    //     child: Center(
                    //       child: TextField(
                    //         style: TextStyle(
                    //             color: Colors.white, fontSize: 15.sp),
                    //         decoration: InputDecoration(
                    //             border: InputBorder.none,
                    //             errorBorder: InputBorder.none,
                    //             focusedBorder: InputBorder.none,
                    //             hintText: "Search Team By Name",
                    //             hintStyle: TextStyle(
                    //                 color: Colors.grey, fontSize: 15.sp)),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    FutureBuilder<List<Team>>(
                        future: getTeams(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding:
                                  EdgeInsets.only(top: 100.h, bottom: 100.h),
                              child: Center(
                                  child: Text(
                                "Loading Teams...",
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14.sp),
                              )),
                            );
                          } else {
                            return Container(
                              width: double.maxFinite,
                              height: 570.h,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.r)),
                              child: ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (_, index) => TeamView(
                                        team: snapshot.data!.elementAt(index),
                                        selected: snapshot.data!
                                            .elementAt(index)
                                            .isSelected,
                                      )),
                            );
                          }
                        }),
                    // SizedBox(
                    //   height: 10.h,
                    // ),
                    Padding(
                      padding: EdgeInsets.all(10.h),
                      child: Center(
                        child: Text(
                          'Developed and Designed By Henit C.',
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }
}

class TeamView extends StatefulWidget {
  TeamView({required this.team, required this.selected});

  Team team;
  bool selected;

  @override
  _TeamViewState createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  IconData getIcon() {
    if (widget.selected == true) {
      return Icons.done;
    } else {
      return Icons.add;
    }
  }

  Color getIconColor() {
    if (widget.selected == true) {
      return Colors.green.shade700;
    } else {
      return Colors.black;
    }
  }

  Future<List<String>> getSavedElements() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var IDs = sharedPreferences.get('selectedteams') as List<String>;
    return IDs;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        height: 260.h,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: FutureBuilder<List<String>>(
            future: getSavedElements(),
            builder: (context, snapshot) {
              return Padding(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              widget.selected = !widget.selected;
                            });
                            SharedPreferences sharedpreference =
                                await SharedPreferences.getInstance();
                            if (widget.selected == false) {
                              snapshot.data!.remove(widget.team.id);
                              sharedpreference.remove("selectedteams");
                              sharedpreference.setStringList(
                                  "selectedteams", snapshot.data!);
                            } else {
                              if (snapshot.data != null) {
                                print(widget.team.id);
                                snapshot.data!.add(widget.team.id);
                                sharedpreference.setStringList(
                                    "selectedteams", snapshot.data!);
                              } else {
                                print(widget.team.id);
                                sharedpreference.setStringList(
                                    "selectedteams", [widget.team.id]);
                              }
                            }
                          },
                          child: Container(
                            height: 30.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15.r)),
                            child: Icon(
                              getIcon(),
                              color: getIconColor(),
                              size: 20.sp,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          widget.team.teamName,
                          style: TextStyle(
                              color: Colors.greenAccent.shade200,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      children: [
                        Container(
                          height: 150.h,
                          width: 200.w,
                          child: ListView.builder(
                            itemCount: widget.team.members.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (_, index) => UserView(
                                user: widget.team.members.elementAt(index)),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 150,
                          color: Colors.grey,
                        ),
                        Container(
                            height: 150.h,
                            width: 120.w,
                            child: Padding(
                              padding: EdgeInsets.only(left: 35),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Round 1.1',
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17.sp),
                                    ),
                                    Text(
                                      widget.team.roundOnePoints.toString(),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 45.sp),
                                    ),
                                    SizedBox(
                                      height: 10.h,
                                    ),
                                    Text(
                                      'Round 1.2',
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.sp),
                                    ),
                                    Text(
                                      widget.team.roundTwoPoints.toString(),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 45.sp),
                                    ),
                                    SizedBox(
                                      height: 10.h,
                                    ),
                                    Text(
                                      'Round 2',
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17.sp),
                                    ),
                                    Text(
                                      '0',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 45.sp),
                                    ),
                                    SizedBox(
                                      height: 10.h,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }
}

class UserView extends StatelessWidget {
  UserView({required this.user});

  final User user;

  Color getTitleColor() {
    if (user.isLeader == true) {
      return Colors.greenAccent.shade200;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 60.h,
      width: 200.w,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.sp),
            child: Image(
              image: NetworkImage(user.photourl),
              height: 30.h,
              width: 30.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140.w,
                child: Text(
                  user.name,
                  style: TextStyle(
                      color: getTitleColor(),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                width: 140.w,
                child: Text(
                  user.email,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class User {
  User(this.isLeader,
      {required this.name, required this.email, required this.photourl});
  final String name;
  final String email;
  final String photourl;
  final bool isLeader;
}
