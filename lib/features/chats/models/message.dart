import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final Timestamp? createdAt;

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
