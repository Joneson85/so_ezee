//Official
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:so_ezee/services/auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//External Plugins
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
//Custom
import 'package:so_ezee/models/user.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class VendorProfileScreen extends StatefulWidget {
  final Vendor vendor;
  VendorProfileScreen(this.vendor);
  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  bool _loading = false;

  Widget _displayProfileImage() {
    return Padding(
      padding: EdgeInsets.only(top: 25, bottom: 15),
      child: CircleAvatar(
        radius: 60.0,
        backgroundColor: Colors.grey,
        backgroundImage: widget.vendor.profileImageUrl.isEmpty
            ? AssetImage(kUserPlaceholderImage)
            : CachedNetworkImageProvider(widget.vendor.profileImageUrl),
      ),
    );
  }

  Widget _displayName() {
    return Padding(
      padding: EdgeInsets.only(top: 25, bottom: 25),
      child: Text(
        widget.vendor.displayName ?? '...',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _displayRatings() {
    FontWeight fWeight = FontWeight.w600;
    //Ratings and reviews
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ratings & reviews',
                style: TextStyle(fontSize: 20, fontWeight: fWeight),
              ),
              Row(
                children: <Widget>[
                  Text(
                    widget.vendor.avgRating.toString(),
                    style: TextStyle(fontSize: 40, fontWeight: fWeight),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15),
                    child: Text(
                      'out of 5',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: fWeight,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              RatingBarIndicator(
                rating: widget.vendor.avgRating,
                itemCount: 5,
                itemSize: 20.0,
                unratedColor: unratedGrey,
                itemBuilder: (context, _) => ratedStar,
              ),
            ],
          ),
          //Load a scaffold via new route when tapped
          GestureDetector(
            onTap: () {
              MaterialPageRoute route;
              //New route to show list of reviews
              route = MaterialPageRoute(
                builder: (BuildContext context) => Scaffold(
                  appBar: AppBar(
                    leading: null,
                    title: Text(
                      'Reviews & Ratings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  body: ReviewsList(widget.vendor.userID),
                ),
              );
              Navigator.push(context, route);
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(30, 20, 10, 35),
              child: Column(
                children: <Widget>[
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                      fontWeight: fWeight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    "${widget.vendor.numReviews} rating(s)",
                    style: TextStyle(fontSize: 12, fontWeight: fWeight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendor Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: Column(
                  children: <Widget>[
                    _displayProfileImage(),
                    _displayName(),
                    Divider(thickness: 1.5),
                    _displayRatings(),
                    const Divider(thickness: 1.5, indent: 25, endIndent: 25),
                    VendorBio(widget.vendor.userID),
                  ],
                ),
              ),
            ),
    );
  }
}

class ReviewsList extends StatefulWidget {
  final String vendorID;
  ReviewsList(this.vendorID) : assert(vendorID != null);
  @override
  _ReviewsListState createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      //Builds a listener on the list of request snippets tied to the user
      stream: Firestore.instance
          .collection(kDB_reviews)
          .where(kDB_vendorid, isEqualTo: widget.vendorID)
          .orderBy(kDB_timestamp, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.data.documents.isEmpty) {
            return ListTile(
              leading: Icon(
                Icons.priority_high,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                'No reviews available yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          } else {
            List<Widget> reviewsList = [];
            for (DocumentSnapshot review in snapshot.data.documents) {
              ReviewLabel reviewLabel = ReviewLabel(
                ratingValue: review.data['value'] ?? 0,
                timestamp: review.data[kDB_timestamp] ?? Timestamp.now(),
                comment: review.data['comment'],
              );
              reviewsList.add(reviewLabel);
              reviewsList.add(SizedBox(height: 10)); //Divider between reviews
            }
            return ListView(
                padding: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20.0,
                ),
                children: reviewsList);
          }
        }
      },
    );
  }
}

class ReviewLabel extends StatelessWidget {
  final double ratingValue;
  final String comment;
  final Timestamp timestamp;
  final Radius _circularEdge = Radius.circular(10.0);
  ReviewLabel({
    @required this.ratingValue,
    @required this.timestamp,
    @required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.all(_circularEdge),
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RatingBarIndicator(
                  rating: ratingValue,
                  itemCount: 5,
                  itemSize: 20.0,
                  unratedColor: Colors.white,
                  itemBuilder: (context, _) => ratedStar,
                ),
                Text(
                  DateFormat.yMMMd().format(timestamp.toDate()).toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(comment),
          ],
        ),
      ),
    );
  }
}

class VendorBio extends StatefulWidget {
  final String vendorID;
  VendorBio(this.vendorID) : assert(vendorID != null);
  @override
  _VendorBioState createState() => _VendorBioState();
}

class _VendorBioState extends State<VendorBio> {
  bool _isLoading = false;
  DocumentSnapshot _details;
  String _bio = '';
  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  void _loadBio() async {
    _isLoading = true;
    DocumentReference detailsDoc = Firestore.instance
        .collection(kDB_users)
        .document(widget.vendorID)
        .collection(kDB_profile)
        .document(kDB_details);
    _details = await detailsDoc.get();
    if (_details.exists) _bio = _details[kDB_bio] ?? "";
    if (_bio.isEmpty) _bio = "* The vendor has yet to write about themselves";
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _displayBio() {
    return Padding(
      padding: EdgeInsets.only(top: 15),
      child: Text(
        _bio,
        style: TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 35),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    kLabel_About,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _displayBio(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditVendorBioScreen extends StatefulWidget {
  final Vendor vendor;
  EditVendorBioScreen(this.vendor);
  @override
  _EditVendorBioScreenState createState() => _EditVendorBioScreenState();
}

class _EditVendorBioScreenState extends State<EditVendorBioScreen> {
  final _formKey = GlobalKey<FormState>();
  final double _formTextSize = 18.0;
  final double _iconSize = 30.0;
  bool _isLoading = false;
  String _bio = '';
  TextEditingController _bioController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _loadBio() async {
    _isLoading = true;
    DocumentSnapshot detailsDoc = await Firestore.instance
        .collection(kDB_users)
        .document(widget.vendor.userID)
        .collection(kDB_profile)
        .document(kDB_details)
        .get();
    if (detailsDoc.exists) _bio = detailsDoc.data[kDB_bio] ?? '';
    _bioController.text = _bio;
    _setLoading(false);
  }

  _submit() async {
    if (_formKey.currentState.validate() && !_isLoading) {
      _formKey.currentState.save();
      _setLoading(true);
      Vendor _vendor = widget.vendor;
      if (_bio.isNotEmpty) {
        _vendor.bio = _bio;
        await _vendor.updateBio();
      }
      _setLoading(false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: primaryColor),
          elevation: 3.0,
          title: Text(
            'Edit business profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          )),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            children: <Widget>[
              _isLoading
                  ? LinearProgressIndicator(
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    )
                  : SizedBox.shrink(),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 20, 25, 0),
                      child: Text(
                        'Give a short description of yourself or your business.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 20, 45, 0),
                      child: TextFormField(
                        controller: _bioController,
                        style: TextStyle(fontSize: _formTextSize),
                        maxLength: 500,
                        maxLines: null,
                        decoration: InputDecoration(
                          icon: Icon(
                            Icons.person,
                            size: _iconSize,
                          ),
                          labelText: 'Description',
                          border: Theme.of(context).inputDecorationTheme.border,
                          enabledBorder: Theme.of(context)
                              .inputDecorationTheme
                              .enabledBorder,
                          focusedBorder: Theme.of(context)
                              .inputDecorationTheme
                              .focusedBorder,
                        ),
                        validator: BioValidator.validate,
                        onSaved: (input) => _bio = input,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(40.0),
                      height: 40.0,
                      width: 250.0,
                      child: FlatButton(
                        onPressed: _isLoading ? null : _submit,
                        color: primaryColorDark,
                        textColor: Colors.white,
                        child: Text(
                          'Save',
                          style: TextStyle(fontSize: _formTextSize),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
