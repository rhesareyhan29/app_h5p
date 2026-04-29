import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../guru/services/student_progress_service.dart';

class ParagraphMaterialPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String courseTitle;

  const ParagraphMaterialPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.courseTitle,
  });

  @override
  State<ParagraphMaterialPage> createState() => _ParagraphMaterialPageState();
}

class _ParagraphMaterialPageState extends State<ParagraphMaterialPage> {
  int currentPageIndex = 0;

  @override
  void didUpdateWidget(covariant ParagraphMaterialPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // reset index saat pindah material
    if (oldWidget.materialId != widget.materialId ||
        oldWidget.courseId != widget.courseId) {
      currentPageIndex = 0;
    }
  }

  @override
  void initState() {
    super.initState();

    StudentProgressService.markMaterialOpened(
      courseId: widget.courseId,
      materialId: widget.materialId,
      materialType: 'paragraph',
      courseTitle: widget.courseTitle,
      materialTitle: 'Paragraph Material',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _pagesStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(widget.materialId)
        .collection('pages')
        .orderBy('order')
        .snapshots();
  }

  Future<String?> _findNextMaterialWithPages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    final docs = snapshot.docs;

    if (docs.isEmpty) return null;

    final currentMaterialIndex =
      docs.indexWhere((doc) => doc.id == widget.materialId);

    if (currentMaterialIndex == -1) return null;

    for (int i = currentMaterialIndex + 1; i < docs.length; i++) {
      final material = docs[i];

      final pagesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(material.id)
        .collection('pages')
        .limit(1)
        .get();

      if (pagesSnapshot.docs.isNotEmpty) {
      return material.id;
      }
    }

    return null;
  }

  Future<void> _goToNextMaterial(BuildContext context) async {
    final nextMaterialId = await _findNextMaterialWithPages();

    if (nextMaterialId == null) {
      if (!mounted) return;
      context.go(
        '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
      );
      return;
    }

    if (!mounted) return;
    context.go(
      '/course/${widget.courseId}/material/$nextMaterialId?title=${Uri.encodeComponent(widget.courseTitle)}',
    );
  }

  Future<void> _nextPage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String currentPageTitle,
  ) async {
    if (docs.isEmpty) return;

    if (currentPageIndex < docs.length - 1) {
      setState(() {
        currentPageIndex++;
      });
      return;
    }

    await StudentProgressService.markMaterialCompleted(
      courseId: widget.courseId,
      materialId: widget.materialId,
      materialType: 'paragraph',
      courseTitle: widget.courseTitle,
      materialTitle: 'Paragraph Material',
    );

    await _goToNextMaterial(context);
  }

  void _previousPage() {
    if (currentPageIndex > 0) {
      setState(() {
        currentPageIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: () {
                context.go(
                  '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Kembali ke daftar materi"),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // jaga agar index tidak keluar batas
        if (currentPageIndex >= docs.length) {
          currentPageIndex = docs.length - 1;
        }

        final pageData = docs[currentPageIndex].data();
        final pageTitle = pageData['title'] ?? 'Page';
        final activities = pageData['activities'] as List<dynamic>? ?? [];

        return Stack(
          children: [
            Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1530),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01A7C2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BREADCRUMB / TITLE
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go(
                                '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
                              );
                            },
                            child: Text(
                              widget.courseTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            " / $pageTitle",
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),

                      // CONTENT
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: activities.map((activity) {
                                if (activity['type'] == 'text') {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      activity['content'] ?? '',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }

                                if (activity['type'] == 'image') {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.network(
                                          activity['url'],
                                          errorBuilder: (_, __, ___) {
                                            return Container(
                                              height: 220,
                                              width: double.infinity,
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Text("Gagal memuat gambar"),
                                            );
                                          },
                                        ),
                                        if ((activity['caption'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              activity['caption'],
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }

                                return const SizedBox();
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // PREVIOUS
            Positioned(
              bottom: 40,
              left: 40,
              child: IconButton(
                iconSize: 40,
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: currentPageIndex > 0 ? _previousPage : null,
              ),
            ),

            // NEXT / BACK TO COURSE
            Positioned(
              bottom: 40,
              right: 40,
              child: FutureBuilder<String?>(
                future: currentPageIndex == docs.length - 1
                    ? _findNextMaterialWithPages()
                    : Future.value("has_next_page"),
                builder: (context, nextSnapshot) {
                  final isLastPage = currentPageIndex == docs.length - 1;

                  // masih ada page berikutnya
                  if (!isLastPage) {
                    return IconButton(
                      iconSize: 40,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => _nextPage(docs, pageTitle),
                    );
                  }

                  // page terakhir + ada material berikutnya
                  if (nextSnapshot.data != null) {
                    return IconButton(
                      iconSize: 40,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => _nextPage(docs, pageTitle),
                    );
                  }

                  // page terakhir + tidak ada material berikutnya
                  return ElevatedButton.icon(
                    onPressed: () {
                      context.go(
                        '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text("Kembali"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}