import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';

class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  Stream<List<Conversation>> watchUserConversations(String uid) {
    return _conversationsRef
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Conversation.fromDoc).toList();
        });
  }

  Future<String> createOrGetConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final existingConversation = await _conversationsRef
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existingConversation.docs) {
      final participants = List<String>.from(doc.data()['participants']);

      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    final conversationId = _uuid.v4();

    await _conversationsRef.doc(conversationId).set({
      'participants': [currentUserId, otherUserId],
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationId;
  }
}
