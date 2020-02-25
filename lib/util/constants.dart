/*
Global constants that are used across the whole application
IMPORTANT: Any modification to the variables in this file needs to be verified
against all files that might refer to them.
*/

import 'package:cloud_firestore/cloud_firestore.dart';

//Page indexing for main navagation bar
const kNavHomeIndex = 0;
const kNavRequestInboxIndex = 1;
const kNavChatInboxIndex = 2;
const kNavSettingIndex = 3;

//Abbreviations
const String kLang_EN = 'en';
const String kCountry_SG = 'sg';

//Route IDs for context navigation
const String kStartScreen_route_id = 'welcome_screen';
const String kHomeScreen_route_id = 'home_screen';
const String kLoginScreen_route_id = 'login_screen';
const String kRegScreen_route_id = 'registration_screen';
const String kChatScreen_route_id = 'chat_screen';
const String kChatInbox_route_id = 'chat_inbox';
const String kRequestInbox_route_id = 'request_inbox';
const String kRequestScreen_route_id = 'request_screen';

//BACKEND-RELATED CONSTANTS they all have the DB prefix

final db = Firestore.instance;

//Generic field names use in multiple data structure
const String kDB_timestamp = 'timestamp';
const String kDB_strid = 'strid';
const String kDB_name = 'name';
const String kDB_other_str_id = 'other';
const String kDB_empty_result = 'empty';
const String kDB_text_input = 'text_input';
const String kDB_appt_time = 'appt_time';
//chat related
const String kDB_chat_sessions = 'chat_sessions';
const String kDB_chat_inbox = 'chat_inbox';
const String kDB_recipient_id = 'recipient_id';
const String kDB_recipient_name = 'recipient_name';
const String kDB_members = 'members';
const String kDB_msg = 'msg';
const String kDB_messages = 'messages';
const String kDB_sender_id = 'sender_id';
//User related
const String kDB_users = 'users';
const String kDB_userid = 'userid';
const String kDB_request_inbox = 'request_inbox';
const String kDB_display_name = 'display_name';
const String kDB_isvendor = 'isvendor';
const String kDB_email = 'email';
const String kDB_avg_rating = 'avg_rating';
const String kDB_total_val = 'total_val';
const String kDB_numreviews = 'numreviews';
const String kDB_bio = 'bio';
const String kDB_profile = 'profile';
const String kDB_details = 'details';
//Request related db constants
const String kDB_request_categories = 'request_categories';
const String kDB_request_subcat = 'request_subcat';
const String kDB_requests = 'requests';
const String kDB_req_status = 'req_status';
//Request data fields
const String kDB_category = 'category';
const String kDB_category_name = 'category_name';
const String kDB_location = 'location';
const String kDB_numquotes = 'numquotes';
const String kDB_status = 'status';
const String kDB_status_name = 'status_name';
const String kDB_formatted_add = 'formatted_add';
const String kDB_item_details = 'item_details';
const String kDB_main_item = 'main_item';
const String kDB_main_item_name = 'main_item_name';
const String kDB_main_item_text = 'main_item_text';
const String kDB_sub_item = 'sub_item';
const String kDB_sub_item_name = 'sub_item_name';
const String kDB_sub_item_text = 'sub_item_text';
const String kDB_subcat = 'subcat';
const String kDB_pending_strID = 'pending';
const String kDB_pending_name = 'Pending';
const String kDB_vendors = 'vendors';
const String kDB_reviewed = 'reviewed';
const String kDB_booked_vendor = 'booked_vendor';
const String kDB_description = 'description';
const String kDB_attached_image_urls = 'attached_image_urls';
const String kDB_completed = 'completed';
//Handyman related constants
const String kDB_handyman_strID = 'handyman';
const String kDB_install_strID = 'install';
const String kDB_repair_strID = 'repair';
//Item related constants
const String kDB_main_items = 'main_items';
const String kDB_sub_items = 'sub_items';
//Property type related constants
const String kDB_property_types = 'property_types';
//Quotes
const String kDB_quotes = 'quotes';
const String kDB_vendorid = 'vendorid';
const String kDB_vendorname = 'vendorname';
const String kDB_price = 'price';
const String kDB_requestid = 'requestid';
const String kDB_quote_status = 'quote_status';
const String kDB_quote_inbox = 'quote_inbox';
const String kDB_open_strID = 'open';
const String kDB_user_name = 'user_name';
const String kDB_req_cat_name = 'req_cat_name';
const String kDB_req_subcat_name = 'req_subcat_name';
const String kDB_booked = 'booked';
const String kDB_rejected = 'rejected';
const String kDB_profileImageUrl = "profileImageUrl";
//Reviews
const String kDB_reviews = 'reviews';
//END OF DB RELATED CONSTANTS

//Google Map related
const String gMapAPIKey = 'AIzaSyAGWv3lP-CtswkrSBa-o0J5lYtLofgZu0s';
//Date related
const String kDefaultDateFormat = 'dd-MMM-yyyy hh:mm';
//Shared preferences fields with prefix kShPref
const String kPrefs_isVendor = 'isVendor';
const String kPrefs_userID = 'userID';
const String kPrefs_userDisplayName = 'userDisplayName';
const String kPrefs_firstLogIn = 'firstLogIn';

//Asset paths
const String kUserPlaceholderImage = 'images/user_placeholder.jpg';
const String kPoweredByGoogleWhite = "images/powered_by_google_on_white.png";
