//Official
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
//3rd party plugins
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
//Custom
import 'package:so_ezee/models/request.dart';
import 'package:so_ezee/models/quote.dart';
import 'package:so_ezee/models/review.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import "package:so_ezee/screens/workflow/image_selector.dart";

class RequestScreen extends StatefulWidget {
  final String requestID;
  RequestScreen({
    @required String requestID,
  }) : this.requestID = requestID;
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  Request _request;
  SharedPreferences _prefs;
  bool _isVendor = false;
  bool _isLoading = false;
  String _currUserID = "";
  String _notification = "";
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    _isLoading = true;
    _prefs = await SharedPreferences.getInstance();
    try {
      _isVendor = _prefs.getBool(kPrefs_isVendor) ?? false;
      _currUserID = _prefs.getString(kPrefs_userID) ?? '';
      if (_currUserID.isEmpty) {
        throw (Exception("Your account ID cannot be found, "
            "please restart app and log in again"));
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print(e);
      _notification = e.message ?? e.toString();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : StreamBuilder<DocumentSnapshot>(
            //Creates listener on the document of current request
            stream: db
                .collection(kDB_requests)
                .document(widget.requestID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              } else {
                return ListView(
                  children: <Widget>[
                    _showNotification(), //Displays notices / errors
                    _populateDetails(snapshot.data),
                  ],
                );
              }
            },
          );
  }

  void _getRequestDetails(DocumentSnapshot requestData) {
    //Category
    RequestCategory _category = RequestCategory(
      requestData[kDB_category],
      requestData[kDB_category_name],
    );
    //Sub-category
    Map _subCat = requestData[kDB_subcat];
    RequestSubCategory _subCategory = RequestSubCategory(
      strID: _subCat[kDB_strid],
      name: _subCat[kDB_name],
      parentStrID: requestData[kDB_category],
    );
    //Main item
    Map _item = requestData[kDB_item_details];
    MainItem _mainItem = MainItem(
      _item[kDB_main_item],
      _item[kDB_main_item_name],
    );
    //Sub-item
    SubItem _subItem = SubItem(
      _item[kDB_sub_item],
      _item[kDB_sub_item_name],
    );
    //Location
    GeoPoint locationGeoPoint = requestData[kDB_location];
    RequestLocation _locationDetails = RequestLocation(
      formattedAddress: requestData[kDB_formatted_add],
      latitude: locationGeoPoint.latitude,
      longitude: locationGeoPoint.longitude,
    );
    RequestStatus _requestStatus = RequestStatus(
      requestData[kDB_status],
      requestData[kDB_status_name],
    );

    List<String> vendorsQuoted;
    if (requestData[kDB_vendors] == null)
      vendorsQuoted = [];
    else
      vendorsQuoted = List<String>.from(requestData[kDB_vendors]);

    List<String> _attachedImagesUrls;
    if (requestData[kDB_attached_image_urls] == null)
      _attachedImagesUrls = [];
    else
      _attachedImagesUrls =
          List<String>.from(requestData[kDB_attached_image_urls]);

    _request = Request(
        category: _category,
        subCategory: _subCategory,
        mainItem: _mainItem,
        subItem: _subItem,
        locationDetails: _locationDetails,
        apptTimestamp: requestData[kDB_appt_time].toDate(),
        reqStatus: _requestStatus,
        requestID: widget.requestID,
        numQuotes: requestData[kDB_numquotes].toInt(),
        userID: requestData[kDB_userid],
        userName: requestData[kDB_user_name],
        vendors: vendorsQuoted,
        reviewed: requestData[kDB_reviewed],
        bookedVendor: requestData[kDB_booked_vendor],
        attachedImageUrls: _attachedImagesUrls,
        description: requestData[kDB_description] ?? '');
  }

