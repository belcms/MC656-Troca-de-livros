import 'package:flutter/material.dart';
import "user_profile/user_profile_screen.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Books',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(
          // Page Titles (like 'Meus Livros')
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          // 'Disponibilidade'-level headers
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          // Book Card Titles
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          // Book Card Year
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400,
            color: Color(0xFF727272),
          ),
        ),
      ),
      home: const UserProfileScreen(),
    );
  }
}
