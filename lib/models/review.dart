import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_ezee/util/constants.dart';

class Review {
  final String userID, vendorID, comments;
  final double ratingValue;
  Review({
    @required this.userID,
    @required this.vendorID,
    @required this.comments,
    @required this.ratingValue,
  });

  Future<bool> writeReviewToDB() async {
    bool submitted = false;
    //CollectionReference reviews = Firestore.instance.collection(kDB_reviews);
    DocumentReference review =
        Firestore.instance.collection(kDB_reviews).document();
    var reviewData = {
      'userid': this.userID,
      'vendorid': this.vendorID,
      'comment': this.comments,
      'value': this.ratingValue,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await review.setData(reviewData, merge: true);
    await updateVendorRatings();
    return submitted;
  }

  Future<void> updateVendorRatings() async {
    DocumentReference vendor =
        Firestore.instance.collection(kDB_users).document(this.vendorID);
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot postSnapshot = await tx.get(vendor);
      int numReviews = (postSnapshot.data['numreviews'] ?? 0).toInt() + 1;
      double totalVal = (postSnapshot.data['total_val'] ?? 0).toDouble() + this.ratingValue;
      double avgRating = totalVal / numReviews;
      var vendorData = {
        'numreviews': numReviews,
        'total_val': totalVal,
        'avg_rating': avgRating,
      };
      if (postSnapshot.exists) {
        await tx.update(vendor, vendorData);
      }
    });
  }
}
