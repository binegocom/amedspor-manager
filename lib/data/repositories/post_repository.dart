import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/firebase/firebase_providers.dart';
import '../../core/utils/bad_words_filter.dart';

class PostRepository {
  Future<void> createPost(PostModel post) async {
    if (BadWordsFilter.containsBadWords(post.title) || BadWordsFilter.containsBadWords(post.content)) {
      throw Exception('İçeriğiniz topluluk kurallarına aykırı kelimeler içeriyor.');
    }
    await firestoreService.posts.doc(post.id).set(post.toMap());
  }

  Stream<List<PostModel>> watchPosts({int limit = 20}) {
    return firestoreService.posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<PostModel>> getPostsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = firestoreService.posts
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Helper to get raw documents for pagination
  Future<QuerySnapshot> getPostsSnapshotPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = firestoreService.posts
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  Stream<List<PostModel>> watchUserPosts(String userId) {
    return firestoreService.posts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<PostModel?> getPost(String postId) async {
    final doc = await firestoreService.posts.doc(postId).get();

    if (!doc.exists || doc.data() == null) return null;

    return PostModel.fromMap(doc.id, doc.data()!);
  }

  Stream<List<CommentModel>> watchComments(String postId) {
    return firestoreService
        .comments(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addComment({
    required String postId,
    required CommentModel comment,
  }) async {
    if (BadWordsFilter.containsBadWords(comment.text)) {
      throw Exception('Yorumunuz topluluk kurallarına aykırı kelimeler içeriyor.');
    }

    final postRef = firestoreService.posts.doc(postId);
    final commentRef = firestoreService.comments(postId).doc(comment.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(postRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Future<void> toggleLike({required String postId, required bool liked}) async {
    await firestoreService.posts.doc(postId).update({
      'likes': FieldValue.increment(liked ? 1 : -1),
    });
  }

  Future<void> createLineupPost({
    required PostModel post,
    required String lineupId,
  }) async {
    await firestoreService.posts.doc(post.id).set({
      ...post.toMap(),
      'lineupId': lineupId,
    });
  }
}
