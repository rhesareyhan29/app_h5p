import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    context.go('/');
  }

  void _openCreateUserDialog() {
    showDialog(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
  }

  void _openCreateClassDialog() {
    showDialog(
      context: context,
      builder: (_) => const _CreateClassDialog(),
    );
  }

  void _openAssignTeacherDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AssignTeacherDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  "Admin Panel",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Tambah User"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateClassDialog,
                  icon: const Icon(Icons.class_),
                  label: const Text("Tambah Kelas"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openAssignTeacherDialog,
                  icon: const Icon(Icons.assignment_ind),
                  label: const Text("Assign Guru"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _AdminSummarySection(),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                tabs: const [
                  Tab(text: "Guru"),
                  Tab(text: "Siswa"),
                  Tab(text: "Kelas"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _GuruListTab(),
                  _SiswaListTab(),
                  _ClassListTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSummarySection extends StatelessWidget {
  const _AdminSummarySection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SummaryCard(
            title: "Total Guru",
            role: "guru",
            icon: Icons.person,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: "Total Siswa",
            role: "siswa",
            icon: Icons.school,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _ClassSummaryCard(),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String role;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.role,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Container(
          height: 110,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF3FF),
                child: Icon(icon, color: const Color(0xFF0C4D8A)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassSummaryCard extends StatelessWidget {
  const _ClassSummaryCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Container(
          height: 110,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.class_, color: Color(0xFF0C4D8A)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Total Kelas",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuruListTab extends StatefulWidget {
  const _GuruListTab();

  @override
  State<_GuruListTab> createState() => _GuruListTabState();
}

class _GuruListTabState extends State<_GuruListTab> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return _PanelContainer(
      child: Column(
        children: [
          _SearchField(
            hintText: "Cari guru...",
            onChanged: (value) {
              setState(() {
                search = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'guru')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final subject =
                      (data['subject'] ?? '').toString().toLowerCase();

                  return name.contains(search) ||
                      email.contains(search) ||
                      subject.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Belum ada guru"));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return _CompactTile(
                      title: data['name'] ?? '-',
                      subtitle:
                          "${data['email'] ?? '-'} • ${data['subject'] ?? '-'}",
                      trailing: doc.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SiswaListTab extends StatefulWidget {
  const _SiswaListTab();

  @override
  State<_SiswaListTab> createState() => _SiswaListTabState();
}

class _SiswaListTabState extends State<_SiswaListTab> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return _PanelContainer(
      child: Column(
        children: [
          _SearchField(
            hintText: "Cari siswa...",
            onChanged: (value) {
              setState(() {
                search = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'siswa')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final classId =
                      (data['classId'] ?? '').toString().toLowerCase();

                  return name.contains(search) ||
                      email.contains(search) ||
                      classId.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Belum ada siswa"));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return _CompactTile(
                      title: data['name'] ?? '-',
                      subtitle:
                          "${data['email'] ?? '-'} • Kelas ${data['classId'] ?? '-'}",
                      trailing: doc.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassListTab extends StatefulWidget {
  const _ClassListTab();

  @override
  State<_ClassListTab> createState() => _ClassListTabState();
}

class _ClassListTabState extends State<_ClassListTab> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return _PanelContainer(
      child: Column(
        children: [
          _SearchField(
            hintText: "Cari kelas...",
            onChanged: (value) {
              setState(() {
                search = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final grade = (data['grade'] ?? '').toString().toLowerCase();
                  final teacherNames = List<String>.from(
                    data['teacherNames'] as List<dynamic>? ?? [],
                  ).join(', ').toLowerCase();

                  return name.contains(search) ||
                      grade.contains(search) ||
                      teacherNames.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Belum ada kelas"));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final teacherNames = List<String>.from(
                      data['teacherNames'] as List<dynamic>? ?? [],
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          data['name'] ?? doc.id,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Grade ${data['grade'] ?? '-'} • Guru: ${teacherNames.isEmpty ? 'Belum diassign' : teacherNames.join(', ')}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => _AssignTeacherDialog(
                                preselectedClassId: doc.id,
                              ),
                            );
                          },
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
    );
  }
}

class _PanelContainer extends StatelessWidget {
  final Widget child;

  const _PanelContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        isDense: true,
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _CompactTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: SizedBox(
          width: 120,
          child: Text(
            trailing,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _uidController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();

  String selectedRole = 'guru';
  String? selectedClassId;
  bool isSaving = false;

  Future<void> _save() async {
    final uid = _uidController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (uid.isEmpty || name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("UID, nama, dan email wajib diisi")),
      );
      return;
    }

    if (selectedRole == 'siswa' && selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih kelas untuk siswa")),
      );
      return;
    }

    if (selectedRole == 'guru' && _subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject guru wajib diisi")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final existingUser = await userRef.get();
      if (existingUser.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("UID sudah digunakan di Firestore")),
        );
        setState(() => isSaving = false);
        return;
      }

      final data = <String, dynamic>{
        "name": name,
        "email": email,
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (selectedRole == 'guru') {
        data["subject"] = _subjectController.text.trim();
      }

      if (selectedRole == 'siswa') {
        data["classId"] = selectedClassId;
      }

      await userRef.set(data);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data user berhasil dibuat")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat user: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tambah User"),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: "UID",
                  hintText: "Paste UID dari Firebase Authentication",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: const [
                  DropdownMenuItem(value: 'guru', child: Text("Guru")),
                  DropdownMenuItem(value: 'siswa', child: Text("Siswa")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedRole = value;
                    if (selectedRole == 'guru') {
                      selectedClassId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              if (selectedRole == 'guru')
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: "Subject"),
                ),
              if (selectedRole == 'siswa')
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final classes = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedClassId,
                      decoration: const InputDecoration(labelText: "Kelas"),
                      items: classes.map((doc) {
                        final data = doc.data();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name'] ?? doc.id),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClassId = value;
                        });
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: Text(isSaving ? "Menyimpan..." : "Simpan"),
        ),
      ],
    );
  }
}

class _CreateClassDialog extends StatefulWidget {
  const _CreateClassDialog();

  @override
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();

  bool isSaving = false;

  Future<void> _save() async {
    if (_idController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _gradeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field kelas wajib diisi")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(_idController.text.trim())
          .set({
        "name": _nameController.text.trim(),
        "grade": int.tryParse(_gradeController.text.trim()) ?? 0,
        "teacherIds": <String>[],
        "teacherNames": <String>[],
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kelas berhasil dibuat")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat kelas: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tambah Kelas"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "ID Kelas",
                hintText: "Contoh: 1A",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Kelas",
                hintText: "Contoh: Kelas 1A",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Grade",
                hintText: "Contoh: 1",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: Text(isSaving ? "Menyimpan..." : "Simpan"),
        ),
      ],
    );
  }
}

class _AssignTeacherDialog extends StatefulWidget {
  final String? preselectedClassId;

  const _AssignTeacherDialog({
    this.preselectedClassId,
  });

  @override
  State<_AssignTeacherDialog> createState() => _AssignTeacherDialogState();
}

class _AssignTeacherDialogState extends State<_AssignTeacherDialog> {
  String? selectedClassId;
  String? selectedClassName;
  bool isSaving = false;

  final List<String> selectedTeacherIds = [];
  final List<String> selectedTeacherNames = [];

  @override
  void initState() {
    super.initState();
    selectedClassId = widget.preselectedClassId;
    _loadPreselectedClass();
  }

  Future<void> _loadPreselectedClass() async {
    if (selectedClassId == null) return;

    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(selectedClassId)
        .get();

    if (!classDoc.exists) return;

    final data = classDoc.data() ?? {};

    setState(() {
      selectedClassName = data['name'] ?? selectedClassId;

      selectedTeacherIds
        ..clear()
        ..addAll(
          List<String>.from(data['teacherIds'] as List<dynamic>? ?? []),
        );

      selectedTeacherNames
        ..clear()
        ..addAll(
          List<String>.from(data['teacherNames'] as List<dynamic>? ?? []),
        );
    });
  }

  Future<void> _save() async {
    if (selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih kelas")),
      );
      return;
    }

    if (selectedTeacherIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal 1 guru")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClassId)
          .update({
        "teacherIds": selectedTeacherIds,
        "teacherNames": selectedTeacherNames,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guru berhasil diassign ke kelas")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal assign guru: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.preselectedClassId != null;

    return AlertDialog(
      title: const Text("Assign Guru ke Kelas"),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditMode)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: Text(
                    selectedClassName ?? selectedClassId ?? '-',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final classes = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: "Pilih Kelas",
                    ),
                    items: classes.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? doc.id),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      final classDoc = await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(value)
                          .get();

                      final data = classDoc.data() ?? {};

                      setState(() {
                        selectedClassId = value;
                        selectedClassName = data['name'] ?? value;

                        selectedTeacherIds
                          ..clear()
                          ..addAll(
                            List<String>.from(
                              data['teacherIds'] as List<dynamic>? ?? [],
                            ),
                          );

                        selectedTeacherNames
                          ..clear()
                          ..addAll(
                            List<String>.from(
                              data['teacherNames'] as List<dynamic>? ?? [],
                            ),
                          );
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'guru')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final teachers = snapshot.data!.docs;

                if (teachers.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Belum ada guru"),
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final doc = teachers[index];
                      final data = doc.data();
                      final teacherId = doc.id;
                      final teacherName = data['name'] ?? doc.id;
                      final isChecked = selectedTeacherIds.contains(teacherId);

                      return CheckboxListTile(
                        value: isChecked,
                        title: Text(teacherName),
                        subtitle: Text(data['subject'] ?? '-'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (!selectedTeacherIds.contains(teacherId)) {
                                selectedTeacherIds.add(teacherId);
                                selectedTeacherNames.add(teacherName);
                              }
                            } else {
                              selectedTeacherIds.remove(teacherId);
                              selectedTeacherNames.remove(teacherName);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: Text(isSaving ? "Menyimpan..." : "Simpan"),
        ),
      ],
    );
  }
}