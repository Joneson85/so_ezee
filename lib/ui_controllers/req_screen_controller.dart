//Official
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//Custom
import 'package:so_ezee/screens/quotes/quotes_display.dart';
import 'package:so_ezee/screens/request/request_display.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';

class ReqScreenController extends StatefulWidget {
  final String requestID, categoryName;
  ReqScreenController(
      {@required String requestID, @required String categoryName})
      : this.requestID = requestID,
        this.categoryName = categoryName;

  @override
  _ReqScreenControllerState createState() => _ReqScreenControllerState();
}

class _ReqScreenControllerState extends State<ReqScreenController>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isVendor = false;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  _loadPrefs() async {
    _isLoading = true;
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _isVendor = _prefs.getBool(kPrefs_isVendor) ?? false;
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  // The ordering of the pages affects what is actually displayed on the app
  // and also the tracking index
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryColor),
        leading: null,
        bottom: _populateTabs(),
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(child: _populateTabViews()),
    );
  }

  Widget _populateTabs() {
    if (_isLoading || _isVendor)
      return PreferredSize(
        child: SizedBox.shrink(),
        preferredSize: Size.zero,
      );
    else {
      return TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.black54,
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _isVendor ? Colors.white : primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: <Widget>[
          Tab(text: kLabel_Details),
          Tab(text: kLabel_Quotes),
        ],
      );
    }
  }

  Widget _populateTabViews() {
    if (_isLoading)
      return Center(child: CircularProgressIndicator());
    else {
      //Vendors can only see request details, Tabs are not required
      if (_isVendor)
        return RequestScreen(requestID: widget.requestID);
      else
        return TabBarView(
          controller: _tabController,
          children: <Widget>[
            RequestScreen(requestID: widget.requestID),
            QuotesList(widget.requestID),
          ],
        );
    }
  }
}
