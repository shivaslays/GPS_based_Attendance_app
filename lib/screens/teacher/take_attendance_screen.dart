import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/location_service.dart';
import '../../services/attendance_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  String? _selectedSubjectId;
  String? _selectedLectureId;
  bool _isLoading = false;
  bool _isSessionActive = false;
  String? _currentSessionId;
  double _rangeInMeters = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopAttendanceSession,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Status Card
            Card(
              color: _isSessionActive ? Colors.green.shade50 : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isSessionActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _isSessionActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSessionActive ? 'Attendance Session Active' : 'No Active Session',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isSessionActive ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSessionActive 
                                ? 'Students can now mark their attendance'
                                : 'Start a session to begin taking attendance',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isSessionActive ? Colors.green.shade700 : Colors.grey.shade600,
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

            if (!_isSessionActive) ...[
              // Subject Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Subject & Lecture',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('subjects')
                            .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text('No subjects found. Please add a subject first.');
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: _selectedSubjectId,
                            decoration: const InputDecoration(
                              labelText: 'Select Subject *',
                              prefixIcon: Icon(Icons.school),
                              border: OutlineInputBorder(),
                            ),
                            items: snapshot.data!.docs.map((doc) {
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(doc['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubjectId = value;
                                _selectedLectureId = null;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Lecture Selection
                      if (_selectedSubjectId != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('lectures')
                              .where('subjectId', isEqualTo: _selectedSubjectId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text('No lectures found for this subject.');
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

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedLectureId,
                              decoration: const InputDecoration(
                                labelText: 'Select Lecture *',
                                prefixIcon: Icon(Icons.book),
                                border: OutlineInputBorder(),
                              ),
                              items: lectures.map((doc) {
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text('${doc['title']} - ${doc['date']}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLectureId = value;
                                });
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Settings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text('Range: ${_rangeInMeters.toInt()} meters'),
                      Slider(
                        value: _rangeInMeters,
                        min: 10.0,
                        max: 50.0,
                        divisions: 4,
                        label: '${_rangeInMeters.toInt()}m',
                        onChanged: (value) {
                          setState(() {
                            _rangeInMeters = value;
                          });
                        },
                      ),
                      const Text(
                        'Students within this range can mark attendance',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Session Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedSubjectId != null && _selectedLectureId != null && !_isLoading
                      ? _startAttendanceSession
                      : null,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Starting...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('Start Attendance Session'),
                          ],
                        ),
                ),
              ),
            ] else ...[
              // Active Session Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Range: ${_rangeInMeters.toInt()} meters'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('Students can mark attendance now'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _stopAttendanceSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop),
                              SizedBox(width: 8),
                              Text('Stop Session'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startAttendanceSession() async {
    if (_selectedSubjectId == null || _selectedLectureId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      final locationService = Provider.of<LocationService>(context, listen: false);
      final success = await locationService.getCurrentLocation();
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location access required for attendance'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final currentPosition = locationService.currentPosition;
      if (currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Start attendance session
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      final sessionId = await attendanceService.startAttendanceSession(
        subjectId: _selectedSubjectId!,
        lectureId: _selectedLectureId!,
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        rangeInMeters: _rangeInMeters,
      );

      setState(() {
        _isSessionActive = true;
        _currentSessionId = sessionId;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopAttendanceSession() async {
    if (_currentSessionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      await attendanceService.endAttendanceSession(_currentSessionId!);

      setState(() {
        _isSessionActive = false;
        _currentSessionId = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session ended!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
