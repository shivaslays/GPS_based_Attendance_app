import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new note
  Future<String> createNote({
    required String title,
    required String content,
    String? subject,
    String? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteId = _firestore.collection('notes').doc().id;
      
      await _firestore.collection('notes').doc(noteId).set({
        'id': noteId,
        'studentId': user.uid,
        'title': title,
        'content': content,
        'subject': subject ?? '',
        'tags': tags ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isOcrGenerated': false,
      });

      notifyListeners();
      return noteId;
    } catch (e) {
      print('Error creating note: $e');
      throw e;
    }
  }

  // Create a note from OCR text
  Future<String> createNoteFromOcr({
    required String content,
    String? subject,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteId = _firestore.collection('notes').doc().id;
      final timestamp = DateTime.now();
      final title = 'OCR Note - ${DateFormat('MMM dd, yyyy HH:mm').format(timestamp)}';
      
      await _firestore.collection('notes').doc(noteId).set({
        'id': noteId,
        'studentId': user.uid,
        'title': title,
        'content': content,
        'subject': subject ?? '',
        'tags': 'OCR, Scanned',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isOcrGenerated': true,
      });

      notifyListeners();
      return noteId;
    } catch (e) {
      print('Error creating OCR note: $e');
      throw e;
    }
  }

  // Get all notes for the current student
  Stream<List<Map<String, dynamic>>> getStudentNotes() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notes')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt on client side
      notes.sort((a, b) {
        try {
          final aTimestamp = a['createdAt'];
          final bTimestamp = b['createdAt'];
          
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
      
      return notes;
    });
  }

  // Get notes by subject
  Stream<List<Map<String, dynamic>>> getNotesBySubject(String subject) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notes')
        .where('studentId', isEqualTo: user.uid)
        .where('subject', isEqualTo: subject)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt on client side
      notes.sort((a, b) {
        try {
          final aTimestamp = a['createdAt'];
          final bTimestamp = b['createdAt'];
          
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
      
      return notes;
    });
  }

  // Search notes by content or title
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('notes')
          .where('studentId', isEqualTo: user.uid)
          .get();

      final allNotes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter notes based on search query
      final filteredNotes = allNotes.where((note) {
        final title = (note['title'] ?? '').toString().toLowerCase();
        final content = (note['content'] ?? '').toString().toLowerCase();
        final subject = (note['subject'] ?? '').toString().toLowerCase();
        final tags = (note['tags'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) ||
               content.contains(searchQuery) ||
               subject.contains(searchQuery) ||
               tags.contains(searchQuery);
      }).toList();

      // Sort by creation date
      filteredNotes.sort((a, b) {
        try {
          final aTimestamp = a['createdAt'];
          final bTimestamp = b['createdAt'];
          
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

      return filteredNotes;
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  // Update a note
  Future<void> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? subject,
    String? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (subject != null) updateData['subject'] = subject;
      if (tags != null) updateData['tags'] = tags;

      await _firestore.collection('notes').doc(noteId).update(updateData);
      notifyListeners();
    } catch (e) {
      print('Error updating note: $e');
      throw e;
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('notes').doc(noteId).delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting note: $e');
      throw e;
    }
  }

  // Get note statistics
  Future<Map<String, dynamic>> getNoteStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'totalNotes': 0, 'ocrNotes': 0, 'subjects': 0};

      final querySnapshot = await _firestore
          .collection('notes')
          .where('studentId', isEqualTo: user.uid)
          .get();

      final notes = querySnapshot.docs.map((doc) => doc.data()).toList();
      final totalNotes = notes.length;
      final ocrNotes = notes.where((note) => note['isOcrGenerated'] == true).length;
      final subjects = notes.map((note) => note['subject']).toSet().length;

      return {
        'totalNotes': totalNotes,
        'ocrNotes': ocrNotes,
        'subjects': subjects,
      };
    } catch (e) {
      print('Error getting note statistics: $e');
      return {'totalNotes': 0, 'ocrNotes': 0, 'subjects': 0};
    }
  }

  // Get all unique subjects
  Future<List<String>> getSubjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('notes')
          .where('studentId', isEqualTo: user.uid)
          .get();

      final subjects = querySnapshot.docs
          .map((doc) => doc.data()['subject'] as String?)
          .where((subject) => subject != null && subject.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      subjects.sort();
      return subjects;
    } catch (e) {
      print('Error getting subjects: $e');
      return [];
    }
  }
}
