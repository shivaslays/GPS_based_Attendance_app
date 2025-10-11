import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/attendance_service.dart';

class AttendancePopup extends StatefulWidget {
  final Map<String, dynamic> session;

  const AttendancePopup({super.key, required this.session});

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup> {
  bool _isLoading = false;
  String? _subjectName;
  String? _lectureTitle;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    try {
      // Get subject name
      final subjectDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.session['subjectId'])
          .get();
      
      if (subjectDoc.exists) {
        setState(() {
          _subjectName = subjectDoc.data()?['name'];
        });
      }

      // Get lecture title
      final lectureDoc = await FirebaseFirestore.instance
          .collection('lectures')
          .doc(widget.session['lectureId'])
          .get();
      
      if (lectureDoc.exists) {
        setState(() {
          _lectureTitle = lectureDoc.data()?['title'];
        });
      }
    } catch (e) {
      print('Error loading session details: $e');
    }
  }

  Future<void> _markAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      final studentId = FirebaseAuth.instance.currentUser?.uid;
      
      if (studentId == null) {
        throw Exception('User not authenticated');
      }

      final success = await attendanceService.markAttendance(
        widget.session['id'],
        studentId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to mark attendance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mark Attendance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You are within the attendance range. Please mark your attendance for:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Subject Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _subjectName ?? 'Loading...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (_lectureTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lectureTitle!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Location Info
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Range: ${widget.session['rangeInMeters']?.toInt() ?? 50}m',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          const Text(
            'Tap "Mark Present" to confirm your attendance.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _markAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text('Mark Present'),
                  ],
                ),
        ),
      ],
    );
  }
}
