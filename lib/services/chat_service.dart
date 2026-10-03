import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get all users from Firestore Users collection
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('uid') || data['uid'] == null || data['uid'].toString().isEmpty) {
          data['uid'] = doc.id;
        }
        return data;
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser?.uid ?? 'guest_user';
    final String currentEmail = _firebaseAuth.currentUser?.email ?? 'guest@example.com';
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    // Construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Get message stream
  Stream<QuerySnapshot> getMessage(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark incoming messages as seen
  Future<void> markMessagesAsSeen(String userId, String otherUserId) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomID = ids.join('_');

    try {
      final unreadDocs = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isSeen', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        await doc.reference.update({'isSeen': true});
      }
    } catch (_) {}
  }

  // Helper: get uid by email
  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? q.docs.first.id).toString();
  }

  // Sync user profile to Users collection in Firestore
  Future<void> syncUserProfile({
    required String uid,
    required String email,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      await _firestore.collection('Users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username ?? email.split('@').first,
        'firstName': firstName ?? username ?? email.split('@').first,
        'lastName': lastName ?? '',
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing user profile to Firestore: $e');
    }
  }
}
