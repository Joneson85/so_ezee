import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_ezee/services/storage.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';

class Request {
  final MainItem mainItem;
  final SubItem subItem;
  final RequestCategory category;
  final RequestSubCategory subCategory;
  final RequestLocation locationDetails;
  final DateTime apptTimestamp;
  final RequestStatus reqStatus;
  final String requestID;
  final String userID;
  final int numQuotes;
  final String userName;
  final List<String> vendors;
  final bool reviewed;
  final String bookedVendor;
  final List<File> attachedImageFiles;
  final String description;
  List<String> attachedImageUrls = [];
  Request({
    @required this.category,
    @required this.mainItem,
    @required this.locationDetails,
    @required this.apptTimestamp,
    @required this.userID,
    @required this.userName,
    this.requestID,
    @required this.reqStatus,
    @required this.subCategory,
    @required this.subItem,
    @required this.numQuotes,
    this.vendors,
    this.reviewed,
    this.bookedVendor,
    this.attachedImageFiles,
    this.description,
    List<String> attachedImageUrls,
  }) : this.attachedImageUrls =
            attachedImageUrls ?? []; //prevent the list from becoming null

  Future<void> writeRequestToDB() async {
    DocumentReference requestDocRef = db.collection(kDB_requests).document();
    /*
    Save images to cloud storage. This needs to be done before
    the request details are written so the image Urls can be passed in
    */
    await saveImagesToDB(requestDocRef.documentID);
    String _subCategoryStrID = "";
    String _subCategoryName = "";
    if (subCategory != null) {
      _subCategoryStrID = subCategory.strID;
      _subCategoryName = subCategory.name;
    }
    String _mainItemStrID = "";
    String _mainItemName = "";
    if (mainItem != null) {
      _mainItemStrID = mainItem.strID;
      _mainItemName = mainItem.name;
    }
    String _subItemStrID = "";
    String _subItemName = "";
    if (subItem != null) {
      _subItemStrID = subItem.strID;
      _subItemName = subItem.name;
    }

    //Numquotes defaulted to 0 and status defaulted to pending
    //Saves all the complete details of the request do the DB
    var requestData = {
      kDB_appt_time: this.apptTimestamp,
      kDB_category: this.category.strID,
      kDB_category_name: this.category.name,
      kDB_formatted_add: this.locationDetails.getFormattedAddress(),
      kDB_item_details: {
        kDB_main_item: _mainItemStrID,
        kDB_main_item_name: _mainItemName,
        kDB_sub_item: _subItemStrID,
        kDB_sub_item_name: _subItemName,
      },
      kDB_location: this.locationDetails.getGeoLocation(),
      kDB_numquotes: this.numQuotes ?? 0,
      kDB_status: kDB_pending_strID,
      kDB_status_name: kDB_pending_name,
      kDB_subcat: {
        kDB_name: _subCategoryName,
        kDB_strid: _subCategoryStrID,
      },
      kDB_timestamp: FieldValue.serverTimestamp(),
      kDB_userid: userID,
      kDB_user_name: this.userName,
      kDB_vendors: this.vendors ?? [],
      kDB_reviewed: this.reviewed ?? false,
      kDB_booked_vendor: bookedVendor ?? '',
      kDB_attached_image_urls: attachedImageUrls ?? [""],
      kDB_description: description ?? "",
    };
    await requestDocRef.setData(requestData, merge: true);

    //Saves a reduced footprint version of the actual request tied to the user object
    //The request inbox screen only displays these minimal info until the user selects
    //a request to drill down into the complete details
    DocumentReference requestInboxDocRef = db
        .collection(kDB_users)
        .document(userID)
        .collection(kDB_request_inbox)
        .document(requestDocRef.documentID);
    var requestInboxDocRefData = {
      kDB_appt_time: this.apptTimestamp,
      kDB_category: this.category.strID,
      kDB_category_name: this.category.name,
      kDB_numquotes: 0,
      kDB_status: kDB_pending_strID,
      kDB_timestamp: FieldValue.serverTimestamp(),
      kDB_formatted_add: locationDetails.getFormattedAddress(),
    };
    await requestInboxDocRef.setData(requestInboxDocRefData, merge: true);

    return requestDocRef;
  }

