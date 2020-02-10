import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:so_ezee/services/auth.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  String _email;
  String _notification = "";
  bool _loading = false;
  final double _textFieldFontSize = 18;
  final _formKey = GlobalKey<FormState>();

  void _setLoading(bool _loadingFlag) {
    if (mounted) {
      setState(() {
        _loading = _loadingFlag;
      });
    }
  }

  Widget _emailField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      textAlign: TextAlign.left,
      style: TextStyle(fontSize: _textFieldFontSize),
      decoration: InputDecoration(hintText: kLabel_Email),
      onSaved: (value) => _email = value,
      validator: EmailValidator.validate,
    );
  }

  _sendResetEmail() async {
    try {
      if (_formKey.currentState.validate() && !_loading) {
        _formKey.currentState.save();
        _setLoading(true);
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
        _notification = "A password reset link has been sent to $_email";
        _setLoading(false);
      }
    } catch (e) {
      print(e);
      if (e.code == "ERROR_USER_NOT_FOUND") {
        _notification =
            "Account not found, please ensure you have entered a valid email.";
      } else {
        _notification = e.message ?? e.toString();
      }
      _setLoading(false);
    }
  }

  Widget _showNotification() {
    return _notification.isNotEmpty
        ? Container(
            color: Colors.amberAccent,
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.only(bottom: 50),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
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
          )
        : SizedBox.shrink();
  }

  Widget _backToLoginButton() {
    return FlatButton(
      child: Text(
        "Log In",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryColorDark,
        ),
      ),
      onPressed: () => Navigator.popAndPushNamed(
        context,
        kLoginScreen_route_id,
      ),
    );
  }

  Widget _sendButton() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: FlatButton(
        color: primaryColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          kLabel_Send,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        onPressed: _sendResetEmail,
      ),
    );
  }

  Widget _logoAndTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Image.asset(mainLogoPath),
          height: 80,
          width: 80,
        ),
        Expanded(
          child: Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _instructionText() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
      child: Text(
        "A link to reset your password will "
        "be sent to your registered email",
        style: TextStyle(fontSize: 18),
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
              alignment: Alignment.center,
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _showNotification(),
                    _logoAndTitle(),
                    _instructionText(),
                    Form(
                      key: _formKey,
                      child: _emailField(),
                    ),
                    _sendButton(),
                    _backToLoginButton(),
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
