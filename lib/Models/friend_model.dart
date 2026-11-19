import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Status from the point of view of the user who owns the subcollection:
///   requested -> current user hassent them a request
///   pending   -> they sent me a request, waiting on me
///   accepted  -> we're friends
///   blocked   -> current user hasblocked them
enum FriendStatus { requested, pending, accepted, blocked }

class Friend {
  final String uid;
  final FriendStatus status;
  final DateTime? since;
  final String email;

  const Friend({
    required this.uid,
    required this.status,
    this.since,
    required this.email,
  });

  factory Friend.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Friend(
      uid: snapshot.id,
      status: FriendStatus.values.byName(data['status'] as String),
      since: (data['since'] as Timestamp?)?.toDate(),
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'status': status.name,
    'since': since != null
        ? Timestamp.fromDate(since!)
        : FieldValue.serverTimestamp(),
    'email': email,
  };
}

class FriendService {
  FriendService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  User get _me {
    final user = _auth.currentUser;
    if (user == null) throw FriendException('You must be signed in.');
    return user;
  }

  String _normalize(String email) => email.trim().toLowerCase();

  CollectionReference<Friend> friendsRef(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .withConverter<Friend>(
          fromFirestore: Friend.fromFirestore,
          toFirestore: (friend, _) => friend.toFirestore(),
        );
  }

  Stream<List<Friend>> _watchByStatus(FriendStatus status) {
    return friendsRef(_me.uid)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Live list of accepted friends.
  Stream<List<Friend>> watchFriends() => _watchByStatus(FriendStatus.accepted);

  /// Live list of requests other people sent me.
  Stream<List<Friend>> watchIncomingRequests() =>
      _watchByStatus(FriendStatus.pending);

  /// Live list of requests current user hassent that haven't been answered.
  Stream<List<Friend>> watchOutgoingRequests() =>
      _watchByStatus(FriendStatus.requested);

  Stream<FriendStatus?> watchStatusWith(String otherUid) {
    return friendsRef(_me.uid)
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data()!.status : null);
  }

  Future<String?> findUidByEmail(String email) async {
    final result = await _db
        .collection('users')
        .where('email', isEqualTo: _normalize(email))
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : result.docs.first.id;
  }

  Future<void> sendRequestByEmail(String email) async {
    final me = _me;
    final theirEmail = _normalize(email);
    final myEmail = _normalize(me.email ?? '');

    if (theirEmail.isEmpty) throw FriendException('Enter an email address.');
    if (theirEmail == myEmail) {
      throw FriendException("You can't add yourself.");
    }

    final theirUid = await findUidByEmail(theirEmail);
    if (theirUid == null) {
      throw FriendException('No user found with that email.');
    }

    final existing = await friendsRef(me.uid).doc(theirUid).get();
    if (existing.exists) {
      switch (existing.data()!.status) {
        case FriendStatus.accepted:
          throw FriendException("You're already friends.");
        case FriendStatus.requested:
          throw FriendException('Request already sent.');
        case FriendStatus.pending:
          // They already asked me, so just accept.
          return acceptRequest(theirUid);
        case FriendStatus.blocked:
          throw FriendException('Unblock this user first.');
      }
    }

    // If they blocked me, don't reveal it: act as if they don't exist.
    final theirSide = await friendsRef(theirUid).doc(me.uid).get();
    if (theirSide.exists && theirSide.data()!.status == FriendStatus.blocked) {
      throw FriendException('No user found with that email.');
    }

    final batch = _db.batch();
    batch.set(
      friendsRef(me.uid).doc(theirUid),
      Friend(uid: theirUid, status: FriendStatus.requested, email: theirEmail),
    );
    batch.set(
      friendsRef(theirUid).doc(me.uid),
      Friend(uid: me.uid, status: FriendStatus.pending, email: myEmail),
    );
    await batch.commit();
  }

  Future<void> acceptRequest(String theirUid) async {
    final me = _me;

    final existing = await friendsRef(me.uid).doc(theirUid).get();
    if (!existing.exists || existing.data()!.status != FriendStatus.pending) {
      throw FriendException('No pending request from this user.');
    }

    final update = {
      'status': FriendStatus.accepted.name,
      'since': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.update(_db.doc('users/${me.uid}/friends/$theirUid'), update);
    batch.update(_db.doc('users/$theirUid/friends/${me.uid}'), update);
    await batch.commit();
  }

  Future<void> declineRequest(String theirUid) => _deleteBothSides(theirUid);

  Future<void> cancelRequest(String theirUid) => _deleteBothSides(theirUid);

  Future<void> removeFriend(String theirUid) => _deleteBothSides(theirUid);

  Stream<List<Friend>> watchBlocked() => _watchByStatus(FriendStatus.blocked);

  Future<void> blockUser(String theirUid, {required String theirEmail}) async {
    final me = _me;
    final batch = _db.batch();
    batch.set(
      friendsRef(me.uid).doc(theirUid),
      Friend(
        uid: theirUid,
        status: FriendStatus.blocked,
        email: _normalize(theirEmail),
      ),
    );
    batch.delete(friendsRef(theirUid).doc(me.uid));
    await batch.commit();
  }

  Future<void> unblockUser(String theirUid) async {
    final doc = await friendsRef(_me.uid).doc(theirUid).get();
    if (doc.exists && doc.data()!.status == FriendStatus.blocked) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteBothSides(String theirUid) async {
    final me = _me;
    final batch = _db.batch();
    batch.delete(friendsRef(me.uid).doc(theirUid));

    final theirSide = await friendsRef(theirUid).doc(me.uid).get();
    if (!(theirSide.exists &&
        theirSide.data()!.status == FriendStatus.blocked)) {
      batch.delete(theirSide.reference);
    }
    await batch.commit();
  }
}

class FriendException implements Exception {
  FriendException(this.message);
  final String message;

  @override
  String toString() => message;
}
