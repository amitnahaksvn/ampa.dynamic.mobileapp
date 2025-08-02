import 'package:flutter/material.dart';
import 'navigation_service.dart';
import 'app_routes.dart';

class AppSidebar extends StatelessWidget {
  final bool isSidebarMinimized;
  final String currentPage;
  final NavigationService navigationService;

  AppSidebar({
    Key? key,
    required this.isSidebarMinimized,
    this.currentPage = 'Dashboard',
    NavigationService? navigationService,
  }) : this.navigationService = navigationService ?? NavigationService(),
      super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSidebarMinimized ? 70 : 220,
      color: Theme.of(context).colorScheme.inversePrimary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (!isSidebarMinimized) _buildNavigationPath(),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: Dashboard tapped");
              // Use direct call instead of Future.microtask
              NavigationService().changePage(0);
            },
            dense: true,
            selected: currentPage == 'Dashboard',
          ),
          ListTile(
            leading: const Icon(Icons.archive, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('Archive', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: Archive tapped");
              NavigationService().changePage(1);
            },
            dense: true,
            selected: currentPage == 'Archive',
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('History', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: History tapped");
              navigationService.changePage(2);
            },
            dense: true,
            selected: currentPage == 'History',
          ),
          ListTile(
            leading: const Icon(Icons.layers, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('Element', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: Element tapped");
              navigationService.changePage(3);
            },
            dense: true,
            selected: currentPage == 'Element',
          ),
          ListTile(
            leading: const Icon(Icons.forum, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('Discussion', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: Discussion tapped");
              navigationService.changePage(4);
            },
            dense: true,
            selected: currentPage == 'Discussion',
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: isSidebarMinimized ? null : const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              print("AppSidebar: Profile tapped");
              navigationService.changePage(5);
            },
            dense: true,
            selected: currentPage == 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPath() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigation Path:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.home, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Home',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 16),
              Flexible(
                child: Text(
                  currentPage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
        ],
      ),
    );
  }
}
