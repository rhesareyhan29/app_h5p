import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizEditorPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String materialTitle;

  const QuizEditorPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  bool _isSubmitting = false;
  bool _allowRetry = false;
  bool _isLoadingSetting = true;

  @override
  void initState() {
    super.initState();
    _loadQuizSetting();
  }

  Future<void> _loadQuizSetting() async {
    try {
      final materialSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .get();

      final data = materialSnapshot.data() ?? {};

      setState(() {
        _allowRetry = data['allowRetry'] ?? false;
        _isLoadingSetting = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSetting = false;
      });
    }
  }

  Future<void> _updateAllowRetry(bool value) async {
    setState(() {
      _allowRetry = value;
    });

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .set({
        "allowRetry": value,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? "Quiz sekarang boleh diulang siswa"
                : "Quiz sekarang tidak boleh diulang siswa",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan setting quiz: $e")),
      );
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _quizPageStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(widget.materialId)
        .collection('pages')
        .doc('page_1')
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> _ensureQuizPageExists() async {
    final pageRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(widget.materialId)
        .collection('pages')
        .doc('page_1');

    final snapshot = await pageRef.get();

    if (!snapshot.exists) {
      await pageRef.set({
        "title": widget.materialTitle,
        "order": 1,
        "questions": [],
      });
    }

    return pageRef;
  }

  Future<void> _openQuestionDialog({
    Map<String, dynamic>? existingQuestion,
    int? editIndex,
  }) async {
    if (_isSubmitting) return;

    final questionController = TextEditingController(
      text: existingQuestion?['question'] ?? '',
    );

    String selectedType = existingQuestion?['type'] ?? 'multiple_choice';

    final optionAController = TextEditingController(
      text: existingQuestion != null &&
              (existingQuestion['options'] as List<dynamic>?) != null &&
              (existingQuestion['options'] as List<dynamic>).isNotEmpty
          ? existingQuestion['options'][0]
          : '',
    );
    final optionBController = TextEditingController(
      text: existingQuestion != null &&
              (existingQuestion['options'] as List<dynamic>?) != null &&
              (existingQuestion['options'] as List<dynamic>).length > 1
          ? existingQuestion['options'][1]
          : '',
    );
    final optionCController = TextEditingController(
      text: existingQuestion != null &&
              (existingQuestion['options'] as List<dynamic>?) != null &&
              (existingQuestion['options'] as List<dynamic>).length > 2
          ? existingQuestion['options'][2]
          : '',
    );
    final optionDController = TextEditingController(
      text: existingQuestion != null &&
              (existingQuestion['options'] as List<dynamic>?) != null &&
              (existingQuestion['options'] as List<dynamic>).length > 3
          ? existingQuestion['options'][3]
          : '',
    );

    int selectedCorrectAnswer = existingQuestion?['correctAnswer'] ?? 0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isMultipleChoice = selectedType == 'multiple_choice';

            return AlertDialog(
              title: Text(
                existingQuestion == null ? "Tambah Soal" : "Edit Soal",
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Tipe Soal",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'multiple_choice',
                            child: Text("Pilihan Ganda"),
                          ),
                          DropdownMenuItem(
                            value: 'essay',
                            child: Text("Essay"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: questionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Pertanyaan",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isMultipleChoice) ...[
                        TextField(
                          controller: optionAController,
                          decoration: const InputDecoration(
                            labelText: "Opsi A",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: optionBController,
                          decoration: const InputDecoration(
                            labelText: "Opsi B",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: optionCController,
                          decoration: const InputDecoration(
                            labelText: "Opsi C",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: optionDController,
                          decoration: const InputDecoration(
                            labelText: "Opsi D",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedCorrectAnswer,
                          decoration: const InputDecoration(
                            labelText: "Jawaban Benar",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text("A")),
                            DropdownMenuItem(value: 1, child: Text("B")),
                            DropdownMenuItem(value: 2, child: Text("C")),
                            DropdownMenuItem(value: 3, child: Text("D")),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedCorrectAnswer = value;
                            });
                          },
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: const Text(
                            "Soal essay akan diperiksa manual oleh guru.",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedType == 'multiple_choice') {
                      Navigator.of(dialogContext).pop({
                        "type": "multiple_choice",
                        "question": questionController.text.trim(),
                        "options": [
                          optionAController.text.trim(),
                          optionBController.text.trim(),
                          optionCController.text.trim(),
                          optionDController.text.trim(),
                        ],
                        "correctAnswer": selectedCorrectAnswer,
                      });
                    } else {
                      Navigator.of(dialogContext).pop({
                        "type": "essay",
                        "question": questionController.text.trim(),
                        "gradingMode": "manual",
                      });
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final type = result["type"] as String? ?? "multiple_choice";
    final question = result["question"] as String? ?? "";

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pertanyaan wajib diisi")),
      );
      return;
    }

    Map<String, dynamic> newQuestion;

    if (type == 'multiple_choice') {
      final options = List<String>.from(result["options"] as List<dynamic>);
      final correctAnswer = result["correctAnswer"] as int;

      if (options.any((option) => option.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua opsi wajib diisi")),
        );
        return;
      }

      newQuestion = {
        "questionId": existingQuestion?['questionId'] ??
            "q_${DateTime.now().millisecondsSinceEpoch}",
        "type": "multiple_choice",
        "question": question,
        "options": options,
        "correctAnswer": correctAnswer,
      };
    } else {
      newQuestion = {
        "questionId": existingQuestion?['questionId'] ??
            "q_${DateTime.now().millisecondsSinceEpoch}",
        "type": "essay",
        "question": question,
        "gradingMode": "manual",
      };
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final pageRef = await _ensureQuizPageExists();
      final snapshot = await pageRef.get();
      final data = snapshot.data() ?? {};
      final questions = List<Map<String, dynamic>>.from(
        (data['questions'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (editIndex != null) {
        questions[editIndex] = newQuestion;
      } else {
        questions.add(newQuestion);
      }

      await pageRef.update({
        "questions": questions,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editIndex != null
                ? "Soal berhasil diperbarui"
                : "Soal berhasil ditambahkan",
          ),
        ),
      );
    } catch (e) {
      debugPrint("SAVE QUESTION ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan soal: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion(int index) async {
    if (_isSubmitting) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hapus Soal"),
          content: const Text("Apakah yakin ingin menghapus soal ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final pageRef = await _ensureQuizPageExists();
      final snapshot = await pageRef.get();
      final data = snapshot.data() ?? {};
      final questions = List<Map<String, dynamic>>.from(
        (data['questions'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (index < 0 || index >= questions.length) return;

      questions.removeAt(index);

      await pageRef.update({
        "questions": questions,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Soal berhasil dihapus")),
      );
    } catch (e) {
      debugPrint("DELETE QUESTION ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus soal: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'essay':
        return 'Essay';
      case 'multiple_choice':
      default:
        return 'Pilihan Ganda';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSetting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz Editor - ${widget.materialTitle}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Izinkan Siswa Mengulang Quiz",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Jika aktif, siswa yang sudah submit bisa mengerjakan ulang quiz dan essay.",
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _allowRetry,
                    onChanged: _updateAllowRetry,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _openQuestionDialog();
                        },
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Soal"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _quizPageStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text("Belum ada soal quiz"),
                    );
                  }

                  final data = snapshot.data!.data() ?? {};
                  final questionsRaw = data['questions'] as List<dynamic>? ?? [];

                  if (questionsRaw.isEmpty) {
                    return const Center(
                      child: Text("Belum ada soal quiz"),
                    );
                  }

                  final questions = questionsRaw
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  return ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final type = question['type'] ?? 'multiple_choice';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Soal ${index + 1}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _questionTypeLabel(type),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(question['question'] ?? ''),
                              const SizedBox(height: 12),
                              if (type == 'multiple_choice') ...[
                                ...List.generate(
                                  (question['options'] as List<dynamic>? ?? [])
                                      .length,
                                  (optionIndex) {
                                    final options = List<String>.from(
                                      question['options'] as List<dynamic>? ?? [],
                                    );
                                    final correctAnswer =
                                        question['correctAnswer'] ?? 0;
                                    final label =
                                        String.fromCharCode(65 + optionIndex);
                                    final isCorrect =
                                        optionIndex == correctAnswer;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        "$label. ${options[optionIndex]}${isCorrect ? '  ✅' : ''}",
                                      ),
                                    );
                                  },
                                ),
                              ] else ...[
                                Text(
                                  "Mode penilaian: ${question['gradingMode'] ?? 'manual'}",
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            _openQuestionDialog(
                                              existingQuestion: question,
                                              editIndex: index,
                                            );
                                          },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            _deleteQuestion(index);
                                          },
                                  ),
                                ],
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
      ),
    );
  }
}