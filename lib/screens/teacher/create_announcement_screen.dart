import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/announcements_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _pointsController = TextEditingController();

  String _selectedType = 'announcement';
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  List<String> _selectedStudentIds = [];
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _availableStudents = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) return;

    final snapshot = await _firestore
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    setState(() {
      _subjects = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  Future<void> _loadStudents() async {
    final announcementsService = AnnouncementsService();
    final students = await announcementsService.getAllStudents();
    
    setState(() {
      _students = students;
      _availableStudents = students;
    });
  }

  Future<void> _loadStudentsForSubject(String subjectId) async {
    final announcementsService = AnnouncementsService();
    final students = await announcementsService.getStudentsForSubject(subjectId);
    
    setState(() {
      _availableStudents = students;
      _selectedStudentIds.clear(); // Clear selection when subject changes
    });
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectStudents() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _StudentSelectionDialog(
        students: _availableStudents,
        selectedStudentIds: _selectedStudentIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStudentIds = result;
      });
    }
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final announcementsService = AnnouncementsService();
      
      await announcementsService.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        subjectId: _selectedSubjectId,
        subjectName: _selectedSubjectName,
        targetStudentIds: _selectedStudentIds.isEmpty ? null : _selectedStudentIds,
        dueDate: _selectedDueDate,
        points: _selectedType == 'assignment' && _pointsController.text.isNotEmpty
            ? int.tryParse(_pointsController.text)
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitAnnouncement,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selection
              Text(
                'Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Announcement'),
                      value: 'announcement',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Message'),
                      value: 'message',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Assignment'),
                      value: 'assignment',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subject Selection
              Text(
                'Subject (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a subject',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No specific subject'),
                  ),
                  ..._subjects.map((subject) => DropdownMenuItem<String>(
                    value: subject['id'],
                    child: Text(subject['name']),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                    _selectedSubjectName = value != null
                        ? _subjects.firstWhere((s) => s['id'] == value)['name']
                        : null;
                  });
                  
                  if (value != null) {
                    _loadStudentsForSubject(value);
                  } else {
                    setState(() {
                      _availableStudents = _students;
                      _selectedStudentIds.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Points (for assignments)
              if (_selectedType == 'assignment') ...[
                TextFormField(
                  controller: _pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points (Optional)',
                    border: OutlineInputBorder(),
                    suffixText: 'points',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final points = int.tryParse(value);
                      if (points == null || points < 0) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Due Date (for assignments)
              if (_selectedType == 'assignment') ...[
                Text(
                  'Due Date (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDueDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDueDate != null
                              ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year} at ${_selectedDueDate!.hour.toString().padLeft(2, '0')}:${_selectedDueDate!.minute.toString().padLeft(2, '0')}'
                              : 'Select due date and time',
                          style: TextStyle(
                            color: _selectedDueDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _selectedDueDate = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Target Students
              Text(
                'Target Students',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectStudents,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedStudentIds.isEmpty
                              ? 'All students'
                              : '${_selectedStudentIds.length} student(s) selected',
                          style: TextStyle(
                            color: _selectedStudentIds.isEmpty ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnnouncement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish Announcement',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<String> selectedStudentIds;

  const _StudentSelectionDialog({
    required this.students,
    required this.selectedStudentIds,
  });

  @override
  State<_StudentSelectionDialog> createState() => _StudentSelectionDialogState();
}

class _StudentSelectionDialogState extends State<_StudentSelectionDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedStudentIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Students'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Select All / Deselect All buttons
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIds = widget.students.map((s) => s['id'] as String).toList();
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                    });
                  },
                  child: const Text('Deselect All'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                    });
                  },
                  child: const Text('Send to All'),
                ),
              ],
            ),
            const Divider(),
            
            // Students list
            Expanded(
              child: ListView.builder(
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  final isSelected = _selectedIds.contains(student['id']);
                  
                  return CheckboxListTile(
                    title: Text(student['name'] ?? 'Unknown Student'),
                    subtitle: Text(student['email'] ?? ''),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(student['id']);
                        } else {
                          _selectedIds.remove(student['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
