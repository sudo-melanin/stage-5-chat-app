import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/conversation.dart';
import '../models/message.dart';

class ChatRepository {
  ChatRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
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
      'typing': {currentUserId: false, otherUserId: false},
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
        'deliveredTo': [senderId],
        'seenBy': [senderId],
        'reactions': {},
        'editedAt': null,
        'deletedFor': [],
        'deletedForEveryone': false,
      });

      transaction.update(conversationRef, {
        'lastMessage': trimmedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markMessagesDeliveredAndSeen({
    required String conversationId,
    required String userId,
  }) async {
    final messagesSnapshot = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();

    for (final doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'deliveredTo': FieldValue.arrayUnion([userId]),
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  Stream<Conversation?> watchConversation(String conversationId) {
    return _conversationsRef.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Conversation.fromDoc(doc);
    });
  }

  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return _conversationsRef.doc(conversationId).update({
      'typing.$userId': isTyping,
    });
  }

  Future<void> setReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return Future.value();

    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'text': trimmedText,
          'editedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteMessageForMe({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedFor': FieldValue.arrayUnion([userId]),
        });
  }

  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
  }) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'text': '',
          'deletedForEveryone': true,
          'editedAt': FieldValue.serverTimestamp(),
          'reactions': {},
        });
  }

  Future<void> sendAudioMessage({
    required String conversationId,
    required String senderId,
    required String filePath,
    required int durationMs,
  }) async {
    final conversationRef = _conversationsRef.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    final storageRef = _storage.ref(
      'voice_notes/$conversationId/${messageRef.id}.m4a',
    );

    await storageRef.putFile(File(filePath));
    final audioUrl = await storageRef.getDownloadURL();

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'senderId': senderId,
        'type': 'audio',
        'text': 'Voice message',
        'audioUrl': audioUrl,
        'audioDurationMs': durationMs,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [senderId],
        'seenBy': [senderId],
        'reactions': {},
        'editedAt': null,
        'deletedFor': [],
        'deletedForEveryone': false,
      });

      transaction.update(conversationRef, {
        'lastMessage': 'Voice message',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
