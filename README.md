# EduPortal - Student Teacher Portal

A comprehensive Flutter application for managing student-teacher interactions with location-based attendance tracking.

## Features

### For Teachers:
- **Authentication**: Secure login/signup system
- **Subject Management**: Add and manage subjects
- **Lecture Scheduling**: Create and schedule lectures
- **Attendance Taking**: Location-based attendance system
- **Dashboard**: Overview of all subjects and lectures

### For Students:
- **Authentication**: Student login system
- **Attendance Popups**: Automatic attendance prompts when in range
- **Attendance History**: View past attendance records
- **Location Services**: Automatic location detection

## Technical Features

- **Firebase Integration**: Real-time database with Firestore
- **Location Services**: GPS-based attendance tracking
- **Modern UI**: Clean, responsive design with Material Design
- **State Management**: Provider pattern for efficient state handling
- **Real-time Updates**: Live attendance session monitoring

## Setup Instructions

### 1. Firebase Configuration ✅ COMPLETED

Your Firebase project is already configured with:
- **Project ID**: `eduportal-b3ca3`
- **Android App ID**: `1:350383415335:android:25f5a371c100b2400fae02`
- **API Key**: `AIzaSyB5UFVSzWjhsyBIj8N8ecde-ixnq6dgXUs`

### 2. Required Firebase Services

Make sure these services are enabled in your Firebase Console:

1. **Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable "Email/Password"

2. **Firestore Database**:
   - Go to Firebase Console → Firestore Database
   - Create database in test mode
   - Choose your region

### 3. Download google-services.json

**IMPORTANT**: Download the `google-services.json` file:
1. Go to Firebase Console → Project Settings → Your Android app
2. Click "Download google-services.json"
3. Place it in: `android/app/google-services.json`

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

## Usage Guide

### Teacher Workflow

1. **Sign Up/Login**: Create a teacher account
2. **Add Subjects**: Create subjects you teach
3. **Schedule Lectures**: Add lectures for each subject
4. **Take Attendance**: 
   - Select subject and lecture
   - Set attendance range (10-200 meters)
   - Start attendance session
   - Students within range will receive popup notifications
   - Stop session when done

### Student Workflow

1. **Sign Up/Login**: Create a student account
2. **Enable Location**: Allow location permissions
3. **Automatic Attendance**: When teacher starts attendance session:
   - Students within range receive popup
   - Tap "Mark Present" to confirm attendance
   - View attendance history in dashboard

## Database Structure

### Collections

- **users**: User profiles (teachers/students)
- **subjects**: Subject information
- **lectures**: Lecture schedules
- **attendance_sessions**: Active attendance sessions
- **attendance_records**: Individual attendance records

### Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Teachers can manage their subjects and lectures
    match /subjects/{subjectId} {
      allow read, write: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
    }
    
    match /lectures/{lectureId} {
      allow read, write: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
    }
    
    // Attendance sessions
    match /attendance_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
    }
    
    // Attendance records
    match /attendance_records/{recordId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Permissions

### Android
- `ACCESS_FINE_LOCATION`: For precise location tracking
- `ACCESS_COARSE_LOCATION`: For approximate location
- `INTERNET`: For Firebase connectivity

### iOS
- Location permissions are handled automatically by the app

## Troubleshooting

### Common Issues

1. **Location not working**: Ensure location permissions are granted
2. **Firebase connection failed**: Check your Firebase configuration
3. **Attendance popup not showing**: Verify you're within the teacher's range
4. **Build errors**: Run `flutter clean` and `flutter pub get`

### Debug Mode

Enable debug logging by adding this to your main.dart:

```dart
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // Enable debug logging
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## Future Enhancements

- Push notifications for attendance sessions
- Offline support for attendance records
- Advanced analytics and reporting
- Multi-language support
- Dark mode theme
- Export attendance reports

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please create an issue in the repository or contact the development team.