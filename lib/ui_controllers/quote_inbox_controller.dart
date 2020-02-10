import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:so_ezee/screens/quotes/quote_inbox.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/labels.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:so_ezee/models/quote.dart';

class QuoteInboxController extends StatefulWidget {
  @override
  _QuoteInboxControllerState createState() => _QuoteInboxControllerState();
}

class _QuoteInboxControllerState extends State<QuoteInboxController> {
  List<QuoteStatus> _quoteStatuses = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() async {
    try {
      _isLoading = true;
      QuerySnapshot queryResults =
          await Firestore.instance.collection(kDB_quote_status).getDocuments();
      for (var doc in queryResults.documents) {
        _quoteStatuses.add(QuoteStatus(
          doc.documentID,
          doc.data[kDB_name].toString(),
        ));
      }
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    } catch (e) {
      print(e);
    }
  }

  List<Widget> _populateTabs() {
    List<Tab> tabs = [];
    _quoteStatuses.forEach((status) => tabs.add(Tab(text: status.name)));
    return tabs;
  }

  List<Widget> _populateTabViews() {
    List<QuoteInbox> tabViews = [];
    _quoteStatuses.forEach(
      (status) => tabViews.add(QuoteInbox(statusStrID: status.strID)),
    );
    return tabViews;
  }

  @override
  Widget build(BuildContext context) {
    int numTabs = _quoteStatuses.length;
    return DefaultTabController(
      length: numTabs,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          leading: null,
          automaticallyImplyLeading: false,
          bottom: _isLoading
              ? PreferredSize(
                  child: SizedBox.shrink(),
                  preferredSize: Size.zero,
                )
              : TabBar(
                  isScrollable: true,
                  labelColor: primaryColor,
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: _populateTabs(),
                ),
          title: Text(kLabel_Quotes,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              )),
        ),
        body: _isLoading
            ? LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(primaryColor),
              )
            : TabBarView(
                children: _populateTabViews(),
              ),
      ),
    );
  }
}
