import 'package:flutter/material.dart';
import 'login_page.dart';
import 'personal_info_page.dart';
import 'profile_page.dart';
import 'profile_page_content.dart';
import 'history_page_content.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_config.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'personal_info_guard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'element_page.dart';
import 'navigation_service.dart';
import 'app_routes.dart';
import 'share_intent_service.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Handle Firebase initialization for both web and mobile
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with proper configuration from firebase_config.dart
    await Firebase.initializeApp(
      options: FirebaseConfig.platformOptions,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue with the app even if Firebase fails to initialize
  }
  
  // Initialize the share intent service
  if (!kIsWeb) {
    ShareIntentService().initialize();
  }
  
  runApp(const MyApp());
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the singleton instance
    final navigationService = NavigationService();
    
    return OKToast(
      child: MaterialApp(
        title: 'Dynamic AmPa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        navigatorKey: navigationService.navigatorKey,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          // A function to handle all routes in the application
          print('Navigating to: ${settings.name}');
          
          // Check if it's one of our content routes and extract the page index
          int pageIndex = 0;
          if (settings.name == AppRoutes.archive) {
            pageIndex = 1;
          } else if (settings.name == AppRoutes.history) {
            pageIndex = 2;
          } else if (settings.name == AppRoutes.element) {
            pageIndex = 3;
          } else if (settings.name == AppRoutes.discussion) {
            pageIndex = 4;
          } else if (settings.name == AppRoutes.profile) {
            pageIndex = 5;
          }
          
          // Handle authentication routes
          if (settings.name == AppRoutes.login) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginPage(),
            );
          }
          
          // For root route, return the auth handler
          if (settings.name == '/' || settings.name == AppRoutes.dashboard) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const RootAuthHandler(),
            );
          }
          
          // For all other content routes, return MyHomePage with the appropriate page index
          // This ensures we're not creating new instances for each navigation
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => MyHomePage(
              title: settings.name?.substring(1) ?? 'Home',
              initialPageIndex: pageIndex,
            ),
          );
        },
      ),
    );
  }
}

