import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_ezee/util/constants.dart';

class ChatSession {
  final String sessionID;
  final String recipientID;
  final String recipientName;
  final String recipientProfileImageUrl;
  ChatSession({
    @required this.sessionID,
    @required this.recipientID,
    @required this.recipientName,
    @required this.recipientProfileImageUrl,
  });

  factory ChatSession.fromDoc(DocumentSnapshot doc) {
    return ChatSession(
      sessionID: doc.documentID,
      recipientID: doc[kDB_recipient_id],
      recipientName: doc[kDB_recipient_name] ?? '...',
      recipientProfileImageUrl: doc['recipient_profile_image_url'] ?? '',
    );
  }
}
