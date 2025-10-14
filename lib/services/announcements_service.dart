import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnnouncementsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new announcement
  Future<String> createAnnouncement({
    required String title,
    required String content,
    required String type, // 'announcement', 'message', 'assignment'
    String? subjectId,
    String? subjectName,
    List<String>? targetStudentIds, // If null, sends to all students
    DateTime? dueDate,
    int? points,
  }) async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) throw Exception('User not authenticated');

    final announcementData = {
      'title': title,
      'content': content,
      'type': type,
      'teacherId': teacherId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'targetStudentIds': targetStudentIds, // null means all students
      'dueDate': dueDate,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    final docRef = await _firestore.collection('announcements').add(announcementData);
    return docRef.id;
  }

  // Get announcements for a specific student
  Stream<List<Map<String, dynamic>>> getStudentAnnouncements(String studentId) {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final announcements = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final targetStudentIds = data['targetStudentIds'] as List<dynamic>?;
        
        // If targetStudentIds is null, it's for all students
        // If targetStudentIds is not null, check if this student is in the list
        if (targetStudentIds == null || targetStudentIds.contains(studentId)) {
          announcements.add({
            'id': doc.id,
            ...data,
          });
        }
      }
      
      // Sort by createdAt in descending order (most recent first)
      announcements.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime);
      });
      
      return announcements;
    });
  }

  // Get announcements created by a specific teacher
  Stream<List<Map<String, dynamic>>> getTeacherAnnouncements(String teacherId) {
    return _firestore
        .collection('announcements')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Sort by createdAt in descending order (most recent first)
      announcements.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime);
      });
      
      return announcements;
    });
  }

  // Get all students for teacher to select from
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'student')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Get students for a specific subject
  Future<List<Map<String, dynamic>>> getStudentsForSubject(String subjectId) async {
    final snapshot = await _firestore
        .collection('subject_enrollments')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    
    final studentIds = snapshot.docs.map((doc) => doc['studentId'] as String).toList();
    
    if (studentIds.isEmpty) return [];
    
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'student')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();
    
    return studentsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Mark announcement as read by student
  Future<void> markAsRead(String announcementId, String studentId) async {
    await _firestore
        .collection('announcement_reads')
        .doc('${announcementId}_$studentId')
        .set({
      'announcementId': announcementId,
      'studentId': studentId,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if announcement is read by student
  Future<bool> isReadByStudent(String announcementId, String studentId) async {
    final doc = await _firestore
        .collection('announcement_reads')
        .doc('${announcementId}_$studentId')
        .get();
    
    return doc.exists;
  }

  // Get read status for all students for an announcement
  Future<Map<String, bool>> getReadStatus(String announcementId, List<String> studentIds) async {
    final Map<String, bool> readStatus = {};
    
    for (final studentId in studentIds) {
      final isRead = await isReadByStudent(announcementId, studentId);
      readStatus[studentId] = isRead;
    }
    
    return readStatus;
  }

  // Delete announcement (soft delete)
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .update({'isActive': false});
  }

  // Update announcement
  Future<void> updateAnnouncement({
    required String announcementId,
    String? title,
    String? content,
    String? type,
    String? subjectId,
    String? subjectName,
    List<String>? targetStudentIds,
    DateTime? dueDate,
    int? points,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updateData['title'] = title;
    if (content != null) updateData['content'] = content;
    if (type != null) updateData['type'] = type;
    if (subjectId != null) updateData['subjectId'] = subjectId;
    if (subjectName != null) updateData['subjectName'] = subjectName;
    if (targetStudentIds != null) updateData['targetStudentIds'] = targetStudentIds;
    if (dueDate != null) updateData['dueDate'] = dueDate;
    if (points != null) updateData['points'] = points;

    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .update(updateData);
  }

  // Get announcement statistics for teacher
  Future<Map<String, int>> getAnnouncementStats(String teacherId) async {
    final snapshot = await _firestore
        .collection('announcements')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .get();

    int totalAnnouncements = 0;
    int totalMessages = 0;
    int totalAssignments = 0;

    for (final doc in snapshot.docs) {
      final type = doc.data()['type'] as String?;
      totalAnnouncements++;
      
      if (type == 'message') {
        totalMessages++;
      } else if (type == 'assignment') {
        totalAssignments++;
      }
    }

    return {
      'totalAnnouncements': totalAnnouncements,
      'totalMessages': totalMessages,
      'totalAssignments': totalAssignments,
    };
  }
}
