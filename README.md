# EduPortal - Student Teacher Portal

A comprehensive Flutter application for managing student-teacher interactions with location-based attendance tracking.

## Features

### For Teachers:
- **Authentication**: Secure login/signup system
- **Subject Management**: Add and manage subjects
- **Lecture Scheduling**: Create and schedule lectures
- **Attendance Taking**: Location-based attendance system
- **Attendance Report**: Generates report for attendance
- **Dashboard**: Overview of all subjects and lectures
- **Announcements**: Teacher can send messages to all students or any particular student
- 

### For Students:
- **Authentication**: Student login system
- **Attendance Popups**: Automatic attendance prompts when in range
- **Attendance History**: View past attendance records
- **Location Services**: Automatic location detection
- **OCR Service**: OCR is used to scan notes
- **Attendance Report**: Generates report for attendance

## Technical Features

- **Firebase Integration**: Real-time database with Firestore
- **Location Services**: GPS-based attendance tracking
- **Modern UI**: Clean, responsive design with Material Design
- **State Management**: Provider pattern for efficient state handling
- **Real-time Updates**: Live attendance session monitoring


usage guide

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


### Collections

- **users**: User profiles (teachers/students)
- **subjects**: Subject information
- **lectures**: Lecture schedules
- **attendance_sessions**: Active attendance sessions
- **attendance_records**: Individual attendance records


