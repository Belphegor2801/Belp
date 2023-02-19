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
import 'package:social_media_app/models/friend.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:social_media_app/screens/chats/conversation.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/pages/profile.dart';
import 'package:social_media_app/screens/posts/view_image.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';

class ListFriends extends StatefulWidget {
  const ListFriends({super.key});

  @override
  State<ListFriends> createState() => _ListFriendsState();
}

class _ListFriendsState extends State<ListFriends> {
  User? user;
  bool isLoading = false;
  UserModel? users;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.keyboard_backspace),
        ),
        automaticallyImplyLeading: false,
        title: Text(
                "Friends",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
              ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder(
              stream: friendsRef.doc(currentUserId()).collection('userFriends')
                  .snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  QuerySnapshot<Object?>? snap =
                      snapshot.data;
                  List<DocumentSnapshot> docs = snap!.docs;
                  return totalFriendContainer(docs.length.toString()?? "0");
                } else {
                  return totalFriendContainer("0");
                }
              }
            ),
            SizedBox(height: 10,),
            Container(
              height: MediaQuery.of(context).size.height - 150,
              child: StreamBuilder(
                stream: friendsRef.doc(currentUserId()).collection('userFriends').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var snap = snapshot.data;
                    List docs = snap!.docs;
                    if(docs.length.toString() == "0"){
                      return Column(
                        children: [
                          SizedBox(height: 10,),
                          Text(
                            'No Friends',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
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
                          FriendModel friends = FriendModel.fromJson(docs[index].data());
                          return gridViewItem(friends: friends);
                        },
                      );
                    }
                    
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
                    return circularProgress(context);
                  } else
                    return Center(
                      child: Text(
                        'No Friends',
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

  totalFriendContainer(String total){
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
                "Friends: ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Quicksand'
                ),
              ),
              Text(
                total,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand'
                ),
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
                              '${user.username![0].toUpperCase()}',
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
    {required FriendModel friends}
  ){
    return StreamBuilder(
      stream: usersRef.doc(friends.friendId!).snapshots(),
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
                          height: 170,
                          width: 200,
                          child: user.photoUrl!.isEmpty
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor: Constants.lightAccent,
                                child: Center(
                                  child: Text(
                                    '${user.username![0].toUpperCase()}',
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
                    ],
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).secondaryHeaderColor
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(height: 5,),
                          Text(
                            user.username!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(height: 5,),
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

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => Profile(profileId: profileId),
      ),
    );
  }
}

