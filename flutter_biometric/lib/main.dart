import 'package:flutter/material.dart';
import 'package:flutter_biometric/ui/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Biometric Authentication',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const AuthScreen(),
    );
  }
}
