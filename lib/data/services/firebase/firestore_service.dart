import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get matches =>
      _db.collection('matches');

  CollectionReference<Map<String, dynamic>> matchEvents(String matchId) {
    return matches.doc(matchId).collection('events');
  }

  CollectionReference<Map<String, dynamic>> motmVotes(String matchId) {
    return matches.doc(matchId).collection('motmVotes');
  }

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

  CollectionReference<Map<String, dynamic>> get players =>
      _db.collection('players');

  CollectionReference<Map<String, dynamic>> get questions =>
      _db.collection('questions');

  CollectionReference<Map<String, dynamic>> get appSettings =>
      _db.collection('appSettings');

  CollectionReference<Map<String, dynamic>> get feedback =>
      _db.collection('feedback');

  CollectionReference<Map<String, dynamic>> get errorReports =>
      _db.collection('errorReports');

  CollectionReference<Map<String, dynamic>> get auditLogs =>
      _db.collection('auditLogs');

  CollectionReference<Map<String, dynamic>> get moderationLogs =>
      _db.collection('moderationLogs');

  CollectionReference<Map<String, dynamic>> messages(String roomId) {
    return chatRooms.doc(roomId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> comments(String postId) {
    return posts.doc(postId).collection('comments');
  }

  CollectionReference<Map<String, dynamic>> postLikes(String postId) {
    return posts.doc(postId).collection('likes');
  }

  CollectionReference<Map<String, dynamic>> lineupComments(String lineupId) {
    return lineups.doc(lineupId).collection('comments');
  }

  CollectionReference<Map<String, dynamic>> lineupLikes(String lineupId) {
    return lineups.doc(lineupId).collection('likes');
  }

  // Gamification Collections
  CollectionReference<Map<String, dynamic>> get badges =>
      _db.collection('badges');

  CollectionReference<Map<String, dynamic>> get missions =>
      _db.collection('missions');

  CollectionReference<Map<String, dynamic>> get seasons =>
      _db.collection('seasons');

  CollectionReference<Map<String, dynamic>> get gamificationRules =>
      _db.collection('gamificationRules');

  // User-specific Gamification Subcollections
  CollectionReference<Map<String, dynamic>> userBadges(String userId) {
    return users.doc(userId).collection('badges');
  }

  CollectionReference<Map<String, dynamic>> userXpEvents(String userId) {
    return users.doc(userId).collection('xpEvents');
  }

  CollectionReference<Map<String, dynamic>> userMissions(String userId) {
    return users.doc(userId).collection('missions');
  }

  CollectionReference<Map<String, dynamic>> userStreaks(String userId) {
    return users.doc(userId).collection('streaks');
  }

  CollectionReference<Map<String, dynamic>> userSeasonStats(String userId) {
    return users.doc(userId).collection('seasonStats');
  }
}
