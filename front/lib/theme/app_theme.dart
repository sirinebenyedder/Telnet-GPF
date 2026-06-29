import 'package:flutter/material.dart';
import 'package:Telnet/theme/button_theme.dart';
import 'package:Telnet/theme/input_decoration_theme.dart';

import '../constants.dart';
import 'checkbox_themedata.dart';
import 'theme_data.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: "Plus Jakarta",
      primarySwatch: primaryMaterialColor,
      primaryColor: const Color.fromRGBO(123, 97, 255, 1),
      scaffoldBackgroundColor: const Color.fromARGB(255, 250, 248, 248),
      iconTheme: const IconThemeData(color: blackColor),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: blackColor40)),
      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      outlinedButtonTheme: outlinedButtonTheme(),
      inputDecorationTheme: lightInputDecorationTheme,
      checkboxTheme: checkboxThemeData.copyWith(
        side: const BorderSide(color: blackColor40),
      ),
      appBarTheme: appBarLightTheme,
      scrollbarTheme: scrollbarThemeData,
      dataTableTheme: dataTableLightThemeData,
    );
  }
}
