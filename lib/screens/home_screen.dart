import 'package:flutter/material.dart';
import 'package:so_ezee/util/ui_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(Key key)
      : assert(key != null),
        super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Center(
          child: Text(
            'Welcome to So-Ezee!!!',
            style: TextStyle(
              fontSize: 32.0,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
