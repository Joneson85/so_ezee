import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_ezee/util/constants.dart';

class FeedbackMsg {
  final String userID;
  final String subject;
  final String textMsg;
  FeedbackMsg({
    @required this.subject,
    @required this.userID,
    @required this.textMsg,
  });

  Future<bool> send() async {
    try {
      DocumentReference docRef = db.collection('feedback').document();
      await docRef.setData({
        'userID': userID,
        'subject': subject,
        'textMsg': textMsg,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
