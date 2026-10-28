import '../Models/auth_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPresenter {
  final AuthModel _authModel = AuthModel();

  Future<String?> signIn(String email, String password) async {
    return _authModel.signIn(email, password);
  } 

  Future<String?> signUp(String email, String password) async {
    return _authModel.signUp(email, password);
  } 

  Future<void> signOut() => _authModel.signOut();

  Stream<User?> authStateChanges() => _authModel.authStateChanges();


  Stream<User?> get user => _authModel.authStateChanges();
  User? get currentUser => _authModel.currentUser;

  Future<Object?> login(String trim, String trim2) async {}
}