import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RoleRedirectPage extends StatelessWidget {
  const RoleRedirectPage({super.key});

  Future<String?> _getRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['role'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == 'guru') {
            context.go('/guru');
          } else if (role == 'siswa') {
            context.go('/siswa');
          } else {
            context.go('/');
          }
        });

        return const SizedBox();
      },
    );
  }
}
