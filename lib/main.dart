import 'package:flutter/material.dart';

void main() {
  //setupServices();
  runApp(const MyApp());
}

//basis https://github.com/hozhiyi/face-recognition-and-antispoofing-flutter-app

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //home: MyHomePage(),
    );
  }
}
