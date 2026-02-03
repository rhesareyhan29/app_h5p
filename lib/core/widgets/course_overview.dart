import 'package:flutter/material.dart';
import 'course_card.dart';
import 'empty_course_placeholder.dart';

class CourseOverview extends StatelessWidget {
  const CourseOverview({super.key});

  @override
  Widget build(BuildContext context) {
    // DUMMY DATA
    final courses = [
      {'title': 'Biologi', 'progress': 0.6},
      {'title': 'Matematika', 'progress': 0.3},
      {'title': 'Fisika', 'progress': 0.8},
      {'title': 'Kimia', 'progress': 0.1},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C4D8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: courses.isEmpty
                ? const EmptyCoursePlaceholder()
                : GridView.builder(
                    itemCount: courses.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return CourseCard(
                        title: course['title'] as String,
                        progress: course['progress'] as double,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
