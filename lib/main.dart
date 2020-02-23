<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> parent of f9bfac2... Push notification enabled
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

<<<<<<< HEAD
class SoEzee extends StatefulWidget {
  @override
  _SoEzeeState createState() => _SoEzeeState();
}

class _SoEzeeState extends State<SoEzee> {
=======
class SoEzee extends StatelessWidget {
>>>>>>> parent of f9bfac2... Push notification enabled
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: soEzeeTheme,
      //If user is already logged in, show the homescreen instead of starting screen
      //This prevents the user from having to log in again if the app is killed and
      //reloaded
      home: StreamBuilder(
        stream: FirebaseAuth.instance.onAuthStateChanged,
        builder: (context, firebaseUser) {
          if (firebaseUser != null)
            return MainNavController();
          else
            return StartScreen();
        },
      ),
      routes: {
        kStartScreen_route_id: (context) => StartScreen(),
        kLoginScreen_route_id: (context) => LoginScreen(),
        kRegScreen_route_id: (context) => RegistrationScreen(),
        kHomeScreen_route_id: (context) => MainNavController(),
      },
    );
  }
}
