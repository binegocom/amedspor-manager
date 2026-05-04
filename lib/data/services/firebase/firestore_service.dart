import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get matches =>
      _db.collection('matches');

  CollectionReference<Map<String, dynamic>> get lineups =>
      _db.collection('lineups');

  CollectionReference<Map<String, dynamic>> get posts =>
      _db.collection('posts');

  CollectionReference<Map<String, dynamic>> get predictions =>
      _db.collection('predictions');

  CollectionReference<Map<String, dynamic>> get chatRooms =>
      _db.collection('chatRooms');

  CollectionReference<Map<String, dynamic>> get reports =>
      _db.collection('reports');

  CollectionReference<Map<String, dynamic>> get notifications =>
      _db.collection('notifications');

  CollectionReference<Map<String, dynamic>> messages(String roomId) {
    return chatRooms.doc(roomId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> comments(String postId) {
    return posts.doc(postId).collection('comments');
  }
}