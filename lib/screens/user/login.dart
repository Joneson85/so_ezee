//Official
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
//Custom
import 'package:so_ezee/screens/user/reset_password.dart';
import 'package:so_ezee/services/auth.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class LoginScreen extends StatefulWidget {
  static const String route_id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';
  String _notification = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  FirebaseUser _currUser;
  final double _textFieldFontSize = 16.0;
  final _formKey = GlobalKey<FormState>();

  void _setLoading(bool _loadingFlag) {
    if (mounted) {
      setState(() {
        _isLoading = _loadingFlag;
      });
    }
  }

  void _loadHomePage(FirebaseUser user) async {
    try {
      _setLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (user != null) {
        DocumentSnapshot userDoc = await Firestore.instance
            .collection(kDB_users)
            .document(user.uid)
            .get();
        if (userDoc.exists) {
          await prefs.setString(kPrefs_userID, user.uid);
          await prefs.setBool(
            kPrefs_isVendor,
            userDoc.data[kDB_isvendor] ?? false,
          );

          await prefs.setString(
            kPrefs_userDisplayName,
            userDoc.data[kDB_display_name] ?? '',
          );
          _setLoading(false);
          Navigator.pushNamed(context, kHomeScreen_route_id);
        } else {
          throw Exception([
            'Account not found, please ensure you have entered a valid email.'
          ]);
        }
      }
    } catch (e) {
      print(e);
      _notification = e.message ?? e.toString();
      _setLoading(false);
    }
  }

  void _login() async {
    if (_formKey.currentState.validate() && !_isLoading) {
      _formKey.currentState.save();
      _setLoading(true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        _currUser = await FirebaseAuth.instance.currentUser();
        _currUser.reload();
        print('User verified? ---> ' + _currUser.isEmailVerified.toString());
        if (_currUser.isEmailVerified) {
          _loadHomePage(_currUser);
        } else {
          //TODO: Uncomment below codes to turn on verification check outside of dev environment
          /*_notification = 'Please verify your account before logging in';
          _setLoading(false);*/
          _loadHomePage(_currUser);
        }
      } catch (e) {
        print(e);
        if (e.code == "ERROR_USER_NOT_FOUND") {
          _notification = "Account not found. "
              "Please ensure you have entered a valid email.";
        } else {
          _notification = e.message ?? e.toString();
        }
        _setLoading(false);
      }
    }
  }

  void _loadPasswordResetScreen() {
    MaterialPageRoute _route = MaterialPageRoute(
      builder: (BuildContext context) => ResetPasswordScreen(),
    );
    Navigator.push(context, _route);
  }

  void _resendVerification() async {
    _setLoading(true);
    //User did not attempt to sign in
    if (_currUser == null) {
      if (_formKey.currentState.validate()) {
        _formKey.currentState.save();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        _currUser = await FirebaseAuth.instance.currentUser();
        if (_currUser.isEmailVerified) {
          _notification = kEmailVerified;
        } else {
          await _currUser.sendEmailVerification();
          _notification = kVerificationEmailSent;
        }
      }
    } else {
      if (_currUser.isEmailVerified) {
        _notification = kVerificationEmailSent;
      } else {
        await _currUser.sendEmailVerification();
        _notification = kVerificationEmailSent;
      }
    }
    _setLoading(false);
  }

  Widget _emailField() {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: TextFormField(
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.emailAddress,
        textAlign: TextAlign.left,
        style: TextStyle(fontSize: _textFieldFontSize),
        decoration: InputDecoration(hintText: kLabel_Email),
        onSaved: (value) {
          _email = value;
        },
        validator: EmailValidator.validate,
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: TextFormField(
        autocorrect: false,
        enableSuggestions: false,
        obscureText: _obscurePassword,
        textAlign: TextAlign.left,
        style: TextStyle(fontSize: _textFieldFontSize),
        decoration: InputDecoration(
          hintText: kLabel_Password,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: primaryColorDark,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        onSaved: (input) {
          _password = input;
        },
        //TODO: turn on password validator before releasing live
        //validator: PasswordValidator.validate,
      ),
    );
  }

  Widget _loginButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 50,
      child: RaisedButton(
        color: Theme.of(context).primaryColorDark,
        child: Text(
          'Log in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () async {
          _login();
        },
      ),
    );
  }

  Widget _resetPasswordButton() {
    return FlatButton(
      child: Text(
        'Forgot password?',
        style: TextStyle(
          color: primaryColorDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: _loadPasswordResetScreen,
    );
  }

  Widget _resendVerificationButton() {
    return FlatButton(
      child: Text(
        'Re-send verification email',
        style: TextStyle(
          color: primaryColorDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: _resendVerification,
    );
  }

  Widget _showNotification() {
    if (_notification.isNotEmpty) {
      return Container(
        color: Colors.amberAccent,
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 50),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.error_outline),
            ),
            Expanded(
              child: Text(
                _notification,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _notification = "";
                  });
                }
              },
            )
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _logoAndTitle() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Image.asset(mainLogoPath),
            height: 80.0,
            width: 80.0,
          ),
          Text(
            'So Ezee',
            style: TextStyle(
              fontSize: 45.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColorDark),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _showNotification(),
                    _logoAndTitle(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _emailField(),
                          _passwordField(),
                          _loginButton(),
                          _resetPasswordButton(),
                          _resendVerificationButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _isLoading ? modalLoadingIndicator() : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
