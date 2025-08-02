# DynamicAMPA - Cross-Platform Mobile App

DynamicAMPA is a cross-platform mobile application built with Flutter that allows users to share content from other apps and view their shared history. The app features a clean, modern UI with a side navigation system and integrates with a custom backend API for data storage and retrieval.

## Features

- **User Authentication**: Secure login and user management using Firebase Authentication
- **Content Sharing**: Share content from other applications to the app
- **History View**: View all previously shared content in a chronological list
- **Responsive UI**: Works on both mobile and tablet devices with an adaptive sidebar
- **Real-time Updates**: Refreshes content automatically when tabs are changed
- **Pull-to-Refresh**: Manual refresh capability for content lists

## Technical Stack

### Frontend
- **Flutter**: Framework for building cross-platform mobile applications
- **Dart**: Programming language used with Flutter
- **Firebase Auth**: For user authentication and management
- **HTTP Package**: For API communication
- **JSON Serialization**: For parsing API responses
- **Provider Pattern**: For state management
- **Singleton Services**: For app-wide functionality (e.g., navigation)

### Backend Integration
- **REST API**: Custom backend API for data storage and retrieval
- **JWT Authentication**: For secure API communication
- **User Data Management**: Storing and retrieving user-specific content

## Project Structure

```
lib/
  ├── api_config.dart          # API endpoint configuration
  ├── app_header.dart          # App header component
  ├── app_routes.dart          # Application routes
  ├── app_sidebar.dart         # Sidebar navigation component
  ├── auth_wrapper.dart        # Authentication wrapper
  ├── firebase_config.dart     # Firebase configuration
  ├── history_page_content.dart # History page implementation
  ├── login_page.dart          # Login page
  ├── main_page.dart           # Main page structure
  ├── main.dart                # Application entry point
  ├── navigation_controller.dart # Navigation controller
  ├── navigation_service.dart  # Navigation service singleton
  └── share_intent_service.dart # Service for handling share intents
```

## API Integration

The application integrates with a custom backend API that provides:

1. **User Authentication**: `/api/UserAuth/upsert` endpoint for user registration and updates
2. **Content Storage**: `/api/UserRawData` endpoint for saving shared content
3. **Content Retrieval**: `/api/UserRawData/list/{userId}?isValid=true` endpoint for retrieving user's shared content

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Android Studio or VS Code with Flutter extensions
- Firebase account for authentication
- Backend API running (see API endpoints in api_config.dart)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dynamicampa.git
cd dynamicampa
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Navigation System

The app uses a custom navigation system with the following components:

1. **NavigationService**: A singleton service that manages page changes
2. **AppSidebar**: Sidebar component with navigation menu items
3. **IndexedStack**: Used in main.dart to efficiently switch between pages

This system allows for efficient tab-based navigation without recreating page components.

## Optimization Techniques

1. **Lazy Loading**: Data is only loaded when a page becomes visible
2. **Navigation Caching**: Pages are kept in memory using IndexedStack for quick switching
3. **Singleton Pattern**: Used for services to maintain app-wide state
4. **Efficient Rebuilds**: Minimizing unnecessary widget rebuilds
5. **Debug Logging**: Comprehensive logging for troubleshooting

## Troubleshooting

If you encounter issues with navigation:
- Check the console logs for navigation events
- Verify the API endpoints in api_config.dart
- Ensure Firebase is properly configured

## License

This project is licensed under the MIT License - see the LICENSE file for details.
