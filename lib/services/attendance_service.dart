import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Start attendance session
  Future<String> startAttendanceSession({
    required String subjectId,
    required String lectureId,
    required double latitude,
    required double longitude,
    required double rangeInMeters,
  }) async {
    try {
      final sessionId = _firestore.collection('attendance_sessions').doc().id;
      
      await _firestore.collection('attendance_sessions').doc(sessionId).set({
        'teacherId': _auth.currentUser?.uid,
        'subjectId': subjectId,
        'lectureId': lectureId,
        'latitude': latitude,
        'longitude': longitude,
        'rangeInMeters': rangeInMeters,
        'startTime': FieldValue.serverTimestamp(),
        'isActive': true,
        'attendedStudents': <String>[],
      });

      return sessionId;
    } catch (e) {
      print('Error starting attendance session: $e');
      throw e;
    }
  }

  // End attendance session
  Future<void> endAttendanceSession(String sessionId) async {
    try {
      await _firestore.collection('attendance_sessions').doc(sessionId).update({
        'isActive': false,
        'endTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error ending attendance session: $e');
      throw e;
    }
  }

  // Mark student as present
  Future<bool> markAttendance(String sessionId, String studentId) async {
    try {
      await _firestore.collection('attendance_sessions').doc(sessionId).update({
        'attendedStudents': FieldValue.arrayUnion([studentId]),
      });

      // Also save individual attendance record
      await _firestore.collection('attendance_records').add({
        'sessionId': sessionId,
        'studentId': studentId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  // Get active attendance sessions for students
  Stream<List<Map<String, dynamic>>> getActiveAttendanceSessions() {
    return _firestore
        .collection('attendance_sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get attendance history for a student
  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance_records')
          .where('studentId', isEqualTo: studentId)
          .get();

      final records = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by timestamp in descending order (most recent first)
      records.sort((a, b) {
        try {
          final aTimestamp = a['timestamp'];
          final bTimestamp = b['timestamp'];
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          // Convert to DateTime for comparison
          DateTime aDateTime = aTimestamp is DateTime 
              ? aTimestamp 
              : (aTimestamp as Timestamp).toDate();
          DateTime bDateTime = bTimestamp is DateTime 
              ? bTimestamp 
              : (bTimestamp as Timestamp).toDate();
          
          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });
      
      return records;
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  // Get attendance statistics for a teacher
  Future<Map<String, dynamic>> getAttendanceStats(String subjectId, String lectureId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance_sessions')
          .where('subjectId', isEqualTo: subjectId)
          .where('lectureId', isEqualTo: lectureId)
          .get();

      int totalSessions = querySnapshot.docs.length;
      int totalAttendance = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalAttendance += (data['attendedStudents'] as List).length;
      }

      return {
        'totalSessions': totalSessions,
        'totalAttendance': totalAttendance,
        'averageAttendance': totalSessions > 0 ? totalAttendance / totalSessions : 0,
      };
    } catch (e) {
      print('Error getting attendance stats: $e');
      return {'totalSessions': 0, 'totalAttendance': 0, 'averageAttendance': 0.0};
    }
  }

  // Get comprehensive attendance report for a student
  Future<List<Map<String, dynamic>>> getStudentAttendanceReport(String studentId) async {
    try {
      // Get all attendance sessions
      final sessionsSnapshot = await _firestore
          .collection('attendance_sessions')
          .get();

      // Get student's attendance records
      final attendanceRecords = await getStudentAttendanceHistory(studentId);
      final attendedSessionIds = attendanceRecords.map((record) => record['sessionId']).toSet();

      List<Map<String, dynamic>> report = [];

      for (var sessionDoc in sessionsSnapshot.docs) {
        final sessionData = sessionDoc.data();
        final sessionId = sessionDoc.id;
        final isPresent = attendedSessionIds.contains(sessionId);

        // Get lecture details
        final lectureDoc = await _firestore
            .collection('lectures')
            .doc(sessionData['lectureId'])
            .get();

        // Get subject details
        final subjectDoc = await _firestore
            .collection('subjects')
            .doc(sessionData['subjectId'])
            .get();

        if (lectureDoc.exists && subjectDoc.exists) {
          report.add({
            'sessionId': sessionId,
            'lectureTitle': lectureDoc.data()?['title'] ?? 'Unknown Lecture',
            'subjectName': subjectDoc.data()?['name'] ?? 'Unknown Subject',
            'date': sessionData['startTime'] != null 
                ? DateFormat('yyyy-MM-dd').format((sessionData['startTime'] as Timestamp).toDate())
                : 'Unknown Date',
            'time': sessionData['startTime'] != null 
                ? DateFormat('HH:mm').format((sessionData['startTime'] as Timestamp).toDate())
                : 'Unknown Time',
            'isPresent': isPresent,
            'timestamp': sessionData['startTime'],
          });
        }
      }

      // Sort by timestamp in descending order (most recent first)
      report.sort((a, b) {
        try {
          final aTimestamp = a['timestamp'];
          final bTimestamp = b['timestamp'];
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          DateTime aDateTime = aTimestamp is DateTime 
              ? aTimestamp 
              : (aTimestamp as Timestamp).toDate();
          DateTime bDateTime = bTimestamp is DateTime 
              ? bTimestamp 
              : (bTimestamp as Timestamp).toDate();
          
          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });

      return report;
    } catch (e) {
      print('Error getting student attendance report: $e');
      return [];
    }
  }

  // Get comprehensive attendance report for a teacher
  Future<List<Map<String, dynamic>>> getTeacherAttendanceReport(String teacherId) async {
    try {
      // Get all attendance sessions for this teacher
      final sessionsSnapshot = await _firestore
          .collection('attendance_sessions')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      List<Map<String, dynamic>> report = [];

      for (var sessionDoc in sessionsSnapshot.docs) {
        final sessionData = sessionDoc.data();

        // Get lecture details
        final lectureDoc = await _firestore
            .collection('lectures')
            .doc(sessionData['lectureId'])
            .get();

        // Get subject details
        final subjectDoc = await _firestore
            .collection('subjects')
            .doc(sessionData['subjectId'])
            .get();

        if (lectureDoc.exists && subjectDoc.exists) {
          final attendedStudents = sessionData['attendedStudents'] as List? ?? [];
          
          report.add({
            'sessionId': sessionDoc.id,
            'lectureTitle': lectureDoc.data()?['title'] ?? 'Unknown Lecture',
            'subjectName': subjectDoc.data()?['name'] ?? 'Unknown Subject',
            'date': sessionData['startTime'] != null 
                ? DateFormat('yyyy-MM-dd').format((sessionData['startTime'] as Timestamp).toDate())
                : 'Unknown Date',
            'time': sessionData['startTime'] != null 
                ? DateFormat('HH:mm').format((sessionData['startTime'] as Timestamp).toDate())
                : 'Unknown Time',
            'attendedCount': attendedStudents.length,
            'attendedStudents': attendedStudents,
            'isActive': sessionData['isActive'] ?? false,
            'timestamp': sessionData['startTime'],
          });
        }
      }

      // Sort by timestamp in descending order (most recent first)
      report.sort((a, b) {
        try {
          final aTimestamp = a['timestamp'];
          final bTimestamp = b['timestamp'];
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          DateTime aDateTime = aTimestamp is DateTime 
              ? aTimestamp 
              : (aTimestamp as Timestamp).toDate();
          DateTime bDateTime = bTimestamp is DateTime 
              ? bTimestamp 
              : (bTimestamp as Timestamp).toDate();
          
          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });

      return report;
    } catch (e) {
      print('Error getting teacher attendance report: $e');
      return [];
    }
  }
}
