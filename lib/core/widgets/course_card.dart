import 'package:flutter/material.dart';

class CourseCard extends StatefulWidget {
  final String title;
  final double progress; // 0.0 - 1.0

  const CourseCard({
    super.key,
    required this.title,
    required this.progress,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF01A7C2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE / ABSTRACT PLACEHOLDER
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFB33951),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),

            // TITLE
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.4),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF0C4D8A)),
              ),
            ),
            const SizedBox(height: 6),

            Text(
              '${(widget.progress * 100).toInt()}% selesai',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
