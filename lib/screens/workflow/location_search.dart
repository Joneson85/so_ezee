import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:so_ezee/models/request.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/screens/workflow/request_workflow_screen.dart';
import 'package:rxdart/rxdart.dart';

class LocationSearchWidget extends StatefulWidget {
  final String apiKey;
  final String language;
  final String sessionToken;
  final List<Component> components;
  final ValueChanged<Prediction> onTap;
  final RequestLocation locationDetails;

  LocationSearchWidget({
    @required this.apiKey,
    this.language,
    this.sessionToken,
    this.components,
    this.onTap,
    this.locationDetails,
    Key key,
  }) : super(key: key);

  @override
  _LocationSearchWidgetState createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  TextEditingController _queryTextController;
  TextEditingController _customAddressTextController;
  GoogleMapsPlaces _places;
  List<Prediction> _predictions = [];
  bool _isSearching = false;
  bool _showPredictions;
  final _queryBehavior = BehaviorSubject<String>.seeded('');

  @override
  void initState() {
    super.initState();
    //If the widget is created with address already passed in, display the address immediately
    if (widget.locationDetails.getFormattedAddress().isEmpty)
      _showPredictions = true;
    else
      _showPredictions = false;
    _predictions = [];
    _queryTextController = TextEditingController(text: "");
    _customAddressTextController = TextEditingController(text: "");
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
    _queryTextController.addListener(_onQueryChange);
    _queryBehavior.stream
        .debounceTime(const Duration(milliseconds: 200))
        .listen(doSearch);
  }

  @override
  void dispose() {
    _places.dispose();
    _queryBehavior.close();
    _queryTextController.removeListener(_onQueryChange);
    super.dispose();
  }

  Future<Null> doSearch(String value) async {
    if (mounted && value.isNotEmpty) {
      setState(() {
        _showPredictions = true;
        _isSearching = true;
      });
      final res = await _places.autocomplete(
        value,
        language: widget.language,
        sessionToken: widget.sessionToken,
        components: widget.components,
      );
      if (res.errorMessage?.isNotEmpty == true ||
          res.status == "REQUEST_DENIED") {
        throw Exception("Response Error");
      } else {
        onResponse(res);
      }
    } else {
      onResponse(null);
    }
  }

  void _onQueryChange() {
    _queryBehavior.add(_queryTextController.text);
  }

  @mustCallSuper
  void onResponse(PlacesAutocompleteResponse res) {
    if (!mounted) return;
    setState(() {
      if (res != null) {
        _predictions = res.predictions ?? [];
        _isSearching = false;
      }
    });
  }

  void _setShowPredictions(bool showFlag) {
    if (mounted) setState(() => _showPredictions = showFlag);
  }

  void setLocationDetails(Prediction prediction) async {
    PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(prediction.placeId);
    final double lat = detail.result.geometry.location.lat ?? -1;
    final double lng = detail.result.geometry.location.lat ?? -1;
    widget.locationDetails.setFormattedAddress(prediction.description);
    widget.locationDetails.setGeoPoint(lat, lng);
    _setShowPredictions(false);
    //Reset parent widget's state so that the control buttons can be activated
    RequestWorkflowScreenState parentState =
        context.findAncestorStateOfType<RequestWorkflowScreenState>();
    parentState.setState(() {});
  }

  void _clearSelectedAddress() {
    if (mounted)
      setState(() {
        widget.locationDetails.setFormattedAddress("");
        widget.locationDetails.setGeoPoint(-1, -1);
      });
  }

  void _clearPredictions() {
    if (mounted) {
      setState(() {
        _predictions.clear();
        _showPredictions = false;
      });
    }
  }

