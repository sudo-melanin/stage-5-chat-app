import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final userConversationsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(chatRepositoryProvider).watchUserConversations(user.uid);
});