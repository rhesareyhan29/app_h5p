import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import '../../guru/services/student_progress_service.dart';

class VideoMaterialPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String courseTitle;

  const VideoMaterialPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.courseTitle,
  });

  @override
  State<VideoMaterialPage> createState() => _VideoMaterialPageState();
}

class _VideoMaterialPageState extends State<VideoMaterialPage> {
  String? _registeredViewType;

  static const double _videoWidth = 1200;
  static const double _videoHeight = 600;

  @override
  void initState() {
    super.initState();

    StudentProgressService.markMaterialOpened(
      courseId: widget.courseId,
      materialId: widget.materialId,
      materialType: 'video',
      courseTitle: widget.courseTitle,
      materialTitle: 'Video Material',
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

  Future<String?> _findNextMaterial() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) return null;

    final currentIndex = docs.indexWhere((doc) => doc.id == widget.materialId);

    if (currentIndex == -1 || currentIndex == docs.length - 1) {
      return null;
    }

    return docs[currentIndex + 1].id;
  }

  Future<void> _goNextMaterial(BuildContext context) async {
    final nextMaterialId = await _findNextMaterial();

    if (nextMaterialId == null) {
      if (!mounted) return;
      _goBackToCourse(context);
      return;
    }

    if (!mounted) return;
    context.go(
      '/course/${widget.courseId}/material/$nextMaterialId?title=${Uri.encodeComponent(widget.courseTitle)}',
    );
  }

  void _goBackToCourse(BuildContext context) {
    context.go(
      '/course/${widget.courseId}?title=${Uri.encodeComponent(widget.courseTitle)}',
    );
  }

  Future<void> _completeAndBackToCourse(BuildContext context) async {
    await StudentProgressService.markMaterialCompleted(
      courseId: widget.courseId,
      materialId: widget.materialId,
      materialType: 'video',
      courseTitle: widget.courseTitle,
      materialTitle: 'Video Material',
    );

    if (!mounted) return;
    _goBackToCourse(context);
  }

  Future<void> _completeAndNext(BuildContext context) async {
    await StudentProgressService.markMaterialCompleted(
      courseId: widget.courseId,
      materialId: widget.materialId,
    );

    if (!mounted) return;
    await _goNextMaterial(context);
  }

  void _registerIframe(String previewUrl) {
    final viewType =
        'gdrive-video-${widget.courseId}-${widget.materialId}-${previewUrl.hashCode}-${_videoWidth.toInt()}x${_videoHeight.toInt()}';

    if (_registeredViewType == viewType) return;

    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = previewUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; fullscreen'
        ..allowFullscreen = true;

      return iframe;
    });

    _registeredViewType = viewType;
  }

  Widget _buildActionButtons(BuildContext context, {required bool hasNext}) {
    return Stack(
      children: [
        Positioned(
          bottom: 24,
          left: 24,
          child: IconButton(
            iconSize: 40,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _completeAndBackToCourse(context),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: hasNext
              ? IconButton(
                  iconSize: 40,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _completeAndNext(context),
                )
              : ElevatedButton.icon(
                  onPressed: () => _completeAndBackToCourse(context),
                  icon: const Icon(Icons.list),
                  label: const Text("Kembali"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            body: Center(
              child: ElevatedButton.icon(
                onPressed: () => _goBackToCourse(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Kembali ke daftar materi"),
              ),
            ),
          );
        }

        final pageDoc = snapshot.data!.docs.first;
        final pageData = pageDoc.data();
        final pageTitle = pageData['title'] ?? 'Materi Video';
        final activities = pageData['activities'] as List<dynamic>? ?? [];

        Map<String, dynamic>? videoActivity;
        for (final activity in activities) {
          if (activity['type'] == 'video') {
            videoActivity = Map<String, dynamic>.from(activity as Map);
            break;
          }
        }

        final previewUrl = videoActivity?['previewUrl'] ?? '';

        if (previewUrl.toString().isNotEmpty) {
          _registerIframe(previewUrl);
        }

        return FutureBuilder<String?>(
          future: _findNextMaterial(),
          builder: (context, nextSnapshot) {
            final hasNextMaterial = nextSnapshot.data != null;

            return Stack(
              children: [
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1750),
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
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: previewUrl.toString().isEmpty
                                    ? const Text(
                                        "Video belum tersedia",
                                        style: TextStyle(fontSize: 16),
                                      )
                                    : SingleChildScrollView(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Container(
                                            width: _videoWidth,
                                            height: _videoHeight,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: _registeredViewType == null
                                                ? const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  )
                                                : HtmlElementView(
                                                    key: ValueKey(
                                                      _registeredViewType,
                                                    ),
                                                    viewType:
                                                        _registeredViewType!,
                                                  ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionButtons(
                  context,
                  hasNext: hasNextMaterial,
                ),
              ],
            );
          },
        );
      },
    );
  }
}