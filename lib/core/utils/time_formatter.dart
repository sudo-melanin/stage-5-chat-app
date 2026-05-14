import 'package:cloud_firestore/cloud_firestore.dart';

class TimeFormatter {
  const TimeFormatter._();

  static String relative(Timestamp? timestamp) {
    if (timestamp == null) return 'Sending...';

    final messageTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
  }
}