  void _setCustomAddress() {
    if (_customAddressTextController.text.isNotEmpty) {
      if (mounted) setState(() => _showPredictions = false);
      widget.locationDetails.setFormattedAddress(
        _customAddressTextController.text,
      );
      _clearPredictions();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _enterAddressPrompt(),
        Divider(height: 0, thickness: 2),
        _autoCompleteTextfield(),
        _loadingIndicator(),
        _poweredByGoogleImage(),
        _showPredictions ? _displayPredictions() : _displayAddressDetails(),
      ],
    );
  }

  Widget _enterAddressPrompt() {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.grey[400],
      child: Text(
        "Enter address for the request",
        maxLines: 2,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _displayPredictions() {
    List<Widget> _predictionTilesList = [];
    _predictionTilesList.add(_customAddressPrompt());
    if (_predictions.isNotEmpty) {
      for (Prediction _p in _predictions) {
        /*Only show the prediction if the description is not null or empty
        This prevents the location details from containing an empty string
        as an address*/
        if (_p.description != null && _p.description.isNotEmpty) {
          _predictionTilesList.add(
            ListTile(
              onTap: () => setLocationDetails(_p),
              leading: Icon(Icons.location_on),
              title: Text(_p.description),
            ),
          );
        }
      }
    }
    return Column(children: _predictionTilesList);
  }

  Widget _loadingIndicator() {
    if (_isSearching)
      return LinearProgressIndicator();
    else
      return SizedBox.shrink();
  }

  Widget _clearSearchIcon() {
    return InkWell(
      child: Icon(Icons.clear),
      onTap: () {
        //Binding prevents error during clearing of the text controller
        //between frames
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _queryTextController.clear(),
        );
        _clearPredictions();
      },
    );
  }

  Widget _autoCompleteTextfield() {
    return Container(
      padding: EdgeInsets.all(10),
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(top: 20),
      child: TextField(
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (value) => value.isEmpty ? _clearPredictions() : null,
        controller: _queryTextController,
        style: TextStyle(fontSize: 16.0),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[300],
          focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[700],
          ),
          suffixIcon: _clearSearchIcon(),
          hintText: "Address",
          hintStyle: TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }

  //Return "Powered By Google" Image when prediction list is empty
  //and user has not selected address before
  Widget _poweredByGoogleImage() {
    if (_predictions.isEmpty &&
        _queryTextController.text.isEmpty &&
        widget.locationDetails.getFormattedAddress().isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 20.0),
            child: Image.asset(
              kPoweredByGoogleWhite,
              height: 50,
              width: MediaQuery.of(context).size.width * 0.75,
            ),
          )
        ],
      );
    } else
      return SizedBox.shrink();
  }

  //Prompts user to enter address manually
  Widget _customAddressPrompt() {
    if (_queryTextController.text.isEmpty)
      return SizedBox.shrink();
    else {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 25),
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Address not found? ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                InkWell(
                  onTap: () => _showCustomAddressDialog(context),
                  child: Text(
                    "Enter it here",
                    style: TextStyle(
                      color: primaryColorDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
            Divider(thickness: 2),
          ],
        ),
      );
    }
  }

  Future<void> _showCustomAddressDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        _customAddressTextController.clear();
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.location_on,
                color: primaryColor,
              ),
              Text("Address"),
            ],
          ),
          content: TextFormField(
            autofocus: true,
            autocorrect: false,
            autovalidate: true,
            enableSuggestions: false,
            controller: _customAddressTextController,
            decoration: InputDecoration(hintText: "Address"),
            minLines: 2,
            maxLines: 5,
            maxLength: 150,
            validator: ((input) {
              if (input.trim().isEmpty)
                return "Address cannot be empty";
              else
                return null;
            }),
          ),
          actions: <Widget>[
            RaisedButton(
              color: Colors.white,
              child: Text(
                "Ok",
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () => _setCustomAddress(),
            ),
            RaisedButton(
              child: Text('Cancel'),
              onPressed: () {
                _customAddressTextController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _displayAddressDetails() {
    if (widget.locationDetails.getFormattedAddress().isNotEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 20,
        ),
        child: Material(
          elevation: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _selectedAddressTitle(),
              Divider(indent: 15, endIndent: 15, thickness: 3),
              _formattedAddress(),
            ],
          ),
        ),
      );
    } else
      return SizedBox.shrink();
  }

  Widget _selectedAddressTitle() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Text(
              "Selected Address",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formattedAddress() {
    String _address;
    if (widget.locationDetails.getFormattedAddress().isEmpty)
      _address = "Address not found";
    else
      _address =
          widget.locationDetails.getFormattedAddress() ?? "Address not found";
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: primaryColor,
        ),
        title: Text(
          _address,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: InkWell(
          child: Text(
            "Remove",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _clearSelectedAddress(),
        ),
      ),
    );
  }
}
