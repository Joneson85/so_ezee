import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//Logo path of size 80 by 80
const String mainLogoPath = "images/soezee_logo.png";
//Borders
const BorderRadius _roundedBorder = BorderRadius.all(Radius.circular(4.0));
//Colors
const Color primaryColor = Color(0xffff6348);
const Color primaryColorDark = Color(0xffc52e1e);
const Color primaryColorLight = Color(0xffff9575);
const Color unratedGrey = Color(0xFF9E9E9E);
//Others
const Icon ratedStar = Icon(Icons.star, color: Colors.amber);
//Color swatch for date picker
const MaterialColor primarySwatch = const MaterialColor(
  0xffff6348,
  const <int, Color>{
    50: const Color(0xffff6348),
    100: const Color(0xffff6348),
    200: const Color(0xffff6348),
    300: const Color(0xffff6348),
    400: const Color(0xffff6348),
    500: const Color(0xffff6348),
    600: const Color(0xffff6348),
    700: const Color(0xffff6348),
    800: const Color(0xffff6348),
    900: const Color(0xffff6348),
  },
);

//Theme of App
ThemeData soEzeeTheme = ThemeData(
  accentColor: primaryColor,
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(color: primaryColor),
    actionsIconTheme: IconThemeData(color: primaryColor),
    color: Colors.white,
    textTheme: TextTheme(
      title: TextStyle(color: Colors.black),
    ),
  ),
  backgroundColor: Colors.white,
  buttonColor: Colors.white,
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  ),
  cupertinoOverrideTheme: CupertinoThemeData(primaryColor: primaryColor),
  cursorColor: primaryColor,
  iconTheme: IconThemeData(color: primaryColor, size: 24),
  inputDecorationTheme: InputDecorationTheme(
    border: UnderlineInputBorder(borderRadius: _roundedBorder),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 1.0),
      borderRadius: _roundedBorder,
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2.0),
      borderRadius: _roundedBorder,
    ),
    errorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryColorDark, width: 2.0),
      borderRadius: _roundedBorder,
    ),
    errorStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: primaryColorDark,
    ),
  ),
  primaryColor: primaryColor,
  primaryColorLight: primaryColorLight,
  primaryColorDark: primaryColorDark,
  primarySwatch: primarySwatch,
  textSelectionColor: primaryColorLight,
  textSelectionHandleColor: primaryColor,
  textTheme: TextTheme(
    body1: TextStyle(color: Colors.black),
    body2: TextStyle(color: Colors.black),
    button: TextStyle(color: Colors.black),
    display1: TextStyle(color: Colors.black),
    display2: TextStyle(color: Colors.black),
    display3: TextStyle(color: Colors.black),
    display4: TextStyle(color: Colors.black),
    headline: TextStyle(color: Colors.black),
    subhead: TextStyle(color: Colors.black),
    caption: TextStyle(color: Colors.black),
    subtitle: TextStyle(color: Colors.black),
  ),
);

Widget modalLoadingIndicator() {
  return Stack(
    children: [
      Opacity(
        opacity: 0.4,
        child: ModalBarrier(
          dismissible: false,
          color: Colors.white,
        ),
      ),
      Center(child: CircularProgressIndicator()),
    ],
  );
}
