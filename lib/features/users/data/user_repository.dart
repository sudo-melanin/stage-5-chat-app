import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final now = Timestamp.now();

    final user = AppUser(
      uid: uid,
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _usersRef.doc(uid).set(user.toMap());
  }

  Stream<List<AppUser>> searchUsers(String query, String currentUserId) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return Stream.value([]);
    }

    return _usersRef
        .where('email', isGreaterThanOrEqualTo: normalizedQuery)
        .where('email', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) => AppUser.fromMap(doc.data()))
              .toList();
        });
  }
}
