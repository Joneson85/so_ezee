import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<String> uploadUserProfileImage(
    File imageFile,
    String userID,
  ) async {
    File image = await compressImage(userID, imageFile);

    StorageReference storageRef = FirebaseStorage.instance.ref();
    StorageUploadTask uploadTask =
        storageRef.child('users/userProfileImages/$userID.jpg').putFile(image);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  static Future<String> uploadRequestAttachedImage({
    File imageFile,
    String requestID,
    int imgIndex,
  }) async {
    if (requestID == null) throw Exception("Request ID not found!");
    File image = await compressImage("$requestID$imgIndex", imageFile);

    StorageReference storageRef = FirebaseStorage.instance.ref();
    StorageUploadTask uploadTask = storageRef
        .child("requests/attachments/images/$requestID/$imgIndex.jpg")
        .putFile(image);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  static Future<File> compressImage(String photoId, File image) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    File compressedImageFile = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      '$path/img_$photoId.jpg',
      quality: 10,
    );
    return compressedImageFile;
  }
}