Future<bool> _checkUserAuth(User user) async {
  try {
    // Make sure we have a valid UID
    if (user.uid.isEmpty) {
      return false;
    }
    
    // Directly upsert user data without checking if it exists first
    try {
      final upsertUrl = Uri.parse('${ApiConfig.userAuth}/upsert');
      
      // Prepare full user data for upsert
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'displayName': user.displayName ?? '',
        'lastSignInTime': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      
      final upsertRes = await http.post(
        upsertUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));
      
      if (upsertRes.statusCode == 200 || upsertRes.statusCode == 201 || upsertRes.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> _checkPersonalInfo(User user) async {
  try {
    // Make sure we have a valid UID
    if (user.uid.isEmpty) {
      return false;
    }
    
    final url = Uri.parse('${ApiConfig.userInfo}/${user.uid}');
    
    http.Response? res;
    try {
      res = await http.get(url).timeout(const Duration(seconds: 10));
    } catch (e) {
      return false;
    }
    
    if (res.statusCode == 200) {
      try {
        if (res.body.isEmpty) {
          return false;
        }
        
        final data = jsonDecode(res.body);
        
        // Check if required fields exist and are not null or empty
        bool hasRequiredInfo = data['firstName'] != null && data['firstName'].toString().isNotEmpty && 
                              data['lastName'] != null && data['lastName'].toString().isNotEmpty && 
                              data['gender'] != null && data['gender'].toString().isNotEmpty;
                              
        return hasRequiredInfo;
      } catch (e) {
        return false;
      }
    } else if (res.statusCode == 404) {
      return false;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

// A dedicated widget to handle auth state, separated from route definition
class RootAuthHandler extends StatefulWidget {
  const RootAuthHandler({Key? key}) : super(key: key);

  @override
  State<RootAuthHandler> createState() => _RootAuthHandlerState();
}

class _RootAuthHandlerState extends State<RootAuthHandler> {
  @override
  void initState() {
    super.initState();
    // Add listener to track auth state changes
    _auth.authStateChanges().listen((User? user) {
      // We'll handle auth state changes in the StreamBuilder
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
                  const SizedBox(height: 20),
                  const Text("Authentication Error", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "There was an error with the authentication process: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          
          return FutureBuilder<bool>(
            future: _checkUserAuth(user),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text('Verifying user account...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }
              
              // If user_auth check is successful, check for personal info
              if (authSnapshot.hasData && authSnapshot.data == true) {
                return FutureBuilder<bool>(
                  future: _checkPersonalInfo(user),
                  builder: (context, infoSnapshot) {
                    if (infoSnapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text('Checking profile information...', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // If personal info exists, go to dashboard
                    if (infoSnapshot.hasData && infoSnapshot.data == true) {
                      return MyHomePage(title: 'Home');
                    } else {
                      // Personal info doesn't exist, show form to collect it
                      return PersonalInfoPage(
                        user: user,
                        onComplete: () {
                          // Use WidgetsBinding to schedule after frame
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            NavigationService().replaceTo(AppRoutes.dashboard);
                          });
                        },
                      );
                    }
                  },
                );
              } else {
                // If there was an error with user_auth
                return Scaffold(
                  body: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
                          const SizedBox(height: 20),
                          const Text("Error creating user account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            "Failed to create or verify user authentication record.",
                            style: TextStyle(color: Colors.red[700], fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("User Information:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text("User ID: ${user.uid}", style: TextStyle(fontFamily: 'monospace')),
                                Text("Phone: ${user.phoneNumber ?? 'Not provided'}", style: TextStyle(fontFamily: 'monospace')),
                                Text("Email: ${user.email ?? 'Not provided'}", style: TextStyle(fontFamily: 'monospace')),
                                Text("Name: ${user.displayName ?? 'Not provided'}", style: TextStyle(fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Please check the console logs for detailed error information. "
                            "You may need to check your internet connection or contact support.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"),
                                onPressed: () async {
                                  // Try again
                                  if (context.mounted) {
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(width: 15),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.logout),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                                label: const Text("Return to Login"),
                                onPressed: () async {
                                  await _auth.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.login,
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ));
              }
            },
          );
        } else {
          // User is not authenticated
          return const LoginPage();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final int initialPageIndex;
  
  const MyHomePage({super.key, required this.title, this.initialPageIndex = 0});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isSidebarMinimized = false;
  final TextEditingController _searchController = TextEditingController();
  final NavigationService _navigationService = NavigationService();
  late int _selectedPage;
  
  // User data logic
  bool _userLoadError = false;
  String? _userPhoneNumber;
  String? _userId;
  
  @override
  void initState() {
    super.initState();
    _selectedPage = widget.initialPageIndex;
    _loadUserData();
    
    // Set up the navigation service to update our local state
    print("Setting onPageChanged callback on NavigationService");
    _navigationService.onPageChanged = (pageIndex) {
      print("MyHomePage: onPageChanged callback called with pageIndex=$pageIndex");
      // Only setState if the widget is still mounted
      if (mounted) {
        print("MyHomePage: Widget is mounted, updating state");
        setState(() {
          _selectedPage = pageIndex;
          print("MyHomePage: _selectedPage set to $_selectedPage");
        });
      } else {
        print("MyHomePage: Widget is NOT mounted!");
      }
    };
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _navigationService.onPageChanged = null;
    
    // No need to dispose ShareIntentService here as it's a singleton
    // and should remain active for the app's lifetime
    
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp(options: FirebaseConfig.platformOptions);
      }
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _userPhoneNumber = currentUser.phoneNumber;
          _userId = currentUser.uid;
          _userLoadError = false;
        });
      }
    } catch (e) {
      setState(() {
        _userLoadError = true;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarMinimized = !_isSidebarMinimized;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      
      // Clear user data completely
      setState(() {
        _userPhoneNumber = null;
        _userId = null;
        _userLoadError = false;
        _counter = 0; // Reset counter as well
      });
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Dismiss the loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        // Use Future.microtask to schedule navigation after the build phase
        Future.microtask(() {
          // Navigate to login and remove all previous routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false, // This removes all previous routes
          );
        });
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  
  // Test method to simulate sharing content (since we can't easily test real sharing in the browser)
  void _testShareContent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in')),
        );
        return;
      }
      
      // Get the share intent service singleton
      final shareService = ShareIntentService();
      
      // Use the reflection to access the private method
      // This is just for testing - normally we'd let the system trigger this
      await shareService.simulateSharedContent("https://example.com/shared-content");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share intent processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error in test share content: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  String _getPageTitle() {
    switch (_selectedPage) {
      case 0: return 'Dashboard';
      case 1: return 'Archive';
      case 2: return 'History';
      case 3: return 'Element';
      case 4: return 'Discussion';
      case 5: return 'Profile';
      default: return 'Dashboard';
    }
  }

  // Build the Dashboard page content
  Widget _buildDashboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome ${_userLoadError ? "User" : (_userPhoneNumber ?? "User")}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          if (_userId != null && _userId!.isNotEmpty)
            Text(
              'User ID: $_userId',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 20),
          Text(
            'This is the dashboard page.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('You have pushed the button this many times:'),
          Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          // Add a test button for simulating sharing
          if (kIsWeb) // Only show in web for testing
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("Test Share Intent"),
              onPressed: _testShareContent,
            ),
        ],
      ),
    );
  }

  // Content for other pages
  Widget _buildArchiveContent() => const Center(child: Text('Archive Content', style: TextStyle(fontSize: 24)));
  Widget _buildHistoryContent() => const HistoryPageContent();
  Widget _buildElementContent() => const Center(child: Text('Element Content', style: TextStyle(fontSize: 24)));
  Widget _buildDiscussionContent() => const Center(child: Text('Discussion Content', style: TextStyle(fontSize: 24)));
  
  // Build profile content without the duplicate header and sidebar
  Widget _buildProfileContent() => const ProfilePageContent();

  // Get the current page content based on _selectedPage
  Widget _buildCurrentPageContent() {
    print("MyHomePage: Building content for page $_selectedPage");
    switch (_selectedPage) {
      case 0: return _buildDashboard();
      case 1: return _buildArchiveContent();
      case 2: return _buildHistoryContent();
      case 3: return _buildElementContent();
      case 4: return _buildDiscussionContent();
      case 5: return _buildProfileContent();
      default: return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building MyHomePage with _selectedPage=$_selectedPage");
    return Scaffold(
      appBar: AppHeader(
        title: _getPageTitle(),
        isSidebarMinimized: _isSidebarMinimized,
        onToggleSidebar: _toggleSidebar,
        searchController: _searchController,
        onLogout: () => _handleLogout(context),
      ),
      body: Row(
        children: [
          AppSidebar(
            isSidebarMinimized: _isSidebarMinimized,
            currentPage: _getPageTitle(),
            navigationService: _navigationService,
          ),
          Expanded(
            // Using a ValueKey forces the widget to rebuild when _selectedPage changes
            key: ValueKey<int>(_selectedPage),
            child: _buildCurrentPageContent(),
          ),
        ],
      ),
      floatingActionButton: _selectedPage == 0 ? FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
