import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset('images/imagelogo.png'),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 20),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Agne',
                color: Colors.blueAccent,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Rest API Demo Flutter',
                    speed: Duration(milliseconds: 100),
                  ),
                ],
                repeatForever: false,
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
