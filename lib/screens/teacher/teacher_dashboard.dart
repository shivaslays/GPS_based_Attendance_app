import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import 'add_subject_screen.dart';
import 'add_lecture_screen.dart';
import 'take_attendance_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<AuthService>(
                            builder: (context, authService, child) {
                              final userName = authService.userName ?? 'Teacher';
                              return Text(
                                'Welcome, $userName!',
                                style: Theme.of(context).textTheme.headlineSmall,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your classes and take attendance',
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

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.add_circle,
                    title: 'Add Subject',
                    subtitle: 'Create new subject',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddSubjectScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.book,
                    title: 'Add Lecture',
                    subtitle: 'Schedule lecture',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddLectureScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.assignment,
                    title: 'Take Attendance',
                    subtitle: 'Mark attendance',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TakeAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.analytics,
                    title: 'Attendance Report',
                    subtitle: 'View detailed reports',
                    color: Colors.blue,
                    onTap: () {
                      _showAttendanceReportDialog();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Lectures Section
            Text(
              'Recent Lectures',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('lectures')
                  .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.book,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No lectures yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first lecture to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddLectureScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Lecture'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort lectures by dateTime in descending order (most recent first)
                final lectures = snapshot.data!.docs.toList();
                lectures.sort((a, b) {
                  try {
                    final aTimestamp = a['dateTime'];
                    final bTimestamp = b['dateTime'];
                    
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
                    // If there's any error in sorting, just return 0 (no change)
                    return 0;
                  }
                });

                // Show only the first 5 lectures
                final recentLectures = lectures.take(5).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLectures.length,
                  itemBuilder: (context, index) {
                    final lecture = recentLectures[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(lecture['title'] ?? 'Untitled Lecture'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${lecture['date'] ?? 'N/A'}'),
                            if (lecture['time'] != null)
                              Text('Time: ${lecture['time']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // You can add navigation to lecture details here
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Subjects Section
            Text(
              'My Subjects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('subjects')
                  .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects yet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first subject to get started',
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
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final subject = snapshot.data!.docs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.school, color: Colors.white),
                        ),
                        title: Text(subject['name']),
                        subtitle: Text(subject['description'] ?? ''),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'lectures',
                              child: Row(
                                children: [
                                  Icon(Icons.book),
                                  SizedBox(width: 8),
                                  Text('View Lectures'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'lectures') {
                              _showLecturesDialog(subject.id, subject['name']);
                            } else if (value == 'delete') {
                              _deleteSubject(subject.id);
                            }
                          },
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

  void _showAttendanceReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getTeacherAttendanceReport(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No attendance sessions yet'),
                      SizedBox(height: 8),
                      Text('Start taking attendance to see reports'),
                    ],
                  ),
                );
              }

              final records = snapshot.data!;
              final totalSessions = records.length;
              final totalAttendance = records.fold<int>(0, (total, record) => total + (record['attendedCount'] as int));
              final averageAttendance = totalSessions > 0 ? (totalAttendance / totalSessions).round() : 0;

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
                        _StatItem('Sessions', totalSessions.toString(), Colors.blue),
                        _StatItem('Total Attendance', totalAttendance.toString(), Colors.green),
                        _StatItem('Average', averageAttendance.toString(), Colors.orange),
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
                              backgroundColor: record['isActive'] ? Colors.orange : Colors.blue,
                              child: Icon(
                                record['isActive'] ? Icons.play_arrow : Icons.stop,
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
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${record['attendedCount']} students',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  record['isActive'] ? 'Active' : 'Completed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: record['isActive'] ? Colors.orange : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showSessionDetails(record),
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

  Future<List<Map<String, dynamic>>> _getTeacherAttendanceReport() async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) return [];

    // Import the attendance service
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    return await attendanceService.getTeacherAttendanceReport(teacherId);
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Details - ${session['lectureTitle']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Subject', session['subjectName'] ?? 'Unknown'),
              _DetailRow('Date', session['date'] ?? 'Unknown'),
              _DetailRow('Time', session['time'] ?? 'Unknown'),
              _DetailRow('Status', session['isActive'] ? 'Active' : 'Completed'),
              _DetailRow('Students Attended', '${session['attendedCount']}'),
              const SizedBox(height: 16),
              const Text(
                'Attended Students:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: session['attendedStudents'] != null && (session['attendedStudents'] as List).isNotEmpty
                    ? ListView.builder(
                        itemCount: (session['attendedStudents'] as List).length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.person, color: Colors.white, size: 16),
                            ),
                            title: Text('Student ${index + 1}'),
                            subtitle: Text('ID: ${(session['attendedStudents'] as List)[index]}'),
                          );
                        },
                      )
                    : const Center(
                        child: Text('No students attended this session'),
                      ),
              ),
            ],
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

  void _showLecturesDialog(String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lectures for $subjectName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('lectures')
                .where('subjectId', isEqualTo: subjectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No lectures found'),
                );
              }

              // Sort lectures by dateTime in descending order (most recent first)
              final lectures = snapshot.data!.docs.toList();
              lectures.sort((a, b) {
                try {
                  final aTimestamp = a['dateTime'];
                  final bTimestamp = b['dateTime'];
                  
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
                  // If there's any error in sorting, just return 0 (no change)
                  return 0;
                }
              });

              return ListView.builder(
                itemCount: lectures.length,
                itemBuilder: (context, index) {
                  final lecture = lectures[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.book, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        lecture['title'] ?? 'Untitled Lecture',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${lecture['date'] ?? 'N/A'}'),
                          if (lecture['time'] != null)
                            Text('Time: ${lecture['time']}'),
                          if (lecture['room'] != null && lecture['room'].isNotEmpty)
                            Text('Room: ${lecture['room']}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
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

  void _deleteSubject(String subjectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('subjects').doc(subjectId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
