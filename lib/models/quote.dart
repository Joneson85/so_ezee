import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_ezee/util/constants.dart';

class Quote {
  final DateTime apptTimestamp;
  final double price;
  final String requestID;
  final String statusStrID;
  final String vendorID;
  final String vendorName;
  final String userID;
  final String userName;
  final String reqCatName;
  final String reqSubCatName;
  final String quoteID;
  Quote({
    @required this.apptTimestamp,
    @required this.price,
    @required this.requestID,
    @required this.statusStrID,
    @required this.vendorID,
    @required this.vendorName,
    @required this.userID,
    @required this.userName,
    @required this.reqCatName,
    @required this.reqSubCatName,
    this.quoteID,
  });

  Future<String> writeQuoteToDB() async {
    DocumentReference quoteDetails =
        Firestore.instance.collection(kDB_quotes).document();
    //Status is defaulted to open
    var quoteData = {
      kDB_appt_time: this.apptTimestamp,
      kDB_price: this.price ?? 0,
      kDB_requestid: this.requestID,
      kDB_status: kDB_open_strID,
      kDB_vendorid: this.vendorID,
      kDB_vendorname: this.vendorName,
      kDB_userid: this.userID,
      kDB_user_name: this.userName,
      kDB_req_cat_name: this.reqCatName,
      kDB_req_subcat_name: this.reqSubCatName,
      kDB_timestamp: FieldValue.serverTimestamp(),
    };
    await quoteDetails.setData(quoteData, merge: true);
    await updateRequestNumQuote(requestID);
    await updateRequestVendors(requestID, vendorID);
    return quoteDetails.documentID;
  }

  Future<void> updateRequestNumQuote(String requestID) async {
    //Increase count of quotes by one on the request document
    db.collection(kDB_requests).document(requestID).updateData({
      kDB_numquotes: FieldValue.increment(1),
    });
    //Increase count of quotes by one on request document in user's inbox
    db
        .collection(kDB_users)
        .document(userID)
        .collection(kDB_request_inbox)
        .document(requestID)
        .updateData({
      kDB_numquotes: FieldValue.increment(1),
    });
  }

  Future<void> updateRequestVendors(String requestID, String vendorID) async {
    await db.collection(kDB_requests).document(requestID).updateData({
      kDB_vendors: FieldValue.arrayUnion([vendorID]),
    });
  }

  Future<bool> markAsComplete() async {
    try {
      var batch = db.batch();
      //Marks the quote as completed. Action is driven by vendor.
      DocumentReference quoteRef = db.collection(kDB_quotes).document(quoteID);
      batch.updateData(quoteRef, ({kDB_status: kDB_completed}));
      //Also marks the request that the quote is attached to as "Completed"
      DocumentReference requestRef =
          db.collection(kDB_requests).document(requestID);
      batch.updateData(
        requestRef,
        ({
          kDB_status: kDB_completed,
          kDB_status_name: 'Completed',
        }),
      );
      //Updates request snippet data in user's request inbox
      DocumentReference inboxRequestRef = db
          .collection(kDB_users)
          .document(userID)
          .collection(kDB_request_inbox)
          .document(requestID);
      batch.updateData(inboxRequestRef, {kDB_status: kDB_completed});
      batch.commit();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  factory Quote.fromDoc(DocumentSnapshot doc) {
    return Quote(
      quoteID: doc.documentID,
      requestID: doc[kDB_requestid] ?? '',
      apptTimestamp: doc[kDB_appt_time].toDate() ?? Timestamp.now().toDate(),
      statusStrID: doc[kDB_status] ?? '',
      price: doc[kDB_price].toDouble() ?? '0',
      vendorID: doc[kDB_vendorid] ?? '',
      vendorName: doc[kDB_vendorname] ?? '',
      userID: doc[kDB_userid] ?? '',
      userName: doc[kDB_user_name] ?? '',
      reqCatName: doc[kDB_req_cat_name] ?? '',
      reqSubCatName: doc[kDB_req_subcat_name] ?? '',
    );
  }
}

class QuoteStatus {
  final String strID;
  final String name;
  QuoteStatus(this.strID, this.name);
}
