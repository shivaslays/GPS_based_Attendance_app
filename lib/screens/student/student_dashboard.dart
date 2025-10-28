import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/announcements_service.dart';
import '../../services/location_service.dart';
import 'attendance_popup.dart';
import 'notes_screen.dart';
import 'ocr_scan_screen.dart';
import 'announcements_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialize location service when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    if (locationService.currentPosition == null) {
      await locationService.getCurrentLocation();
    }
  }

  void _onDrawerItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Start location monitoring when attendance screen is selected
    if (index == 1) { // Attendance index
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.startLocationMonitoring();
    } else {
      // Stop monitoring when leaving attendance screen
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.stopLocationMonitoring();
    }
    
    // Close drawer
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Notification Bell
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AnnouncementsService().getStudentAnnouncements(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => _showNotificationsDialog(snapshot.data!),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${snapshot.data!.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => _showNotificationsDialog([]),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildMainContent(),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Attendance';
      case 2:
        return 'My Notes';
      case 3:
        return 'Scan Notes';
      case 4:
        return 'Attendance Report';
      case 5:
        return 'Announcements';
      default:
        return 'Student Dashboard';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final userName = authService.userName ?? 'Student';
              return UserAccountsDrawerHeader(
                accountName: Text('Welcome, $userName!'),
                accountEmail: Text(authService.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                ),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
              );
            },
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                _DrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onDrawerItemSelected(0),
                ),
                _DrawerItem(
                  icon: Icons.check_circle,
                  title: 'Attendance',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onDrawerItemSelected(1),
                ),
                _DrawerItem(
                  icon: Icons.note,
                  title: 'My Notes',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onDrawerItemSelected(2),
                ),
                _DrawerItem(
                  icon: Icons.camera_alt,
                  title: 'Scan Notes',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onDrawerItemSelected(3),
                ),
                _DrawerItem(
                  icon: Icons.analytics,
                  title: 'Attendance Report',
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onDrawerItemSelected(4),
                ),
                _DrawerItem(
                  icon: Icons.campaign,
                  title: 'Announcements',
                  isSelected: _selectedIndex == 5,
                  onTap: () => _onDrawerItemSelected(5),
                ),
              ],
            ),
          ),
          
          // Logout Section
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildAttendanceContent();
      case 2:
        return _buildNotesContent();
      case 3:
        return _buildScanNotesContent();
      case 4:
        return _buildAttendanceReportContent();
      case 5:
        return const AnnouncementsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final userName = authService.userName ?? 'Student';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $userName!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to learn today?',
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
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.check_circle,
                  title: 'Mark Attendance',
                  subtitle: 'Check in for class',
                  color: Colors.green,
                  onTap: () => _onDrawerItemSelected(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.camera_alt,
                  title: 'Scan Notes',
                  subtitle: 'OCR text recognition',
                  color: Colors.orange,
                  onTap: () => _onDrawerItemSelected(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.note,
                  title: 'My Notes',
                  subtitle: 'View saved notes',
                  color: Colors.purple,
                  onTap: () => _onDrawerItemSelected(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.analytics,
                  title: 'Attendance Report',
                  subtitle: 'Detailed statistics',
                  color: Colors.blue,
                  onTap: () => _onDrawerItemSelected(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    return Consumer2<AttendanceService, LocationService>(
      builder: (context, attendanceService, locationService, child) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: attendanceService.getActiveAttendanceSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final sessions = snapshot.data ?? [];
            
            if (sessions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active attendance sessions',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later or ask your teacher',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            
            // Filter sessions based on location and show only accessible ones
            final accessibleSessions = <Map<String, dynamic>>[];
            
            for (final session in sessions) {
              final teacherLat = session['latitude'] as double?;
              final teacherLon = session['longitude'] as double?;
              final rangeInMeters = (session['rangeInMeters'] as double?) ?? 50.0;
              
              if (teacherLat != null && teacherLon != null) {
                final isWithinRange = locationService.isWithinRange(
                  teacherLat, 
                  teacherLon, 
                  rangeInMeters
                );
                
                if (isWithinRange) {
                  accessibleSessions.add(session);
                }
              }
            }
            
            return Column(
              children: [
                // Location Status
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: locationService.currentPosition != null 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: locationService.currentPosition != null 
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        locationService.currentPosition != null 
                            ? Icons.location_on 
                            : Icons.location_off,
                        color: locationService.currentPosition != null 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationService.currentPosition != null 
                              ? 'Location tracking active'
                              : 'Location not available',
                          style: TextStyle(
                            color: locationService.currentPosition != null 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (locationService.currentPosition == null)
                        TextButton(
                          onPressed: () async {
                            await locationService.getCurrentLocation();
                          },
                          child: const Text('Enable'),
                        ),
                    ],
                  ),
                ),
                
                // Sessions List
                Expanded(
                  child: accessibleSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, size: 64, color: Colors.orange),
                              const SizedBox(height: 16),
                              const Text(
                                'No attendance sessions in range',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Move closer to the teacher or wait for a new session',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: accessibleSessions.length,
                          itemBuilder: (context, index) {
                            final session = accessibleSessions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.green),
                                title: const Text('Attendance Session'),
                                subtitle: Text('Range: ${session['rangeInMeters']?.toInt() ?? 50}m'),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AttendancePopup(session: session),
                                    );
                                  },
                                  child: const Text('Mark Present'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotesContent() {
    return const NotesScreen();
  }

  Widget _buildScanNotesContent() {
    return OcrScanScreen(
      onBackPressed: () {
        setState(() {
          _selectedIndex = 0; // Go back to dashboard
        });
      },
    );
  }

  Widget _buildAttendanceReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.check_circle,
                  title: 'Present',
                  subtitle: '0 classes',
                  color: Colors.green,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.cancel,
                  title: 'Absent',
                  subtitle: '0 classes',
                  color: Colors.red,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Attendance
          Text(
            'Recent Attendance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
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
                          'Your attendance will appear here once you start attending classes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final records = snapshot.data!;
              final recentRecords = records.take(5).toList();

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
                      trailing: Text(
                        record['isPresent'] ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: record['isPresent'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No attendance records found'),
                    ],
                  ),
                );
              }

              final records = snapshot.data!;
              final presentCount = records.where((r) => r['isPresent'] == true).length;
              final absentCount = records.length - presentCount;

              return Column(
                children: [
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem('Present', presentCount.toString(), Colors.green),
                        _StatItem('Absent', absentCount.toString(), Colors.red),
                        _StatItem('Total', records.length.toString(), Colors.blue),
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
                            trailing: Text(
                              record['isPresent'] ? 'Present' : 'Absent',
                              style: TextStyle(
                                color: record['isPresent'] ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
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

  void _showNotificationsDialog(List<Map<String, dynamic>> announcements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: announcements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(announcement['type']),
                          child: Icon(
                            _getTypeIcon(announcement['type']),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          announcement['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  announcement['type']?.toString().toUpperCase() ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getTypeColor(announcement['type']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (announcement['subjectName'] != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${announcement['subjectName']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                                if (announcement['dueDate'] != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• Due: ${_formatDate(announcement['dueDate'])}',
                                    style: const TextStyle(fontSize: 10, color: Colors.red),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAnnouncementDetails(announcement);
                        },
                      ),
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

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'announcement':
        return Colors.blue;
      case 'message':
        return Colors.green;
      case 'assignment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign;
      case 'message':
        return Icons.message;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return '';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement['title'] ?? 'Announcement Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement['content'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (announcement['subjectName'] != null) ...[
                Row(
                  children: [
                    const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(announcement['subjectName']),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (announcement['points'] != null) ...[
                Row(
                  children: [
                    const Text('Points: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${announcement['points']} points'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (announcement['dueDate'] != null) ...[
                Row(
                  children: [
                    const Text('Due Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _formatDate(announcement['dueDate']),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(announcement['type']?.toString().toUpperCase() ?? ''),
                ],
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withValues(alpha: 0.1),
      onTap: onTap,
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
            fontSize: 24,
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
