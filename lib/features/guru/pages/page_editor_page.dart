import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PageEditorPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String pageId;
  final String pageTitle;

  const PageEditorPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.pageId,
    required this.pageTitle,
  });

  @override
  State<PageEditorPage> createState() => _PageEditorPageState();
}

class _PageEditorPageState extends State<PageEditorPage> {
  bool _isSubmitting = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _pageStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .doc(widget.materialId)
        .collection('pages')
        .doc(widget.pageId)
        .snapshots();
  }

  Future<void> _addParagraph() async {
    if (_isSubmitting) return;

    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tambah Paragraf"),
          content: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Tulis isi paragraf...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    if (text == null || text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final pageRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc(widget.pageId);

      final snapshot = await pageRef.get();
      final data = snapshot.data() ?? {};
      final activities = List<Map<String, dynamic>>.from(
        (data['activities'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      activities.add({
        "activityId": "act_${DateTime.now().millisecondsSinceEpoch}",
        "type": "text",
        "content": text,
      });

      await pageRef.update({
        "activities": activities,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paragraf berhasil ditambahkan")),
      );
    } catch (e) {
      debugPrint("ADD PARAGRAPH ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan paragraf: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addImage() async {
    if (_isSubmitting) return;

    final urlController = TextEditingController();
    final captionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Tambah Gambar"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: "Masukkan URL gambar...",
                    border: OutlineInputBorder(),
                    labelText: "Image URL",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    hintText: "Caption opsional",
                    border: OutlineInputBorder(),
                    labelText: "Caption",
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
              onPressed: () {
                Navigator.of(dialogContext).pop({
                  "url": urlController.text.trim(),
                  "caption": captionController.text.trim(),
                });
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final url = result["url"] ?? "";
    final caption = result["caption"] ?? "";

    if (url.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final pageRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc(widget.pageId);

      final snapshot = await pageRef.get();
      final data = snapshot.data() ?? {};
      final activities = List<Map<String, dynamic>>.from(
        (data['activities'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      activities.add({
        "activityId": "act_${DateTime.now().millisecondsSinceEpoch}",
        "type": "image",
        "url": url,
        "caption": caption,
      });

      await pageRef.update({
        "activities": activities,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gambar berhasil ditambahkan")),
      );
    } catch (e) {
      debugPrint("ADD IMAGE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan gambar: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteActivity(int index, String label) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final pageRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc(widget.pageId);

      final snapshot = await pageRef.get();
      final data = snapshot.data() ?? {};
      final activities = List<Map<String, dynamic>>.from(
        (data['activities'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (index < 0 || index >= activities.length) return;

      activities.removeAt(index);

      await pageRef.update({
        "activities": activities,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label berhasil dihapus")),
      );
    } catch (e) {
      debugPrint("DELETE ACTIVITY ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus $label: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showDeleteDialog(String label) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Hapus $label"),
          content: Text("Apakah yakin ingin menghapus $label ini?"),
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
        title: Text("Edit Page - ${widget.pageTitle}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addParagraph,
                  icon: const Icon(Icons.add),
                  label: Text(_isSubmitting ? "Memproses..." : "Tambah Paragraf"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text("Tambah Gambar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _pageStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return const Center(
                      child: Text("Page tidak ditemukan"),
                    );
                  }

                  final data = snapshot.data!.data()!;
                  final activities = data['activities'] as List<dynamic>? ?? [];

                  if (activities.isEmpty) {
                    return const Center(
                      child: Text("Belum ada konten pada page ini"),
                    );
                  }

                  return ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity =
                          Map<String, dynamic>.from(activities[index] as Map);

                      if (activity['type'] == 'text') {
                        return Card(
                          child: ListTile(
                            title: Text(
                              activity['content'] ?? '',
                              textAlign: TextAlign.left,
                            ),
                            subtitle: const Text("Paragraf"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      final confirm =
                                          await _showDeleteDialog("paragraf");
                                      if (confirm == true) {
                                        await _deleteActivity(index, "Paragraf");
                                      }
                                    },
                            ),
                          ),
                        );
                      }

                      if (activity['type'] == 'image') {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((activity['url'] ?? '').toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      activity['url'],
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
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
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  activity['caption'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () async {
                                            final confirm =
                                                await _showDeleteDialog("gambar");
                                            if (confirm == true) {
                                              await _deleteActivity(index, "Gambar");
                                            }
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return const SizedBox();
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