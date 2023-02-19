import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/utils/firebase.dart';

class ChatService {
  FirebaseStorage storage = FirebaseStorage.instance;

  Future sendMessage(Message message, String chatId) async {
    //will update "lastTextTime" to the last time a text was sent
    await chatRef.doc("$chatId").update({"lastTextTime": Timestamp.now()});
    //will send message to chats collection with the usersId
    await chatRef.doc("$chatId").collection("messages").add(message.toJson());
  }

  Future setupFirstChat(String recipient) async {
    User user = firebaseAuth.currentUser!;
    String chatId = getUser(recipient, user.uid);
    await chatRef.doc(chatId).set({
      'chatId': chatId,
      'reads': {},
      'typing': {},
      'users': [recipient, user.uid],
    });
  }

  String getUser(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    var chatId = "${list[0]}-${list[1]}";
    return chatId;
  }

  Future<String> uploadImage(File image, String chatId) async {
    Reference storageReference =
        storage.ref().child("chats").child(chatId).child(uuid.v4());
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.whenComplete(() => null);
    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }

//determine if a user has read a chat and updates how many messages are unread
  setUserRead(String chatId, User user, int count) async {
    DocumentSnapshot snap = await chatRef.doc(chatId).get();
    Map reads = snap.get('reads') ?? {};
    reads[user.uid] = count;
    await chatRef.doc(chatId).update({'reads': reads});
  }

//determine when a user has start typing a message
  setUserTyping(String chatId, User user, bool userTyping) async {
    DocumentSnapshot snap = await chatRef.doc(chatId).get();
    Map typing = snap.get('typing') ?? {};
    typing[user.uid] = userTyping;
    await chatRef.doc(chatId).update({
      'typing': typing,
    });
  }
}
