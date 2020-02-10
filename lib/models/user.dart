import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:so_ezee/util/constants.dart';

class User {
  final String userID;
  final String displayName;
  final String email;
  final String profileImageUrl;
  final bool isVendor;
  User({
    @required this.userID,
    @required this.displayName,
    @required this.email,
    this.isVendor,
    this.profileImageUrl,
  });
  Future<void> updateUserProfile() async {
    print('userID to be updated : $userID');
    DocumentReference userDoc =
        Firestore.instance.collection(kDB_users).document(userID);
    var userData = {
      'display_name': displayName,
      'email': email,
      kDB_profileImageUrl: profileImageUrl ?? '',
    };
    await userDoc.updateData(userData);
  }

  Future<void> createNewUser() async {
    print('userID to be created : $userID');
    DocumentReference userDoc =
        Firestore.instance.collection(kDB_users).document(userID);
    var userData = {
      'display_name': displayName,
      'email': email,
      kDB_profileImageUrl: profileImageUrl ?? '',
    };
    await userDoc.setData(userData);
  }

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
      userID: doc.documentID,
      displayName: doc[kDB_display_name],
      email: doc[kDB_email],
      profileImageUrl: doc[kDB_profileImageUrl] ?? '',
      isVendor: doc[kDB_isvendor] ?? false,
    );
  }
}

class Vendor extends User {
  List<String> reviews = [];
  String bio = '';
  double avgRating;
  double totalVal;
  int numReviews;

  Vendor({
    @required String userID,
    @required String displayName,
    @required String email,
    @required String profileImageUrl,
    @required double avgRating,
    @required double totalVal,
    @required int numReviews,
    bool isVendor,
    String bio,
    List<String> reviews,
  })  : this.avgRating = avgRating,
        this.totalVal = totalVal,
        this.numReviews = numReviews,
        this.reviews = reviews,
        this.bio = bio ?? '',
        super(
          userID: userID,
          displayName: displayName,
          email: email,
          profileImageUrl: profileImageUrl,
          isVendor: isVendor,
        );

  updateBio() async {
    DocumentReference detailsRef = Firestore.instance
        .collection(kDB_users)
        .document(userID)
        .collection(kDB_profile)
        .document(kDB_details);
    await detailsRef.setData({kDB_bio: bio});
  }

  factory Vendor.fromDoc(DocumentSnapshot doc) {
    return Vendor(
      userID: doc.documentID,
      displayName: doc[kDB_display_name],
      email: doc[kDB_email],
      profileImageUrl: doc[kDB_profileImageUrl] ?? '',
      avgRating: doc[kDB_avg_rating] ?? 0,
      totalVal: doc[kDB_total_val] ?? 0,
      numReviews: doc[kDB_numreviews] ?? 0,
      bio: doc[kDB_bio] ?? '',
      reviews: doc[kDB_reviews] ?? [],
      isVendor: doc[kDB_isvendor] ?? false,
    );
  }
}
