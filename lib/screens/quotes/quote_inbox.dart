//Official
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//Custom packages
import 'package:so_ezee/models/quote.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/screens/chat/chat_screen.dart';

//Quote Inbox for vendors
class QuoteInbox extends StatefulWidget {
  final String statusStrID;
  QuoteInbox({@required this.statusStrID});

  @override
  _QuoteInboxState createState() => _QuoteInboxState();
}

class _QuoteInboxState extends State<QuoteInbox> {
  String _userID;
  bool _isLoading = false;
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      _isLoading = true;
      _prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userID = _prefs.get(kPrefs_userID);
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? LinearProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                QuotesStream(
                  statusStrID: widget.statusStrID,
                  userID: _userID,
                ),
              ],
            ),
    );
  }
}

class QuotesStream extends StatefulWidget {
  final String statusStrID;
  final String userID;

  QuotesStream({
    @required this.statusStrID,
    @required this.userID,
  })  : assert(statusStrID != null),
        assert(userID != null);

  @override
  _QuotesStreamState createState() => _QuotesStreamState();
}

class _QuotesStreamState extends State<QuotesStream> {
  List<Widget> _widgets = [];

  void _loadData(AsyncSnapshot<dynamic> snapshot) {
    try {
      for (DocumentSnapshot docSnapshot in snapshot.data.documents) {
        _widgets.add(QuoteInboxLabel(Quote.fromDoc(docSnapshot)));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder(
        stream: Firestore.instance
            .collection(kDB_quotes)
            .where(kDB_vendorid, isEqualTo: widget.userID)
            .where(kDB_status, isEqualTo: widget.statusStrID)
            .orderBy(kDB_timestamp, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              margin: EdgeInsets.only(top: 50),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.data.documents.isEmpty) {
            return ListTile(
              leading: Icon(
                Icons.priority_high,
                size: 24,
                color: primaryColor,
              ),
              title: Text(
                kLabel_NoQuotesFoundText,
                style: TextStyle(fontSize: 24),
              ),
            );
          } else if (snapshot.data.documents.isNotEmpty) {
            _loadData(snapshot);
            return Expanded(child: ListView(children: _widgets));
          }
          //catch-all
          else
            return SizedBox.shrink();
        },
      );
    } catch (e) {
      print(e);
      return SizedBox.shrink();
    }
  }
}

class QuoteInboxLabel extends StatelessWidget {
  final Quote _quote;
  QuoteInboxLabel(Quote quote) : _quote = quote;
  @override
  Widget build(BuildContext context) {
    bool _canChat = false;
    bool _canComplete = false;
    //Vendors can only chat with users where quotes are booked or open
    if (_quote.statusStrID == "booked") {
      _canChat = true;
      _canComplete = true;
    }
    if (_quote.statusStrID == "open") {
      _canChat = true;
    }
    const _normalStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
    return Card(
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //Category of request
            Text(
              _quote.reqCatName ?? "Category not found!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Divider(thickness: 1.5),
            //Appointment time row
            SizedBox(height: 5),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Text(
                  _quote.quoteID ?? "",
                  style: _normalStyle,
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: <Widget>[
                Icon(Icons.insert_invitation),
                SizedBox(width: 10),
                Text(
                  DateFormat('dd-MMM-yyyy')
                      .format(_quote.apptTimestamp)
                      .toString(),
                  style: _normalStyle,
                ),
              ],
            ),
            SizedBox(height: 5),
            //Name of user who created request
            Row(
              children: <Widget>[
                Icon(Icons.person),
                SizedBox(width: 10),
                Text(
                  _quote.userName.isEmpty
                      ? 'Requestor name not found!'
                      : 'Requestor: ${_quote.userName}',
                  style: _normalStyle,
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: <Widget>[
                Icon(Icons.monetization_on),
                SizedBox(width: 10),
                Text(
                  'You Quoted: ${_quote.price} SGD',
                  style: _normalStyle,
                ),
              ],
            ),
            SizedBox(height: 5),
            _canChat
                ? Row(
                    children: <Widget>[
                      //Vendor can only chat with users on quotes that are open/booked
                      Expanded(
                        child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          child: Text(
                            'Contact user',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => _initiateChat(context),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            _canComplete
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          child: Text(
                            'Mark as complete',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () =>
                              _showMarkCompleteConfirmationDialog(context),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Future<void> _showMarkCompleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Mark as completed? You will not be able to undo this.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () async {
                _showLoadingDialog(context);
                bool completed = await _quote.markAsComplete();
                completed
                    ? _showCompletedDialog(context)
                    : _showCompleteFailedDialog(context);
              },
            ),
            FlatButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Marking as complete, please wait...'),
          content: Container(
            height: 200,
            width: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Future<void> _showCompletedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Quote and request have been completed'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName(kHomeScreen_route_id),
                );
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _showCompleteFailedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('An error occured, please try again'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName(kHomeScreen_route_id),
                );
              },
            )
          ],
        );
      },
    );
  }

  void _initiateChat(BuildContext context) {
    MaterialPageRoute route;
    route = MaterialPageRoute(
      builder: (BuildContext context) => ChatScreen(
        userID: _quote.vendorID,
        recipientID: _quote.userID,
      ),
    );
    Navigator.push(context, route);
  }
}
