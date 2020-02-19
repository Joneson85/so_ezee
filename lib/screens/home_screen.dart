import 'package:firebase_messaging/firebase_messaging.dart';
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const _headerStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: <Widget>[
            SizedBox(height: 15),
            Center(
              child: Text(
                'Welcome to So Ezee!!!',
                style: TextStyle(
                  fontSize: 32.0,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 20),
            Divider(thickness: 1.5),
            SizedBox(height: 10),
            Text(
              'Hiring professional services is so easy!',
              style: _headerStyle,
            ),
            SizedBox(height: 10),
            Text(
              'At So Ezee, we aim to connect people who'
              ' have needs for professional services to professionals who can fulfill them.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 10),
            Divider(thickness: 1.5),
            SizedBox(height: 10),
            Text(
              'Create a request now!',
              style: _headerStyle,
            ),
            SizedBox(height: 10),
            Text(
              "Click on the 'Requests' tab and start creating a new request! It's that easy!",
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 10),
            Divider(thickness: 1.5),
            SizedBox(height: 10),
            Text(
              'Receive quotes',
              style: _headerStyle,
            ),
            SizedBox(height: 10),
            Text(
              'Our registered professionals will provide quotes based on the details of your request.'
              '\nYou can also speak to them via the in-app chat.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 10),
            Divider(thickness: 1.5),
            SizedBox(height: 10),
            Text(
              "Can't find the service you want?",
              style: _headerStyle,
            ),
            SizedBox(height: 10),
            Text(
              'Currently, our coverage is limited to Handyman and Electrician services, but we plan to expand'
              ' the range of services covered in the near future. \nStay tuned for updates!',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