  Widget _populateDetails(DocumentSnapshot docSnapshot) {
    _getRequestDetails(docSnapshot);
    return Card(
      margin: const EdgeInsets.all(5),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _populateMainDetails(),
          _populateButtons(),
        ],
      ),
    );
  }

  Widget _populateMainDetails() {
    /*
    Main details consist of:
    1. Category
    2. Request ID
    3. Appointment date
    4. Location
    5. Sub-category (Know as 'Work Required' to the consumer)
    */
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 25),
          Text(
            "Request details",
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(thickness: 1.5),
          SizedBox(height: 10),
          //Request ID
          RequestDetailRow(
            iconData: Icons.info_outline,
            inputText: _request.requestID,
          ),
          //Appointment date and time
          RequestDetailRow(
            iconData: Icons.calendar_today,
            inputText: DateFormat(kDefaultDateFormat)
                .format(_request.apptTimestamp)
                .toString(),
          ),
          //Location details
          RequestDetailRow(
            iconData: Icons.location_on,
            inputText: _request.locationDetails.getFormattedAddress(),
            spacerHeight: 15,
          ),
          Divider(thickness: 1.5),
          SizedBox(height: 10),
          //Work required
          _request.subCategory.name.isNotEmpty
              ? RequestDetailRow(
                  label: kLabel_SubCat,
                  inputText: _request.subCategory.name,
                  spacerHeight: 5,
                )
              : SizedBox.shrink(),
          //Main item
          _request.mainItem.name.isNotEmpty
              ? RequestDetailRow(
                  label: kLabel_MainItem,
                  inputText: _request.mainItem.name,
                  spacerHeight: 5,
                )
              : SizedBox.shrink(),
          //Sub item
          _request.subItem.name.isNotEmpty
              ? RequestDetailRow(
                  label: kLabel_SubItem,
                  inputText: _request.subItem.name,
                  spacerHeight: 5,
                )
              : SizedBox.shrink(),
          //Number of quotes
          RequestDetailRow(
            label: kLabel_Quotes,
            inputText: _request.numQuotes.toString(),
            spacerHeight: 5,
          ),
          //Status
          RequestDetailRow(
            label: kLabel_Status,
            inputText: _request.reqStatus.name,
            spacerHeight: 5,
          ),
          //Display attached description if it exists
          _request.description.isNotEmpty
              ? _displayDescription()
              : SizedBox.shrink(),
          //Display attached images if they exist
          _request.attachedImageUrls.isNotEmpty
              ? _displayAttachedImages()
              : SizedBox.shrink(),
          SizedBox(height: 35),
        ],
      ),
    );
  }

  Widget _displayDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(thickness: 2),
        SizedBox(height: 10),
        Text(
          "Description:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "${_request.description}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _displayAttachedImages() {
    List<Widget> _imageWidgets = [];
    for (var imageUrl in _request.attachedImageUrls) {
      _imageWidgets.add(
        AttachedImageThumbnail(
          CachedNetworkImageProvider(imageUrl),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Divider(thickness: 2),
        SizedBox(height: 25),
        Text(
          "Attached images:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        ..._imageWidgets,
      ],
    );
  }

  Widget _populateButtons() {
    Widget _button = SizedBox.shrink();
    if (_isVendor) {
      bool _canQuote, _quoted;
      //Check if vendor has quoted this request before
      _quoted = _request.vendors.contains(_currUserID) ?? false;
      if (_request.numQuotes > 4 || _quoted)
        _canQuote = false;
      else
        _canQuote = true;
      _button = Container(
        margin: const EdgeInsets.all(8),
        child: RaisedButton(
          color: Theme.of(context).primaryColorDark,
          child: Text(
            'Quote',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          onPressed: _canQuote ? () => _quoteDialog(context) : null,
        ),
      );
    }
    //Populate button for user based on status of request
    else {
      //Allow user to review vendors after request is completed
      if (_request.reqStatus.strID == "completed") {
        _button = Container(
          margin: const EdgeInsets.all(8),
          child: RaisedButton(
            color: Theme.of(context).primaryColorDark,
            child: Text(
              "Review Vendor",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            onPressed: () => _reviewDialog(context),
          ),
        );
      }
      //Allow user to cancel requests that are pending / booked
      else if (_request.reqStatus.strID == "pending" ||
          _request.reqStatus.strID == "booked") {
        _button = Container(
          margin: const EdgeInsets.all(8),
          child: RaisedButton(
            color: Theme.of(context).primaryColorDark,
            child: Text(
              "Cancel request",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            onPressed: () => _showCancelConfirmation(context),
          ),
        );
      }
    }
    return _button;
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel request? You will not be able to undo this"),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () => _cancelRequest(),
            ),
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  _cancelRequest() async {
    bool cancelled = await _request.cancelRequest();
    if (!cancelled) {
      _notification = "An error occurred. Please try again.";
    } else
      Navigator.of(context).popAndPushNamed(kHomeScreen_route_id);
  }

  Widget _showNotification() {
    if (_notification.isNotEmpty) {
      return Container(
        color: Colors.amberAccent,
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.only(bottom: 50),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
                if (mounted) setState(() => _notification = "");
              },
            )
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future<void> _quoteDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Quote in SGD'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Enter a number"),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly,
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Submit'),
              onPressed: () {
                double quotePrice = 0;
                if (_textFieldController.value.text.isNotEmpty) {
                  quotePrice = double.parse(_textFieldController.value.text);
                }
                if (quotePrice == 0)
                  _quoteZeroDialog(context);
                else
                  _confirmQuoteDialog(context, quotePrice);
              },
            ),
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmQuoteDialog(
    BuildContext context,
    double quotePrice,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Quote?'),
          actions: <Widget>[
            FlatButton(
              child: Text('Submit'),
              onPressed: () async {
                _loadingDialog(context, 'Submitting quote...');
                String quoteID = await _submitQuote(quotePrice);
                if (quoteID != null) {
                  await _submitQuoteCompleteDialog(context, quoteID);
                }
              },
            ),
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //Prevents vendor from giving quotes that are zero / blank
  Future<void> _quoteZeroDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Quote cannot be left blank or zero'),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //Dialog to show loading indicator after the vendor submits quote
  Future<void> _loadingDialog(BuildContext context, String loadingText) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loadingText),
          content: SizedBox(
            height: 150,
            width: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Future<void> _submitQuoteCompleteDialog(
    BuildContext context,
    String quoteID,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Quote submitted. ID: ' + quoteID ?? ''),
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

  Future<String> _submitQuote(double price) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Quote quote = Quote(
        price: price,
        apptTimestamp: _request.apptTimestamp,
        requestID: _request.requestID,
        reqCatName: _request.category.name,
        reqSubCatName: _request.subCategory.name,
        statusStrID: kDB_open_strID,
        vendorID: prefs.getString(kPrefs_userID) ?? '',
        vendorName: prefs.getString(kPrefs_userDisplayName) ?? '',
        userID: _request.userID,
        userName: _request.userName,
      );
      String result = await quote.writeQuoteToDB();
      return result;
    } catch (e) {
      print(e);
      return 'Error during submission, please try again';
    }
  }

  Future<void> _reviewDialog(BuildContext context) async {
    DocumentReference vendorDoc =
        db.collection(kDB_users).document(_request.bookedVendor ?? '');
    DocumentSnapshot vendorData = await vendorDoc.get();
    String vendorName = vendorData[kDB_display_name];
    double ratingValue;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter review of ' + vendorName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RatingBar(
                allowHalfRating: true,
                itemSize: 28,
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                unratedColor: Colors.grey[600],
                onRatingUpdate: (rating) {
                  if (mounted)
                    setState(() {
                      ratingValue = rating;
                    });
                },
              ),
              Text(
                "(Tap on stars to select)",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 25),
              TextField(
                controller: _textFieldController,
                minLines: 5,
                maxLines: 20,
                maxLengthEnforced: true,
                maxLength: 500,
                decoration: InputDecoration(hintText: "Enter comment"),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Submit'),
              onPressed: () async {
                await _confirmReviewDialog(
                  context,
                  vendorData,
                  ratingValue,
                  _textFieldController.text,
                );
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

  Future<void> _confirmReviewDialog(
    BuildContext context,
    DocumentSnapshot vendorData,
    double rating,
    String comments,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Review?'),
          actions: <Widget>[
            FlatButton(
              child: Text('Submit'),
              onPressed: () async {
                _loadingDialog(context, 'Submitting review...');
                await _submitReview(
                  vendorData: vendorData,
                  rating: rating,
                  comments: comments,
                );
                await _submitReviewCompleteDialog(context);
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

  Future<void> _submitReviewCompleteDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Review submitted'),
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

  Future<void> _submitReview({
    DocumentSnapshot vendorData,
    double rating,
    String comments,
  }) async {
    try {
      Review review = Review(
        userID: _currUserID,
        vendorID: vendorData.documentID,
        ratingValue: rating,
        comments: comments,
      );
      await review.writeReviewToDB();
    } catch (e) {
      print(e);
    }
  }
}

class RequestDetailRow extends StatelessWidget {
  final String label;
  final String inputText;
  final IconData iconData;
  final double spacerHeight;
  RequestDetailRow({
    this.label,
    this.inputText,
    this.iconData,
    this.spacerHeight = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              iconData == null
                  ? SizedBox.shrink()
                  : Container(
                      margin: const EdgeInsets.only(right: 15),
                      child: Icon(iconData),
                    ),
              label == null
                  ? SizedBox.shrink()
                  : Text(
                      "$label: ",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
              inputText == null
                  ? SizedBox.shrink()
                  : Expanded(
                      child: Text(
                        "$inputText",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ],
          ),
          SizedBox(height: spacerHeight),
        ],
      ),
    );
  }
}
