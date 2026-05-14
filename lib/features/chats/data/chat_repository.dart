import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/message.dart';

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

    final usersRef = _firestore.collection('users');

    final currentUserDoc = await usersRef.doc(currentUserId).get();
    final otherUserDoc = await usersRef.doc(otherUserId).get();

    final currentUserData = currentUserDoc.data() ?? {};
    final otherUserData = otherUserDoc.data() ?? {};

    final conversationId = _uuid.v4();

    await _conversationsRef.doc(conversationId).set({
      'participants': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUserData['displayName'] ?? 'User',
        otherUserId: otherUserData['displayName'] ?? 'User',
      },
      'participantEmails': {
        currentUserId: currentUserData['email'] ?? '',
        otherUserId: otherUserData['email'] ?? '',
      },
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationId;
  }

  Stream<List<Message>> watchMessages(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Message.fromDoc).toList();
        });
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) return;

    final conversationRef = _conversationsRef.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'senderId': senderId,
        'text': trimmedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(conversationRef, {
        'lastMessage': trimmedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
