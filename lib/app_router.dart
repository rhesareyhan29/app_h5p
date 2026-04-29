import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/widgets/auth_gate.dart';
import 'core/widgets/student_navbar.dart';

import 'features/student_course/pages/siswa_home_page.dart';
import 'features/student_course/pages/course_student_page.dart';
import 'features/student_course/pages/materi_paragraf_page.dart';
import 'features/student_course/pages/materi_video_page.dart';
import 'features/student_course/pages/materi_quiz_page.dart';

import 'features/guru/pages/guru_home_page.dart';
import 'features/home/pages/admin_home_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoginPage = state.matchedLocation == '/';

    if (user == null) {
      if (!isLoginPage) return '/';
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = userDoc.data()?['role'];

    if (isLoginPage) {
      if (role == 'admin') return '/admin';
      if (role == 'guru') return '/guru';
      return '/siswa';
    }

    if (role == 'admin') {
      if (state.matchedLocation != '/admin') return '/admin';
    }

    if (role == 'guru') {
      if (state.matchedLocation == '/admin') return '/guru';
    }

    if (role == 'siswa') {
      if (state.matchedLocation == '/admin') return '/siswa';
      if (state.matchedLocation == '/guru') return '/siswa';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),

    // ADMIN di luar shell
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomePage(),
    ),

    // SISWA + GURU pakai navbar
    ShellRoute(
      builder: (context, state, child) {
        final isBluePage = state.matchedLocation.contains('/material');

        return Scaffold(
          body: SafeArea(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              color: isBluePage
                  ? const Color(0xFF0C4D8A)
                  : Colors.white,
              child: Column(
                children: [
                  StudentNavbar(
                    backgroundColor: const Color(0xFF00A6FB),
                    foregroundColor: Colors.white,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(state.matchedLocation),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/siswa',
          builder: (context, state) => const SiswaHomePage(),
        ),
        GoRoute(
          path: '/guru',
          builder: (context, state) => const GuruDashboardPage(),
        ),
        GoRoute(
          path: '/course/:courseId',
          builder: (context, state) {
            final id = state.pathParameters['courseId']!;
            final title = state.uri.queryParameters['title'] ?? '';

            return CourseStudentPage(
              courseId: id,
              courseTitle: title,
            );
          },
        ),
        GoRoute(
          path: '/course/:courseId/material/:materialId',
          builder: (context, state) {
            final courseId = state.pathParameters['courseId']!;
            final materialId = state.pathParameters['materialId']!;
            final title = state.uri.queryParameters['title'] ?? '';

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('materials')
                  .doc(materialId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Scaffold(
                    body: Center(child: Text("Material tidak ditemukan")),
                  );
                }

                final data = snapshot.data!.data()!;
                final type = data['type'] ?? 'paragraph';

                if (type == 'video') {
                  return VideoMaterialPage(
                    courseId: courseId,
                    materialId: materialId,
                    courseTitle: title,
                  );
                }

                if (type == 'quiz') {
                  return QuizMaterialPage(
                    courseId: courseId,
                    materialId: materialId,
                    courseTitle: title,
                  );
                }

                return ParagraphMaterialPage(
                  courseId: courseId,
                  materialId: materialId,
                  courseTitle: title,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);