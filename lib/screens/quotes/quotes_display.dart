//Official
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//3rd party plug ins
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
//Custom
import 'package:so_ezee/models/quote.dart';
import 'package:so_ezee/models/user.dart';
import 'package:so_ezee/screens/chat/chat_screen.dart';
import 'package:so_ezee/screens/user/vendor_profile.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

//Widget that displays quote details
class QuotesList extends StatefulWidget {
  final String requestID;
  QuotesList(this.requestID);
  @override
  _QuotesListState createState() => _QuotesListState();
}

class _QuotesListState extends State<QuotesList> {
  List<Quote> _quotes = [];
  Stream<QuerySnapshot> _stream;
  @override
  void initState() {
    super.initState();
    _stream = db
        .collection(kDB_quotes)
        .where(kDB_requestid, isEqualTo: widget.requestID)
        .snapshots();
  }

  void _loadData(List<DocumentSnapshot> documents) {
    _quotes = [];
    for (DocumentSnapshot doc in documents) {
      print("adding quote");
      Quote _quote = Quote.fromDoc(doc);
      _quotes.add(_quote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.data.documents.isEmpty) {
          return _noQuotesFound();
        } else if (snapshot.data.documents.isNotEmpty) {
          _loadData(snapshot.data.documents);
          return SafeArea(
            child: ListView(
              children: _displayQuotes(),
            ),
          );
        } else {
          //Catch-all
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _noQuotesFound() {
    return ListTile(
      leading: Icon(
        Icons.priority_high,
        size: 24,
        color: primaryColor,
      ),
      title: Text(
        kLabel_NoQuotesFoundText,
        style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
      ),
    );
  }

  List<Widget> _displayQuotes() {
    try {
      List<Widget> _quoteLabels = [];
      for (var quote in _quotes) {
        //Display Quote details meant for consumers
        QuoteLabelUser quoteLabel = QuoteLabelUser(quote);
        _quoteLabels.add(quoteLabel);
      }
      return _quoteLabels;
    } catch (e) {
      print(e);
      return <Widget>[SizedBox.shrink()];
    }
  }
}

class QuoteLabelUser extends StatefulWidget {
  final Quote quote;

  QuoteLabelUser(this.quote);

  @override
  _QuoteLabelUserState createState() => _QuoteLabelUserState();
}

class _QuoteLabelUserState extends State<QuoteLabelUser> {
  Vendor _vendor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  void _loadVendor() async {
    _isLoading = true;
    try {
      DocumentSnapshot docSnapshot =
          await db.collection(kDB_users).document(widget.quote.vendorID).get();
      _vendor = Vendor.fromDoc(docSnapshot);
      if (mounted) setState(() => _isLoading = false);
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
          rating: _vendor.avgRating,
          itemSize: 18.0,
          unratedColor: unratedGrey,
          itemBuilder: (context, _) => ratedStar,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "(${_vendor.numReviews} reviews)",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _displayVendorAvatar() {
    return GestureDetector(
      //Displays vendor's full profile when user clicks on the avatar
      onTap: () {
        MaterialPageRoute route;
        route = MaterialPageRoute(
          builder: (BuildContext context) => VendorProfileScreen(_vendor),
        );
        Navigator.push(context, route);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _displayProfileImage(_vendor.profileImageUrl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _vendor.displayName ?? '...',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 24,
                    color: primaryColor,
                  ),
                ),
                _displayRatings(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _loadingIndicator() {
    return Container(
      height: 1,
      child: LinearProgressIndicator(),
    );
  }

  Widget _displayPrice() {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        text: "Price Quoted: ",
        style: TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        children: <TextSpan>[
          TextSpan(
            text: "${widget.quote.price}",
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayButtons(bool allowChat, bool allowBook) {
    return Row(
      children: <Widget>[
        //User can only chat with vendors on quotes that are open/booked
        allowChat
            ? Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 5, 7.5, 5),
                  child: FlatButton(
                    disabledColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 0.5),
                    ),
                    child: Text(
                      'Contact vendor',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    onPressed: () => _initiateChat(context),
                  ),
                ),
              )
            : SizedBox.shrink(),
        //User can only book quotes that are still open
        allowBook
            ? Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(7.5, 5, 10, 5),
                  child: FlatButton(
                    color: primaryColorDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 0.5),
                    ),
                    child: Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => _confirmDialog(context),
                  ),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //Users can only book quotes that are still in the open state
    //Users can only chat with vendors in quotes that are open or booked
    //Users cannot talk to vendors they rejected, or if the job is completed
    bool _canChat = true;
    bool _canBook = true;
    //Only open quotes can be booked
    if (widget.quote.statusStrID != kDB_open_strID) _canBook = false;
    /*User can chat with vendors who they booked, or if they have not
    booked any vendor*/
    if (widget.quote.statusStrID == kDB_booked ||
        widget.quote.statusStrID == kDB_open_strID)
      _canChat = true;
    else
      _canChat = false;
    return _isLoading
        ? _loadingIndicator()
        : Card(
            color: Colors.white,
            margin: EdgeInsets.all(5),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  //Vendor name
                  _displayVendorAvatar(),
                  Divider(thickness: 1.5),
                  //Price row
                  _displayPrice(),
                  _displayButtons(_canChat, _canBook),
                ],
              ),
            ),
          );
  }

  void _initiateChat(BuildContext context) {
    MaterialPageRoute route;
    route = MaterialPageRoute(
      builder: (BuildContext context) => ChatScreen(
        userID: widget.quote.userID,
        recipientID: widget.quote.vendorID,
      ),
    );
    Navigator.push(context, route);
  }

  Future<void> _confirmDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Book selected vendor?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () async {
                _bookingDialog(context);
                bool booked = await _bookQuote(
                      widget.quote.quoteID,
                      widget.quote.requestID,
                      widget.quote.vendorID,
                    ) ??
                    false;
                booked
                    ? await _bookSucceedDialog(context)
                    : await _bookErrorDialog(context);
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

  Future<void> _bookingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirming your booking, please wait...'),
          content: Container(
            height: 200,
            width: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Future<void> _bookSucceedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Booking completed'),
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

  Future<void> _bookErrorDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error encountered during booking, please try again'),
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

  Future<bool> _bookQuote(
    String quoteID,
    String requestID,
    String vendorID,
  ) async {
    try {
      DocumentReference quoteDoc = db.collection(kDB_quotes).document(quoteID);
      await quoteDoc.updateData({kDB_status: kDB_booked});
      DocumentReference reqDoc =
          db.collection(kDB_requests).document(requestID);
      await reqDoc.updateData({
        kDB_status: kDB_booked,
        kDB_status_name: kLabel_Booked,
      });
      await reqDoc.updateData({kDB_booked_vendor: vendorID});
      await reqDoc.get().then(
        (reqDocData) {
          if (reqDocData.exists) {
            //Updating the normalised request data in user's request inbox
            DocumentReference inboxDocRef = db
                .collection(kDB_users)
                .document(reqDocData[kDB_userid])
                .collection(kDB_request_inbox)
                .document(reqDocData.documentID);
            inboxDocRef.updateData({kDB_status: kDB_booked});
            if (reqDocData[kDB_vendors] != null) {
              List<String> otherVendors = List.from(reqDocData[kDB_vendors]);
              //Get all other vendors who have quoted this request
              otherVendors.remove(vendorID);
              //Set other quotes to "rejected"
              for (var vendor in otherVendors) {
                db
                    .collection(kDB_quotes)
                    .where(kDB_requestid, isEqualTo: requestID)
                    .where(kDB_vendorid, isEqualTo: vendor)
                    .getDocuments()
                    .then(
                  (resultsSnapshot) async {
                    for (var quote in resultsSnapshot.documents) {
                      await quote.reference.updateData(
                        {kDB_status: kDB_rejected},
                      );
                    }
                  },
                );
              }
            }
          }
        },
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
