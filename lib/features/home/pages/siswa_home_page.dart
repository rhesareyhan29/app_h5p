import 'package:flutter/material.dart';
import '../../../core/widgets/student_navbar.dart';
import '../../../core/widgets/student_profile.dart';
import '../../../core/widgets/course_overview.dart';

class SiswaHomePage extends StatelessWidget {
  const SiswaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const StudentNavbar(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Profile Card
                  StudentProfileCard(),
                  SizedBox(width: 32),
                  Expanded(child: CourseOverview()),

                  //Course
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
