import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/posts/view_image.dart';
import 'package:social_media_app/services/services.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:uuid/uuid.dart';

class PostService extends Service {
  String postId = Uuid().v4();

//uploads post to the post collection
  uploadPost(String images, String description) async {
    List<String> imgs = images.split('-imagesplit-');
    List<String> links = [];
    for (int i = 0; i < imgs.length; i++){
      links.add(await uploadImage(posts, File(imgs[i])));
    }
    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(
      doc.data() as Map<String, dynamic>,
    );
    var ref = postRef.doc();
    ref.set({
      "id": ref.id,
      "postId": ref.id,
      "username": user!.username,
      "ownerId": firebaseAuth.currentUser!.uid,
      "mediaUrl": links.join('-imagesplit-'),
      "description": description ?? "",
      "timestamp": Timestamp.now(),
    });
  }

  editPost({String? postId, String? images, String? description}) async {
    if (images == null){
      var ref = postRef.doc(postId);
      ref.update({
        "description": description ?? "",
        "timestamp": Timestamp.now(),
      });
    }
    else{
      List<String> imgs = images!.split('-imagesplit-');
      List<String> links = [];
      for (int i = 0; i < imgs.length; i++){
        links.add(await uploadImage(posts, File(imgs[i])));
      }
      var ref = postRef.doc(postId);
      ref.update({
        "mediaUrl": links.join('-imagesplit-'),
        "description": description ?? "",
        "timestamp": Timestamp.now(),
      });
    }
  }

  deletePost(String postId) async{
    DocumentSnapshot doc = await postRef.doc(postId).get();
    PostModel post = PostModel.fromJson(doc.data() as Map<String, dynamic>);
    String mediaUrls = post.mediaUrl!;
    deleteMedia(mediaUrls);
    await postRef.doc(postId).get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  deleteMedia(String mediaUrls) async{
    List<String> imgs = mediaUrls!.split('-imagesplit-');
    for (int i = 0; i < imgs.length; i++){
      FirebaseStorage.instance.refFromURL(imgs[i]).delete();
    }
  }

//upload a comment
  uploadComment(String currentUserId, String comment, String postId,
      String ownerId, String mediaUrl) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    await commentRef.doc(postId).collection("comments").add({
      "username": user!.username,
      "comment": comment,
      "timestamp": Timestamp.now(),
      "userDp": user!.photoUrl,
      "userId": user!.id,
    });
    bool isNotMe = ownerId != currentUserId;
    if (isNotMe) {
      addCommentToNotification("comment", comment, user!.username!, user!.id!,
          postId, mediaUrl, ownerId, user!.photoUrl!);
    }
  }

//add the comment to notification collection
  addCommentToNotification(
      String type,
      String commentData,
      String username,
      String userId,
      String postId,
      String mediaUrl,
      String ownerId,
      String userDp) async {
    await notificationRef.doc(ownerId).collection('notifications').add({
      "type": type,
      "commentData": commentData,
      "username": username,
      "userId": userId,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

//add the likes to the notfication collection
  addLikesToNotification(String type, String username, String userId,
      String postId, String mediaUrl, String ownerId, String userDp) async {
    await notificationRef
        .doc(ownerId)
        .collection('notifications')
        .doc(postId)
        .set({
      "type": type,
      "username": username,
      "userId": firebaseAuth.currentUser!.uid,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

  //remove likes from notification
  removeLikeFromNotification(
      String ownerId, String postId, String currentUser) async {
    bool isNotMe = currentUser != ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUser).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(ownerId)
          .collection('notifications')
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }
}
