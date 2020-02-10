import 'package:flutter/material.dart';
import 'package:so_ezee/ui_controllers/quote_inbox_controller.dart';
import 'package:so_ezee/ui_controllers/req_inbox_controller.dart';
import 'package:so_ezee/screens/home_screen.dart';
import 'package:so_ezee/screens/chat/chat_inbox.dart';
import 'package:so_ezee/screens/user/main_profile.dart';
import 'package:so_ezee/util/constants.dart';
import 'package:so_ezee/util/ui_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavController extends StatefulWidget {
  @override
  _MainNavControllerState createState() => _MainNavControllerState();
}

class _MainNavControllerState extends State<MainNavController> {
  // The ordering of the pages affects what is actually displayed on the app
  // and also the tracking index
  List<Widget> pages = [];
  final PageStorageBucket _bucket = PageStorageBucket();
  //Start with the Home Page
  int _selectedIndex = 0;
  bool _dataLoaded = false;
  bool _isVendor = false;
  List<BottomNavigationBarItem> _botNavItems = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _isVendor = _prefs.getBool(kPrefs_isVendor) ?? false;
    if (mounted)
      setState(() {
        _dataLoaded = true;
        _loadPages();
        _loadBotNavItems();
      });
  }

  void _loadPages() {
    var _homeScreen = HomeScreen(PageStorageKey('home_screen'));
    var _reqInboxController = ReqInboxController();
    var _quoteInboxController = QuoteInboxController();
    var _chatInbox = ChatInbox(PageStorageKey('chat_inbox'));
    var _profileScreen = ProfileScreen(PageStorageKey('profile_page'));
    if (_isVendor) {
      pages = [
        _homeScreen,
        _reqInboxController,
        _quoteInboxController,
        _chatInbox,
        _profileScreen,
      ];
    } else {
      pages = [
        _homeScreen,
        _reqInboxController,
        _chatInbox,
        _profileScreen,
      ];
    }
  }

  void _loadBotNavItems() {
    double iconSize = 36.0;
    var _homeItem = BottomNavigationBarItem(
      icon: Icon(Icons.home, size: iconSize),
      title: Text('Home'),
    );
    var _requestItem = BottomNavigationBarItem(
      icon: Icon(Icons.work, size: iconSize),
      title: Text('Requests'),
    );
    var _quoteItem = BottomNavigationBarItem(
      icon: Icon(Icons.assignment, size: iconSize),
      title: Text('Quotes'),
    );
    var _msgItem = BottomNavigationBarItem(
      icon: Icon(Icons.chat, size: iconSize),
      title: Text('Messages'),
    );
    var _profileItem = BottomNavigationBarItem(
      icon: Icon(Icons.more_horiz, size: iconSize),
      title: Text('More'),
    );
    if (_isVendor) {
      _botNavItems = [
        _homeItem,
        _requestItem,
        _quoteItem,
        _msgItem,
        _profileItem,
      ];
    } else {
      _botNavItems = [
        _homeItem,
        _requestItem,
        _msgItem,
        _profileItem,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return CircularProgressIndicator();
    } else {
      return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: _botNavItems,
          currentIndex: _selectedIndex,
          unselectedItemColor: Colors.grey[700],
          selectedItemColor: primaryColor,
          onTap: (tappedIndex) {
            if (mounted) {
              setState(() {
                _selectedIndex = tappedIndex;
              });
            }
          },
        ),
        body: PageStorage(
          child: pages[_selectedIndex],
          bucket: _bucket,
        ),
      );
    }
  }
}
