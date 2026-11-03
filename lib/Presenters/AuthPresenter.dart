import '../models/auth_model.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AuthPresenter {
  AuthModel? _authModel;

  AuthModel get _model => _authModel ??= AuthModel();

  Future<String?> signIn(String email, String password) async {
    return _model.signIn(email, password);
  }

  Future<String?> signUp(String email, String password) async {
    return _model.signUp(email, password);
  }

  Future<void> signOut() => _model.signOut();

  Stream<User?> authStateChanges() => _model.authStateChanges();

  Stream<User?> get user => _model.authStateChanges();
  User? get currentUser => _model.currentUser;

  Future<String?> login(String email, String password) {
    return signIn(email, password);
  }
}
