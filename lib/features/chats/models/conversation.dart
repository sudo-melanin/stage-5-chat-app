import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantEmails,
    required this.typing,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantEmails;
  final Map<String, bool> typing;
  final String? lastMessage;
  final Timestamp? lastMessageAt;

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      ),
      participantEmails: Map<String, String>.from(
        data['participantEmails'] as Map? ?? {},
      ),
      typing: Map<String, bool>.from(data['typing'] as Map? ?? {}),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
    );
  }

  String displayNameFor(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => currentUserId,
    );

    return participantNames[otherUserId] ??
        participantEmails[otherUserId] ??
        'Chat';
  }

  String displayEmailFor(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => currentUserId,
    );

    return participantEmails[otherUserId] ?? '';
  }

  bool isOtherUserTyping(String currentUserId) {
    return typing.entries.any((entry) {
      return entry.key != currentUserId && entry.value == true;
    });
  }
}
