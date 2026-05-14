import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/firebase/firebase_providers.dart';
import '../../core/utils/bad_words_filter.dart';

class PostRepository {
  Future<void> createPost(PostModel post) async {
    // Client Pre-validation Filter: Rapid UX response.
    // Full definitive dictionary validation is managed dynamically by backend security functions.
    if (BadWordsFilter.containsBadWords(post.title) ||
        BadWordsFilter.containsBadWords(post.content)) {
      throw Exception(
        'İçeriğiniz topluluk kurallarına aykırı kelimeler içeriyor.',
      );
    }

    // Attach marker to inform server network rules of validation step completion
    final payload = {
      ...post.toMap(),
      'clientSanitized': true,
    };
    await firestoreService.posts.doc(post.id).set(payload);
  }

  Stream<List<PostModel>> watchPosts({int limit = 20}) {
    return firestoreService.posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .where((post) => !post.hidden)
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
        .map(
          (doc) =>
              PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .where((post) => !post.hidden)
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

  Stream<List<PostModel>> watchUserPosts(String userId, {int limit = 30}) {
    return firestoreService.posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .where((post) => !post.hidden)
              .toList(),
        );
  }

  Future<PostModel?> getPost(String postId) async {
    final doc = await firestoreService.posts.doc(postId).get();

    if (!doc.exists || doc.data() == null) return null;

    return PostModel.fromMap(doc.id, doc.data()!);
  }

  Stream<PostModel?> watchPost(String postId) {
    return firestoreService.posts.doc(postId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final post = PostModel.fromMap(doc.id, data);
      return post.hidden ? null : post;
    });
  }

  Stream<bool> watchLikedByCurrentUser({
    required String postId,
    required String userId,
  }) {
    return firestoreService
        .postLikes(postId)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
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
    // Client Pre-validation Filter
    if (BadWordsFilter.containsBadWords(comment.text)) {
      throw Exception(
        'Yorumunuz topluluk kurallarına aykırı kelimeler içeriyor.',
      );
    }

    final postRef = firestoreService.posts.doc(postId);
    final commentRef = firestoreService.comments(postId).doc(comment.id);
    final payload = {
      ...comment.toMap(),
      'clientSanitized': true,
    };

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, payload);
      transaction.update(postRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = firestoreService.posts.doc(postId);
    final likeRef = firestoreService.postLikes(postId).doc(userId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return false;

      if (likeDoc.exists) {
        final currentLikes = (postDoc.data()?['likes'] ?? 0) as int;
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likes': FieldValue.increment(currentLikes > 0 ? -1 : 0),
        });
        return false;
      }

      transaction.set(likeRef, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'likes': FieldValue.increment(1)});
      return true;
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

// Küresel gönderi akışı sağlayıcısı
final postsStreamProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  return PostRepository().watchPosts();
});

// Beğeni durumu parametresi
class PostLikeParam {
  final String postId;
  final String userId;
  const PostLikeParam({required this.postId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostLikeParam &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          userId == other.userId;

  @override
  int get hashCode => postId.hashCode ^ userId.hashCode;
}

// Bireysel gönderi beğeni durumu akışı
final postLikedStreamProvider = StreamProvider.family.autoDispose<bool, PostLikeParam>((ref, param) {
  return PostRepository().watchLikedByCurrentUser(postId: param.postId, userId: param.userId);
});
