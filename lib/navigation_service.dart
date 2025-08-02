import 'package:flutter/material.dart';
import 'app_routes.dart';

// A service that manages navigation throughout the app
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  
  // Singleton pattern
  factory NavigationService() {
    return _instance;
  }
  
  NavigationService._internal();
  
  // Global key for navigator
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Current page index for single-page application functionality
  int _currentPageIndex = 0;
  
  // Callback for when the page index changes (for single-page app behavior)
  Function(int)? onPageChanged;

  // Get the current page index
  int get currentPageIndex => _currentPageIndex;
  
  // Change page in single-page mode - ONLY updates the index, no URL changes
  void changePage(int pageIndex) {
    print("NavigationService: Changing page to $pageIndex");
    
    // Update directly without microtask
    _currentPageIndex = pageIndex;
    print("NavigationService: Page index updated to $_currentPageIndex");
    
    if (onPageChanged != null) {
      print("NavigationService: Calling onPageChanged callback");
      onPageChanged!(pageIndex);
    } else {
      print("NavigationService: WARNING - onPageChanged callback is null!");
    }
  }
  
  // For full navigation to a named route (creates new instance)
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    // Use Future.microtask to ensure navigation doesn't happen during build
    return Future.microtask(() => 
      navigatorKey.currentState!.pushNamed(routeName, arguments: arguments)
    );
  }
  
  // Function to replace the current route
  Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    // Use Future.microtask to ensure navigation doesn't happen during build
    return Future.microtask(() => 
      navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments)
    );
  }
  
  // Function to go back
  void goBack() {
    return navigatorKey.currentState!.pop();
  }
  
  // Function to go back to the first route
  void goToRoot() {
    return navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
}
