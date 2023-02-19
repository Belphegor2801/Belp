import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  String? senderId;
  String? receiverId;

  FriendRequestModel(
      {this.senderId,
      this.receiverId});

  FriendRequestModel.fromJson(Map<String, dynamic> json) {
    senderId = json['senderId'];
    receiverId = json['receiverId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['senderId'] = this.senderId;
    data['receiverId'] = this.receiverId;
    return data;
  }
}
