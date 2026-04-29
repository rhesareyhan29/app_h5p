import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'page_editor_page.dart';

class PageManagerPage extends StatefulWidget {
  final String courseId;
  final String materialId;
  final String materialTitle;

  const PageManagerPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<PageManagerPage> createState() => _PageManagerPageState();
}

class _PageManagerPageState extends State<PageManagerPage> {
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

  Future<void> _addPage() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final pagesRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages');

      final snapshot = await pagesRef.get();
      final nextOrder = snapshot.docs.length + 1;

      await pagesRef.add({
        "title": "Halaman $nextOrder",
        "order": nextOrder,
        "activities": [],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Page berhasil ditambahkan")),
      );
    } catch (e) {
      debugPrint("ADD PAGE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan page: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deletePage(String pageId) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final pagesRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages');

      await pagesRef.doc(pageId).delete();

      final snapshot = await pagesRef.orderBy('order').get();
      for (int i = 0; i < snapshot.docs.length; i++) {
        await pagesRef.doc(snapshot.docs[i].id).update({
          "order": i + 1,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Page berhasil dihapus")),
      );
    } catch (e) {
      debugPrint("DELETE PAGE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus page: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _editPageTitle(String pageId, String currentTitle) async {
    if (_isSubmitting) return;

    final controller = TextEditingController(text: currentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Judul Page"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Masukkan judul page",
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

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages')
          .doc(pageId)
          .update({
        "title": newTitle,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul page berhasil diperbarui")),
      );
    } catch (e) {
      debugPrint("EDIT PAGE TITLE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui judul page: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _reorderPages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int oldIndex,
    int newIndex,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final reorderedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final movedItem = reorderedDocs.removeAt(oldIndex);
      reorderedDocs.insert(newIndex, movedItem);

      final pagesRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials')
          .doc(widget.materialId)
          .collection('pages');

      for (int i = 0; i < reorderedDocs.length; i++) {
        await pagesRef.doc(reorderedDocs[i].id).update({
          "order": i + 1,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Urutan page berhasil diubah")),
      );
    } catch (e) {
      debugPrint("REORDER PAGE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengubah urutan page: $e")),
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
          title: const Text("Hapus Page"),
          content: const Text("Apakah yakin ingin menghapus page ini?"),
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
        title: Text("Pages - ${widget.materialTitle}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addPage,
                  icon: const Icon(Icons.add),
                  label: Text(_isSubmitting ? "Memproses..." : "Tambah Page"),
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

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("Gagal memuat page"),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Belum ada page"),
                    );
                  }

                  return ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: docs.length,
                    onReorder: _isSubmitting
                        ? (_, __) {}
                        : (oldIndex, newIndex) async {
                            await _reorderPages(docs, oldIndex, newIndex);
                          },
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final title = data['title'] ?? "Page";

                      return Card(
                        key: ValueKey(doc.id),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(title),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        _editPageTitle(doc.id, title);
                                      },
                              ),
                            ],
                          ),
                          subtitle: Text("Order: ${data['order'] ?? '-'}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_indicator),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.article_outlined),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PageEditorPage(
                                              courseId: widget.courseId,
                                              materialId: widget.materialId,
                                              pageId: doc.id,
                                              pageTitle: title,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        final confirm = await _showDeleteDialog();
                                        if (confirm == true) {
                                          await _deletePage(doc.id);
                                        }
                                      },
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