import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kealthy_delivery/Pages/Login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/OrderStatusChecker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  DatabaseReference databaseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://kealthy-90c55-dd236.firebaseio.com/",
  ).ref();

  late OrderStatusChecker orderStatusChecker;

  @override
  void initState() {
    super.initState();
    orderStatusChecker = OrderStatusChecker(databaseRef);

    Timer(const Duration(seconds: 2), () async {
      final hasUserData = await _checkUserData();
      if (hasUserData) {
        await orderStatusChecker.checkOrderStatus(context);
      } else {
        _navigateToLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/FIXED-removebg-preview.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ID');
    final userId = prefs.getString('userId');
    return id != null && userId != null;
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      CupertinoModalPopupRoute(
        builder: (context) => const LoginFields(),
      ),
    );
  }
}
