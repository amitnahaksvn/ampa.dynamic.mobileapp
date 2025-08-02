import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_config.dart';
import 'navigation_service.dart';
import 'app_routes.dart';

// Use conditional import to only import receive_sharing_intent on mobile platforms
import 'share_intent_platform.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  StreamSubscription? _intentDataStreamSubscription;
  final NavigationService _navigationService = NavigationService();
  
  // Singleton pattern
  factory ShareIntentService() {
    return _instance;
  }
  
  ShareIntentService._internal();

  void initialize() {
    if (kIsWeb) {
      print('Share intent service not supported on web');
      return;
    }
    
    // Call the platform-specific code through our platform helper
    initPlatformShareHandling(
      onInitialShare: (String? value) {
        if (value != null && value.isNotEmpty) {
          _processSharedText(value);
        }
      },
      onShareReceived: (String value) {
        if (value.isNotEmpty) {
          _processSharedText(value);
        }
      },
      onError: (dynamic error) {
        print("Share intent error: $error");
      },
      onSubscription: (StreamSubscription? subscription) {
        _intentDataStreamSubscription = subscription;
      }
    );
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }

  // For testing in browser or development environment
  Future<void> simulateSharedContent(String content) async {
    try {
      await _processSharedText(content);
    } catch (e) {
      print("Error in simulateSharedContent: $e");
      // Re-throw to allow calling code to handle the error
      rethrow;
    }
  }

  Future<void> _processSharedText(String sharedText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(
        "Please login to save shared content",
        duration: const Duration(seconds: 3),
        position: ToastPosition.bottom,
        backgroundColor: Colors.red,
        textStyle: const TextStyle(color: Colors.white),
      );
      return;
    }

    try {
      // Get device info
      String deviceType = await _getDeviceType();
      
      // Get app name (in a real app, you might want to parse this from the shared content)
      String appName = "External App";
      if (sharedText.contains("instagram.com")) {
        appName = "Instagram";
      } else if (sharedText.contains("twitter.com") || sharedText.contains("x.com")) {
        appName = "Twitter/X";
      } else if (sharedText.contains("facebook.com")) {
        appName = "Facebook";
      } else if (sharedText.contains("youtube.com")) {
        appName = "YouTube";
      } else if (sharedText.contains("linkedin.com")) {
        appName = "LinkedIn";
      }
      
      // Create payload
      final payload = {
        "uid": user.uid,
        "url": sharedText,
        "appName": appName,
        "isActive": true,
        "isProcessed": false,
        "deviceName": deviceType,
        "isValid": true
      };
      
      print("Sending shared content to API: ${jsonEncode(payload)}");
      print("API endpoint: ${ApiConfig.rawData}");
      
      // Send data to API
      final response = await http.post(
        Uri.parse(ApiConfig.rawData),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Content saved successfully with status: ${response.statusCode}");
        showToast(
          "Content saved successfully!",
          duration: const Duration(seconds: 3),
          position: ToastPosition.bottom,
          backgroundColor: Colors.green,
          textStyle: const TextStyle(color: Colors.white),
        );
        
        // Navigate to dashboard
        _navigationService.changePage(0); // Dashboard is index 0
      } else {
        print("API error: Status ${response.statusCode}, Response body: ${response.body}");
        throw Exception("Failed to save shared content: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      showToast(
        "Error saving shared content: $e",
        duration: const Duration(seconds: 3),
        position: ToastPosition.bottom,
        backgroundColor: Colors.red,
        textStyle: const TextStyle(color: Colors.white),
      );
      print("Error processing shared text: $e");
    }
  }
  
  Future<String> _getDeviceType() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      return "Web";
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return "Android (${androidInfo.model})";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return "iOS (${iosInfo.model})";
    } else {
      return "Other";
    }
  }
}
