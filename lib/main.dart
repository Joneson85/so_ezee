import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_ezee/screens/start_screen.dart';
import 'package:so_ezee/screens/user/login.dart';
import 'package:so_ezee/screens/user/registration.dart';
import 'package:so_ezee/ui_controllers/main_nav_controller.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/ui_constants.dart';

void main() {
  //App runs in portrait up orientation only
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(SoEzee());
  });
}

class SoEzee extends StatefulWidget {
  @override
  _SoEzeeState createState() => _SoEzeeState();
}

class _SoEzeeState extends State<SoEzee> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String _homeScreenText = "Waiting for token...";
  String _messageText = "Waiting for message...";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        setState(() {
          _messageText = "ON MESSAGE: $message";
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        setState(() {
          _messageText = "ON LAUNCH: $message";
        });
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        setState(() {
          _messageText = "ON RESUME: $message";
        });
        print("onResume: $message");
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then(
      (String token) {
        assert(token != null);
        setState(() {
          _homeScreenText = "Push Messaging token: $token";
        });
        print(_homeScreenText);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /*
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Push Messaging Demo'),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Center(
                child: Text(_homeScreenText),
              ),
              Row(children: <Widget>[
                Expanded(
                  child: Text(_messageText),
                ),
              ])
            ],
          ),
        ),
      ),
    );*/
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: soEzeeTheme,
      initialRoute: kStartScreen_route_id,
      routes: {
        kStartScreen_route_id: (context) => StartScreen(),
        kLoginScreen_route_id: (context) => LoginScreen(),
        kRegScreen_route_id: (context) => RegistrationScreen(),
        kHomeScreen_route_id: (context) => MainNavController(),
      },
    );
  }
}
