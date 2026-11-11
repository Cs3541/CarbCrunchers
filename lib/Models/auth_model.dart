import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('username_index');

  String _normalizeUsername(String username) =>
      username.trim().toLowerCase();

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-z0-9][a-z0-9._-]{2,19}$')
        .hasMatch(_normalizeUsername(username));
  }

  // Sign in using either an email address or a username.
  Future<String?> signIn(
    String emailOrUsername,
    String password,
  ) async {
    try {
      final identifier = emailOrUsername.trim();
      final email = identifier.contains('@')
          ? identifier
          : await _resolveUsernameEmail(identifier);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Refresh the username record's email if the account's email changed.
      await _syncUsernameEmail(credential.user);

      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'invalid-credential' || 'user-not-found' =>
          'Email/username or password is incorrect.',
        'too-many-requests' =>
          'Too many attempts. Wait a while and try again.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        _ => error.message ?? 'Could not sign in.',
      };
    } on FirebaseException catch (error) {
      return error.message ?? 'Could not look up that username.';
    } catch (error) {
      return error.toString();
    }
  }

  // Create an account with email and password.
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'email-already-in-use' => 'That email is already registered.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Choose a stronger password.',
        _ => error.message ?? 'Could not create your account.',
      };
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> sendPasswordResetEmail(String emailOrUsername) async {
    try {
      final identifier = emailOrUsername.trim();
      final email = identifier.contains('@')
          ? identifier
          : await _resolveUsernameEmail(identifier);

      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' =>
          'Too many requests. Please wait a while and try again.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        _ => error.message ?? 'Could not send the password reset email.',
      };
    } on FirebaseException catch (error) {
      return error.message ?? 'Could not look up that username.';
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> signOut() => _auth.signOut();

  // Create or change the signed-in user's username.
  Future<void> updateUsernameAndEmail({
    required String username,
    String? newEmail,
    String? currentPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to change your username.');
    }

    final normalized = _normalizeUsername(username);

    if (!_isValidUsername(username)) {
      throw StateError(
        'Use 3–20 letters, numbers, periods, underscores, or hyphens.',
      );
    }

    final currentEmail = user.email;

    if (currentEmail == null) {
      throw StateError('A signed-in email account is required.');
    }

    final requestedEmail = newEmail?.trim();
    final isChangingEmail = requestedEmail != null &&
        requestedEmail.isNotEmpty &&
        requestedEmail.toLowerCase() != currentEmail.toLowerCase();

    if (isChangingEmail) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw StateError('Enter your current password to change your email.');
      }

      await reauthenticate(currentPassword);
    }

    final targetRef = _usernames.doc(normalized);

    final oldUsername = user.displayName;
    final oldKey = oldUsername == null
        ? null
        : _normalizeUsername(oldUsername);

    final oldRef = oldKey == null || oldKey.isEmpty
        ? null
        : _usernames.doc(oldKey);

    await _firestore.runTransaction((transaction) async {
      final targetSnapshot = await transaction.get(targetRef);

      if (targetSnapshot.exists &&
          targetSnapshot.data()?['uid'] != user.uid) {
        throw StateError('That username is already in use. Choose another.');
      }

      DocumentSnapshot<Map<String, dynamic>>? oldSnapshot;

      if (oldRef != null && oldRef.path != targetRef.path) {
        oldSnapshot = await transaction.get(oldRef);
      }

      transaction.set(targetRef, {
        'uid': user.uid,
        'username': normalized,
        'email': currentEmail,
      });

      if (oldRef != null &&
          oldRef.path != targetRef.path &&
          oldSnapshot?.data()?['uid'] == user.uid) {
        transaction.delete(oldRef);
      }
    });

    try {
      await user.updateDisplayName(normalized);
    } catch (error) {
      // The username record is already saved. Report the profile update issue.
      throw StateError(
        'Username was saved, but the profile could not be refreshed: $error',
      );
    }

    if (isChangingEmail) {
      try {
        await user.verifyBeforeUpdateEmail(requestedEmail);
      } on FirebaseAuthException catch (error) {
        final message = switch (error.code) {
          'email-already-in-use' =>
            'That email is already used by another account.',
          'invalid-email' => 'Enter a valid new email address.',
          'requires-recent-login' =>
            'Sign out and sign back in before changing your email.',
          'too-many-requests' =>
            'Too many attempts. Wait a while and try again.',
          'network-request-failed' =>
            'Check your internet connection and try again.',
          _ => error.message ?? 'Could not send the email verification.',
        };

        throw StateError(message);
      }
    }
  }

  // Reauthenticate before sensitive account changes.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw StateError('A signed-in email account is required.');
    }

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> updatePassword(String password) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to change your password.');
    }

    await user.updatePassword(password);
  }

  // Remove only the username record, then delete the Firebase Auth account.
  // This deliberately does not touch recipe or meal-plan documents.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to delete your account.');
    }

    final matches = await _usernames
        .where('uid', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();

    for (final document in matches.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
    await user.delete();
  }

  Future<String> _resolveUsernameEmail(String username) async {
    final normalized = _normalizeUsername(username);

    if (!_isValidUsername(normalized)) {
      throw StateError('Enter a valid username or email address.');
    }

    final snapshot = await _usernames.doc(normalized).get();

    if (!snapshot.exists) {
      throw StateError('No account was found with that username.');
    }

    final email = snapshot.data()?['email'];

    if (email is! String || email.isEmpty) {
      throw StateError('The username does not have a sign-in email.');
    }

    return email;
  }

  // Keep the lookup email current after a user verifies an email change.
  Future<void> _syncUsernameEmail(User? user) async {
    if (user == null || user.email == null || user.displayName == null) {
      return;
    }

    final username = _normalizeUsername(user.displayName!);

    if (!_isValidUsername(username)) return;

    final reference = _usernames.doc(username);
    final snapshot = await reference.get();

    if (snapshot.exists && snapshot.data()?['uid'] == user.uid) {
      await reference.update({'email': user.email});
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;
}