import 'package:flutter/material.dart';

class EmptyCoursePlaceholder extends StatelessWidget {
  const EmptyCoursePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada course',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Silakan tunggu guru membagikan materi',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
