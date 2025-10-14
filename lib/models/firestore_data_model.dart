// Firestore Data Model Documentation
// This file documents the Firestore collections and their structure

class FirestoreDataModel {
  // Collection: users
  // Documents: User profiles for both teachers and students
  static const String usersCollection = 'users';
  
  // User document structure:
  static const Map<String, dynamic> userDocument = {
    'uid': 'string', // Firebase Auth UID
    'email': 'string',
    'name': 'string',
    'userType': 'string', // 'teacher' or 'student'
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Collection: subjects
  // Documents: Subject information created by teachers
  static const String subjectsCollection = 'subjects';
  
  // Subject document structure:
  static const Map<String, dynamic> subjectDocument = {
    'id': 'string', // Document ID
    'name': 'string',
    'description': 'string',
    'teacherId': 'string', // Reference to users collection
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Collection: lectures
  // Documents: Lecture sessions created by teachers
  static const String lecturesCollection = 'lectures';
  
  // Lecture document structure:
  static const Map<String, dynamic> lectureDocument = {
    'id': 'string', // Document ID
    'title': 'string',
    'description': 'string',
    'subjectId': 'string', // Reference to subjects collection
    'subjectName': 'string',
    'teacherId': 'string', // Reference to users collection
    'date': 'string', // Format: 'YYYY-MM-DD'
    'time': 'string', // Format: 'HH:MM'
    'dateTime': 'timestamp', // Combined date and time
    'location': 'string', // Optional
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Collection: attendance_sessions
  // Documents: Active attendance sessions
  static const String attendanceSessionsCollection = 'attendance_sessions';
  
  // Attendance session document structure:
  static const Map<String, dynamic> attendanceSessionDocument = {
    'id': 'string', // Document ID
    'lectureId': 'string', // Reference to lectures collection
    'lectureTitle': 'string',
    'subjectId': 'string', // Reference to subjects collection
    'subjectName': 'string',
    'teacherId': 'string', // Reference to users collection
    'date': 'string', // Format: 'YYYY-MM-DD'
    'time': 'string', // Format: 'HH:MM'
    'startTime': 'timestamp',
    'endTime': 'timestamp', // null if still active
    'isActive': 'boolean',
    'location': 'map', // {latitude: number, longitude: number}
    'radius': 'number', // in meters
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Collection: attendance_records
  // Documents: Individual student attendance records
  static const String attendanceRecordsCollection = 'attendance_records';
  
  // Attendance record document structure:
  static const Map<String, dynamic> attendanceRecordDocument = {
    'id': 'string', // Document ID
    'sessionId': 'string', // Reference to attendance_sessions collection
    'studentId': 'string', // Reference to users collection
    'timestamp': 'timestamp',
    'location': 'map', // {latitude: number, longitude: number}
    'isPresent': 'boolean',
    'createdAt': 'timestamp',
  };

  // Collection: announcements
  // Documents: Announcements, messages, and assignments
  static const String announcementsCollection = 'announcements';
  
  // Announcement document structure:
  static const Map<String, dynamic> announcementDocument = {
    'id': 'string', // Document ID
    'title': 'string',
    'content': 'string',
    'type': 'string', // 'announcement', 'message', or 'assignment'
    'teacherId': 'string', // Reference to users collection
    'subjectId': 'string', // Optional - Reference to subjects collection
    'subjectName': 'string', // Optional
    'targetStudentIds': 'array', // Optional - Array of student IDs, null means all students
    'dueDate': 'timestamp', // Optional - For assignments
    'points': 'number', // Optional - For assignments
    'isActive': 'boolean', // For soft delete
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Collection: announcement_reads
  // Documents: Track which students have read which announcements
  static const String announcementReadsCollection = 'announcement_reads';
  
  // Announcement read document structure:
  static const Map<String, dynamic> announcementReadDocument = {
    'id': 'string', // Format: '${announcementId}_${studentId}'
    'announcementId': 'string', // Reference to announcements collection
    'studentId': 'string', // Reference to users collection
    'readAt': 'timestamp',
  };

  // Collection: subject_enrollments
  // Documents: Track which students are enrolled in which subjects
  static const String subjectEnrollmentsCollection = 'subject_enrollments';
  
  // Subject enrollment document structure:
  static const Map<String, dynamic> subjectEnrollmentDocument = {
    'id': 'string', // Document ID
    'subjectId': 'string', // Reference to subjects collection
    'studentId': 'string', // Reference to users collection
    'enrolledAt': 'timestamp',
  };

  // Collection: notes
  // Documents: Student notes (including OCR-generated notes)
  static const String notesCollection = 'notes';
  
  // Note document structure:
  static const Map<String, dynamic> noteDocument = {
    'id': 'string', // Document ID
    'title': 'string',
    'content': 'string',
    'studentId': 'string', // Reference to users collection
    'subject': 'string', // Optional
    'tags': 'array', // Optional - Array of strings
    'isFromOcr': 'boolean', // true if generated from OCR
    'createdAt': 'timestamp',
    'updatedAt': 'timestamp',
  };

  // Indexes required for Firestore queries:
  static const List<Map<String, dynamic>> requiredIndexes = [
    // For announcements queries
    {
      'collection': 'announcements',
      'fields': ['teacherId', 'isActive', 'createdAt'],
      'order': ['teacherId', 'isActive', 'createdAt desc'],
    },
    {
      'collection': 'announcements',
      'fields': ['isActive', 'createdAt'],
      'order': ['isActive', 'createdAt desc'],
    },
    
    // For attendance queries
    {
      'collection': 'attendance_sessions',
      'fields': ['teacherId', 'isActive', 'startTime'],
      'order': ['teacherId', 'isActive', 'startTime desc'],
    },
    {
      'collection': 'attendance_records',
      'fields': ['studentId', 'timestamp'],
      'order': ['studentId', 'timestamp desc'],
    },
    
    // For notes queries
    {
      'collection': 'notes',
      'fields': ['studentId', 'createdAt'],
      'order': ['studentId', 'createdAt desc'],
    },
    {
      'collection': 'notes',
      'fields': ['studentId', 'subject', 'createdAt'],
      'order': ['studentId', 'subject', 'createdAt desc'],
    },
    
    // For subject enrollments
    {
      'collection': 'subject_enrollments',
      'fields': ['subjectId', 'studentId'],
      'order': ['subjectId', 'studentId'],
    },
    {
      'collection': 'subject_enrollments',
      'fields': ['studentId', 'subjectId'],
      'order': ['studentId', 'subjectId'],
    },
  ];

  // Helper methods for creating document references
  static String getUserDocumentPath(String uid) {
    return '$usersCollection/$uid';
  }

  static String getSubjectDocumentPath(String subjectId) {
    return '$subjectsCollection/$subjectId';
  }

  static String getLectureDocumentPath(String lectureId) {
    return '$lecturesCollection/$lectureId';
  }

  static String getAttendanceSessionDocumentPath(String sessionId) {
    return '$attendanceSessionsCollection/$sessionId';
  }

  static String getAttendanceRecordDocumentPath(String recordId) {
    return '$attendanceRecordsCollection/$recordId';
  }

  static String getAnnouncementDocumentPath(String announcementId) {
    return '$announcementsCollection/$announcementId';
  }

  static String getAnnouncementReadDocumentPath(String announcementId, String studentId) {
    return '$announcementReadsCollection/${announcementId}_$studentId';
  }

  static String getSubjectEnrollmentDocumentPath(String enrollmentId) {
    return '$subjectEnrollmentsCollection/$enrollmentId';
  }

  static String getNoteDocumentPath(String noteId) {
    return '$notesCollection/$noteId';
  }
}

// Data validation rules
class DataValidationRules {
  // User validation
  static bool isValidUserType(String userType) {
    return ['teacher', 'student'].contains(userType);
  }

  // Announcement validation
  static bool isValidAnnouncementType(String type) {
    return ['announcement', 'message', 'assignment'].contains(type);
  }

  // Date validation
  static bool isValidDateString(String date) {
    // Format: YYYY-MM-DD
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(date)) return false;
    
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Time validation
  static bool isValidTimeString(String time) {
    // Format: HH:MM
    final regex = RegExp(r'^\d{2}:\d{2}$');
    if (!regex.hasMatch(time)) return false;
    
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
    } catch (e) {
      return false;
    }
  }

  // Location validation
  static bool isValidLocation(Map<String, dynamic> location) {
    if (!location.containsKey('latitude') || !location.containsKey('longitude')) {
      return false;
    }
    
    final lat = location['latitude'];
    final lng = location['longitude'];
    
    return lat is num && lng is num && 
           lat >= -90 && lat <= 90 && 
           lng >= -180 && lng <= 180;
  }
}
