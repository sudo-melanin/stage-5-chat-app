import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.deliveredTo,
    required this.seenBy,
    required this.reactions,
    required this.deletedFor,
    required this.deletedForEveryone,
    required this.type,
    this.audioUrl,
    this.audioDurationMs,
    this.editedAt,
  });

  final String id;
  final String senderId;
  final String text;
  final Timestamp? createdAt;
  final List<String> deliveredTo;
  final List<String> seenBy;
  final Map<String, String> reactions;
  final List<String> deletedFor;
  final bool deletedForEveryone;
  final String type;
  final String? audioUrl;
  final int? audioDurationMs;
  final Timestamp? editedAt;

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      deliveredTo: List<String>.from(data['deliveredTo'] as List? ?? []),
      seenBy: List<String>.from(data['seenBy'] as List? ?? []),
      reactions: Map<String, String>.from(data['reactions'] as Map? ?? {}),
      deletedFor: List<String>.from(data['deletedFor'] as List? ?? []),
      deletedForEveryone: data['deletedForEveryone'] as bool? ?? false,
      type: data['type'] as String? ?? 'text',
      audioUrl: data['audioUrl'] as String?,
      audioDurationMs: data['audioDurationMs'] as int?,
      editedAt: data['editedAt'] as Timestamp?,
    );
  }

  bool get isAudio => type == 'audio';

  String get visibleText {
    if (deletedForEveryone) return 'This message was deleted.';
    return text;
  }

  bool isDeletedFor(String userId) => deletedFor.contains(userId);
  bool get isEdited => editedAt != null;

  bool matchesSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return text.toLowerCase().contains(normalizedQuery);
  }

  String statusFor(String currentUserId) {
    if (senderId != currentUserId) return '';

    final otherUsersDelivered = deliveredTo.where(
      (uid) => uid != currentUserId,
    );
    final otherUsersSeen = seenBy.where((uid) => uid != currentUserId);

    if (otherUsersSeen.isNotEmpty) return 'Seen';
    if (otherUsersDelivered.isNotEmpty) return 'Delivered';
    return 'Sent';
  }
}
