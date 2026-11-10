import 'package:firebase_auth/firebase_auth.dart';

import '../Models/auth_model.dart';

class AuthPresenter {
  AuthModel? _authModel;

  AuthModel get _model => _authModel ??= AuthModel();

  Future<String?> signIn(String emailOrUsername, String password) async {
    return _model.signIn(emailOrUsername, password);
  }

  Future<String?> signUp(String email, String password) async {
    return _model.signUp(email, password);
  }

  Future<String?> sendPasswordResetEmail(String email) {
    return _model.sendPasswordResetEmail(email);
  }

  Future<void> signOut() => _model.signOut();

  Future<void> updateUsernameAndEmail({
    required String username,
    String? newEmail,
    String? currentPassword,
  }) => _model.updateUsernameAndEmail(
    username: username,
    newEmail: newEmail,
    currentPassword: currentPassword,
  );

  Future<void> reauthenticate(String password) =>
      _model.reauthenticate(password);

  Future<void> updatePassword(String password) =>
      _model.updatePassword(password);

  Future<void> deleteAccount() => _model.deleteAccount();

  Stream<User?> authStateChanges() => _model.authStateChanges();
  Stream<User?> userChanges() => _model.userChanges();

  Stream<User?> get user => _model.userChanges();
  User? get currentUser => _model.currentUser;

  Future<String?> login(String email, String password) {
    return signIn(email, password);
  }
}
