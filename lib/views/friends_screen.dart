import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/profile_avatar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const _backgroundColor = Color.fromARGB(255, 247, 231, 206);
  static const _primaryColor = Color(0xFF1F5DA8);

  final _firestore = FirebaseFirestore.instance;
  final _database = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();

  bool _isAdding = false;
  bool _isManaging = false;
  String _searchQuery = '';

  User? get _user => _auth.currentUser;

  String _normalize(String username) => username.trim().toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFriend() async {
    final user = _user;
    if (user == null) return;

    final usernameController = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add friend'),
        content: TextField(
          controller: usernameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter an exact username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, usernameController.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    usernameController.dispose();

    if (!mounted || username == null) return;
    final normalized = _normalize(username);
    if (normalized.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final indexSnapshot = await _firestore
          .collection('username_index')
          .doc(normalized)
          .get();
      final data = indexSnapshot.data();
      final friendUid = data?['uid'];

      if (!indexSnapshot.exists || friendUid is! String || friendUid.isEmpty) {
        _showMessage('No account found for "$normalized".');
        return;
      }
      if (friendUid == user.uid) {
        _showMessage('You cannot add yourself.');
        return;
      }

      final friendUsername = data?['username'];
      final friendName = friendUsername is String ? friendUsername : normalized;
      final ownUsername = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'unknown';

      await _database.ref('friends/${user.uid}/$friendUid').set({
        'username': friendName,
        'addedAt': ServerValue.timestamp,
      });
      await _database.ref('friends/$friendUid/${user.uid}').set({
        'username': ownUsername,
        'addedAt': ServerValue.timestamp,
      });

      _showMessage('$friendName added to friends.');
    } catch (error) {
      _showMessage('Could not add friend: $error');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removeFriend(String friendUid, String friendUsername) async {
    final user = _user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove "$friendUsername" from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await Future.wait([
        _database.ref('friends/${user.uid}/$friendUid').remove(),
        _database.ref('friends/$friendUid/${user.uid}').remove(),
      ]);
      _showMessage('$friendUsername removed.');
    } catch (error) {
      _showMessage('Could not remove friend: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: _backgroundColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAdding ? null : _addFriend,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: _isAdding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add_alt_1),
        label: Text(_isAdding ? 'Adding...' : 'Add friend'),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view your friends.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() => _isManaging = !_isManaging);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: Icon(
                            _isManaging
                                ? Icons.check
                                : Icons.manage_accounts_outlined,
                          ),
                          label: Text(
                            _isManaging ? 'Done managing' : 'Manage friends',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(
                          () => _searchQuery = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search friends',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _database.ref('friends/${user.uid}').onValue,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Could not load friends.'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final value = snapshot.data?.snapshot.value;
                      final rawFriends = value is Map
                          ? Map<Object?, Object?>.from(value)
                          : null;
                      final friends =
                          rawFriends?.entries
                              .where(
                                (entry) =>
                                    entry.key is String && entry.value is Map,
                              )
                              .map((entry) {
                                final uid = entry.key as String;
                                final data = Map<Object?, Object?>.from(
                                  entry.value as Map,
                                );
                                final username = data['username'];
                                return (
                                  uid: uid,
                                  username: username is String
                                      ? username
                                      : 'Unknown user',
                                );
                              })
                              .toList() ??
                          [];

                      if (friends.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 72,
                                  color: _primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No friends yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Use Add friend to find someone by username.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      friends.sort(
                        (a, b) => a.username.toLowerCase().compareTo(
                          b.username.toLowerCase(),
                        ),
                      );
                      final filteredFriends = friends
                          .where(
                            (friend) => friend.username.toLowerCase().contains(
                              _searchQuery,
                            ),
                          )
                          .toList();

                      if (filteredFriends.isEmpty) {
                        return Center(
                          child: Text('No friends match "$_searchQuery".'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: filteredFriends.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      StreamBuilder<DatabaseEvent>(
                                        stream: _database
                                            .ref(
                                              'profileImages/${friend.uid}',
                                            )
                                            .onValue,
                                        builder: (context, imageSnapshot) {
                                          if (imageSnapshot.hasError) {
                                            return const Tooltip(
                                              message:
                                                  'Could not load profile picture',
                                              child: CircleAvatar(
                                                backgroundColor: _primaryColor,
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          }

                                          return ProfileAvatar(
                                            profileData: imageSnapshot
                                                .data
                                                ?.snapshot
                                                .value,
                                            radius: 24,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          friend.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (_isManaging)
                                        IconButton(
                                          tooltip: 'Remove friend',
                                          onPressed: () => _removeFriend(
                                            friend.uid,
                                            friend.username,
                                          ),
                                          icon: const Icon(
                                            Icons.person_remove_outlined,
                                          ),
                                          color: Colors.red.shade700,
                                        ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (context) =>
                                                _FriendProfileScreen(
                                              friendUid: friend.uid,
                                              username: friend.username,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('View profile'),
                                    ),
                                  ),
                                ],
                              ),
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

class _FriendProfileScreen extends StatelessWidget {
  const _FriendProfileScreen({
    required this.friendUid,
    required this.username,
  });

  final String friendUid;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FriendsScreenState._backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: _FriendsScreenState._backgroundColor,
      ),
      body: Center(
        child: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance
              .ref('profileImages/$friendUid')
              .onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Could not load this profile.');
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(
                  profileData: snapshot.data?.snapshot.value,
                  radius: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
