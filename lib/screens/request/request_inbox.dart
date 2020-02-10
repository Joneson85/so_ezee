//Flutter
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:so_ezee/models/request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
//Backend
import 'package:cloud_firestore/cloud_firestore.dart';
//Custom packages
import 'package:so_ezee/ui_controllers/req_screen_controller.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class RequestInbox extends StatefulWidget {
  final String statusStrID;
  RequestInbox(this.statusStrID);

  @override
  _RequestInboxState createState() => _RequestInboxState();
}

class _RequestInboxState extends State<RequestInbox> {
  SharedPreferences _prefs;
  bool _prefsLoaded = false;
  String _userID = '';
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
    return SafeArea(
      child: _prefsLoaded
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RequestsStream(
                  statusStrID: widget.statusStrID,
                  userID: _userID,
                ),
              ],
            )
          : Container(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class RequestsStream extends StatefulWidget {
  final String statusStrID;
  final String userID;
  RequestsStream({
    @required this.statusStrID,
    @required this.userID,
  })  : assert(statusStrID != null),
        assert(userID != null);
  @override
  _RequestsStreamState createState() => _RequestsStreamState();
}

class _RequestsStreamState extends State<RequestsStream> {
  static const TextStyle _normalStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  Widget _requestSnippetLabel(RequestSnippet reqSnippet) {
    return GestureDetector(
      onTap: () {
        _labelTapHandler(
          context,
          reqSnippet.requestID ?? '',
          reqSnippet.categoryName ?? '',
        );
      },
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                reqSnippet.categoryName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Divider(thickness: 1.5),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "ID: ${reqSnippet.requestID}",
                      style: _normalStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.format_quote,
                      size: 24,
                      color: primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$kLabel_Quotes: ${reqSnippet.numQuotes}',
                      style: _normalStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.insert_invitation),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd()
                          .format(reqSnippet.apptTimestamp.toDate())
                          .toString(),
                      style: _normalStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.location_on),
                  ),
                  Expanded(
                    child: Text(
                      reqSnippet.address,
                      style: _normalStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _labelTapHandler(
    BuildContext context,
    String reqID,
    String categoryName,
  ) {
    var _route = MaterialPageRoute(
      builder: (BuildContext context) => ReqScreenController(
        requestID: reqID,
        categoryName: categoryName,
      ),
    );
    Navigator.push(context, _route);
  }

  @override
  Widget build(BuildContext context) {
    //A composite index is required to be created on firestore
    //2 fields: Ascending status and Descending app_time
    Stream<QuerySnapshot> streamSnapshot = db
        .collection(kDB_users)
        .document(widget.userID)
        .collection(kDB_request_inbox)
        .where(kDB_status, isEqualTo: widget.statusStrID)
        .orderBy(kDB_appt_time, descending: true)
        .snapshots();
    return StreamBuilder(
      //Builds a listener on the list of request snippets tied to the user
      stream: streamSnapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.only(top: 50),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.data.documents.isEmpty) {
          return Expanded(
            child: Container(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                  Icons.priority_high,
                  size: 24,
                  color: primaryColor,
                ),
                title: Text(
                  kLabel_NoRequestsFoundText,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        } else if (snapshot.data.documents.isNotEmpty) {
          List<Widget> _requestSnippetLabels = [];
          RequestSnippet _requestSnippet;
          for (DocumentSnapshot docSnapshot in snapshot.data.documents) {
            _requestSnippet = RequestSnippet.fromDoc(docSnapshot);
            _requestSnippetLabels.add(_requestSnippetLabel(_requestSnippet));
          }
          return Expanded(child: ListView(children: _requestSnippetLabels));
        }
        //catch-all
        else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
