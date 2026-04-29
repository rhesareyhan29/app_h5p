import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class StudentNavbar extends StatelessWidget {
  final Color backgroundColor;
  final Color foregroundColor;

  const StudentNavbar({
    super.key,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // HAMBURGER MENU
          PopupMenuButton<String>(
            icon: Icon(
              Icons.menu,
              size: 34,
              color: foregroundColor,
            ),
            onSelected: (value) {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Halaman pengaturan belum tersedia'),
                  ),
                );
              }

              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Pengaturan'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // APP NAME
          Text(
            'APP NAME',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),

          const Spacer(),

          // NOTIFICATION ICON
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: foregroundColor,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
