import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'navigation_service.dart';
import 'navigation_controller.dart';
import 'app_routes.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSidebarMinimized;
  final VoidCallback onToggleSidebar;
  final TextEditingController searchController;
  final VoidCallback onLogout;

  const AppHeader({
    Key? key,
    required this.title,
    required this.isSidebarMinimized,
    required this.onToggleSidebar,
    required this.searchController,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect to login if user is not authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Row(
        children: [
          // Logo
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSidebarMinimized
                ? Container(
                    key: const ValueKey('smallLogo'),
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      'assets/logo/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  )
                : Container(
                    key: const ValueKey('largeLogo'),
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      'assets/logo/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // User first name (left side)
          if ((user.displayName != null && user.displayName!.isNotEmpty) || (user.email != null && user.email!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                user.displayName != null && user.displayName!.isNotEmpty
                    ? user.displayName!
                    : (user.email ?? ''),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
          IconButton(
            icon: Icon(isSidebarMinimized ? Icons.menu : Icons.menu_open, color: Colors.white),
            onPressed: onToggleSidebar,
            tooltip: isSidebarMinimized ? 'Expand sidebar' : 'Collapse sidebar',
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 320,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search...',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onSelected: (value) async {
            if (value == 'logout') {
              onLogout();
            } else if (value == 'profile') {
              Future.microtask(() => NavigationService().changePage(5));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('My Profile'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
