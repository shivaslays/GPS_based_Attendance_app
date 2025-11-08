import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/announcements_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnnouncementsService _announcementsService = AnnouncementsService();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Messages', icon: Icon(Icons.message)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('All Types'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'announcement',
                child: Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Announcements'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Messages'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'assignment',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Assignments'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllAnnouncements(studentId),
          _buildAssignments(studentId),
          _buildMessages(studentId),
        ],
      ),
    );
  }

  Widget _buildAllAnnouncements(String studentId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _announcementsService.getStudentAnnouncements(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final announcements = snapshot.data ?? [];
        final filteredAnnouncements = _selectedFilter != null
            ? announcements.where((a) => a['type'] == _selectedFilter).toList()
            : announcements;

        if (filteredAnnouncements.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAnnouncements.length,
          itemBuilder: (context, index) {
            final announcement = filteredAnnouncements[index];
            return _buildAnnouncementCard(announcement);
          },
        );
      },
    );
  }

  Widget _buildAssignments(String studentId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _announcementsService.getStudentAnnouncements(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final announcements = snapshot.data ?? [];
        final assignments = announcements.where((a) => a['type'] == 'assignment').toList();

        if (assignments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment,
            title: 'No Assignments',
            subtitle: 'You have no assignments yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _buildAnnouncementCard(assignment);
          },
        );
      },
    );
  }

  Widget _buildMessages(String studentId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _announcementsService.getStudentAnnouncements(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final announcements = snapshot.data ?? [];
        final messages = announcements.where((a) => a['type'] == 'message').toList();

        if (messages.isEmpty) {
          return _buildEmptyState(
            icon: Icons.message,
            title: 'No Messages',
            subtitle: 'You have no messages yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildAnnouncementCard(message);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({IconData? icon, String? title, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.campaign,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'No Announcements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? 'You have no announcements yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final isAssignment = announcement['type'] == 'assignment';
    final hasDueDate = announcement['dueDate'] != null;
    final dueDate = announcement['dueDate'];
    
    // Check if assignment is overdue
    bool isOverdue = false;
    if (isAssignment && hasDueDate) {
      DateTime dueDateTime;
      if (dueDate is Timestamp) {
        dueDateTime = dueDate.toDate();
      } else if (dueDate is DateTime) {
        dueDateTime = dueDate;
      } else {
        dueDateTime = DateTime.now();
      }
      isOverdue = DateTime.now().isAfter(dueDateTime);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAnnouncementDetails(announcement),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and subject
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getTypeColor(announcement['type']),
                    child: Icon(
                      _getTypeIcon(announcement['type']),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement['type']?.toString().toUpperCase() ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(announcement['type']),
                          ),
                        ),
                        if (announcement['subjectName'] != null)
                          Text(
                            announcement['subjectName'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isAssignment && hasDueDate)
                    Flexible(
                      flex: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Due: ${_formatDate(dueDate)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                announcement['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                announcement['content'] ?? '',
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer with points and date
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isAssignment && announcement['points'] != null) ...[
                          Flexible(
                            flex: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${announcement['points']} points',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 0,
                    child: Text(
                      _formatDate(announcement['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _getTypeColor(announcement['type']),
              child: Icon(
                _getTypeIcon(announcement['type']),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(announcement['title'] ?? 'Announcement Details'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type and subject
              Row(
                children: [
                  const Text(
                    'Type: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      announcement['type']?.toString().toUpperCase() ?? '',
                      style: TextStyle(
                        color: _getTypeColor(announcement['type']),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (announcement['subjectName'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        announcement['subjectName'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              if (announcement['points'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Points: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        '${announcement['points']} points',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              if (announcement['dueDate'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Due Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        _formatDate(announcement['dueDate']),
                        style: const TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Content
              Text(
                announcement['content'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Created date
              Text(
                'Posted: ${_formatDate(announcement['createdAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
