import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/student_profile.dart';
import '../../../core/widgets/course_overview.dart';
class SiswaHomePage extends StatelessWidget {
  const SiswaHomePage({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
            return const Center(
              child: Text("Data user tidak ditemukan"),
            );
          }

          final userData = userSnapshot.data!.data()!;
          final classId = userData['classId'];

          if (classId == null) {
            return const Center(
              child: Text("Class tidak ditemukan"),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1100;

              // 📱 Tampilan layar sempit
              if (isNarrow) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const StudentProfileCard(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 600,
                        child: CourseOverview(classId: classId),
                      ),
                    ],
                  ),
                );
              }
              // 🖥 Tampilan layar lebar
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StudentProfileCard(

                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: CourseOverview(classId: classId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
