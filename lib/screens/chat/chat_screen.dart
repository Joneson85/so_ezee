import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:so_ezee/models/user.dart';
import 'package:so_ezee/screens/user/vendor_profile.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/ui_constants.dart';

class ChatScreen extends StatefulWidget {
  final String userID;
  final String recipientID;
  ChatScreen({Key key, @required String userID, @required String recipientID})
      : assert(userID != null),
        assert(recipientID != null),
        this.userID = userID,
        this.recipientID = recipientID,
        super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _messageTextInput = "";
  String _chatSessionID = "";
  bool _isLoading = false;
  var _recipient;
  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _setLoading(bool isLoading) {
    if (mounted) setState(() => _isLoading = isLoading);
  }

  void _initChat() async {
    /*
    There should only be one unique chat session between 2 users, thus array position [0]
    is used to retrieve the chat session
    */
    _isLoading = true;
    try {
      DocumentSnapshot recipientData =
          await db.collection(kDB_users).document(widget.recipientID).get();
      //Load profile details of recipient
      _loadRecipientProfile(recipientData);
      QuerySnapshot query = await db
          .collection(kDB_users)
          .document(widget.userID)
          .collection(kDB_chat_inbox)
          .where(kDB_recipient_id, isEqualTo: widget.recipientID)
          .getDocuments();
      if (query.documents.isNotEmpty) {
        DocumentSnapshot chatSession = query.documents[0];
        _chatSessionID = chatSession.documentID;
      } else {
        //Chat session does not exist, create a new one
        DocumentReference chatSession =
            db.collection(kDB_chat_sessions).document();
        var chatSessionData = {
          kDB_members: [widget.userID, widget.recipientID],
        };
        await chatSession.setData(chatSessionData, merge: true);
        _chatSessionID = chatSession.documentID;
        //Saves chat session to the current user's chat inbox
        _saveSessionToChatInbox(
          ownerID: widget.userID,
          recipientID: widget.recipientID,
        );
        //Saves chat session to the recipient's chat inbox
        _saveSessionToChatInbox(
          ownerID: widget.recipientID,
          recipientID: widget.userID,
        );
      }
    } catch (e) {
      print(e);
    }
    _setLoading(false);
  }

  void _loadRecipientProfile(DocumentSnapshot recipientData) {
    if (recipientData.data[kDB_isvendor])
      _recipient = Vendor.fromDoc(recipientData);
    else
      _recipient = User.fromDoc(recipientData);
  }

  void _saveSessionToChatInbox({
    @required String ownerID,
    @required String recipientID,
  }) async {
    try {
      String recipientName;
      DocumentReference chatSession = db
          .collection(kDB_users)
          .document(ownerID)
          .collection(kDB_chat_inbox)
          .document(_chatSessionID);
      DocumentSnapshot recipientSnapshot =
          await db.collection(kDB_users).document(recipientID).get();
      if (recipientSnapshot.data != null) {
        if (recipientSnapshot.data.isNotEmpty) {
          recipientName = recipientSnapshot.data[kDB_display_name].toString();
        }
        var chatSessionData = {
          kDB_recipient_id: recipientID,
          kDB_recipient_name: recipientName
        };
        chatSession.setData(chatSessionData);
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _displayProfileImage(profileImageUrl) {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: CircleAvatar(
        radius: 25.0,
        backgroundColor: Colors.grey,
        backgroundImage: profileImageUrl.isEmpty
            ? AssetImage(kUserPlaceholderImage)
            : CachedNetworkImageProvider(profileImageUrl),
      ),
    );
  }

  Widget _displayRatings() {
    return Row(
      children: <Widget>[
        RatingBarIndicator(
          rating: _recipient.avgRating,
          itemSize: 18.0,
          unratedColor: unratedGrey,
          itemBuilder: (context, _) => ratedStar,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "(${_recipient.numReviews} reviews)",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  //Input bar at the bottom of screen for user to send messages
  Widget _userInputBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black45, width: 2.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: messageTextController,
                maxLines: 3,
                minLines: 1,
                onChanged: (value) {
                  _messageTextInput = value;
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          MaterialButton(
            minWidth: 24,
            child: Icon(Icons.send, color: primaryColor),
            onPressed: () {
              _sendMessage(
                _chatSessionID,
                _messageTextInput,
                widget.userID,
              );
              messageTextController.clear();
              _messageTextInput = '';
            },
          ),
        ],
      ),
    );
  }

  Widget _recipientAvatar() {
    return GestureDetector(
      onTap: () {
        MaterialPageRoute route;
        route = MaterialPageRoute(
          builder: (BuildContext context) => VendorProfileScreen(_recipient),
        );
        Navigator.push(context, route);
      },
      child: _isLoading
          ? SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _displayProfileImage(_recipient.profileImageUrl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _recipient.displayName ?? '...',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      _recipient.isVendor
                          ? _displayRatings()
                          : SizedBox.shrink(),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          elevation: 3.0,
          iconTheme: IconThemeData(color: primaryColor),
          backgroundColor: Colors.white,
          leading: null,
          title: _recipientAvatar(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    //Build list of messages
                    BuildMessages(
                      chatSessionID: _chatSessionID,
                      userID: widget.userID,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(child: _userInputBar()),
    );
  }

  void _sendMessage(
    String chatSessionID,
    String messageTextInput,
    String userID,
  ) async {
    try {
      if (messageTextInput.isNotEmpty) {
        db
            .collection(kDB_chat_sessions)
            .document(chatSessionID)
            .collection(kDB_messages)
            .add({
          kDB_msg: messageTextInput,
          kDB_sender_id: widget.userID,
          kDB_timestamp: FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print(e);
    }
  }
}

class BuildMessages extends StatefulWidget {
  final String _chatSessionID, _userID;

  BuildMessages({
    @required String chatSessionID,
    @required String userID,
  })  : assert(chatSessionID != null),
        assert(userID != null),
        _chatSessionID = chatSessionID,
        _userID = userID;

  @override
  _BuildMessagesState createState() => _BuildMessagesState();
}

class _BuildMessagesState extends State<BuildMessages> {
  final db = Firestore.instance;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder<QuerySnapshot>(
        stream: db
            .collection(kDB_chat_sessions)
            .document(widget._chatSessionID)
            .collection(kDB_messages)
            .orderBy(kDB_timestamp, descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            return _populateMessages(snapshot.data.documents);
          }
        },
      );
    } catch (e) {
      print(e);
      return SizedBox.shrink();
    }
  }

  Widget _populateMessages(List<DocumentSnapshot> messagesData) {
    List<Widget> messageBubbles = [];
    for (var message in messagesData) {
      messageBubbles.add(
        _messageBubble(
          message[kDB_msg],
          widget._userID == message.data[kDB_sender_id],
        ),
      );
    }
    ListView _messagesList = ListView.builder(
      controller: _scrollController,
      itemCount: messageBubbles.length,
      itemBuilder: (context, index) {
        return messageBubbles[index];
      },
    );
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
    return Expanded(child: _messagesList);
  }

  Widget _messageBubble(String msgText, bool isMe) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          //Formatting message borders according to whether msg was sent by the user
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(15.0) : Radius.circular(0),
              topRight: Radius.circular(15.0),
              bottomLeft: Radius.circular(15.0),
              bottomRight: isMe ? Radius.circular(0) : Radius.circular(15.0),
            ),
            elevation: 5.0,
            color: isMe ? primaryColorLight : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                msgText,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
