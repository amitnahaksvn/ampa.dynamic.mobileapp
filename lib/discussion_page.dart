import 'package:flutter/material.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'navigation_service.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({Key? key}) : super(key: key);

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  bool _isSidebarMinimized = false;
  final TextEditingController _searchController = TextEditingController();
  final NavigationService _navigationService = NavigationService();

  void _toggleSidebar() {
    setState(() {
      _isSidebarMinimized = !_isSidebarMinimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Discussion',
        isSidebarMinimized: _isSidebarMinimized,
        onToggleSidebar: _toggleSidebar,
        searchController: _searchController,
        onLogout: () {
          _navigationService.goToRoot();
        },
      ),
      body: Row(
        children: [
          AppSidebar(
            isSidebarMinimized: _isSidebarMinimized,
            currentPage: 'Discussion',
          ),
          Expanded(
            child: Center(
              child: Text(
                'Discussion Page Content',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
