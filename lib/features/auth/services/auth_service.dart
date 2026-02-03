import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
      );
    
    final uid = credential.user!.uid;

    final userDoc = await _db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      throw Exception('User data not found');
    }

    return userDoc['role'];
  }
}