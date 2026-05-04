import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/firebase/firebase_providers.dart';

class PostRepository {
  Future<void> createPost(PostModel post) async {
    await firestoreService.posts.doc(post.id).set(post.toMap());
  }

  Stream<List<PostModel>> watchPosts() {
    return firestoreService.posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
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
    final postRef = firestoreService.posts.doc(postId);
    final commentRef = firestoreService.comments(postId).doc(comment.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> toggleLike({
    required String postId,
    required bool liked,
  }) async {
    await firestoreService.posts.doc(postId).update({
      'likes': FieldValue.increment(liked ? 1 : -1),
    });
  }
}