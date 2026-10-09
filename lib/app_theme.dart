import 'package:flutter/material.dart';

ThemeData smartChoiceTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff107566)),
  scaffoldBackgroundColor: const Color(0xfff4f7f9),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xff17453e),
    centerTitle: false,
    elevation: 0,
  ),
);
