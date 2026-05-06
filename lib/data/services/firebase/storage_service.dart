import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadProfileAvatar({
    required String userId,
    required File file,
  }) async {
    final ref = _storage.ref('users/$userId/profile/avatar.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }

  Future<String> uploadPostImage({
    required String postId,
    required File file,
  }) async {
    final ref = _storage.ref('posts/$postId/image.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }
}
