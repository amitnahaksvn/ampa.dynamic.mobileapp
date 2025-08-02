import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'navigation_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isSidebarMinimized = false;
  final TextEditingController _searchController = TextEditingController();
  final NavigationService _navigationService = NavigationService();
  
  @override
  void initState() {
    super.initState();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarMinimized = !_isSidebarMinimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'History',
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
            currentPage: 'History',
          ),
          Expanded(
            child: Column(
              children: [
                // Main History Page Content
                Expanded(
                  child: Center(
                    child: Text(
                      'History Page Content',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
