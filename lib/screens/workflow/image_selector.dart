//Official
import 'dart:io';
import 'package:flutter/material.dart';
//3rd party
import 'package:image_picker/image_picker.dart';

class ImageSelector extends StatefulWidget {
  final List<File> imageFiles;
  //This variable controls maximum number of images user can upload.
  //Set to 5 for reduce storage footprint on backend
  final maxImages = 5;
  ImageSelector({@required this.imageFiles});

  @override
  _ImageSelectorState createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  @override
  void initState() {
    super.initState();
  }

  void _handleImageFromCamera() async {
    File _imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    if (_imageFile != null) {
      if (mounted) {
        setState(() {
          widget.imageFiles.add(_imageFile);
        });
      }
    }
  }

  void _handleImageFromGallery() async {
    File _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (_imageFile != null) {
      print("adding image");
      if (mounted)
        setState(() {
          widget.imageFiles.add(_imageFile);
          print("num images = ${widget.imageFiles.length}");
        });
    }
  }

  void _removeImage(int index) {
    try {
      if (mounted) setState(() => widget.imageFiles.removeAt(index));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _showPromptText(context),
        _showImageSelectionButtons(context),
        Divider(thickness: 2),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: widget.maxImages,
            itemBuilder: (context, index) => _imageGridWidget(context, index),
          ),
        ),
      ],
    );
  }

  Widget _showPromptText(context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Attach image (optional)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 25),
              Text(
                "${widget.imageFiles.length}/${widget.maxImages}",
                style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "Attaching images will help vendors to understand your request"
                  " better and give more accurate quotes.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _showImageSelectionButtons(context) {
    TextStyle _imgSelectTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: widget.imageFiles.length == widget.maxImages
          ? Colors.grey[700]
          : Theme.of(context).primaryColor,
    );
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              child: GestureDetector(
                //Cannot add images after max is reached
                onTap: widget.imageFiles.length == widget.maxImages
                    ? null
                    : () => _handleImageFromCamera(),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey[700],
                    ),
                    Text(
                      "Take a photo",
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: _imgSelectTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              child: GestureDetector(
                onTap: widget.imageFiles.length == widget.maxImages
                    ? null
                    : () => _handleImageFromGallery(),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey[700],
                    ),
                    Text(
                      "Select from library",
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: _imgSelectTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageGridWidget(BuildContext context, int index) {
    Widget imgGrid = SizedBox.shrink();
    if (widget.imageFiles.isNotEmpty) {
      //Only display images that exist
      if (widget.imageFiles.length - 1 >= index) {
        imgGrid = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AttachedImageThumbnail(
              FileImage(widget.imageFiles[index]),
            ),
            InkWell(
              child: Text(
                "Remove",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onTap: () => _removeImage(index),
            ),
          ],
        );
      }
    }
    return imgGrid;
  }
}

class AttachedImageThumbnail extends StatelessWidget {
  final ImageProvider<dynamic> image;
  AttachedImageThumbnail(this.image);

  void _displayImageInFullscreen(BuildContext context) {
    MaterialPageRoute route = MaterialPageRoute(
      builder: (BuildContext context) => DisplayPictureScreen(
        image: this.image,
      ),
    );
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _displayImageInFullscreen(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(10),
          child: Image(
            height: 150,
            width: 200,
            fit: BoxFit.fill,
            image: image,
          ),
        ),
      ),
    );
  }
}

// Widget that displays picture in full screen mode
class DisplayPictureScreen extends StatelessWidget {
  final ImageProvider<dynamic> image;

  DisplayPictureScreen({Key key, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Image',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Image(
          image: this.image,
        ),
      ),
    );
  }
}
