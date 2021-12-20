import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoundOneStatus extends StatefulWidget {
  const RoundOneStatus({Key? key}) : super(key: key);

  @override
  _RoundOneStatusState createState() => _RoundOneStatusState();
}

class _RoundOneStatusState extends State<RoundOneStatus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            children: [
              Text(
                "Round 1 Not Completed",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 20.sp),
              ),
              SizedBox(
                height: 20.h,
              ),
              Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: 20,
                    itemBuilder: (_, index) {
                      return TeamNameWidget(teamName: "Hello World");
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TeamNameWidget extends StatelessWidget {
  TeamNameWidget({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.sp),
      child: Container(
        height: 70.h,
        width: double.maxFinite,
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Center(
            child: Text(
              "Team Name",
              style: TextStyle(color: Colors.grey, fontSize: 18.sp),
            ),
          ),
        ),
      ),
    );
  }
}
