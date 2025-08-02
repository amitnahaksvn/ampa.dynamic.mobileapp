import 'package:flutter/material.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'navigation_service.dart';

class ElementPage extends StatefulWidget {
  const ElementPage({Key? key}) : super(key: key);

  @override
  State<ElementPage> createState() => _ElementPageState();
}

class _ElementPageState extends State<ElementPage> {
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
        title: 'Element',
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
            currentPage: 'Element',
          ),
          const Expanded(
            child: Center(
              child: Text('Element Page', style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }
}
