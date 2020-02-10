import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:intl/intl.dart';
//Firebase and firestore
import 'package:cloud_firestore/cloud_firestore.dart';
//Custom packages
import 'package:so_ezee/ui_controllers/req_screen_controller.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorRequestInbox extends StatefulWidget {
  @override
  _VendorRequestInboxState createState() => _VendorRequestInboxState();
}

class _VendorRequestInboxState extends State<VendorRequestInbox> {
  SharedPreferences _prefs;
  bool _prefsLoaded = false;
  String _vendorID = '';
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _prefsLoaded = true;
        _vendorID = _prefs.getString(kPrefs_userID);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _prefsLoaded
        ? SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RequestsStream(vendorID: _vendorID),
              ],
            ),
          )
        : Center(child: CircularProgressIndicator());
  }
}

class RequestsStream extends StatefulWidget {
  final String vendorID;
  RequestsStream({
    @required this.vendorID,
  }) : assert(vendorID != null);
  @override
  _RequestsStreamState createState() => _RequestsStreamState();
}

class _RequestsStreamState extends State<RequestsStream> {
  var db = Firestore.instance;

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> streamSnapshot;
    //Load all pending requests
    streamSnapshot = db
        .collection(kDB_requests)
        .where(kDB_status, isEqualTo: kDB_pending_strID)
        .orderBy(kDB_appt_time, descending: true)
        //.limit(50)
        .snapshots();
    return StreamBuilder(
      //Builds a listener on the list of request snippets tied to the user
      stream: streamSnapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.data.documents.isEmpty) {
          return Container(
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
          );
        } else if (snapshot.data.documents.isNotEmpty) {
          List<Widget> _requestList = [];
          List<String> _vendors;
          bool _hasQuoted = false;
          for (DocumentSnapshot requestData in snapshot.data.documents) {
            _vendors = List.from(requestData[kDB_vendors] ?? ['']);
            if (_vendors.contains(widget.vendorID))
              _hasQuoted = true;
            else
              _hasQuoted = false;
            RequestLabel requestLabel = RequestLabel(
              timestamp: requestData[kDB_appt_time] ?? Timestamp.now(),
              numQuotes: requestData[kDB_numquotes] ?? 0,
              categoryName: requestData[kDB_category_name] ?? '',
              requestID: requestData.documentID ?? '',
              quoted: _hasQuoted ?? false,
            );
            _requestList.add(requestLabel);
          }
          return Expanded(child: ListView(children: _requestList));
        }
        //catch-all
        else {
          return SizedBox.shrink();
        }
      },
    );
  }
}

class RequestLabel extends StatelessWidget {
  final String categoryName, requestID;
  final Timestamp timestamp;
  final int numQuotes;
  final bool quoted;
  RequestLabel({
    @required this.categoryName,
    @required this.requestID,
    @required this.timestamp,
    @required this.numQuotes,
    @required this.quoted,
  })  : assert(categoryName != null),
        assert(requestID != null),
        assert(timestamp != null),
        assert(numQuotes != null),
        assert(quoted != null);

  @override
  Widget build(BuildContext context) {
    FontWeight _fontWeight = FontWeight.w600;
    return GestureDetector(
      onTap: () => _loadRequestDetails(context, requestID, categoryName),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //Show a label to indicate that vendor has quoted before
            quoted
                ? Container(
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.all(5),
                    child: Text(
                      'QUOTED',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: primaryColor),
                    ),
                  )
                : SizedBox.shrink(),
            Text(
              categoryName,
              style: TextStyle(fontSize: 22, fontWeight: _fontWeight),
            ),
            Divider(thickness: 1.5),
            //Request ID
            Row(
              children: <Widget>[
                Text(
                  "ID: $requestID",
                  style: TextStyle(fontSize: 18, fontWeight: _fontWeight),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Icon(Icons.format_quote, size: 18, color: primaryColor),
                Container(
                  margin: EdgeInsets.all(2),
                  child: Text(
                    '$kLabel_Quotes: $numQuotes',
                    style: TextStyle(fontSize: 16, fontWeight: _fontWeight),
                  ),
                ),
              ],
            ),
            //Appointment date time
            Row(
              children: <Widget>[
                Icon(Icons.insert_invitation, size: 20, color: primaryColor),
                Container(
                  margin: EdgeInsets.all(2),
                  child: Text(
                    DateFormat.yMMMd().format(timestamp.toDate()).toString(),
                    style: TextStyle(fontSize: 16, fontWeight: _fontWeight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadRequestDetails(
    BuildContext context,
    String reqID,
    String categoryName,
  ) {
    var _route = new MaterialPageRoute(
      builder: (BuildContext context) => new ReqScreenController(
        requestID: reqID,
        categoryName: categoryName,
      ),
    );
    Navigator.push(context, _route);
  }
}
