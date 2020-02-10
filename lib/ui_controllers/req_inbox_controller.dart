//Official
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//Custom
import 'package:so_ezee/screens/request/request_inbox.dart';
import 'package:so_ezee/screens/request/vendor_request_inbox.dart';
import 'package:so_ezee/screens/workflow/request_workflow_screen.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/models/request.dart';

class ReqInboxController extends StatefulWidget {
  @override
  _ReqInboxControllerState createState() => _ReqInboxControllerState();
}

class _ReqInboxControllerState extends State<ReqInboxController>
    with TickerProviderStateMixin {
  _ReqInboxControllerState();
  List<RequestStatus> _requestStatuses = [];
  TabController _tabController;
  SharedPreferences _prefs;
  bool _isVendor = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    _isLoading = true;
    try {
      QuerySnapshot dataSnapshot =
          await db.collection(kDB_req_status).getDocuments();
      for (DocumentSnapshot doc in dataSnapshot.documents) {
        _requestStatuses.add(RequestStatus(
          doc.documentID,
          doc.data[kDB_name].toString(),
        ));
      }
      _prefs = await SharedPreferences.getInstance();
      _isVendor = _prefs.getBool(kPrefs_isVendor);
      //Vendors can only see pending requests
      _tabController = TabController(
        length: _isVendor ? 1 : _requestStatuses.length,
        vsync: this,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        centerTitle: false,
        leading: null,
        automaticallyImplyLeading: false,
        actions: <Widget>[_newRequestActionButton()],
        bottom: _isLoading
            ? PreferredSize(
                child: SizedBox.shrink(),
                preferredSize: Size.zero,
              )
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primaryColor,
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelColor: Colors.black54,
                indicatorColor: _isVendor ? Colors.white : primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: _populateTabs(),
              ),
        title: Text(
          kLabel_RequestInboxTitle,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _populateTabViews(),
            ),
    );
  }

  Widget _newRequestActionButton() {
    //Only users who are not vendors can create requests
    if (_isLoading)
      return Center(
        child: SizedBox(
          child: CircularProgressIndicator(),
          height: 20,
          width: 20,
        ),
      );
    else {
      return _isVendor
          ? SizedBox.shrink()
          : FlatButton(
              child: Text(
                "New request",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => RequestWorkflowScreen(),
                  ),
                );
              },
            );
    }
  }

  List<Widget> _populateTabs() {
    List<Widget> tabs = [];
    if (!_isVendor) {
      for (var status in _requestStatuses) {
        tabs.add(Tab(text: status.name));
      }
    } else
      tabs.add(Tab(text: 'Pending Requests'));
    return tabs;
  }

  List<Widget> _populateTabViews() {
    List<Widget> tabViews = [];
    if (!_isVendor) {
      for (var status in _requestStatuses) {
        tabViews.add(RequestInbox(status.strID));
      }
    } else
      tabViews.add(VendorRequestInbox());
    return tabViews;
  }
}
