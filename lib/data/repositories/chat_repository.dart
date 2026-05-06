import '../models/message_model.dart';
import '../services/firebase/firebase_providers.dart';

class ChatRepository {
  Future<void> createRoom({
    required String roomId,
    required String name,
    required String createdBy,
  }) async {
    await firestoreService.chatRooms.doc(roomId).set({
      'name': name,
      'createdBy': createdBy,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteRoom(String roomId) async {
    await firestoreService.chatRooms.doc(roomId).delete();
  }

  Stream<List<MessageModel>> watchMessages(String roomId) {
    return firestoreService
        .messages(roomId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String roomId,
    required MessageModel message,
  }) async {
    await firestoreService
        .messages(roomId)
        .doc(message.id)
        .set(message.toMap());
  }

  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await firestoreService.messages(roomId).doc(messageId).delete();
  }
}
