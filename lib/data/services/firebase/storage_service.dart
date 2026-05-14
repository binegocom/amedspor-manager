import 'dart:io';
import 'dart:typed_data';
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
    required String userId,
    required String postId,
    required File file,
  }) async {
    final ref = _storage.ref('posts/$userId/$postId/image.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }

  Future<String> uploadPostImageData({
    required String userId,
    required String postId,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('posts/$userId/$postId/image.jpg');

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }
}
