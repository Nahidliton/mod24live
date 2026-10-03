import 'package:flutter/material.dart';

// A small local provider implementation keeps this screen self-contained.
class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext) create;
  final Widget child;

  const ChangeNotifierProvider({
    super.key,
    required this.create,
    required this.child,
  });

  @override
  State<ChangeNotifierProvider<T>> createState() =>
      _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  late final T _notifier = widget.create(context);

  @override
  Widget build(BuildContext context) =>
      _AttendanceScope<T>(notifier: _notifier, child: widget.child);

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }
}

class _AttendanceScope<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const _AttendanceScope({required super.notifier, required super.child});
}

extension AttendanceProviderContext on BuildContext {
  T watch<T extends ChangeNotifier>() {
    final scope = dependOnInheritedWidgetOfExactType<_AttendanceScope<T>>();
    final notifier = scope?.notifier;
    if (notifier == null) {
      throw StateError('No ChangeNotifierProvider<$T> found in context.');
    }
    return notifier;
  }

  T read<T extends ChangeNotifier>() {
    final element = getElementForInheritedWidgetOfExactType<_AttendanceScope<T>>();
    if (element == null) {
      throw StateError('No ChangeNotifierProvider<$T> found in context.');
    }
    final notifier = (element.widget as _AttendanceScope<T>).notifier;
    if (notifier == null) {
      throw StateError('ChangeNotifierProvider<$T> has no notifier.');
    }
    return notifier;
  }
}

// ------------------- Student Model -------------------
class Student {
  final String id;
  final String name;
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    this.isPresent = false,
  });
}

// ------------------- Attendance Provider -------------------
class AttendanceProvider extends ChangeNotifier {
  final List<Student> _students = [
    Student(id: '1', name: 'Alice Johnson', isPresent: true),
    Student(id: '2', name: 'Bob Smith', isPresent: false),
    Student(id: '3', name: 'Charlie Brown', isPresent: true),
    Student(id: '4', name: 'Diana Prince', isPresent: false),
    Student(id: '5', name: 'Ethan Hunt', isPresent: true),
    Student(id: '6', name: 'Fiona Green', isPresent: false),
    Student(id: '7', name: 'George Miller', isPresent: true),
    Student(id: '8', name: 'Hannah Lee', isPresent: false),
  ];

  // Return a plain copy — safe for UI iteration
  List<Student> get students => List<Student>.from(_students);

  int get totalStudents => _students.length;
  int get presentCount => _students.where((s) => s.isPresent).length;
  int get absentCount => _students.where((s) => !s.isPresent).length;

  void addStudent(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _students.add(
      Student(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
      ),
    );
    notifyListeners();
  }

  void toggleAttendance(String id, bool isPresent) {
    final index = _students.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _students[index].isPresent = isPresent;
    notifyListeners(); // 🔑 this is what refreshes the UI
  }

  void removeStudent(String id) {
    final before = _students.length;
    _students.removeWhere((s) => s.id == id);
    if (_students.length != before) {
      notifyListeners(); // 🔑 only notify if something actually changed
    }
  }
}

// ------------------- Main App -------------------
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AttendanceProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AttendanceScreen(),
    );
  }
}

// ------------------- Attendance Screen -------------------
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                hintText: 'Enter full name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context
                      .read<AttendanceProvider>()
                      .addStudent(nameController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final students = provider.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance Tracker'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ---------- Statistics ----------
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Total',
                      value: provider.totalStudents,
                      color: Colors.indigo,
                    ),
                    _StatItem(
                      label: 'Present',
                      value: provider.presentCount,
                      color: Colors.green,
                    ),
                    _StatItem(
                      label: 'Absent',
                      value: provider.absentCount,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- Student List ----------
          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No students added yet.\nTap + to add a student.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: student.isPresent
                                ? Colors.green
                                : Colors.red,
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            student.isPresent ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: student.isPresent
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: student.isPresent,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  // 🔑 read() for the action
                                  context
                                      .read<AttendanceProvider>()
                                      .toggleAttendance(
                                        student.id,
                                        value ?? false,
                                      );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove Student',
                                onPressed: () {
                                  context
                                      .read<AttendanceProvider>()
                                      .removeStudent(student.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ------------------- Stat Item Widget -------------------
class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}