import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/models/friendRequest.dart';
import 'package:social_media_app/screens/profile/list_friends.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:social_media_app/screens/chats/conversation.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/pages/profile.dart';
import 'package:social_media_app/screens/posts/view_image.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  User? user;
  bool isLoading = false;
  UserModel? users;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fitHeight,
              alignment: FractionalOffset(0.0, 0.0),
              image: ExactAssetImage("assets/images/belp.png"),
            )),
          ),
        ),
        titleSpacing: 5.0,
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Center(child: Text(
                "Friend Requests",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
              ),)
            ),
            StreamBuilder(
              stream: friendsRef.doc(currentUserId()).collection('userFriends')
                  .snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  QuerySnapshot<Object?>? snap =
                      snapshot.data;
                  List<DocumentSnapshot> docs = snap!.docs;
                  return totalFriendContainer(docs.length.toString()?? "0", context);
                } else {
                  return totalFriendContainer("0", context);
                }
              }
            ),
            SizedBox(height: 10,),
            Container(
              height: MediaQuery.of(context).size.height - 150,
              child: StreamBuilder(
                stream: friendRequests_ReceiverRef.doc(currentUserId()).collection('requests').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var snap = snapshot.data;
                    List docs = snap!.docs;
                    if(docs.length.toString() == "0"){
                      return Column(
                        children: [
                          SizedBox(height: 10,),
                          Text(
                            'No Friend Requests',
                            style: TextStyle(
                              fontSize: 18.0,
                            ),
                          )
                        ],
                      );
                    }
                    else{
                      return GridView.builder(
                        itemCount: docs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          FriendRequestModel friendRequests = FriendRequestModel.fromJson(docs[index].data());
                          return gridViewItem(friendRequest: friendRequests);
                        },
                      );
                    }
                    
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
                    return circularProgress(context);
                  } else
                    return Center(
                      child: Text(
                        'No Friend Requests',
                        style: TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                },
              ),
            ),
          ],
        ),
      )
    );
  }

  totalFriendContainer(String total, BuildContext context){
    return Container(
      margin: EdgeInsets.fromLTRB(15, 20, 15, 0),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(blurRadius: 1, color: Constants.lightAccent.withOpacity(0.5))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                "Total friends: ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Quicksand'
                ),
              ),
              GestureDetector(
                onTap: (){
                  showFriendList(context);
                },
                child: Text(
                  total,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand'
                  ),
                )
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)
            ),
            child: StreamBuilder(
                stream: usersRef.doc(currentUserId()).snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot){
                  if (snapshot.hasData) {
                    UserModel user = UserModel.fromJson(
                      snapshot.data!.data() as Map<String, dynamic>,
                    );
                    return user.photoUrl!.isEmpty
                      ? CircleAvatar(
                          radius: 25.0,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary,
                          child: Center(
                            child: Text(
                              user.username![0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 25.0,
                          backgroundImage:
                              CachedNetworkImageProvider(
                            '${user.photoUrl}',
                          ),
                        );
                  }
                  else{
                    return CircleAvatar(
                      radius: 10,
                      backgroundColor: Constants.lightAccent,
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  }
                }
            )
          )
        ],
      ),
    );
  }

  Widget gridViewItem(
    {required FriendRequestModel friendRequest}
  ){
    return StreamBuilder(
      stream: usersRef.doc(friendRequest.senderId!).snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot snap = snapshot.data!;
          UserModel user =
              UserModel.fromJson(snap.data() as Map<String, dynamic>);
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 4,
            shadowColor: Constants.lightAccent,
            child: Container(
              padding: EdgeInsets.only(top:4),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => showProfile(context, profileId: user.id!),
                          child: Container(
                          height: 110,
                          width: 200,
                          child: user.photoUrl!.isEmpty
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor: Constants.lightAccent,
                                child: Center(
                                  child: Text(
                                    '$user.username[0].toUpperCase()}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 50.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    CachedNetworkImageProvider(user.photoUrl!),
                              ),
                        ),
                      ),
                    
                      Positioned(
                        top: 90,
                        width: 130,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).secondaryHeaderColor
                          ),
                          child: Center(
                            child: Text(
                              user.username!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                              ),
                            )
                          )
                        )
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Column(
                        children: [
                          buildButton(
                            text: "Accept Request",
                            function: (){
                              handleAcceptFriendRequest(user.id!);
                            },
                            color: Theme.of(context).colorScheme.secondary
                          ),
                          SizedBox(height: 5,),
                          buildButton(
                            text: "Delete Request",
                            width: 200,
                            function: (){
                              handleDeleteFriendRequest(user.id!);
                            },
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                          ),
                        ],
                      )
                    )
                  )
                ],
              ),
            )
          );
        }
        else{
          return Container();
        }
      } 
    );
  }

  showFriendList(BuildContext context){
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ListFriends()
      ),
    );
  }

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => Profile(profileId: profileId),
      ),
    );
  }

  buildButton({String? text, double? width, Function()? function, Color? color}) {
    return Center(
      child: GestureDetector(
        onTap: function!,
        child: Container(
          height: 36.0,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: color,
          ),
          child: Center(
            child: Text(
              text!,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
  
  handleAcceptFriendRequest(String userId) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    //updates the friends collection of the followed user
    friendsRef
        .doc(userId)
        .collection('userFriends')
        .doc(currentUserId())
        .set({
          "friendId": currentUserId(),
          "timestamp": timestamp
        });
    //updates the following collection of the currentUser
    friendsRef
        .doc(currentUserId())
        .collection('userFriends')
        .doc(userId)
        .set({
          "friendId": userId,
          "timestamp": timestamp
        });
    //update the notification feeds
    friendRequests_SenderRef
        .doc(userId)
        .collection('requests')
        .doc(currentUserId())
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //updates the following collection of the currentUser
    friendRequests_ReceiverRef
        .doc(currentUserId())
        .collection('requests')
        .doc(userId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    notificationRef
        .doc(userId)
        .collection('notifications')
        .doc(currentUserId())
        .set({
      "type": "acceptFriendRequest",
      "ownerId": userId,
      "username": users?.username,
      "userId": users?.id,
      "userDp": users?.photoUrl,
      "timestamp": timestamp,
    });
  }

  handleDeleteFriendRequest(String userId) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    friendRequests_SenderRef
        .doc(userId)
        .collection('requests')
        .doc(currentUserId())
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //updates the following collection of the currentUser
    friendRequests_ReceiverRef
        .doc(currentUserId())
        .collection('requests')
        .doc(userId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  } 
}

