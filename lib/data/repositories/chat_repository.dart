import '../models/message_model.dart';
import '../services/firebase/firebase_providers.dart';

class ChatRepository {
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
}