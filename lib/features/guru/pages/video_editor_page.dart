import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoEditorPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String materialTitle;

  const VideoEditorPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  bool _isSubmitting = false;

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

  String? _extractDriveFileId(String input) {
    final text = input.trim();

    // format: https://drive.google.com/file/d/FILE_ID/view
    final fileRegex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final fileMatch = fileRegex.firstMatch(text);
    if (fileMatch != null) return fileMatch.group(1);

    // format: https://drive.google.com/open?id=FILE_ID
    final openRegex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final openMatch = openRegex.firstMatch(text);
    if (openMatch != null) return openMatch.group(1);

    // kalau user tempel fileId langsung
    final rawIdRegex = RegExp(r'^[a-zA-Z0-9_-]{10,}$');
    if (rawIdRegex.hasMatch(text)) return text;

    return null;
  }

  Future<void> _saveVideo() async {
    if (_isSubmitting) return;

    final pageTitleController = TextEditingController();
    final driveLinkController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tambah / Update Video"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: pageTitleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Judul Page",
                    hintText: "Contoh: Video Ekosistem",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driveLinkController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Link Google Drive / File ID",
                    hintText: "Tempel link Google Drive di sini",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop({
                "pageTitle": pageTitleController.text.trim(),
                "driveLink": driveLinkController.text.trim(),
              }),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final pageTitle = result["pageTitle"] ?? "";
    final driveLink = result["driveLink"] ?? "";

    if (pageTitle.isEmpty || driveLink.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul page dan link video wajib diisi")),
      );
      return;
    }

    final fileId = _extractDriveFileId(driveLink);
    if (fileId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link Google Drive tidak valid")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final pagesRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages');

      final pagesSnapshot = await pagesRef.get();

      if (pagesSnapshot.docs.isEmpty) {
        await pagesRef.add({
          "title": pageTitle,
          "order": 1,
          "activities": [
            {
              "activityId": "act_${DateTime.now().millisecondsSinceEpoch}",
              "type": "video",
              "source": "google_drive",
              "fileId": fileId,
              "previewUrl": "https://drive.google.com/file/d/$fileId/preview",
            }
          ],
        });
      } else {
        final pageDoc = pagesSnapshot.docs.first.reference;

        await pageDoc.update({
          "title": pageTitle,
          "order": 1,
          "activities": [
            {
              "activityId": "act_${DateTime.now().millisecondsSinceEpoch}",
              "type": "video",
              "source": "google_drive",
              "fileId": fileId,
              "previewUrl": "https://drive.google.com/file/d/$fileId/preview",
            }
          ],
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video berhasil disimpan")),
      );
    } catch (e) {
      debugPrint("SAVE VIDEO ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan video: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteVideoPage(String pageId) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc(pageId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video berhasil dihapus")),
      );
    } catch (e) {
      debugPrint("DELETE VIDEO PAGE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus video: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hapus Video"),
          content: const Text("Apakah yakin ingin menghapus video ini?"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Editor - ${widget.materialTitle}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _saveVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(_isSubmitting ? "Memproses..." : "Tambah / Update Video"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    return const Center(
                      child: Text("Belum ada video"),
                    );
                  }

                  final pageDoc = snapshot.data!.docs.first;
                  final pageData = pageDoc.data();
                  final activities = pageData['activities'] as List<dynamic>? ?? [];

                  if (activities.isEmpty) {
                    return const Center(
                      child: Text("Belum ada video"),
                    );
                  }

                  final videoActivity =
                      Map<String, dynamic>.from(activities.first as Map);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pageData['title'] ?? 'Video',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text("Source: ${videoActivity['source'] ?? '-'}"),
                          const SizedBox(height: 8),
                          Text("File ID: ${videoActivity['fileId'] ?? '-'}"),
                          const SizedBox(height: 8),
                          Text(
                            "Preview URL: ${videoActivity['previewUrl'] ?? '-'}",
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      final confirm = await _showDeleteDialog();
                                      if (confirm == true) {
                                        await _deleteVideoPage(pageDoc.id);
                                      }
                                    },
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
      ),
    );
  }
}