import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_data_model.dart';

class FirestoreSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize user document when user signs up
  Future<void> initializeUserDocument({
    required String uid,
    required String email,
    required String name,
    required String userType,
  }) async {
    try {
      await _firestore.collection(FirestoreDataModel.usersCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to initialize user document: $e');
    }
  }

  // Create a sample subject for testing
  Future<String> createSampleSubject({
    required String name,
    required String description,
  }) async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore.collection(FirestoreDataModel.subjectsCollection).add({
        'name': name,
        'description': description,
        'teacherId': teacherId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create subject: $e');
    }
  }

  // Enroll a student in a subject
  Future<void> enrollStudentInSubject({
    required String subjectId,
    required String studentId,
  }) async {
    try {
      await _firestore.collection(FirestoreDataModel.subjectEnrollmentsCollection).add({
        'subjectId': subjectId,
        'studentId': studentId,
        'enrolledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to enroll student in subject: $e');
    }
  }

  // Create a sample announcement for testing
  Future<String> createSampleAnnouncement({
    required String title,
    required String content,
    required String type,
    String? subjectId,
    String? subjectName,
    List<String>? targetStudentIds,
    DateTime? dueDate,
    int? points,
  }) async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore.collection(FirestoreDataModel.announcementsCollection).add({
        'title': title,
        'content': content,
        'type': type,
        'teacherId': teacherId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'targetStudentIds': targetStudentIds,
        'dueDate': dueDate,
        'points': points,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  // Setup sample data for testing
  Future<void> setupSampleData() async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) throw Exception('User not authenticated');

    try {
      // Create sample subjects
      final mathSubjectId = await createSampleSubject(
        name: 'Mathematics',
        description: 'Advanced Mathematics Course',
      );

      final scienceSubjectId = await createSampleSubject(
        name: 'Science',
        description: 'General Science Course',
      );

      // Create sample announcements
      await createSampleAnnouncement(
        title: 'Welcome to the New Semester!',
        content: 'Welcome everyone to the new semester. Please check your schedules and be ready for classes.',
        type: 'announcement',
        subjectId: mathSubjectId,
        subjectName: 'Mathematics',
      );

      await createSampleAnnouncement(
        title: 'Homework Assignment #1',
        content: 'Complete exercises 1-10 from chapter 3. Submit by next Monday.',
        type: 'assignment',
        subjectId: mathSubjectId,
        subjectName: 'Mathematics',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        points: 100,
      );

      await createSampleAnnouncement(
        title: 'Lab Safety Reminder',
        content: 'Please remember to follow all safety protocols in the science lab.',
        type: 'message',
        subjectId: scienceSubjectId,
        subjectName: 'Science',
      );

      print('Sample data created successfully!');
    } catch (e) {
      throw Exception('Failed to setup sample data: $e');
    }
  }

  // Check if required indexes exist (this is a helper method)
  // Note: In production, indexes should be created through Firebase Console
  Future<void> checkRequiredIndexes() async {
    print('Required Firestore Indexes:');
    print('================================');
    
    for (final index in FirestoreDataModel.requiredIndexes) {
      print('Collection: ${index['collection']}');
      print('Fields: ${index['fields']}');
      print('Order: ${index['order']}');
      print('---');
    }
    
    print('Please create these indexes in the Firebase Console:');
    print('https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes');
  }

  // Validate data structure
  Future<bool> validateDataStructure() async {
    try {
      // Check if users collection exists and has proper structure
      final usersSnapshot = await _firestore
          .collection(FirestoreDataModel.usersCollection)
          .limit(1)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final userDoc = usersSnapshot.docs.first.data();
        final requiredFields = ['uid', 'email', 'name', 'userType', 'createdAt'];
        
        for (final field in requiredFields) {
          if (!userDoc.containsKey(field)) {
            print('Missing field in users collection: $field');
            return false;
          }
        }
      }

      // Check if announcements collection exists
      final announcementsSnapshot = await _firestore
          .collection(FirestoreDataModel.announcementsCollection)
          .limit(1)
          .get();
      
      if (announcementsSnapshot.docs.isNotEmpty) {
        final announcementDoc = announcementsSnapshot.docs.first.data();
        final requiredFields = ['title', 'content', 'type', 'teacherId', 'isActive', 'createdAt'];
        
        for (final field in requiredFields) {
          if (!announcementDoc.containsKey(field)) {
            print('Missing field in announcements collection: $field');
            return false;
          }
        }
      }

      print('Data structure validation passed!');
      return true;
    } catch (e) {
      print('Data structure validation failed: $e');
      return false;
    }
  }

  // Clean up test data (for development/testing purposes)
  Future<void> cleanupTestData() async {
    try {
      // Delete all test announcements
      final announcementsSnapshot = await _firestore
          .collection(FirestoreDataModel.announcementsCollection)
          .get();
      
      for (final doc in announcementsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all test subjects
      final subjectsSnapshot = await _firestore
          .collection(FirestoreDataModel.subjectsCollection)
          .get();
      
      for (final doc in subjectsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all test enrollments
      final enrollmentsSnapshot = await _firestore
          .collection(FirestoreDataModel.subjectEnrollmentsCollection)
          .get();
      
      for (final doc in enrollmentsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Test data cleaned up successfully!');
    } catch (e) {
      throw Exception('Failed to cleanup test data: $e');
    }
  }
}
