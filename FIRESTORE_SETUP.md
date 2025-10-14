# Firestore Data Model Setup Guide

This guide explains how to set up the Firestore database for the EduPortal application.

## Collections Overview

The application uses the following Firestore collections:

### 1. `users`
Stores user profiles for both teachers and students.

**Document Structure:**
```json
{
  "uid": "string",
  "email": "string", 
  "name": "string",
  "userType": "string", // "teacher" or "student"
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 2. `subjects`
Stores subject information created by teachers.

**Document Structure:**
```json
{
  "name": "string",
  "description": "string",
  "teacherId": "string", // Reference to users collection
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 3. `lectures`
Stores lecture sessions created by teachers.

**Document Structure:**
```json
{
  "title": "string",
  "description": "string",
  "subjectId": "string", // Reference to subjects collection
  "subjectName": "string",
  "teacherId": "string", // Reference to users collection
  "date": "string", // Format: "YYYY-MM-DD"
  "time": "string", // Format: "HH:MM"
  "dateTime": "timestamp", // Combined date and time
  "location": "string", // Optional
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4. `attendance_sessions`
Stores active attendance sessions.

**Document Structure:**
```json
{
  "lectureId": "string", // Reference to lectures collection
  "lectureTitle": "string",
  "subjectId": "string", // Reference to subjects collection
  "subjectName": "string",
  "teacherId": "string", // Reference to users collection
  "date": "string", // Format: "YYYY-MM-DD"
  "time": "string", // Format: "HH:MM"
  "startTime": "timestamp",
  "endTime": "timestamp", // null if still active
  "isActive": "boolean",
  "location": {
    "latitude": "number",
    "longitude": "number"
  },
  "radius": "number", // in meters
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 5. `attendance_records`
Stores individual student attendance records.

**Document Structure:**
```json
{
  "sessionId": "string", // Reference to attendance_sessions collection
  "studentId": "string", // Reference to users collection
  "timestamp": "timestamp",
  "location": {
    "latitude": "number",
    "longitude": "number"
  },
  "isPresent": "boolean",
  "createdAt": "timestamp"
}
```

### 6. `announcements`
Stores announcements, messages, and assignments.

**Document Structure:**
```json
{
  "title": "string",
  "content": "string",
  "type": "string", // "announcement", "message", or "assignment"
  "teacherId": "string", // Reference to users collection
  "subjectId": "string", // Optional - Reference to subjects collection
  "subjectName": "string", // Optional
  "targetStudentIds": ["string"], // Optional - Array of student IDs, null means all students
  "dueDate": "timestamp", // Optional - For assignments
  "points": "number", // Optional - For assignments
  "isActive": "boolean", // For soft delete
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 7. `announcement_reads`
Tracks which students have read which announcements.

**Document Structure:**
```json
{
  "announcementId": "string", // Reference to announcements collection
  "studentId": "string", // Reference to users collection
  "readAt": "timestamp"
}
```

**Document ID Format:** `${announcementId}_${studentId}`

### 8. `subject_enrollments`
Tracks which students are enrolled in which subjects.

**Document Structure:**
```json
{
  "subjectId": "string", // Reference to subjects collection
  "studentId": "string", // Reference to users collection
  "enrolledAt": "timestamp"
}
```

### 9. `notes`
Stores student notes (including OCR-generated notes).

**Document Structure:**
```json
{
  "title": "string",
  "content": "string",
  "studentId": "string", // Reference to users collection
  "subject": "string", // Optional
  "tags": ["string"], // Optional - Array of strings
  "isFromOcr": "boolean", // true if generated from OCR
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Required Firestore Indexes

To ensure optimal query performance, create the following composite indexes in the Firebase Console:

### Announcements Indexes
1. **Collection:** `announcements`
   - **Fields:** `teacherId` (Ascending), `isActive` (Ascending), `createdAt` (Descending)

2. **Collection:** `announcements`
   - **Fields:** `isActive` (Ascending), `createdAt` (Descending)

### Attendance Indexes
3. **Collection:** `attendance_sessions`
   - **Fields:** `teacherId` (Ascending), `isActive` (Ascending), `startTime` (Descending)

4. **Collection:** `attendance_records`
   - **Fields:** `studentId` (Ascending), `timestamp` (Descending)

### Notes Indexes
5. **Collection:** `notes`
   - **Fields:** `studentId` (Ascending), `createdAt` (Descending)

6. **Collection:** `notes`
   - **Fields:** `studentId` (Ascending), `subject` (Ascending), `createdAt` (Descending)

### Subject Enrollments Indexes
7. **Collection:** `subject_enrollments`
   - **Fields:** `subjectId` (Ascending), `studentId` (Ascending)

8. **Collection:** `subject_enrollments`
   - **Fields:** `studentId` (Ascending), `subjectId` (Ascending)

## Setting Up Indexes

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** > **Indexes**
4. Click **Create Index**
5. For each index listed above:
   - Select the collection
   - Add the fields in the specified order
   - Set the sort order (Ascending/Descending) as specified
   - Click **Create**

## Security Rules

Here are the recommended Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Teachers can read/write subjects they created
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.teacherId;
    }
    
    // Teachers can read/write lectures they created
    match /lectures/{lectureId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.teacherId;
    }
    
    // Teachers can read/write attendance sessions they created
    match /attendance_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.teacherId;
    }
    
    // Students can read/write their own attendance records
    match /attendance_records/{recordId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.studentId;
    }
    
    // Teachers can read/write announcements they created
    // Students can read announcements targeted to them
    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.teacherId;
    }
    
    // Students can read/write their own announcement reads
    match /announcement_reads/{readId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.studentId;
    }
    
    // Students can read enrollments for subjects they're enrolled in
    match /subject_enrollments/{enrollmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Students can read/write their own notes
    match /notes/{noteId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.studentId;
    }
  }
}
```

## Testing the Setup

1. **Create Test Users:**
   - Create teacher and student accounts through the app
   - Verify user documents are created in the `users` collection

2. **Create Test Data:**
   - Use the `FirestoreSetupService.setupSampleData()` method
   - This will create sample subjects and announcements

3. **Verify Indexes:**
   - Run queries that use the composite indexes
   - Check the Firebase Console for any missing index errors

4. **Test Security Rules:**
   - Try to access documents with different user roles
   - Ensure users can only access their own data

## Troubleshooting

### Common Issues:

1. **Missing Index Errors:**
   - Check the Firebase Console for index creation errors
   - Ensure all required composite indexes are created

2. **Permission Denied Errors:**
   - Verify security rules are properly configured
   - Check that users are authenticated

3. **Query Performance Issues:**
   - Ensure composite indexes are created for all query combinations
   - Use client-side sorting when possible to avoid complex indexes

### Getting Help:

- Check the [Firebase Documentation](https://firebase.google.com/docs/firestore)
- Review the [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- Use the Firebase Console to monitor query performance and errors