  //Saves attached images to Firebase storage, then store the file
  //Urls on the request document
  Future<void> saveImagesToDB(String docID) async {
    if (attachedImageFiles != null) {
      for (int index = 0; index < attachedImageFiles.length; index++)
        if (attachedImageFiles[index] != null) {
          //Saves the attached image to cloud firestore and get the Url of
          //saved image
          String _imageUrl = await StorageService.uploadRequestAttachedImage(
              imageFile: attachedImageFiles[index],
              requestID: docID,
              imgIndex: index);
          attachedImageUrls.add(_imageUrl);
        }
    }
  }

  Future<bool> cancelRequest() async {
    try {
      //Set request to "Cancelled"
      DocumentReference _requestDoc =
          db.collection('requests').document(requestID);
      await _requestDoc
          .updateData({kDB_status: 'cancelled', kDB_status_name: 'Cancelled'});
      //Set request snippet data in user's request inbox to "Cancelled"
      DocumentReference _requestInboxDoc = db
          .collection('users')
          .document(userID)
          .collection('request_inbox')
          .document(requestID);
      await _requestInboxDoc.updateData({kDB_status: 'cancelled'});
      //Get all quotes attached to this request
      QuerySnapshot _attachedQuotes = await db
          .collection(kDB_quotes)
          .where(kDB_requestid, isEqualTo: requestID)
          .getDocuments();
      //Set attached quotes to "rejected"
      var batch = db.batch();
      for (var quoteDoc in _attachedQuotes.documents) {
        batch.updateData(quoteDoc.reference, {kDB_status: 'rejected'});
      }
      await batch.commit();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}

class RequestSnippet {
  final String userID;
  final String requestID;
  final Timestamp apptTimestamp;
  final String categoryStrID;
  final String categoryName;
  final int numQuotes;
  final String statusStrID;
  final String address;

  RequestSnippet({
    this.userID,
    @required this.requestID,
    @required this.apptTimestamp,
    @required this.categoryStrID,
    @required this.categoryName,
    @required this.numQuotes,
    @required this.statusStrID,
    @required this.address,
  });

  Future<void> writeRequestSnippetToDB() async {
    DocumentReference requestSnippet = Firestore.instance
        .collection(kDB_users)
        .document(userID)
        .collection(kDB_request_inbox)
        .document(requestID);
    var requestSnippetData = {
      kDB_appt_time: this.apptTimestamp,
      kDB_category: this.categoryStrID,
      kDB_category_name: this.categoryName,
      kDB_numquotes: this.numQuotes,
      kDB_status: this.statusStrID
    };
    await requestSnippet.setData(requestSnippetData, merge: true);
  }

  factory RequestSnippet.fromDoc(DocumentSnapshot doc) {
    return RequestSnippet(
      requestID: doc.documentID ?? '',
      apptTimestamp: doc[kDB_appt_time] ?? Timestamp.now(),
      numQuotes: doc[kDB_numquotes] ?? 0,
      categoryStrID: doc[kDB_category] ?? '',
      categoryName: doc[kDB_category_name] ?? '',
      address: doc[kDB_formatted_add] ?? '',
      statusStrID: doc[kDB_status] ?? '',
    );
  }
}

class RequestCategory {
  //Unique string ID of each request category
  final String strID;
  final String name;
  final List<RequestSubCategory> subCategories = [];
  final List<MainItem> mainItems = [];
  RequestSubCategory _selectedSubCategory;

  RequestCategory(this.strID, this.name);

  void addSubCategory(String subCatStrID, String name) {
    subCategories.add(RequestSubCategory(
      strID: subCatStrID,
      name: name,
      parentStrID: this.strID,
    ));
  }

  void clearSubCategories() {
    subCategories.clear();
  }

  void setSelectedSubCategory(String subCatStrID) {
    _selectedSubCategory = subCategories
        .firstWhere((subCat) => subCat.strID == subCatStrID, orElse: null);
  }

  RequestSubCategory getSelectedSubCategory() {
    return _selectedSubCategory;
  }

  Future<void> fetchSubCategories() async {
    QuerySnapshot querySnapshot = await db
        .collection(kDB_request_categories)
        .document(strID)
        .collection(kDB_request_subcat)
        .getDocuments();
    for (var doc in querySnapshot.documents) {
      //The logic below ensures that "Other" subcategory will always be at
      //the last element of the list
      if (doc.documentID == "other" || subCategories.isEmpty) {
        addSubCategory(doc.documentID ?? "", doc[kDB_name] ?? "");
      } else {
        subCategories.insert(
          subCategories.length - 1,
          RequestSubCategory(
            strID: doc.documentID,
            name: doc[kDB_name],
          ),
        );
      }
    }
  }

  void clearMainItems() {
    mainItems.clear();
  }

  void addMainItem(String mainItemStrID, String mainItemName) {
    mainItems.add(MainItem(mainItemStrID, mainItemName));
  }

  Future<void> fetchMainItems() async {
    QuerySnapshot querySnapshot = await db.collection(kDB_main_items).where(
      "request_categories",
      arrayContainsAny: ["$strID", "all"],
    ).getDocuments();
    for (var doc in querySnapshot.documents) {
      //Ensure that "Other" is always at the last element of the list
      if (doc.documentID == "other" || mainItems.isEmpty) {
        addMainItem(doc.documentID ?? "", doc[kDB_name] ?? "");
      } else {
        mainItems.insert(
          mainItems.length - 1,
          MainItem(doc.documentID ?? "", doc[kDB_name] ?? ""),
        );
      }
    }
  }
}

class RequestSubCategory {
  RequestSubCategory({this.strID, this.name, this.parentStrID});
  final String strID; //Unique string ID of each request subcategory
  final String name;
  final String parentStrID;
  static String _textInput;
  setTextInput(String textInput) {
    _textInput = textInput;
  }

  String getTextInput() {
    return _textInput;
  }
}

class MainItem {
  MainItem(this.strID, this.name);
  final String strID;
  final String name;
  final List<SubItem> subItems = [];

  Future<void> fetchSubItems() async {
    try {
      QuerySnapshot querySnapshot = await Firestore.instance
          .collection(kDB_main_items)
          .document(strID)
          .collection(kDB_sub_items)
          .getDocuments();
      if (querySnapshot != null) {
        for (var doc in querySnapshot.documents) {
          if (doc.documentID == "other" || subItems.isEmpty) {
            addSubItem(doc.documentID ?? "", doc[kDB_name] ?? "");
          } else {
            subItems.insert(
              subItems.length - 1,
              SubItem(doc.documentID ?? "", doc[kDB_name] ?? ""),
            );
          }
        }
      }
      return subItems;
    } catch (e) {
      print(e);
    }
  }

  addSubItem(String strID, String name) {
    subItems.add(SubItem(strID, name));
  }
}

class SubItem {
  SubItem(this.strID, this.name);
  final String strID;
  final String name;
}

class PropertyType {
  PropertyType(this.strID, this.name);
  final String strID;
  final String name;
}

class RequestLocation {
  GeoPoint _geoLocation;
  String _formattedAddress;

  RequestLocation({
    @required double latitude,
    @required double longitude,
    @required String formattedAddress,
  })  : _geoLocation = GeoPoint(latitude ?? 0, longitude ?? 0),
        _formattedAddress = formattedAddress ?? kLabel_UnkownAddress;

  void setGeoPoint(double lat, double lng) {
    _geoLocation = GeoPoint(lat ?? 0, lng ?? 0);
  }

  void setFormattedAddress(String formattedAddress) {
    _formattedAddress = formattedAddress ?? kLabel_UnkownAddress;
  }

  GeoPoint getGeoLocation() {
    return _geoLocation;
  }

  String getFormattedAddress() {
    return _formattedAddress;
  }
}

class RequestStatus {
  final String strID;
  final String name;
  RequestStatus(this.strID, this.name);
}
