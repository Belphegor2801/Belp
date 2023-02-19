import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/screens/posts/view_image.dart';

class FriendModel {
  String? friendId;
  Timestamp? timestamp;

  FriendModel(
      {this.friendId,
      this.timestamp}
  );

  FriendModel.fromJson(Map<String, dynamic> json) {
    friendId = json['friendId'];
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['friendId'] = this.friendId;
    data['timestamp'] = this.timestamp;
    return data;
  }
}
