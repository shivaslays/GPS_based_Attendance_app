import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                          Consumer<AuthService>(
                            builder: (context, authService, child) {
                              final userName = authService.userName ?? 'Student';
                              return Text(
                                'Welcome, $userName!',
                                style: Theme.of(context).textTheme.headlineSmall,
                              );
                            },
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

            // Attendance Report Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Report',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showDetailedAttendanceReport(),
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Attendance Summary Cards
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getAttendanceReport(),
              builder: (context, snapshot) {
                int presentCount = 0;
                int absentCount = 0;
                
                if (snapshot.hasData) {
                  presentCount = snapshot.data!.where((r) => r['isPresent']).length;
                  absentCount = snapshot.data!.where((r) => !r['isPresent']).length;
                }
                
                return Row(
                  children: [
                    Expanded(
                      child: _AttendanceSummaryCard(
                        title: 'Present',
                        count: presentCount,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AttendanceSummaryCard(
                        title: 'Absent',
                        count: absentCount,
                        color: Colors.red,
                        icon: Icons.cancel,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Recent Attendance Records
            Text(
              'Recent Attendance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getAttendanceReport(),
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

                // Show only the first 5 recent records
                final recentRecords = snapshot.data!.take(5).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentRecords.length,
                  itemBuilder: (context, index) {
                    final record = recentRecords[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record['isPresent'] ? Colors.green : Colors.red,
                          child: Icon(
                            record['isPresent'] ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(record['lectureTitle'] ?? 'Unknown Lecture'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record['subjectName'] ?? 'Unknown Subject'),
                            Text('${record['date']} at ${record['time']}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: record['isPresent'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            record['isPresent'] ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: record['isPresent'] ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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

  Future<List<Map<String, dynamic>>> _getAttendanceReport() async {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) return [];

    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    return await attendanceService.getStudentAttendanceReport(studentId);
  }


  void _showDetailedAttendanceReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Attendance Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getAttendanceReport(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No attendance records found'),
                );
              }

              final records = snapshot.data!;
              final presentCount = records.where((r) => r['isPresent']).length;
              final absentCount = records.where((r) => !r['isPresent']).length;
              final totalCount = records.length;
              final attendancePercentage = totalCount > 0 ? (presentCount / totalCount * 100).round() : 0;

              return Column(
                children: [
                  // Summary Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem('Total', totalCount.toString(), Colors.blue),
                        _StatItem('Present', presentCount.toString(), Colors.green),
                        _StatItem('Absent', absentCount.toString(), Colors.red),
                        _StatItem('Percentage', '$attendancePercentage%', Colors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Detailed List
                  Expanded(
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: record['isPresent'] ? Colors.green : Colors.red,
                              child: Icon(
                                record['isPresent'] ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              record['lectureTitle'] ?? 'Unknown Lecture',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record['subjectName'] ?? 'Unknown Subject'),
                                Text('${record['date']} at ${record['time']}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: record['isPresent'] 
                                    ? Colors.green.withValues(alpha: 0.1) 
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record['isPresent'] ? 'Present' : 'Absent',
                                style: TextStyle(
                                  color: record['isPresent'] ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}

class _AttendanceSummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _AttendanceSummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
