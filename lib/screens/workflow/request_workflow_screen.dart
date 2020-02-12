//Official
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
//3rd Party
import 'package:uuid/uuid.dart';
//Custom
import 'package:so_ezee/models/request.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/screens/start_screen.dart';
import "package:so_ezee/screens/workflow/location_search.dart";
import "package:so_ezee/screens/workflow/image_selector.dart";

class RequestWorkflowScreen extends StatefulWidget {
  @override
  RequestWorkflowScreenState createState() => RequestWorkflowScreenState();
}

class RequestWorkflowScreenState extends State<RequestWorkflowScreen> {
  //Lists
  List<RequestCategory> _requestCategories = [];
  List<PropertyType> _propertyTypes = [];
  List<File> imageFiles = [];
  final List<String> imagePaths = List<String>.filled(5, "", growable: false);
  //Objects to track user's selection
  RequestCategory _selectedCategory;
  RequestSubCategory _selectedSubCategory;
  MainItem _selectedMainItem;
  SubItem _selectedSubItem;
  DateTime _selectedApptTimestamp;
  RequestLocation locationDetails;
  //User prefs
  SharedPreferences _prefs;
  String _userID = "";
  String _userName = "";
  //Strings to track user's selection
  String _selectedCategoryStrID = "";
  String _selectedSubcategoryStrID = "";
  String _selectedMainItemStrID = "";
  String _selectedSubItemStrID = "";
  String _selectedPropertyTypeStrID = "";
  String _description = "";
  //Flags
  bool _isLoading = false;
  bool _isOtherSelected = false;
  bool _allowNext = false;
  //Text input controller
  final TextEditingController _textEditingController =
      TextEditingController(text: "");
  //keeps track of which step of the request creation user is in
  int _prevStep;
  int _currStep;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _prevStep = _currStep = 0;
  }

  void _loadInitialData() async {
    _isLoading = true;
    locationDetails = RequestLocation(
      latitude: -1,
      longitude: -1,
      formattedAddress: "",
    );
    _selectedApptTimestamp = DateTime.now();
    await _loadUserData();
    await _loadRequestCategories(); //Pre-load categories for 1st step of workflow
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    _prefs = await SharedPreferences.getInstance();
    _userID = _prefs.getString(kPrefs_userID);
    _userName = _prefs.getString(kPrefs_userDisplayName);
    //Force user to re-login if user preferences cannot be loaded
    if (_userID == null || _userName == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => StartScreen(),
        ),
      );
    }
  }

  Future<void> _loadRequestCategories() async {
    try {
      QuerySnapshot _allCategories =
          await db.collection(kDB_request_categories).getDocuments();
      if (_allCategories.documents.isNotEmpty) {
        for (var doc in _allCategories.documents) {
          //If the category is "Other", it will be at the end of the list
          if (doc.documentID == "other" || _requestCategories.isEmpty) {
            _requestCategories.add(
              RequestCategory(
                doc.documentID,
                doc[kDB_name],
              ),
            );
          } else {
            _requestCategories.insert(
              _requestCategories.length - 1,
              RequestCategory(
                doc.documentID,
                doc[kDB_name],
              ),
            );
          }
        }
      }
    } catch (e) {
      print(e);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryColor),
        automaticallyImplyLeading: false,
        leading: null,
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Discard',
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () =>
                _showDiscardConfirmation(context), //Navigator.pop(context),
          ),
        ],
        title: Text(
          "New request",
          style: TextStyle(fontSize: 22),
        ),
      ),
      body: GestureDetector(
        onTap: (() {
          if (mounted)
            setState(() {
              FocusScope.of(context).unfocus();
            });
        }),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _displayWorkflow(_currStep),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _stepControlButtons(_currStep),
      ),
    );
  }

  void _loadSubCategories(RequestCategory reqCategory) async {
    _isLoading = true;
    await reqCategory.fetchSubCategories();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadPropertyTypes() async {
    _isLoading = true;
    QuerySnapshot querySnapshot =
        await db.collection(kDB_property_types).getDocuments();
    for (var doc in querySnapshot.documents) {
      if (doc.documentID == "other" || _propertyTypes.isEmpty) {
        _propertyTypes.add(
          PropertyType(
            doc.documentID,
            doc[kDB_name],
          ),
        );
      } else {
        _propertyTypes.insert(
          _propertyTypes.length - 1,
          PropertyType(
            doc.documentID,
            doc[kDB_name],
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMainItems() async {
    _isLoading = true;
    await _selectedCategory.fetchMainItems();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadSubItems(MainItem mainItem) async {
    _isLoading = true;
    await mainItem.fetchSubItems();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _continueToNextStep() {
    //If the user selected "Other" on any step, skip directly to property type selection
    if (_isOtherSelected && _currStep < 4) {
      if (_textEditingController.text != null &&
          _textEditingController.text.isNotEmpty) {
        _description = _textEditingController.text;
      }
      if (mounted)
        setState(() {
          _prevStep = _currStep;
          _currStep = 4;
        });
    } else {
      if (mounted)
        setState(() {
          _prevStep = _currStep;
          _currStep++;
        });
    }
  }

  void _backToPrevStep() {
    if (mounted)
      setState(() {
        //Set current step to previous step
        _currStep = _prevStep;
        _prevStep--;
      });
  }

  Widget _descriptionTextFormField() {
    //The logic to extract the user's input and store it into the Request object
    //is done at the point of submitting the request. This reduces computation of the input
    //to only once before submission
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TextFormField(
        autovalidate: true,
        controller: _textEditingController,
        decoration: InputDecoration(
          hintText: "Description",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(6.0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
              width: 1.0,
            ),
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColorDark,
              width: 2.0,
            ),
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
          ),
        ),
        textInputAction: TextInputAction.done,
        maxLines: 5,
        maxLength: 1500,
        validator: (value) {
          if (_textEditingController.text.isEmpty) {
            return "Description cannot be blank";
          } else
            return null;
        },
        onEditingComplete: (() {
          FocusScope.of(context).unfocus();
          if (mounted) setState(() => _allowNext = true);
        }),
      ),
    );
  }

  Widget _displayCategorySelection() {
    List<Widget> _options = [];
    _allowNext = false;
    //Add each request category as an option in a radiolist
    for (RequestCategory _category in _requestCategories) {
      if (_selectedCategoryStrID == _category.strID) _allowNext = true;
      _options.add(
        RadioListTile(
          value: _category.strID,
          groupValue: _selectedCategoryStrID,
          title: Text(
            _category.name,
            style: TextStyle(fontSize: 16),
          ),
          onChanged: (selectedVal) {
            if (mounted) {
              setState(
                () {
                  //Storing the selected category and strid into memory
                  _selectedCategoryStrID = selectedVal;
                  _selectedCategory = _requestCategories.firstWhere(
                    (reqCategory) =>
                        reqCategory.strID == _selectedCategoryStrID,
                  );
                  if (selectedVal == "other")
                    _isOtherSelected = true;
                  else {
                    _isOtherSelected = false;
                    _textEditingController.clear();
                  }
                },
              );
            }
          },
          selected: _selectedCategoryStrID == _category.strID,
          activeColor: primaryColor,
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _selectionPromptText(
                "Select the category of your request",
              ),
            ),
          ],
        ),
        const Divider(thickness: 1.5, indent: 25, endIndent: 25),
        ..._options,
        //Allows the user to enter a text-based description if "Other" is selected
        _isOtherSelected ? _descriptionTextFormField() : SizedBox.shrink(),
      ],
    );
  }

  Widget _displaySubcategorySelection() {
    //Only query the DB for subCategories if they have not been loaded before
    if (_selectedCategory.subCategories.isEmpty) {
      _loadSubCategories(_selectedCategory);
    }
    if (_isLoading) return Center(child: CircularProgressIndicator());
    List<Widget> _options = [];
    _allowNext = false;
    for (RequestSubCategory _subCat in _selectedCategory.subCategories) {
      //Only allow user to proceed if a valid selection has been made.
      //When the user clicks back, selected value is not null, but might not
      //be within the current options
      if (_subCat.strID == _selectedSubcategoryStrID) _allowNext = true;
      _options.add(
        RadioListTile(
          value: _subCat.strID,
          groupValue: _selectedSubcategoryStrID,
          title: Text(_subCat.name),
          onChanged: (selectedVal) {
            if (mounted) {
              setState(
                () {
                  _selectedSubcategoryStrID = selectedVal;
                  _selectedSubCategory =
                      _selectedCategory.subCategories.firstWhere(
                    (selSubCat) => selSubCat.strID == _selectedSubcategoryStrID,
                  );
                  if (selectedVal == "other")
                    _isOtherSelected = true;
                  else {
                    _textEditingController.clear();
                    _isOtherSelected = false;
                  }
                },
              );
            }
          },
          selected: _selectedSubcategoryStrID == _subCat.strID,
          activeColor: primaryColor,
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _selectionPromptText(
                "Select the type of work required",
              ),
            ),
          ],
        ),
        const Divider(thickness: 1.5, indent: 25, endIndent: 25),
        ..._options,
        //Allows the user to enter a text-based description if "Other" is selected
        _isOtherSelected ? _descriptionTextFormField() : SizedBox.shrink(),
      ],
    );
  }

  Widget _displayMainItemSelection() {
    if (_selectedCategory.mainItems.isEmpty) {
      _loadMainItems();
    }
    if (_isLoading) return Center(child: CircularProgressIndicator());
    List<Widget> _options = [];
    _allowNext = false;
    for (MainItem _mainItem in _selectedCategory.mainItems) {
      if (_selectedMainItemStrID == _mainItem.strID) _allowNext = true;
      _options.add(
        RadioListTile(
          value: _mainItem.strID,
          groupValue: _selectedMainItemStrID,
          title: Text(_mainItem.name),
          onChanged: (selectedVal) {
            if (mounted) {
              setState(
                () {
                  _selectedMainItemStrID = selectedVal;
                  _selectedMainItem = _selectedCategory.mainItems.firstWhere(
                    (listItem) => listItem.strID == selectedVal,
                  );
                  if (selectedVal == "other")
                    _isOtherSelected = true;
                  else {
                    _textEditingController.clear();
                    _isOtherSelected = false;
                  }
                },
              );
            }
          },
          selected: _selectedMainItemStrID == _mainItem.strID,
          activeColor: primaryColor,
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _selectionPromptText("Select the primary item"),
            ),
          ],
        ),
        const Divider(thickness: 1.5, indent: 25, endIndent: 25),
        ..._options,
        //Allows the user to enter a text-based description if "Other" is selected
        _isOtherSelected ? _descriptionTextFormField() : SizedBox.shrink(),
      ],
    );
  }

  Widget _displaySubItemSelection() {
    //Load subitems if not loaded yet
    if (_selectedMainItem.subItems == null ||
        _selectedMainItem.subItems.length == 0) {
      _loadSubItems(_selectedMainItem);
    }
    if (_isLoading) return Center(child: CircularProgressIndicator());
    List<Widget> _options = [];
    _allowNext = false;
    for (SubItem _subItem in _selectedMainItem.subItems) {
      if (_selectedSubItemStrID == _subItem.strID) _allowNext = true;
      _options.add(RadioListTile(
        value: _subItem.strID,
        groupValue: _selectedSubItemStrID,
        title: Text(_subItem.name),
        onChanged: (selectedVal) {
          if (mounted) {
            setState(() {
              _selectedSubItemStrID = selectedVal;
              _selectedSubItem = _selectedMainItem.subItems.firstWhere(
                (listItem) => listItem.strID == selectedVal,
              );
              if (selectedVal == "other")
                _isOtherSelected = true;
              else {
                _textEditingController.clear();
                _isOtherSelected = false;
              }
            });
          }
        },
        selected: _selectedSubItemStrID == _subItem.strID,
        activeColor: primaryColor,
      ));
    }
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _selectionPromptText("Select the part(s) to be worked on"),
            ),
          ],
        ),
        const Divider(thickness: 1.5, indent: 25, endIndent: 25),
        ..._options,
        //Allows the user to enter a text-based description if "Other" is selected
        _isOtherSelected ? _descriptionTextFormField() : SizedBox.shrink(),
      ],
    );
  }

  Widget _displayPropertyTypeSelection() {
    if (_propertyTypes.isEmpty) _loadPropertyTypes();
    if (_isLoading) return Center(child: CircularProgressIndicator());
    List<Widget> _options = [];
    _allowNext = false;
    for (PropertyType _propType in _propertyTypes) {
      if (_selectedPropertyTypeStrID == _propType.strID) _allowNext = true;
      _options.add(
        RadioListTile(
          value: _propType.strID,
          groupValue: _selectedPropertyTypeStrID,
          //Using the name as the title of the radio button
          title: Text(_propType.name),
          onChanged: (selectedVal) {
            if (mounted)
              setState(() => _selectedPropertyTypeStrID = selectedVal);
          },
          selected: _selectedPropertyTypeStrID == _propType.strID,
          activeColor: primaryColor,
        ),
      );
    }
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _selectionPromptText("Select property type"),
            ),
          ],
        ),
        const Divider(thickness: 1.5, indent: 25, endIndent: 25),
        ..._options,
      ],
    );
  }

  Widget _displayLocationSearchBar() {
    if (locationDetails.getFormattedAddress().isEmpty)
      _allowNext = false;
    else
      _allowNext = true;
    return LocationSearchWidget(
      sessionToken: Uuid().v4(),
      language: kLang_EN,
      components: [Component(Component.country, kCountry_SG)],
      apiKey: gMapAPIKey,
      locationDetails: locationDetails,
    );
  }

  Widget _selectionPromptText(String promptText) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        promptText ?? "",
        maxLines: 2,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _stepControlButtons(int currStep) {
    if (_isOtherSelected && _textEditingController.text.isEmpty)
      _allowNext = false;
    return Row(
      children: <Widget>[
        currStep == 0
            ? SizedBox.shrink() //Do not display "Back button for first step"
            : Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: _backButton(),
                ),
              ),
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(5, 10, 10, 10),
            //Display "Submit" on the final step
            child: currStep == 7 ? _submitButton() : _nextButton(_allowNext),
          ),
        ),
      ],
    );
  }

  Widget _displayAddMedia() {
    _allowNext = true;
    return ImageSelector(imageFiles: this.imageFiles);
  }

  Widget _displayWorkflow(int workflowStep) {
    switch (workflowStep) {
      //Request category selection
      case 0:
        return _displayCategorySelection();
      case 1:
        return _displaySubcategorySelection();
      case 2:
        return _displayMainItemSelection();
      case 3:
        return _displaySubItemSelection();
      case 4:
        return _displayPropertyTypeSelection();
      case 5:
        return _displayLocationSearchBar();
      case 6:
        return _displayDatePicker();
      case 7:
        return _displayAddMedia();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _displayDatePicker() {
    //Set the time to be now, if user has not chosen a time before
    _allowNext = true;
    if (_selectedApptTimestamp == null) {
      _selectedApptTimestamp = DateTime.now();
    }
    return ListView(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(15),
          color: Colors.grey[300],
          child: Text(
            "When do you need the request?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Divider(
          height: 0,
          thickness: 2,
        ),
        _appointmentDetails(),
      ],
    );
  }

  _pickDate() async {
    showDatePicker(
      context: context,
      initialDate: _selectedApptTimestamp,
      firstDate: DateTime(_selectedApptTimestamp.year - 1),
      lastDate: DateTime(_selectedApptTimestamp.year + 1),
    ).then((date) {
      if (mounted) {
        setState(() {
          //Only if the user picked a date
          if (date != null) {
            _selectedApptTimestamp = new DateTime(
              date.year,
              date.month,
              date.day,
            );
          }
        });
      }
    });
  }

  _pickTime() async {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedApptTimestamp.hour,
        minute: _selectedApptTimestamp.minute,
      ),
    ).then((time) {
      if (mounted) {
        setState(() {
          //Only if the user picked a time
          if (time != null) {
            _selectedApptTimestamp = new DateTime(
              _selectedApptTimestamp.year,
              _selectedApptTimestamp.month,
              _selectedApptTimestamp.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    });
  }

  Widget _appointmentDetails() {
    const TextStyle _textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
    return Container(
      margin: EdgeInsets.all(15),
      child: Material(
        color: Colors.grey[200],
        elevation: 3.0,
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Text(
                "Appointment",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Divider(indent: 5, endIndent: 5, thickness: 1),
            ListTile(
              leading: Text("Date:", style: _textStyle),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  DateFormat('dd-MMM-yyyy')
                          .format(_selectedApptTimestamp)
                          .toString() ??
                      "",
                  style: _textStyle,
                ),
              ),
              trailing: _editDateTimeButton("date"),
            ),
            ListTile(
              leading: Text("Time:", style: _textStyle),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  DateFormat('hh:mm')
                          .format(_selectedApptTimestamp)
                          .toString() ??
                      "",
                  style: _textStyle,
                ),
              ),
              trailing: _editDateTimeButton("time"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editDateTimeButton(String mode) {
    return FlatButton(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          "Edit",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onPressed: () => mode == "date" ? _pickDate() : _pickTime(),
    );
  }

  Widget _nextButton(bool enabled) {
    bool _canProceed = true;
    if (_isLoading || !enabled) {
      _canProceed = false;
    }
    return RaisedButton(
      color: Theme.of(context).primaryColorDark,
      disabledColor: Colors.grey[200],
      child: Text(
        "Next",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: _canProceed ? () => _continueToNextStep() : null,
    );
  }

  Widget _backButton() {
    return RaisedButton(
      color: Colors.white,
      disabledColor: Colors.grey[200],
      child: Text(
        "Back",
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: _isLoading ? null : () => _backToPrevStep(),
    );
  }

  Widget _submitButton() {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
            color: Theme.of(context).primaryColorDark,
            child: Text(
              kLabel_Submit,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _isLoading ? null : () => _submitRequest(),
          ),
        ),
      ],
    );
  }

  void _submitRequest() async {
    if (mounted) setState(() => _isLoading = true);

    //Requests are created with "Pending" status by default and 0 quotes
    var _reqStatus = RequestStatus(kDB_pending_strID, kDB_pending_name);
    var _request = Request(
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      mainItem: _selectedMainItem,
      subItem: _selectedSubItem,
      locationDetails: locationDetails,
      apptTimestamp: _selectedApptTimestamp,
      reqStatus: _reqStatus,
      userID: _userID,
      userName: _userName,
      numQuotes: 0,
      description: _description,
      attachedImageFiles: imageFiles,
    );
    try {
      await _request.writeRequestToDB();
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
    if (mounted) setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  Future<void> _showDiscardConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Discard? You will lose all unsaved information'),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () =>
                  Navigator.of(context).popAndPushNamed(kHomeScreen_route_id),
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
}
