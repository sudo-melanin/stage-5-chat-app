import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../users/models/app_user.dart';
import '../data/chat_repository.dart';
import '../models/conversation.dart';
import '../models/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final userConversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  return ref.watch(chatRepositoryProvider).watchUserConversations(user.uid);
});

final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(
      UserSearchQueryNotifier.new,
    );

class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final searchedUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final query = ref.watch(userSearchQueryProvider);
  final currentUser = ref.watch(authStateProvider).value;

  if (currentUser == null || query.trim().isEmpty) {
    return Stream.value([]);
  }

  return ref.watch(userRepositoryProvider).searchUsers(query, currentUser.uid);
});

final conversationProvider = StreamProvider.family<Conversation?, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatRepositoryProvider).watchConversation(conversationId);
});
