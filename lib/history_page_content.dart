import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/services.dart';
import 'navigation_service.dart';

class HistoryPageContent extends StatefulWidget {
  const HistoryPageContent({Key? key}) : super(key: key);

  @override
  State<HistoryPageContent> createState() => _HistoryPageContentState();
}

class _HistoryPageContentState extends State<HistoryPageContent> {
  List<dynamic> _rawData = [];
  bool _isLoading = false;  // Changed from true to false
  bool _isInitialized = false;  // New flag to track if data has been loaded
  String? _error;
  NavigationService _navigationService = NavigationService();
  
  // Add a listener to handle tab changes
  void _onPageChanged(int pageIndex) {
    print("HistoryPageContent: _onPageChanged called with pageIndex=$pageIndex, isInitialized=$_isInitialized, mounted=$mounted");
    // If History tab is selected (index 2) and we've already initialized once
    if (pageIndex == 2 && mounted) {
      print("History tab selected, refreshing data");
      // If this is our first time seeing the history tab, mark as initialized
      if (!_isInitialized) {
        _isInitialized = true;
      }
      
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _loadRawData();
    }
  }

  @override
  void initState() {
    super.initState();
    print("HistoryPageContent: initState called");
    
    // Get a reference to the navigation service
    _navigationService = NavigationService();
    
    // Register listener for page changes
    _navigationService.onPageChanged = _onPageChanged;
    
    // Check if we're already on the history page (index 2)
    if (_navigationService.currentPageIndex == 2) {
      print("HistoryPageContent: Already on history page, triggering data load");
      _isInitialized = true;
      setState(() {
        _isLoading = true;
      });
      // Use post-frame callback to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRawData();
        }
      });
    }
  }
  
  @override
  void dispose() {
    // Clean up to avoid memory leaks
    _navigationService.onPageChanged = null;
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!mounted) {
      print("HistoryPageContent: Widget not mounted in didChangeDependencies");
      return;
    }
    
    // Check if this widget is currently visible in the page
    final NavigationService navigationService = NavigationService();
    final bool isCurrentlyVisible = navigationService.currentPageIndex == 2; // History is at index 2
    
    print("HistoryPageContent: didChangeDependencies called, currentPageIndex=${navigationService.currentPageIndex}, isCurrentlyVisible=$isCurrentlyVisible, _isInitialized=$_isInitialized");
    
    // Only load data when the widget is visible and hasn't been initialized yet
    if (!_isInitialized && isCurrentlyVisible) {
      print("History page is visible, loading data for the first time");
      _isInitialized = true;
      setState(() {
        _isLoading = true;
      });
      // Use post-frame callback to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRawData();
        }
      });
    }
  }

  Future<void> _loadRawData() async {
    print("Starting to load raw data...");
    if (!mounted) {
      print("HistoryPageContent: Widget not mounted at start of _loadRawData, returning early");
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not authenticated");
      if (!mounted) {
        print("HistoryPageContent: Widget not mounted after user check, returning early");
        return;
      }
      setState(() {
        _isLoading = false;
        _error = "User not authenticated";
      });
      return;
    }

    try {
      print("Requesting data from: ${ApiConfig.rawData}/list/${user.uid}");
      if (!mounted) {
        print("HistoryPageContent: Widget not mounted before API call, returning early");
        return;
      }
      setState(() {
        _isLoading = true;
      });
      
      final response = await http.get(
        Uri.parse('${ApiConfig.rawData}/list/${user.uid}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print("Response status: ${response.statusCode}");
      if (!mounted) {
        print("HistoryPageContent: Widget not mounted after API response, returning early");
        return;
      }
      
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        print("Received ${rawData is List ? rawData.length : 0} items");
        if (rawData is List && rawData.isNotEmpty) {
          print("First item timestamp: ${rawData.first['createdAt']}");
        }
        
        if (!mounted) return;
        setState(() {
          _rawData = rawData;
          _isLoading = false;
        });
      } else {
        print("Error loading shared content: Status ${response.statusCode}, Response: ${response.body}");
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = "Failed to load data: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text("Error: $_error", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadRawData();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!mounted) return;
        setState(() {
          _isLoading = true;
          _error = null;
        });
        await _loadRawData();
      },
      child: _rawData.isEmpty 
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        "No shared content yet",
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Share content from other apps to see it here",
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Pull down to refresh",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: _rawData.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = _rawData[index];
                
                // Parse date with error handling
                DateTime createdDate;
                try {
                  createdDate = DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String());
                } catch (e) {
                  print("Error parsing date: ${item['createdAt']}");
                  createdDate = DateTime.now();
                }
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getIconForApp(item['appName']), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              item['appName'] ?? 'Unknown App',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(createdDate),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['url'] ?? 'No URL',
                          style: const TextStyle(color: Colors.blue),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Device: ${item['deviceName'] ?? 'Unknown'}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              item['isProcessed'] ? 'Processed' : 'Pending',
                              style: TextStyle(
                                color: item['isProcessed'] ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      // Handle tap to show details or open URL
                      _showDetailDialog(context, item);
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForApp(String? appName) {
    if (appName == null) return Icons.link;
    
    switch (appName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter/x':
        return Icons.chat_bubble_outline;
      case 'facebook':
        return Icons.thumb_up;
      case 'youtube':
        return Icons.video_library;
      case 'linkedin':
        return Icons.business;
      default:
        return Icons.link;
    }
  }

  String _formatDate(DateTime date) {
    // Format with zero-padding for minutes
    final minutes = date.minute.toString().padLeft(2, '0');
    final hours = date.hour.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hours:$minutes';
  }

  void _showDetailDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconForApp(item['appName']), size: 24),
            const SizedBox(width: 8),
            Text(item['appName'] ?? 'Shared Content'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(item['url'] ?? 'No URL'),
              const SizedBox(height: 16),
              const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Device: ${item['deviceName'] ?? 'Unknown'}'),
              Text('Status: ${item['isProcessed'] ? 'Processed' : 'Pending'}'),
              Text('Created: ${_formatDate(DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String()))}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Copy URL to clipboard
              Clipboard.setData(ClipboardData(text: item['url'] ?? ''));
              Navigator.pop(context);
              showToast(
                "URL copied to clipboard",
                duration: const Duration(seconds: 2),
                position: ToastPosition.bottom,
                backgroundColor: Colors.green,
                textStyle: const TextStyle(color: Colors.white),
              );
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}
