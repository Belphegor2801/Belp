import 'dart:ffi';

import 'package:animations/animations.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:social_media_app/components/custom_card.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/pages/profile.dart';
import 'package:social_media_app/screens/posts/edit_post.dart';
import 'package:social_media_app/screens/posts/comment.dart';
import 'package:social_media_app/screens/posts/view_image.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/image_slider.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserPost extends StatefulWidget {
  final Widget? feeds;
  final PostModel? post;

  UserPost({this.feeds, this.post});

  @override
  State<UserPost> createState() => _UserPostState();
}

class _UserPostState extends State<UserPost> {
  final DateTime timestamp = DateTime.now();

  bool isFriends = false;
  bool isBlocked_sender = false;
  bool isMe = false;

  @override
  void initState() {
    super.initState();
    checkIfFriendOrBlocked();
  }

  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  final PostService services = PostService();

  checkIfFriendOrBlocked() async {
    setState(() {
      isMe = currentUserId() == widget.post!.ownerId;
    });
    if (!isMe){
      DocumentSnapshot friendDoc = await friendsRef
        .doc(currentUserId())
        .collection('userFriends')
        .doc(widget.post!.ownerId!)
        .get();
      DocumentSnapshot block_senderDoc = await blockRef
          .doc(currentUserId()) 
          .collection('userBlock')
          .doc(widget.post!.ownerId!)
          .get();
      setState(() {
        isFriends = friendDoc.exists;
        isBlocked_sender = block_senderDoc.exists;
        isMe = currentUserId() == widget.post!.ownerId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isMe || isFriends ? CustomCard(
      onTap: () {
      },
      borderRadius: BorderRadius.circular(10.0),
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return ViewImage(post: widget.post);
        },
        closedElevation: 0.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
        ),
        onClosed: (v) {},
        closedColor: Theme.of(context).cardColor,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Stack(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      ImageSlider(
                        imageUrls: widget.post!.mediaUrl!,
                        maxImages: 4,
                        onExpandClicked: (){},
                        onImageClicked: (i){},
                        type: widget.post!.mediaUrl!.contains('.mp4')? 'online-video': 'online-images',
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: widget.post!.description != null &&
                              widget.post!.description.toString().isNotEmpty,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5.0, top: 3.0),
                            child: Text(
                              '${widget.post?.description ?? ""}',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.caption!.color,
                                fontSize: 15.0,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Row(
                            children: [
                              buildLikeButton(),
                              SizedBox(width: 5.0),
                              InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => Comments(post: widget.post),
                                    ),
                                  );
                                },
                                child: Icon(
                                  CupertinoIcons.chat_bubble,
                                  size: 25.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 0.0),
                                child: StreamBuilder(
                                  stream: likesRef
                                      .where('postId', isEqualTo: widget.post!.postId)
                                      .snapshots(),
                                  builder: (context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasData) {
                                      QuerySnapshot snap = snapshot.data!;
                                      List<DocumentSnapshot> docs = snap.docs;
                                      return buildLikesCount(
                                          context, docs.length ?? 0);
                                    } else {
                                      return buildLikesCount(context, 0);
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 5.0),
                            StreamBuilder(
                              stream: commentRef
                                  .doc(widget.post!.postId!)
                                  .collection("comments")
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasData) {
                                  QuerySnapshot snap = snapshot.data!;
                                  List<DocumentSnapshot> docs = snap.docs;
                                  return buildCommentsCount(
                                      context, docs.length ?? 0);
                                } else {
                                  return buildCommentsCount(context, 0);
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 3.0),
                        // SizedBox(height: 5.0),
                      ],
                    ),
                  )
                ],
              ),
              buildUser(context),
            ],
          );
        },
      ),
    ): SizedBox();
  }

  buildLikeButton() {
    return StreamBuilder(
      stream: likesRef
          .where('postId', isEqualTo: widget.post!.postId)
          .where('userId', isEqualTo: currentUserId())
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

          ///replaced this with an animated like button
          // return IconButton(
          //   onPressed: () {
          //     if (docs.isEmpty) {
          //       likesRef.add({
          //         'userId': currentUserId(),
          //         'postId': widget.post!.postId,
          //         'dateCreated': Timestamp.now(),
          //       });
          //       addLikesToNotification();
          //     } else {
          //       likesRef.doc(docs[0].id).delete();
          //       services.removeLikeFromNotification(
          //           widget.post!.ownerId!, widget.post!.postId!, currentUserId());
          //     }
          //   },
          //   icon: docs.isEmpty
          //       ? Icon(
          //           CupertinoIcons.heart,
          //         )
          //       : Icon(
          //           CupertinoIcons.heart_fill,
          //           color: Colors.red,
          //         ),
          // );
          Future<bool> onLikeButtonTapped(bool isLiked) async {
            if (docs.isEmpty) {
              likesRef.add({
                'userId': currentUserId(),
                'postId': widget.post!.postId,
                'dateCreated': Timestamp.now(),
              });
              addLikesToNotification();
              return !isLiked;
            } else {
              likesRef.doc(docs[0].id).delete();
              services.removeLikeFromNotification(
                  widget.post!.ownerId!, widget.post!.postId!, currentUserId());
              return isLiked;
            }
          }

          return LikeButton(
            onTap: onLikeButtonTapped,
            size: 25.0,
            circleColor:
                CircleColor(start: Color(0xffFFC0CB), end: Color(0xffff0000)),
            bubblesColor: BubblesColor(
                dotPrimaryColor: Color(0xffFFA500),
                dotSecondaryColor: Color(0xffd8392b),
                dotThirdColor: Color(0xffFF69B4),
                dotLastColor: Color(0xffff8c00)),
            likeBuilder: (bool isLiked) {
              return Icon(
                docs.isEmpty ? Ionicons.heart_outline : Ionicons.heart,
                color: docs.isEmpty
                    ? Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black
                    : Colors.red,
                size: 25,
              );
            },
          );
        }
        return Container();
      },
    );
  }

  addLikesToNotification() async {
    bool isNotMe = currentUserId() != widget.post!.ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      services.addLikesToNotification(
        "like",
        user!.username!,
        currentUserId(),
        widget.post!.postId!,
        widget.post!.mediaUrl!,
        widget.post!.ownerId!,
        user!.photoUrl!,
      );
    }
  }

  buildLikesCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 7.0),
      child: Text(
        '$count likes',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10.0,
        ),
      ),
    );
  }

  buildCommentsCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.5),
      child: Text(
        '-   $count comments',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  buildUser(BuildContext context) {
    return StreamBuilder(
      stream: usersRef.doc(widget.post!.ownerId).snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot snap = snapshot.data!;
          UserModel user =
              UserModel.fromJson(snap.data() as Map<String, dynamic>);
          return Container(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.white60,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: GestureDetector(
                  onTap: () => showProfile(context, profileId: user.id!),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        user.photoUrl!.isEmpty
                            ? CircleAvatar(
                                radius: 20.0,
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                child: Center(
                                  child: Text(
                                    '${user.username![0].toUpperCase()}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 20.0,
                                backgroundImage: CachedNetworkImageProvider(
                                  '${user.photoUrl}',
                                ),
                              ),
                        SizedBox(width: 5.0),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.post?.username ?? ""}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeago.format(widget.post!.timestamp!.toDate()),
                              style: TextStyle(fontSize: 10.0),
                            ),
                          ],
                        ),
                        new Spacer(),
                        IconButton(
                          icon: Icon(
                            Ionicons.ellipsis_vertical_outline,
                            size: 30),
                          onPressed: () => buildChooseOption(context), 
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
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

  buildChooseOption(BuildContext context) {
    bool isMe = currentUserId() == widget.post!.ownerId;
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: .6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Center(
                  child: Text(
                    'Choose Option',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              Divider(),
              isMe?
                ListTile(
                  leading: Icon(
                    CupertinoIcons.camera_on_rectangle,
                    size: 25.0,
                  ),
                  title: Text('Edit post'),
                  onTap: () async{
                    Navigator.pop(context, true);
                    await Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => EditPost(post: widget.post!,),
                      ),
                    );
                  },
                ): SizedBox(height: 1,),
              isMe?
                ListTile(
                  leading: Icon(
                    CupertinoIcons.camera_on_rectangle,
                    size: 25.0,
                  ),
                  title: Text('Delete Post'),
                  onTap: () async {
                    Navigator.pop(context, true);
                    await confirmDelete(context);
                  },
                ):
                ListTile(
                  leading: Icon(
                    CupertinoIcons.camera_on_rectangle,
                    size: 25.0,
                  ),
                  title: Text('Report Post'),
                  onTap: () {
                    Flushbar(
                      message: "Sorry, I haven't developed this feature yet",
                      icon: Icon(
                        Icons.info_outline,
                        size: 28.0,
                        color: Colors.blue[300],
                        ),
                      duration: Duration(seconds: 3),
                      leftBarIndicatorColor: Colors.blue[300],
                    )..show(context);
                  }
                ),
              isMe?
                SizedBox(height: 5,)
                :
                !isBlocked_sender? 
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.camera_on_rectangle,
                      size: 25.0,
                    ),
                    title: Text('Block User'),
                    onTap: (){
                      Navigator.pop(context);
                      confirmBlock(context);
                    } 
                  )
                  : ListTile(
                    leading: Icon(
                      CupertinoIcons.camera_on_rectangle,
                      size: 25.0,
                    ),
                    title: Text('Unblock User'),
                    onTap: (){
                      Navigator.pop(context);
                      handleUnBlock();
                    } 
                  ),
            ],
          ),
        );
      },
    );
  }

  confirmDelete(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: .6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Center(
                  child: Text(
                    'Confirm Delete',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Delete this post'),
                onTap: () async{
                  Navigator.pop(context);
                  Flushbar(
                    message: "Deleted successfully!",
                    icon: Icon(
                      Icons.info_outline,
                      size: 28.0,
                      color: Colors.blue[300],
                      ),
                    duration: Duration(seconds: 2),
                    leftBarIndicatorColor: Colors.blue[300],
                  )..show(context);
                  await services.deletePost(widget.post!.postId!);
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                  Flushbar(
                    message: "Canceled",
                    icon: Icon(
                      Icons.info_outline,
                      size: 28.0,
                      color: Colors.blue[300],
                      ),
                    duration: Duration(seconds: 3),
                    leftBarIndicatorColor: Colors.blue[300],
                  )..show(context);
                }
              ),
            ],
          ),
        );
      },
    );
  }

  confirmBlock(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: .6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Center(
                  child: Text(
                    'Confirm Block',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Block this person!'),
                onTap: () async{
                  Navigator.pop(context);
                  Flushbar(
                    message: "Blocked successfully!",
                    icon: Icon(
                      Icons.info_outline,
                      size: 28.0,
                      color: Colors.blue[300],
                      ),
                    duration: Duration(seconds: 2),
                    leftBarIndicatorColor: Colors.blue[300],
                  )..show(context);
                  handleBLock();
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                  Flushbar(
                    message: "Canceled",
                    icon: Icon(
                      Icons.info_outline,
                      size: 28.0,
                      color: Colors.blue[300],
                      ),
                    duration: Duration(seconds: 3),
                    leftBarIndicatorColor: Colors.blue[300],
                  )..show(context);
                }
              ),
            ],
          ),
        );
      },
    );
  }

  handleUnBlock()  async {
    DocumentSnapshot doc = await blockRef.doc(currentUserId()).get();
    setState(() {
      isBlocked_sender = false;
    });
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.post!.ownerId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleBLock() async {
    DocumentSnapshot doc = await blockRef.doc(currentUserId()).get();
    setState(() {
      isBlocked_sender = true;
    });
    //updates the following collection of the currentUser
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.post!.ownerId)
        .set({
          "blockId": widget.post!.ownerId,
          "timestamp": timestamp
        });
    //update the notification feeds
    friendRequests_SenderRef
        .doc(widget.post!.ownerId)
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
        .doc(widget.post!.ownerId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //unfriends
    friendsRef
        .doc(widget.post!.ownerId)
        .collection('userFriends')
        .doc(currentUserId())
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    friendsRef
        .doc(currentUserId())
        .collection('userFriends')
        .doc(widget.post!.ownerId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }


}
