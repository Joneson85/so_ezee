//Official
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//Custom
import 'package:so_ezee/models/user.dart';
import 'package:so_ezee/services/auth.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String _name = "";
  String _email = "";
  String _password = "";
  String _notification = "";
  bool _loading = false;
  bool _obscurePassword = true;
  final double _textFieldFontSize = 16.0;
  final _formKey = GlobalKey<FormState>();

  void _setLoading(bool _loadingFlag) {
    if (mounted) {
      setState(() {
        _loading = _loadingFlag;
      });
    }
  }

  void _registerUser() async {
    if (_formKey.currentState.validate() && !_loading) {
      _formKey.currentState.save();
      _setLoading(true);
      try {
        final AuthResult _authResult =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        if (_authResult != null) {
          UserUpdateInfo _userInfo = UserUpdateInfo();
          _userInfo.displayName = _name;
          FirebaseUser _currUser = await FirebaseAuth.instance.currentUser();
          await _currUser.updateProfile(_userInfo);
          await _authResult.user.reload();
          await _currUser.sendEmailVerification();
          User _user = User(
            userID: _authResult.user.uid,
            displayName: _name,
            email: _email,
          );
          await _user.createNewUser();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => RegisteredScreen(),
            ),
          );
        }
        _setLoading(false);
      } catch (e) {
        print(e);
        _notification = e.message ?? e.toString();
        _setLoading(false);
      }
    }
  }

  Widget _nameField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 25),
      child: TextFormField(
        textAlign: TextAlign.left,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(fontSize: _textFieldFontSize),
        decoration: InputDecoration(hintText: kLabel_Name),
        onSaved: (value) => _name = value,
        validator: NameValidator.validate,
      ),
    );
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
        onSaved: (value) => _email = value,
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
        onSaved: (input) => _password = input,
        validator: PasswordValidator.validate,
      ),
    );
  }

  Widget _logInPromptButton() {
    return Container(
      margin: EdgeInsets.only(top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Already registered? ",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            child: Text(
              "Log In",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            onTap: () =>
                Navigator.popAndPushNamed(context, kLoginScreen_route_id),
          ),
        ],
      ),
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

  Widget _logo() {
    return Container(
      child: Image.asset(mainLogoPath),
      height: 80.0,
      width: 80.0,
    );
  }

  Widget _title() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Account Registration',
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _nameField(),
          _emailField(),
          _passwordField(),
        ],
      ),
    );
  }

  Widget _registerButton() {
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
      child: ButtonTheme(
        minWidth: 200.0,
        height: 50.0,
        child: FlatButton(
          color: Theme.of(context).primaryColorDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            'Register',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: _registerUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    _logo(),
                    SizedBox(height: 10),
                    _title(),
                    _inputForm(),
                    _registerButton(),
                    _logInPromptButton(),
                  ],
                ),
              ),
            ),
            _loading ? modalLoadingIndicator() : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class RegisteredScreen extends StatelessWidget {
  void _loadLoginScreen(BuildContext context) {
    Navigator.pushNamed(
      context,
      kLoginScreen_route_id,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _style = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColorDark),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Account Registered!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Divider(thickness: 2),
            SizedBox(height: 25),
            Text(
              "An account verification email has been sent.",
              style: _style,
            ),
            SizedBox(height: 15),
            Text(
              "Please check your spam and other tagged folders too.",
              style: _style,
            ),
            SizedBox(height: 15),
            Text(
              "You will be able to log in after you verify your account.",
              style: _style,
            ),
            SizedBox(height: 50),
            RaisedButton(
              color: Theme.of(context).primaryColorDark,
              child: Text(
                "Log in",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _loadLoginScreen(context),
            ),
          ],
        ),
      ),
    );
  }
}
