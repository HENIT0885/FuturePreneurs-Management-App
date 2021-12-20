import 'dart:convert';
import 'package:peerdoor/Pages/landingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class basePage extends StatefulWidget {
  const basePage({Key? key}) : super(key: key);
  @override
  _basePageState createState() => _basePageState();
}

class _basePageState extends State<basePage> {
  var alert = "Get Inside";

  void sendDataToDatabase(GoogleSignInAccount user) async {
    SharedPreferences sharedreferences = await SharedPreferences.getInstance();

    setState(() {
      alert = "Identifying You";
    });
    var body = {
      "email": user.email,
      "name": user.displayName,
      "photourl": user.photoUrl,
    };
    var response = await http.post(
        Uri.parse(
            "https://futurepreneursbackend.herokuapp.com/api/management/createManager"),
        body: jsonEncode(body),
        headers: {"content-type": "application/json"});
    print(response.statusCode);
    if (response.statusCode == 200) {
      print(response.body);
      await sharedreferences.setString("user", response.body);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => landingPage()));
    } else {
      setState(() {
        alert = "Gadbad ho gayi!";
      });
    }
  }

  void requestLogin() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var loggedIn = sharedPreferences.getString("user");

    setState(() {
      alert = "Loading...";
    });

    if (loggedIn == null) {
      final user = await GoogleSignIn().signIn();
      sendDataToDatabase(user);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => landingPage()));
    }
    // final user = await GoogleSignIn().signIn();
    // sendDataToDatabase(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 50.sp, bottom: 50.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
              ),
              Image(
                height: 270.h,
                image: AssetImage('images/fplogo.png'),
              ),
              SizedBox(
                height: 50.h,
              ),
              Text(
                "@Management",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp),
              ),
              Spacer(),
              Text(
                'Powered By',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              SizedBox(
                height: 10.h,
              ),
              Image(
                image: AssetImage('images/ecellLogo.png'),
                height: 60,
              ),
              Padding(
                padding: EdgeInsets.only(top: 50.h, left: 30.w, right: 30.w),
                child: TextButton(
                  onPressed: () {
                    requestLogin();
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (_) => instructionsPage()));
                  },
                  child: Container(
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20.r)),
                    height: 60.h,
                    child: Center(
                      child: Text(
                        alert,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
