import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'essay_review_page.dart';

class StudentActivityPage extends StatefulWidget {
  const StudentActivityPage({super.key});

  @override
  State<StudentActivityPage> createState() => _StudentActivityPageState();
}

class _StudentActivityPageState extends State<StudentActivityPage> {
  String? selectedStudentId;
  String? selectedStudentName;

  Future<List<String>> _getTeacherClassIds() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: uid)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<String>>(
        future: _getTeacherClassIds(),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (classSnapshot.hasError) {
            return Center(
              child: Text("Error: ${classSnapshot.error}"),
            );
          }

          final classIds = classSnapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Kembali"),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Aktivitas Siswa",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: classIds.isEmpty
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C4D8A),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              "Guru belum diassign ke kelas mana pun",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 360,
                              child: _StudentListPanel(
                                classIds: classIds,
                                selectedStudentId: selectedStudentId,
                                onSelectStudent: (studentId, studentName) {
                                  setState(() {
                                    selectedStudentId = studentId;
                                    selectedStudentName = studentName;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: selectedStudentId == null
                                  ? const _EmptyStudentDetail()
                                  : _StudentDetailPanel(
                                      studentId: selectedStudentId!,
                                      studentName: selectedStudentName ?? '-',
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentListPanel extends StatelessWidget {
  final List<String> classIds;
  final String? selectedStudentId;
  final void Function(String studentId, String studentName) onSelectStudent;

  const _StudentListPanel({
    required this.classIds,
    required this.selectedStudentId,
    required this.onSelectStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C4D8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daftar Siswa",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 2, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'siswa')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return classIds.contains(data['classId']);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada siswa di kelas guru ini",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final isSelected = selectedStudentId == doc.id;

                    return InkWell(
                      onTap: () {
                        onSelectStudent(doc.id, data['name'] ?? '-');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF01A7C2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Kelas ${data['classId'] ?? '-'}",
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDetailPanel extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _StudentDetailPanel({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C4D8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aktivitas $studentName",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 2, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _ProgressSection(studentId: studentId),
                  const SizedBox(height: 20),
                  _QuizResultSection(
                    studentId: studentId,
                    studentName: studentName,
                    ),
                  const SizedBox(height: 20),
                  _ActivityLogSection(studentId: studentId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final String studentId;

  const _ProgressSection({
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Progress Course",
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('course_progress')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Text("Belum ada progress");
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final progress = data['progressPercent'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Course ID: ${doc.id}"),
                    ),
                    SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        value: (progress / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("$progress%"),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _QuizResultSection extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _QuizResultSection({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Hasil Quiz",
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('quiz_results')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Text("Belum ada hasil quiz");
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final courseId = data['courseId'] ?? '';
              final materialId = data['materialId'] ?? '';
              final pageTitle = data['pageTitle'] ?? doc.id;
              final essayAnswers =
                  Map<String, dynamic>.from(data['essayAnswers'] ?? {});
              final hasEssay = essayAnswers.isNotEmpty;

              final displayCorrect =
                  data['finalCorrectCount'] ?? data['score'] ?? 0;
              final displayPercent =
                  data['finalPercentage'] ?? data['percentage'] ?? 0;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(pageTitle),
                subtitle: Text(
                  "Benar: $displayCorrect/${data['totalQuestions'] ?? 0}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$displayPercent%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasEssay) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EssayReviewPage(
                                studentId: studentId,
                                studentName: studentName,
                                courseId: courseId,
                                materialId: materialId,
                                materialTitle: pageTitle,
                              ),
                            ),
                          );
                        },
                        child: const Text("Review Essay"),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ActivityLogSection extends StatelessWidget {
  final String studentId;

  const _ActivityLogSection({
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Riwayat Aktivitas",
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('activity_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Text("Belum ada activity log");
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final action = data['action'] ?? '-';
              final materialType = data['materialType'] ?? '-';
              final materialTitle = data['materialTitle'] ?? '-';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(materialTitle),
                subtitle: Text("Action: $action • Type: $materialType"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyStudentDetail extends StatelessWidget {
  const _EmptyStudentDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C4D8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          "Pilih siswa untuk melihat aktivitas",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}