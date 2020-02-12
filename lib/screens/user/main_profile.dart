//Official
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:so_ezee/models/feedback_msg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
//External Plugins
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
//Custom
import 'package:so_ezee/models/user.dart';
import 'package:so_ezee/screens/user/vendor_profile.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/services/auth.dart';
import "package:so_ezee/services/storage.dart";

class ProfileScreen extends StatefulWidget {
  ProfileScreen(Key key) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isVendor = false;
  bool _loading = false;
  String _userID = '';
  SharedPreferences _prefs;
  var _userObj;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    _loading = true;
    _prefs = _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isVendor = _prefs.getBool(kPrefs_isVendor) ?? false;
        _userID = _prefs.getString(kPrefs_userID) ?? '';
        _loading = false;
      });
    }
  }

  void _showReviews() {
    MaterialPageRoute route;
    //New route to show list of reviews
    route = MaterialPageRoute(
      builder: (BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Theme.of(context).primaryColor,
          ),
          leading: null,
          title: Text(
            'Reviews',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: ReviewsList(_userObj.userID),
      ),
    );
    Navigator.push(context, route);
  }

  Widget _displayProfileImage() {
    return Padding(
      padding: EdgeInsets.fromLTRB(5, 15, 5, 5),
      child: CircleAvatar(
        radius: 50.0,
        backgroundColor: Colors.grey,
        backgroundImage: _userObj.profileImageUrl.isEmpty
            ? AssetImage(kUserPlaceholderImage)
            : CachedNetworkImageProvider(_userObj.profileImageUrl),
      ),
    );
  }

  Widget _displayName() {
    return Text(
      _userObj.displayName ?? '...',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _displayRatings() {
    FontWeight fWeight = FontWeight.w600;
    //Ratings and reviews
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Ratings & reviews',
                  style: TextStyle(fontSize: 20, fontWeight: fWeight),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      _userObj.avgRating.toString(),
                      style: TextStyle(fontSize: 30, fontWeight: fWeight),
                    ),
                    SizedBox(width: 15),
                    RatingBarIndicator(
                      rating: _userObj.avgRating,
                      itemCount: 5,
                      itemSize: 20.0,
                      unratedColor: unratedGrey,
                      itemBuilder: (context, _) => ratedStar,
                    ),
                  ],
                ),
                Text(
                  'out of 5',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
        ),
        //Load a scaffold via new route when tapped
        GestureDetector(
          onTap: () => _showReviews(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 20, 10, 35),
            child: Column(
              children: <Widget>[
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  _userObj.numReviews.toString() + ' rating(s)',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _displayEditProfile() {
    return ListTile(
      leading: Icon(
        Icons.edit,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        "Edit profile",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).primaryColor,
      ),
      onTap: () {
        MaterialPageRoute route;
        route = MaterialPageRoute(
          builder: (BuildContext context) => EditProfileScreen(_userObj),
        );
        Navigator.push(context, route);
      },
    );
  }

  Widget _displayEditBio() {
    return ListTile(
      leading: Icon(Icons.business, color: primaryColor),
      title: Text(
        'Edit Business Profile',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
      onTap: () {
        MaterialPageRoute route = MaterialPageRoute(
          builder: (BuildContext context) => EditVendorBioScreen(_userObj),
        );
        Navigator.push(context, route);
      },
    );
  }

  Widget _contactUsListTile() {
    return ListTile(
      leading: Icon(
        Icons.live_help,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        "Contact us",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).primaryColor,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ContactUsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : FutureBuilder(
            future: db.collection(kDB_users).document(_userID).get(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              _isVendor
                  ? _userObj = Vendor.fromDoc(snapshot.data)
                  : _userObj = User.fromDoc(snapshot.data);
              return Scaffold(
                appBar: AppBar(
                  leading: null,
                  automaticallyImplyLeading: false,
                  title: Text("Profile & Settings",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      )),
                  iconTheme: IconThemeData(color: primaryColor),
                ),
                body: SafeArea(
                  minimum: EdgeInsets.all(10),
                  child: ListView(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          SizedBox(height: 10),
                          _displayProfileImage(),
                          SizedBox(height: 25),
                          _displayName(),
                          SizedBox(height: 25),
                          _isVendor ? _displayRatings() : SizedBox.shrink(),
                          SizedBox(height: 25),
                        ],
                      ),
                      Divider(thickness: 1.5),
                      _displayEditProfile(),
                      const Divider(thickness: 1.5, indent: 25, endIndent: 25),
                      _isVendor ? _displayEditBio() : SizedBox.shrink(),
                      _isVendor
                          ? const Divider(
                              thickness: 1.5, indent: 25, endIndent: 25)
                          : SizedBox.shrink(),
                      _contactUsListTile(),
                      const Divider(thickness: 1.5, indent: 25, endIndent: 25),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class EditProfileScreen extends StatefulWidget {
  final User user;

  EditProfileScreen(this.user);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final double _iconSize = 30.0;
  final double _formTextSize = 18.0;
  File _profileImage;
  String _displayName = '';
  String _email = '';
  bool _isLoading = false;
  String _password = '';
  FirebaseUser _currUser;

  @override
  void initState() {
    super.initState();
    _loadCurrUser();
    _displayName = widget.user.displayName;
    _email = widget.user.email;
  }

  _loadCurrUser() async {
    _isLoading = true;
    _currUser = await FirebaseAuth.instance.currentUser();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _handleImageFromGallery() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      if (mounted) {
        setState(() {
          _profileImage = imageFile;
        });
      }
    }
  }

  _displayProfileImage() {
    if (_profileImage == null) {
      // No existing profile image
      if (widget.user.profileImageUrl.isEmpty) {
        return AssetImage(kUserPlaceholderImage);
      } else {
        return CachedNetworkImageProvider(widget.user.profileImageUrl);
      }
    } else {
      return FileImage(_profileImage);
    }
  }

  _submit() async {
    if (_formKey.currentState.validate() && !_isLoading) {
      _formKey.currentState.save();
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      String _profileImageUrl = "";
      if (_profileImage == null) {
        _profileImageUrl = widget.user.profileImageUrl;
      } else {
        _profileImageUrl = await StorageService.uploadUserProfileImage(
          _profileImage,
          widget.user.userID,
        );
      }
      User _user = User(
        userID: widget.user.userID,
        displayName: _displayName,
        profileImageUrl: _profileImageUrl ?? "",
        email: widget.user.email,
      );
      await _user.updateUserProfile();
      if (_password.isNotEmpty)
        try {
          await _currUser.updatePassword(_password);
        } catch (e) {
          print(e);
        }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      Navigator.pop(context);
    }
  }

  Widget _profileImageWidget() {
    return CircleAvatar(
      radius: 60.0,
      backgroundColor: Colors.grey,
      backgroundImage: _displayProfileImage(),
    );
  }

  Widget _changeProfileImageButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: FlatButton(
        child: Text(
          "Change Profile Image",
          style: TextStyle(
            color: primaryColor,
            fontSize: _formTextSize,
            decoration: TextDecoration.underline,
          ),
        ),
        onPressed: _isLoading ? null : _handleImageFromGallery,
      ),
    );
  }

  Widget _displayNameFormField() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        enabled: !_isLoading,
        initialValue: _displayName,
        style: TextStyle(fontSize: _formTextSize),
        decoration: InputDecoration(
          icon: Icon(Icons.person, size: _iconSize),
          labelText: kLabel_Name,
        ),
        validator: NameValidator.validate,
        onSaved: (input) => _displayName = input,
      ),
    );
  }

  Widget _emailFormField() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: _email,
        style: TextStyle(fontSize: _formTextSize),
        decoration: InputDecoration(
          icon: Icon(Icons.email, size: _iconSize),
          labelText: kLabel_Email,
        ),
        validator: EmailValidator.validate,
        onSaved: (input) => _email = input,
      ),
    );
  }

  Widget _passwordFormField() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: _password,
        obscureText: true,
        style: TextStyle(fontSize: _formTextSize),
        decoration: InputDecoration(
          icon: Icon(Icons.lock, size: _iconSize),
          labelText: kLabel_Password,
        ),
        validator: PasswordValidator.validatePasswordChaged,
        onSaved: (input) => _password = input,
      ),
    );
  }

  Widget _saveProfileButton() {
    return Container(
      margin: EdgeInsets.all(40.0),
      height: 40.0,
      width: 250.0,
      child: FlatButton(
        onPressed: _isLoading ? null : _submit,
        color: primaryColorDark,
        textColor: Colors.white,
        child: Text(
          'Save Profile',
          style: TextStyle(fontSize: _formTextSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryColor),
        elevation: 3,
        title: Text('Edit profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
            )),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              _isLoading
                  ? LinearProgressIndicator(
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    )
                  : SizedBox.shrink(),
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      _profileImageWidget(),
                      _changeProfileImageButton(),
                      _displayNameFormField(),
                      _emailFormField(),
                      _passwordFormField(),
                      _saveProfileButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactUsScreen extends StatefulWidget {
  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  String _subject = '';
  String _textMsg = '';
  bool _isLoading = false;
  FirebaseUser _currUser;
  final _contactUsFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCurrUser();
  }

  _loadCurrUser() async {
    try {
      _isLoading = true;
      _currUser = await FirebaseAuth.instance.currentUser();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      _isLoading = false;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact us',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Form(
                key: _contactUsFormKey,
                child: Column(
                  children: <Widget>[
                    _isLoading
                        ? LinearProgressIndicator(
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(primaryColor),
                          )
                        : SizedBox.shrink(),
                    TextFormField(
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Subject',
                      ),
                      onSaved: (value) => _subject = value,
                      validator: (input) {
                        if (input.isEmpty)
                          return 'Please enter a subject';
                        else
                          return null;
                      },
                    ),
                    TextFormField(
                      maxLength: 1000,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText:
                            "Leave us a message, and we'll get back to you",
                      ),
                      onSaved: (value) => _textMsg = value,
                      validator: (input) {
                        if (input.isEmpty)
                          return 'Message cannot be left empty';
                        else
                          return null;
                      },
                    ),
                    SizedBox(height: 20),
                    RaisedButton(
                      color: Theme.of(context).primaryColorDark,
                      child: Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => _isLoading ? null : _sendMsg(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sentFailedDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error occured, please try again'),
          actions: <Widget>[
            RaisedButton(
              child: Text('Ok'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sentSuccessDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text('Message sent, we will get back to you as soon as possible'),
          actions: <Widget>[
            RaisedButton(
                child: Text('Ok'),
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  Future<void> _sendMsg() async {
    if (_contactUsFormKey.currentState.validate() && !_isLoading) {
      bool _sent = false;
      _contactUsFormKey.currentState.save();
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      FeedbackMsg _feedbackMsg = FeedbackMsg(
        userID: _currUser.uid,
        subject: _subject,
        textMsg: _textMsg,
      );
      _sent = await _feedbackMsg.send();
      if (_sent)
        _sentSuccessDialog();
      else
        _sentFailedDialog();
    }
  }
}
