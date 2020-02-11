import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:so_ezee/models/chat.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/screens/chat/chat_screen.dart';
import 'package:so_ezee/util/labels.dart';

class ChatInbox extends StatefulWidget {
  ChatInbox(Key key) : super(key: key);
  @override
  _ChatInboxState createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  SharedPreferences _prefs;
  bool _prefsLoaded = false;
  String _userID = "";

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(() {
          _prefsLoaded = true;
          _userID = _prefs.getString(kPrefs_userID);
        });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          kLabel_Chats,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 28,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: _prefsLoaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ChatSessionsStream(_userID),
                ],
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ChatSessionsStream extends StatefulWidget {
  final String userID;
  ChatSessionsStream(this.userID) : assert(userID != null);

  @override
  _ChatSessionsStreamState createState() => _ChatSessionsStreamState();
}

class _ChatSessionsStreamState extends State<ChatSessionsStream> {
  //Load chat screen with recipient
  void _loadChatScreen(String recipientID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => ChatScreen(
          recipientID: recipientID,
          userID: widget.userID,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder(
        //Listener on the list of chat sessions of the user
        stream: db
            .collection(kDB_users)
            .document(widget.userID)
            .collection(kDB_chat_inbox)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            List<Widget> sessionList = [];
            for (DocumentSnapshot docSnapshot in snapshot.data.documents) {
              ChatSession _session = ChatSession.fromDoc(docSnapshot);
              sessionList.add(
                GestureDetector(
                  onTap: () => _loadChatScreen(_session.recipientID),
                  child: ChatSessionLabel(_session),
                ),
              );
            }
            return Expanded(
              child: ListView(
                children: sessionList,
              ),
            );
          }
        },
      );
    } catch (e) {
      print(e);
      return SizedBox.shrink();
    }
  }
}

class ChatSessionLabel extends StatefulWidget {
  final ChatSession chatSession;
  ChatSessionLabel(this.chatSession);
  @override
  _ChatSessionLabelState createState() => _ChatSessionLabelState();
}

class _ChatSessionLabelState extends State<ChatSessionLabel> {
  var _image;
  @override
  void initState() {
    super.initState();
    _image = AssetImage(kUserPlaceholderImage);
    _loadRecipientProfileImage();
  }

  _loadRecipientProfileImage() async {
    try {
      DocumentSnapshot recipientSnapshot = await db
          .collection(kDB_users)
          .document(widget.chatSession.recipientID)
          .get();
      if (recipientSnapshot[kDB_profileImageUrl] != null) {
        if (recipientSnapshot[kDB_profileImageUrl].isNotEmpty) {
          if (mounted)
            setState(() {
              _image = CachedNetworkImageProvider(
                recipientSnapshot[kDB_profileImageUrl],
              );
            });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(10),
          child: CircleAvatar(
            radius: 24.0,
            backgroundColor: Colors.grey,
            backgroundImage: _image,
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.only(top: 10),
            margin: EdgeInsets.fromLTRB(10, 10, 0, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black26),
              ),
            ),
            height: 75,
            child: Text(
              widget.chatSession.recipientName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
