import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_editor_page.dart';
import 'page_manager_page.dart';
import 'quiz_editor_page.dart';

class MaterialManagerPage extends StatefulWidget {
  final String courseId;

  const MaterialManagerPage({
    super.key,
    required this.courseId,
  });

  @override
  State<MaterialManagerPage> createState() => _MaterialManagerPageState();
}

class _MaterialManagerPageState extends State<MaterialManagerPage> {
  bool _isSubmitting = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _materialsStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('materials')
        .orderBy('order')
        .snapshots();
  }

  Future<void> _addMaterial() async {
    if (_isSubmitting) return;

    final titleController = TextEditingController();
    String selectedType = 'paragraph';

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Material"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Masukkan judul material",
                      labelText: "Judul Material",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Type Material",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'paragraph',
                        child: Text("Paragraph"),
                      ),
                      DropdownMenuItem(
                        value: 'video',
                        child: Text("Video"),
                      ),
                      DropdownMenuItem(
                        value: 'quiz',
                        child: Text("Quiz"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      "title": titleController.text.trim(),
                      "type": selectedType,
                    });
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

    final title = result["title"] ?? "";
    final type = result["type"] ?? "paragraph";

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul material wajib diisi")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final materialsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials');

      final snapshot = await materialsRef.get();
      final nextOrder = snapshot.docs.length + 1;

      await materialsRef.add({
        "title": title,
        "type": type,
        "order": nextOrder,
        "isActive": true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material berhasil ditambahkan")),
      );
    } catch (e) {
      debugPrint("ADD MATERIAL ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan material: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteMaterial(String id) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final materialsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials');

      await materialsRef.doc(id).delete();

      final snapshot = await materialsRef.orderBy('order').get();
      for (int i = 0; i < snapshot.docs.length; i++) {
        await materialsRef.doc(snapshot.docs[i].id).update({
          "order": i + 1,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material berhasil dihapus")),
      );
    } catch (e) {
      debugPrint("DELETE MATERIAL ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus material: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _editMaterialTitle(String materialId, String currentTitle) async {
    if (_isSubmitting) return;

    final controller = TextEditingController(text: currentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Judul Material"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Masukkan judul material",
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
          .doc(materialId)
          .update({
        "title": newTitle,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul material berhasil diperbarui")),
      );
    } catch (e) {
      debugPrint("EDIT MATERIAL TITLE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui judul material: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _reorderMaterials(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int oldIndex,
    int newIndex,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final reorderedDocs =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final movedItem = reorderedDocs.removeAt(oldIndex);
      reorderedDocs.insert(newIndex, movedItem);

      final materialsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('materials');

      for (int i = 0; i < reorderedDocs.length; i++) {
        await materialsRef.doc(reorderedDocs[i].id).update({
          "order": i + 1,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Urutan material berhasil diubah")),
      );
    } catch (e) {
      debugPrint("REORDER MATERIAL ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengubah urutan material: $e")),
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
          title: const Text("Hapus Material"),
          content: const Text("Apakah yakin ingin menghapus material ini?"),
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

  IconData _materialIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'paragraph':
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Material Manager"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addMaterial,
                  icon: const Icon(Icons.add),
                  label: Text(_isSubmitting ? "Memproses..." : "Tambah Material"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _materialsStream(),
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

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("Gagal memuat material"),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Belum ada material"),
                    );
                  }

                  return ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: docs.length,
                    onReorder: _isSubmitting
                        ? (_, __) {}
                        : (oldIndex, newIndex) async {
                            await _reorderMaterials(docs, oldIndex, newIndex);
                          },
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final title = data['title'] ?? "Material";
                      final type = data['type'] ?? 'paragraph';

                      return Card(
                        key: ValueKey(doc.id),
                        child: ListTile(
                          leading: Icon(_materialIcon(type)),
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
                                        _editMaterialTitle(doc.id, title);
                                      },
                              ),
                            ],
                          ),
                          subtitle: Text("Type: $type"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_indicator),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  type == 'video' 
                                    ? Icons.video_library_outlined
                                    :type == 'quiz'
                                      ? Icons.quiz_outlined
                                      : Icons.article_outlined,
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        if (type == 'video') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => VideoEditorPage(
                                                courseId: widget.courseId,
                                                materialId: doc.id,
                                                materialTitle: title,
                                              ),
                                            ),
                                          );
                                        } else if (type == 'quiz') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QuizEditorPage(
                                                courseId: widget.courseId, 
                                                materialId: doc.id, 
                                                materialTitle: title,
                                                ), 
                                              ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PageManagerPage(
                                                courseId: widget.courseId,
                                                materialId: doc.id,
                                                materialTitle: title,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        final confirm = await _showDeleteDialog();
                                        if (confirm == true) {
                                          await _deleteMaterial(doc.id);
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