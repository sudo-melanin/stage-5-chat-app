import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserConversations(
    String uid,
  ) {
    return _conversationsRef
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }
}