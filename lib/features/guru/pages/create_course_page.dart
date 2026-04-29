import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  String? selectedClass;
  bool isSubmitting = false;

  Future<void> _createCourse() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (_titleController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi semua field")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('courses').add({
        "title": _titleController.text.trim(),
        "subject": _subjectController.text.trim(),
        "classId": selectedClass,
        "teacherId": uid,
        "isActive": true,
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course berhasil dibuat")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat course: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _classStream() {
    return FirebaseFirestore.instance.collection('classes').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Course"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Judul Course",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Contoh: Penjelasan Biologi",
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Subject",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Contoh: IPA",
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Pilih Kelas",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _classStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final allClasses = snapshot.data!.docs;

                  final availableClasses = allClasses.where((doc) {
                    final data = doc.data();
                    final teacherIds = List<String>.from(
                      data['teacherIds'] as List<dynamic>? ?? [],
                    );
                    return teacherIds.contains(uid);
                  }).toList();

                  if (availableClasses.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Belum ada kelas yang diassign ke guru ini",
                      ),
                    );
                  }

                  if (selectedClass != null &&
                      !availableClasses.any((doc) => doc.id == selectedClass)) {
                    selectedClass = null;
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedClass,
                    items: availableClasses.map((doc) {
                      final data = doc.data();

                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? doc.id),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              selectedClass = value;
                            });
                          },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _createCourse,
                  child: Text(
                    isSubmitting ? "Menyimpan..." : "Create Course",
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