import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/attendance_service.dart';
import 'attendance_popup.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenForAttendanceSessions();
  }

  Future<void> _initializeLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();
  }

  void _listenForAttendanceSessions() {
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    attendanceService.getActiveAttendanceSessions().listen((sessions) {
      for (var session in sessions) {
        if (locationService.isWithinRange(
          session['latitude'],
          session['longitude'],
          session['rangeInMeters'],
        )) {
          _showAttendancePopup(session);
        }
      }
    });
  }

  void _showAttendancePopup(Map<String, dynamic> session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AttendancePopup(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Student!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mark your attendance when prompted',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Location Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<LocationService>(
                      builder: (context, locationService, child) {
                        return Row(
                          children: [
                            Icon(
                              locationService.isLocationEnabled
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: locationService.isLocationEnabled
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              locationService.isLocationEnabled
                                  ? 'Location enabled - Ready for attendance'
                                  : 'Location disabled - Enable location services',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attendance History
            Text(
              'Attendance History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAttendanceHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records yet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your attendance will appear here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final record = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text('Attendance Marked'),
                        subtitle: Text(record['date'] ?? ''),
                        trailing: Text(
                          record['timestamp'] != null
                              ? _formatTimestamp(record['timestamp'])
                              : '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getAttendanceHistory() {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('attendance_records')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      // Sort by timestamp on client side
      final records = snapshot.docs.map((doc) {
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
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = timestamp.toDate();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
