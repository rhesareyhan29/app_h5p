import 'package:flutter/material.dart';

class StudentNavbar extends StatelessWidget {
  const StudentNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF00A6FB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // APP NAME
          const Text(
            'APP NAME',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // NOTIFICATION ICON
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: Colors.white,
              ),
              onPressed: () {
                // nanti: buka panel notifikasi
              },
            ),
          ),
        ],
      ),
    );
  }
}
