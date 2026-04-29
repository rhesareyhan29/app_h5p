import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProgressService {
  static Future<void> markMaterialCompleted({
    required String courseId,
    required String materialId,
    String? materialType,
    String? courseTitle,
    String? materialTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    final materialsSnapshot = await firestore
        .collection('courses')
        .doc(courseId)
        .collection('materials')
        .where('isActive', isEqualTo: true)
        .get();

    final totalMaterials = materialsSnapshot.docs.length;

    final progressRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('course_progress')
        .doc(courseId);

    final progressSnapshot = await progressRef.get();
    final data = progressSnapshot.data() ?? {};

    final completedMaterialIds = List<String>.from(
      data['completedMaterialIds'] as List<dynamic>? ?? [],
    );

    final wasAlreadyCompleted = completedMaterialIds.contains(materialId);

    if (!wasAlreadyCompleted) {
      completedMaterialIds.add(materialId);
    }

    final progressPercent = totalMaterials == 0
        ? 0
        : ((completedMaterialIds.length / totalMaterials) * 100).round();

    await progressRef.set({
      "courseId": courseId,
      "completedMaterialIds": completedMaterialIds,
      "lastOpenedMaterialId": materialId,
      "progressPercent": progressPercent,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!wasAlreadyCompleted) {
      await _addActivityLog(
        courseId: courseId,
        materialId: materialId,
        materialType: materialType,
        action: 'completed',
        courseTitle: courseTitle,
        materialTitle: materialTitle,
      );
    }
  }

  static Future<void> markMaterialOpened({
    required String courseId,
    required String materialId,
    String? materialType,
    String? courseTitle,
    String? materialTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final progressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('course_progress')
        .doc(courseId);

    await progressRef.set({
      "courseId": courseId,
      "lastOpenedMaterialId": materialId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _addActivityLog(
      courseId: courseId,
      materialId: materialId,
      materialType: materialType,
      action: 'opened',
      courseTitle: courseTitle,
      materialTitle: materialTitle,
    );
  }

  static Future<void> markQuizSubmitted({
    required String courseId,
    required String materialId,
    String? courseTitle,
    String? materialTitle,
  }) async {
    await _addActivityLog(
      courseId: courseId,
      materialId: materialId,
      materialType: 'quiz',
      action: 'quiz_submitted',
      courseTitle: courseTitle,
      materialTitle: materialTitle,
    );
  }

  static Future<void> _addActivityLog({
    required String courseId,
    required String materialId,
    String? materialType,
    required String action,
    String? courseTitle,
    String? materialTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activity_logs')
        .add({
      "courseId": courseId,
      "materialId": materialId,
      "materialType": materialType,
      "action": action,
      "courseTitle": courseTitle,
      "materialTitle": materialTitle,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }
}