import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String? _currentUserId;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      setState(() {
        _currentUserEmail = authUser.email;
        _currentUserId = authUser.uid;
      });
      // Ensure current user is synced to Firestore Users collection
      await _chatService.syncUserProfile(
        uid: authUser.uid,
        email: authUser.email ?? '',
        username: authUser.displayName,
      );
    } else {
      final userData = await userService.value.getUserData();
      if (userData != null) {
        setState(() {
          _currentUserEmail = userData.email;
          _currentUserId = userData.id;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  String _getUserDisplayName(Map<String, dynamic> user) {
    final first = user['firstName']?.toString() ?? '';
    final last = user['lastName']?.toString() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    return user['username']?.toString() ??
        user['email']?.toString() ??
        'Unknown User';
  }

  String _getUserEmail(Map<String, dynamic> user) {
    return user['email']?.toString() ?? 'No email';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar (Enhancement 2: Search Functionality)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                setState(() {
                  _searchText = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search user by name or email...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchChatController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear',
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Users Stream List (Enhancement 1: User Display & Excluding Current User)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading users:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final rawUsers = snapshot.data ?? [];

                // Filter 1: Exclude the current logged-in user
                final usersWithoutMe = rawUsers.where((user) {
                  final uid = user['uid']?.toString() ?? user['id']?.toString() ?? '';
                  final email = user['email']?.toString() ?? '';

                  if (_currentUserId != null && uid.isNotEmpty && uid == _currentUserId) {
                    return false;
                  }
                  if (_currentUserEmail != null &&
                      email.isNotEmpty &&
                      email.toLowerCase() == _currentUserEmail!.toLowerCase()) {
                    return false;
                  }
                  return true;
                }).toList();

                // Filter 2: Apply Search Filter by name or email
                final filteredUsers = usersWithoutMe.where((user) {
                  if (_searchText.isEmpty) return true;
                  final name = _getUserDisplayName(user).toLowerCase();
                  final email = _getUserEmail(user).toLowerCase();
                  return name.contains(_searchText) || email.contains(_searchText);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchText.isNotEmpty ? Icons.search_off : Icons.group_off_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchText.isNotEmpty
                                ? 'No users matching "$_searchText"'
                                : 'No other registered users found yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (_searchText.isEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'When other users register in the app, they will automatically appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final displayName = _getUserDisplayName(user);
                    final email = _getUserEmail(user);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chat_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                currentUserEmail: _currentUserEmail,
                                tappedUser: user,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
