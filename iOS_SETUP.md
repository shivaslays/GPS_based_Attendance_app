# iOS Setup Guide

This guide explains how to set up and run the Flutter app on iOS devices and simulators.

## Prerequisites

1. **macOS**: iOS development requires macOS with Xcode
2. **Xcode**: Install Xcode from the Mac App Store (latest version recommended)
3. **iOS Simulator**: Comes with Xcode
4. **Apple Developer Account**: Required for running on physical devices (free account works for development)

## Project Setup

### 1. iOS Project Structure
The iOS project has been configured with:
- ✅ iOS project files created (`ios/` directory)
- ✅ Firebase configuration (`ios/Runner/GoogleService-Info.plist`)
- ✅ Permissions configured (`ios/Runner/Info.plist`)
- ✅ Dependencies installed via CocoaPods

### 2. Firebase Configuration
The app uses Firebase for:
- Authentication (sign in/sign up)
- Firestore database (notes, attendance, announcements)
- Real-time data synchronization

**Firebase files configured:**
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration
- `ios/Runner/AppDelegate.swift` - Firebase initialization

### 3. Permissions
The following permissions are configured in `ios/Runner/Info.plist`:
- **Camera**: For scanning notes and documents
- **Photo Library**: For selecting images
- **Location**: For attendance tracking
- **Microphone**: For camera functionality

## Running the App

### Option 1: Using Xcode (Recommended)
1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select a simulator from the device dropdown
3. Click the "Run" button (▶️) or press `Cmd+R`

### Option 2: Using Flutter CLI
```bash
# List available devices
flutter devices

# Run on iOS simulator
flutter run -d ios

# Run on specific device
flutter run -d "iPhone 16e"
```

### Option 3: Build Only
```bash
# Build for simulator
flutter build ios --simulator

# Build for device (requires code signing)
flutter build ios --release
```

## Troubleshooting

### Simulator Issues
If you encounter "Unable to find a destination" errors:

1. **Restart Simulator**:
   ```bash
   xcrun simctl shutdown all
   xcrun simctl boot "iPhone 16e"
   ```

2. **Use Xcode**: Open `ios/Runner.xcworkspace` and run from Xcode

3. **Clean and Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install
   ```

### Code Signing Issues
For physical device deployment:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" project
3. Go to "Signing & Capabilities"
4. Select your Development Team
5. Ensure Bundle Identifier is unique

### Dependency Conflicts
If you encounter CocoaPods conflicts:
```bash
cd ios
pod deintegrate
pod install
```

## Current Features Status

### ✅ Working on iOS:
- Firebase Authentication
- Firestore Database
- Camera and Photo Library access
- Location services
- Push notifications
- Announcements system
- Attendance tracking
- Notes management

### ⚠️ Temporarily Disabled:
- **OCR Text Recognition**: Temporarily disabled due to dependency conflicts
  - Manual note entry still works
  - Camera functionality works for other purposes

## Dependencies

### Core Dependencies:
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: Database operations
- `camera`: Camera functionality
- `image_picker`: Image selection
- `geolocator`: Location services
- `permission_handler`: Permission management

### iOS-Specific:
- CocoaPods for dependency management
- Firebase iOS SDK
- iOS Camera framework
- Core Location framework

## File Structure

```
ios/
├── Runner/
│   ├── AppDelegate.swift          # Firebase initialization
│   ├── Info.plist                # Permissions and app config
│   ├── GoogleService-Info.plist  # Firebase iOS config
│   └── Assets.xcassets/          # App icons and images
├── Flutter/                      # Flutter engine config
├── Podfile                       # CocoaPods dependencies
└── Runner.xcworkspace           # Xcode workspace
```

## Next Steps

1. **Enable OCR**: Research and implement iOS-compatible ML Kit version
2. **Test on Device**: Set up code signing for physical device testing
3. **App Store**: Prepare for App Store submission (requires paid Apple Developer account)

## Support

For iOS-specific issues:
1. Check Xcode console for detailed error messages
2. Verify all permissions are granted in iOS Settings
3. Ensure Firebase project is properly configured
4. Check Apple Developer account status for device deployment

