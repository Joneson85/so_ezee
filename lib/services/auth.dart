import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  signOut() {
    _auth.signOut();
  }

  sendPasswordResetEmail(String email) async {
    try {
      _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e);
    }
  }
}

class EmailValidator {
  static String validate(String input) {
    if (input.trim().length < 1)
      return "* Email cannot be left blank";
    else
      return null;
  }
}

class NameValidator {
  static String validate(String input) {
    if (input.trim().length < 1)
      return "* Name cannot be left blank";
    else if (input.length > 50)
      return "* Name cannot be more than 50 characters";
    else
      return null;
  }
}

class PasswordValidator {
  static String validate(String input) {
    if (input.trim().length < 8) {
      return "* Min. length of password is 8 characters";
    } else
      return null;
  }

  static String validatePasswordChaged(String input) {
    String msg;
    if (input.isNotEmpty) {
      if (input.trim().length < 8) {
        msg = "* Min. length of password is 8 characters";
      } else {
        msg = null;
      }
    } else {
      // Do nothing is user did not input a new password
      msg = null;
    }
    return msg;
  }
}

class BioValidator {
  static String validate(String input) {
    if (input.trim().length < 1) {
      return "Please enter a description";
    } else
      return null;
  }
}
