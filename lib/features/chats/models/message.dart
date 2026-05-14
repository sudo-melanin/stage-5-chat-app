import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.deliveredTo,
    required this.seenBy,
  });

  final String id;
  final String senderId;
  final String text;
  final Timestamp? createdAt;
  final List<String> deliveredTo;
  final List<String> seenBy;

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      deliveredTo: List<String>.from(data['deliveredTo'] as List? ?? []),
      seenBy: List<String>.from(data['seenBy'] as List? ?? []),
    );
  }

  String statusFor(String currentUserId) {
    if (senderId != currentUserId) return '';

    final otherUsersDelivered = deliveredTo.where((uid) => uid != currentUserId);
    final otherUsersSeen = seenBy.where((uid) => uid != currentUserId);

    if (otherUsersSeen.isNotEmpty) return 'Seen';
    if (otherUsersDelivered.isNotEmpty) return 'Delivered';
    return 'Sent';
  }
}