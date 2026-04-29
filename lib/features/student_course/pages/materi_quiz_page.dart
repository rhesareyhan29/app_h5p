import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../guru/services/student_progress_service.dart';

class QuizMaterialPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String courseTitle;

  const QuizMaterialPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.courseTitle,
  });

  @override
  State<QuizMaterialPage> createState() => _QuizMaterialPageState();
}

class _QuizMaterialPageState extends State<QuizMaterialPage> {
  int currentQuestionIndex = 0;

  bool isLoading = true;
  bool isSubmitting = false;
  bool isRetrying = false;
  bool allowRetry = false;

  String? errorMessage;
  String pageTitle = 'Quiz';
  List<Map<String, dynamic>> questions = [];

  final Map<int, int> selectedAnswers = {};
  final Map<int, String> essayAnswers = {};

  final TextEditingController _essayController = TextEditingController();

  Map<String, dynamic>? existingQuizResult;
  bool hasSubmitted = false;

  @override
  void initState() {
    super.initState();

    StudentProgressService.markMaterialOpened(
      courseId: widget.courseId,
      materialId: widget.materialId,
      materialType: 'quiz',
      courseTitle: widget.courseTitle,
      materialTitle: 'Quiz Material',
    );

    _loadQuizData();
  }

  @override
  void dispose() {
    _essayController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      final materialSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .get();

      final materialData = materialSnapshot.data() ?? {};

      final pageSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .orderBy('order')
          .get();

      if (pageSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Quiz belum tersedia";
        });
        return;
      }

      final pageDoc = pageSnapshot.docs.first;
      final pageData = pageDoc.data();
      final questionsRaw = pageData['questions'] as List<dynamic>? ?? [];

      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic>? resultData;

      if (user != null) {
        final resultSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quiz_results')
            .doc(widget.materialId)
            .get();

        resultData = resultSnapshot.data();
      }

      setState(() {
        pageTitle = pageData['title'] ?? 'Quiz';
        questions = questionsRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        allowRetry = materialData['allowRetry'] ?? false;
        existingQuizResult = resultData;
        hasSubmitted = resultData != null;

        selectedAnswers.clear();
        essayAnswers.clear();

        if (resultData != null) {
          final savedSelected =
              Map<String, dynamic>.from(resultData['selectedAnswers'] ?? {});
          final savedEssay =
              Map<String, dynamic>.from(resultData['essayAnswers'] ?? {});

          savedSelected.forEach((key, value) {
            selectedAnswers[int.parse(key)] = value as int;
          });

          savedEssay.forEach((key, value) {
            essayAnswers[int.parse(key)] = value.toString();
          });
        }

        isLoading = false;
      });

      _syncEssayController();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  void _syncEssayController() {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) return;

    final currentQuestion = questions[currentQuestionIndex];
    final type = currentQuestion['type'] ?? 'multiple_choice';

    if (type == 'essay') {
      _essayController.text = essayAnswers[currentQuestionIndex] ?? '';
    } else {
      _essayController.clear();
    }
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = optionIndex;
    });
  }

  void _updateEssayAnswer(String value) {
    essayAnswers[currentQuestionIndex] = value;
  }

  void _goToQuestion(int index) {
    setState(() {
      currentQuestionIndex = index;
    });
    _syncEssayController();
  }

  void _goNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _syncEssayController();
    }
  }

  void _goPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _syncEssayController();
    }
  }

  void _goBackToCourse(BuildContext context) {
    context.go(
      '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
    );
  }

  int _calculateScore() {
    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final type = question['type'] ?? 'multiple_choice';

      if (type == 'multiple_choice') {
        final correctAnswer = question['correctAnswer'];
        final selectedAnswer = selectedAnswers[i];

        if (selectedAnswer != null && selectedAnswer == correctAnswer) {
          score++;
        }
      }
    }

    return score;
  }

  Future<void> _saveQuizResult({
    required int score,
    required int totalQuestions,
    required int percentage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User belum login");
    }

    final selectedAnswersForFirestore = <String, int>{};
    selectedAnswers.forEach((key, value) {
      selectedAnswersForFirestore[key.toString()] = value;
    });

    final essayAnswersForFirestore = <String, String>{};
    essayAnswers.forEach((key, value) {
      essayAnswersForFirestore[key.toString()] = value.trim();
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .doc(widget.materialId)
        .set({
      "courseId": widget.courseId,
      "materialId": widget.materialId,
      "pageTitle": pageTitle,
      "score": score,
      "totalQuestions": totalQuestions,
      "percentage": percentage,
      "selectedAnswers": selectedAnswersForFirestore,
      "essayAnswers": essayAnswersForFirestore,
      "submittedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _submitQuiz() async {
    if (isSubmitting) return;

    final answeredMcCount = selectedAnswers.length;
    final answeredEssayCount = essayAnswers.values
        .where((value) => value.trim().isNotEmpty)
        .length;

    final totalAnswered = answeredMcCount + answeredEssayCount;
    final unansweredCount = questions.length - totalAnswered;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Submit Quiz"),
          content: Text(
            unansweredCount > 0
                ? "Masih ada $unansweredCount soal yang belum dijawab.\nApakah kamu yakin ingin submit?"
                : "Apakah kamu yakin ingin submit quiz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final score = _calculateScore();
      final total = questions.length;
      final percentage = total == 0 ? 0 : ((score / total) * 100).round();

      await _saveQuizResult(
        score: score,
        totalQuestions: total,
        percentage: percentage,
      );

      await StudentProgressService.markQuizSubmitted(
        courseId: widget.courseId,
        materialId: widget.materialId,
        courseTitle: widget.courseTitle,
        materialTitle: pageTitle,
      );

      await StudentProgressService.markMaterialCompleted(
        courseId: widget.courseId,
        materialId: widget.materialId,
        materialType: 'quiz',
        courseTitle: widget.courseTitle,
        materialTitle: pageTitle,
      );

      await _loadQuizData();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Quiz berhasil disubmit"),
            content: const Text(
              "Jawaban essay akan diperiksa guru. Buka kembali quiz ini untuk melihat hasil final dan feedback.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan hasil quiz: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _retryQuiz() async {
    if (isRetrying) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Ulangi Quiz"),
          content: const Text(
            "Hasil quiz sebelumnya akan dihapus dan kamu akan mengerjakan ulang dari awal. Lanjutkan?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Ulangi"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isRetrying = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User belum login");
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quiz_results')
          .doc(widget.materialId)
          .delete();

      setState(() {
        existingQuizResult = null;
        hasSubmitted = false;
        currentQuestionIndex = 0;
        selectedAnswers.clear();
        essayAnswers.clear();
        _essayController.clear();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz berhasil direset. Silakan kerjakan ulang.")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengulang quiz: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRetrying = false;
        });
      }
    }
  }

  Widget _buildResultView() {
    final result = existingQuizResult ?? {};
    final totalQuestions = (result['totalQuestions'] ?? questions.length) as int;
    final initialCorrect = (result['score'] ?? 0) as int;
    final initialPercent = (result['percentage'] ?? 0) as int;
    final finalCorrect = result['finalCorrectCount'] ?? initialCorrect;
    final finalPercent = result['finalPercentage'] ?? initialPercent;
    final essayReview =
        Map<String, dynamic>.from(result['essayReview'] ?? {});

    final essayItems = <Map<String, dynamic>>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      if ((q['type'] ?? 'multiple_choice') == 'essay') {
        essayItems.add({
          "index": i,
          "question": q['question'] ?? '-',
          "answer": essayAnswers[i] ?? '',
          "review": essayReview['$i'] != null
              ? Map<String, dynamic>.from(essayReview['$i'] as Map)
              : null,
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C4D8A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1530),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF01A7C2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBackToCourse(context),
                      child: Text(
                        widget.courseTitle,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        " / $pageTitle",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 2, color: Colors.white),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Hasil Quiz",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text("Nilai awal: $initialPercent%"),
                                const SizedBox(height: 6),
                                Text("Nilai final: $finalPercent%"),
                                const SizedBox(height: 6),
                                Text("Jawaban benar final: $finalCorrect / $totalQuestions"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Review Essay",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (essayItems.isEmpty)
                            const Text("Tidak ada soal essay pada quiz ini.")
                          else
                            ...essayItems.map((item) {
                              final review = item['review'] as Map<String, dynamic>?;
                              final reviewed = review != null;
                              final isCorrect = review?['isCorrect'];
                              final feedback = review?['feedback'] ?? '-';

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['question'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Jawaban Anda",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (item['answer'] as String).isEmpty
                                          ? "-"
                                          : item['answer'],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      reviewed
                                          ? "Status: ${isCorrect == true ? 'Benar' : 'Salah'}"
                                          : "Status: Menunggu review guru",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: reviewed
                                            ? (isCorrect == true
                                                ? Colors.green.shade700
                                                : Colors.red.shade700)
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text("Feedback: $feedback"),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (allowRetry)
                      ElevatedButton.icon(
                        onPressed: isRetrying ? null : _retryQuiz,
                        icon: isRetrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(isRetrying ? "Mereset..." : "Ulangi Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    if (allowRetry) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _goBackToCourse(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Kembali"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (currentQuestionIndex >= questions.length) {
      currentQuestionIndex = questions.length - 1;
    }

    final currentQuestion = questions[currentQuestionIndex];
    final type = currentQuestion['type'] ?? 'multiple_choice';
    final selectedOption = selectedAnswers[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    final options = type == 'multiple_choice'
        ? List<String>.from(currentQuestion["options"] as List<dynamic>? ?? [])
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0C4D8A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1530),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF01A7C2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBackToCourse(context),
                      child: Text(
                        widget.courseTitle,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        " / $pageTitle",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 2,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Text(
                                  currentQuestion["question"] ?? '',
                                  key: ValueKey(currentQuestionIndex),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                              if (type == 'multiple_choice') ...[
                                ...List.generate(options.length, (index) {
                                  final isSelected = selectedOption == index;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 28),
                                    child: InkWell(
                                      onTap: isSubmitting
                                          ? null
                                          : () => _selectAnswer(index),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 120),
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              "${String.fromCharCode(65 + index)}. ${options[index]}",
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ] else ...[
                                TextField(
                                  controller: _essayController,
                                  enabled: !isSubmitting,
                                  maxLines: 10,
                                  onChanged: _updateEssayAnswer,
                                  decoration: InputDecoration(
                                    hintText: "Tulis jawaban essay di sini...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 450,
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB33951),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: GridView.builder(
                                  itemCount: questions.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final question = questions[index];
                                    final qType = question['type'] ?? 'multiple_choice';

                                    final isCurrent = index == currentQuestionIndex;

                                    final isAnswered = qType == 'essay'
                                        ? (essayAnswers[index]?.trim().isNotEmpty ?? false)
                                        : selectedAnswers.containsKey(index);

                                    Color bgColor = const Color(0xFF01A7C2);

                                    if (isCurrent) {
                                      bgColor = Colors.black;
                                    } else if (isAnswered) {
                                      bgColor = const Color(0xFF0C4D8A);
                                    }

                                    return InkWell(
                                      onTap: isSubmitting
                                          ? null
                                          : () => _goToQuestion(index),
                                      borderRadius: BorderRadius.circular(16),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    height: 65,
                                    child: ElevatedButton(
                                      onPressed: (currentQuestionIndex > 0 && !isSubmitting)
                                          ? _goPreviousQuestion
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    height: 65,
                                    child: ElevatedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : (isLastQuestion
                                              ? _submitQuiz
                                              : _goNextQuestion),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: isSubmitting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              isLastQuestion
                                                  ? Icons.check
                                                  : Icons.arrow_forward,
                                              size: 34,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C4D8A),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C4D8A),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => _goBackToCourse(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(errorMessage!),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C4D8A),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => _goBackToCourse(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Quiz belum tersedia"),
          ),
        ),
      );
    }

    if (hasSubmitted) {
      return _buildResultView();
    }

    return _buildQuizView();
  }
}