import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EssayReviewPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String courseId;
  final String materialId;
  final String materialTitle;

  const EssayReviewPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<EssayReviewPage> createState() => _EssayReviewPageState();
}

class _EssayReviewPageState extends State<EssayReviewPage> {
  bool isSaving = false;

  Future<Map<String, dynamic>> _loadReviewData() async {
    final materialPageSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(widget.materialId)
        .collection('pages')
        .doc('page_1')
        .get();

    final resultSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentId)
        .collection('quiz_results')
        .doc(widget.materialId)
        .get();

    return {
      "pageData": materialPageSnapshot.data() ?? {},
      "resultData": resultSnapshot.data() ?? {},
    };
  }

  Future<void> _saveEssayReview({
    required int questionIndex,
    required bool isCorrect,
    required String feedback,
  }) async {
    setState(() {
      isSaving = true;
    });

    try {
      final resultRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('quiz_results')
          .doc(widget.materialId);

      final resultSnapshot = await resultRef.get();
      final resultData = resultSnapshot.data() ?? {};

      final selectedAnswers =
          Map<String, dynamic>.from(resultData['selectedAnswers'] ?? {});
      final essayReview =
          Map<String, dynamic>.from(resultData['essayReview'] ?? {});
      final totalQuestions = (resultData['totalQuestions'] ?? 0) as int;

      essayReview["$questionIndex"] = {
        "isCorrect": isCorrect,
        "feedback": feedback.trim(),
        "reviewedAt": FieldValue.serverTimestamp(),
      };

      int mcCorrectCount = 0;
      final pageSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc('page_1')
          .get();

      final pageData = pageSnapshot.data() ?? {};
      final questionsRaw = pageData['questions'] as List<dynamic>? ?? [];
      final questions = questionsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final type = q['type'] ?? 'multiple_choice';

        if (type == 'multiple_choice') {
          final selected = selectedAnswers['$i'];
          final correct = q['correctAnswer'];
          if (selected != null && selected == correct) {
            mcCorrectCount++;
          }
        }
      }

      int essayCorrectCount = 0;
      essayReview.forEach((key, value) {
        final review = Map<String, dynamic>.from(value as Map);
        if (review['isCorrect'] == true) {
          essayCorrectCount++;
        }
      });

      final finalCorrectCount = mcCorrectCount + essayCorrectCount;
      final finalPercentage = totalQuestions == 0
          ? 0
          : ((finalCorrectCount / totalQuestions) * 100).round();

      await resultRef.set({
        "essayReview": essayReview,
        "finalCorrectCount": finalCorrectCount,
        "finalPercentage": finalPercentage,
        "isEssayReviewed": true,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review essay berhasil disimpan")),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan review: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _openReviewDialog({
    required int questionIndex,
    required String questionText,
    required String studentAnswer,
    Map<String, dynamic>? existingReview,
  }) async {
    bool selectedIsCorrect = existingReview?['isCorrect'] ?? true;
    final feedbackController = TextEditingController(
      text: existingReview?['feedback'] ?? '',
    );

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Review Jawaban Essay"),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Soal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(questionText),
                      const SizedBox(height: 16),
                      const Text(
                        "Jawaban Siswa",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(studentAnswer.isEmpty ? "-" : studentAnswer),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<bool>(
                        value: selectedIsCorrect,
                        decoration: const InputDecoration(
                          labelText: "Penilaian",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text("Benar"),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text("Salah"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedIsCorrect = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: feedbackController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Feedback",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(true);

                    await _saveEssayReview(
                      questionIndex: questionIndex,
                      isCorrect: selectedIsCorrect,
                      feedback: feedbackController.text,
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Essay - ${widget.studentName}"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadReviewData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pageData = snapshot.data!['pageData'] as Map<String, dynamic>;
          final resultData = snapshot.data!['resultData'] as Map<String, dynamic>;

          final questionsRaw = pageData['questions'] as List<dynamic>? ?? [];
          final essayAnswers =
              Map<String, dynamic>.from(resultData['essayAnswers'] ?? {});
          final essayReview =
              Map<String, dynamic>.from(resultData['essayReview'] ?? {});
          final finalCorrectCount = resultData['finalCorrectCount'];
          final finalPercentage = resultData['finalPercentage'];

          final questions = questionsRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final essayQuestions = <Map<String, dynamic>>[];

          for (int i = 0; i < questions.length; i++) {
            final q = questions[i];
            if (q['type'] == 'essay') {
              essayQuestions.add({
                "index": i,
                "question": q,
              });
            }
          }

          if (essayQuestions.isEmpty) {
            return const Center(
              child: Text("Tidak ada soal essay pada quiz ini"),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (finalCorrectCount != null || finalPercentage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Nilai akhir saat ini: ${finalCorrectCount ?? '-'} benar • ${finalPercentage ?? '-'}%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: essayQuestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = essayQuestions[index];
                      final questionIndex = item['index'] as int;
                      final question =
                          item['question'] as Map<String, dynamic>;

                      final questionText = question['question'] ?? '-';
                      final studentAnswer =
                          essayAnswers['$questionIndex']?.toString() ?? '';
                      final reviewData = essayReview['$questionIndex'] != null
                          ? Map<String, dynamic>.from(
                              essayReview['$questionIndex'] as Map,
                            )
                          : null;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Soal Essay ${index + 1}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                questionText,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Jawaban Siswa",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  studentAnswer.isEmpty ? "-" : studentAnswer,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (reviewData != null) ...[
                                Text(
                                  "Status: ${reviewData['isCorrect'] == true ? 'Benar' : 'Salah'}",
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Feedback: ${reviewData['feedback'] ?? '-'}",
                                ),
                                const SizedBox(height: 12),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          _openReviewDialog(
                                            questionIndex: questionIndex,
                                            questionText: questionText,
                                            studentAnswer: studentAnswer,
                                            existingReview: reviewData,
                                          );
                                        },
                                  icon: const Icon(Icons.rate_review_outlined),
                                  label: Text(
                                    reviewData == null
                                        ? "Review"
                                        : "Edit Review",
                                  ),
                                ),
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
          );
        },
      ),
    );
  }
}