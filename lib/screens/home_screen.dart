import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/util/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(Key key)
      : assert(key != null),
        super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {},
      onLaunch: (Map<String, dynamic> message) async {},
      onResume: (Map<String, dynamic> message) async {},
    );
    if (Platform.isIOS) {
      _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true),
      );
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {});
    }
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      if (token != null) _saveToken(token);
    });
  }

  //Saves the push token to user's profile in Firestore
  _saveToken(String fcmToken) async {
    var prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString(kPrefs_userID) ?? '';
    if (userID.isNotEmpty) {
      DocumentReference userRef = db.collection(kDB_users).document(userID);
      DocumentSnapshot userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        if (userSnapshot['push_token'] != fcmToken) {
          //Set merge: true to prevent modifying existing data
          userRef.setData({'push_token': fcmToken}, merge: true);
        }
      }
    }
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
