import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseStudentPage extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const CourseStudentPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _materialsStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('materials')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('COURSE ID = $courseId');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [


          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1430),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C4D8A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                context.go('/siswa');
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              courseTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.5),
                        ),

                        const SizedBox(height: 24),

                        // LIST MATERI
                        Expanded(
                          child: StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: _materialsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const _EmptyMaterial();
                              }

                              final docs = snapshot.data!.docs;

                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();

                                  return _MaterialCard(
                                    title: data['title'] ?? '-',
                                    type: data['type'] ?? '',
                                    courseId: courseId,
                                    materialId: docs[index].id,
                                    courseTitle: courseTitle,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatefulWidget {
  final String title;
  final String type;
  final String courseId;
  final String materialId;
  final String courseTitle;

  const _MaterialCard({
    required this.title,
    required this.type,
    required this.courseId,
    required this.materialId,
    required this.courseTitle,
  });

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  bool _hover = false;

  IconData _iconFromType() {
    switch (widget.type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'dragdrop':
        return Icons.extension_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go (
          '/course/${widget.courseId}/material/${widget.materialId}?title=${Uri.encodeComponent(widget.courseTitle)}',
        );
      },
      child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF01A7C2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFB33951),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFromType(),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _EmptyMaterial extends StatelessWidget {
  const _EmptyMaterial();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.menu_book_outlined,
            color: Colors.white70,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada materi pada course ini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
