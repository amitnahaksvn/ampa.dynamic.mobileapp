import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'archive_page.dart';
import 'history_page.dart';
import 'element_page.dart';
import 'discussion_page.dart';
import 'personal_info_page.dart';
import 'profile_page.dart';

class NavigationController {
  static void navigateToDashboard(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void navigateToArchive(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ArchivePage()),
    );
  }

  static void navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HistoryPage()),
    );
  }



  static void navigateToElement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ElementPage()),
    );
  }
  
  static void navigateToDiscussion(BuildContext context) {
    // Use push to maintain consistency with other navigation methods
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DiscussionPage()),
    );
  }
  
  static void navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }
}
