import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class GoalsRepository {
  Future<Map<String, dynamic>> load();

  Future<void> save(Map<String, dynamic> data);
}

class FirestoreGoalsRepository implements GoalsRepository {
  FirestoreGoalsRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _document {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Sign in to load and save your goals.');
    }

    return _firestore.collection('user_goals').doc(user.uid);
  }

  @override
  Future<Map<String, dynamic>> load() async {
    final snapshot = await _document.get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    await _document.set(data);
  }
}