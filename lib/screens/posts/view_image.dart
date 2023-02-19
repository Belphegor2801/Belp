import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/posts/edit_post.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/image_slider.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class ViewImage extends StatefulWidget {
  final PostModel? post;

  ViewImage({this.post});

  @override
  _ViewImageState createState() => _ViewImageState();
}


final DateTime timestamp = DateTime.now();

currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

UserModel? user;

class _ViewImageState extends State<ViewImage> {
  

  bool isFriends = false;
  bool isBlocked_sender = false;
  bool isMe = false;

  @override
  void initState() {
    super.initState();
    checkIfFriendOrBlocked();
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
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.keyboard_backspace),
        ),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            new Spacer(),
            IconButton(
              icon: Icon(
                Ionicons.ellipsis_vertical_outline,
                size: 30),
              onPressed: () => buildChooseOption(context), 
            ),
          ],
        )
      ),
      body: Center(
        child: buildImage(context),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0.0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            height: 50.0,
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post!.username!,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3.0),
                    Row(
                      children: [
                        Icon(Ionicons.alarm_outline, size: 13.0),
                        SizedBox(width: 3.0),
                        Text(
                          timeago.format(widget.post!.timestamp!.toDate()),
                        ),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                buildLikeButton(),
              ],
            ),
          ),
        ),
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
                  Navigator.pop(context);
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


  buildImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: ImageSlider(
          imageUrls: widget.post!.mediaUrl!,
          onExpandClicked: (){},
          onImageClicked: (i){},
          maxImages: 4,
          type: widget.post!.mediaUrl!.contains('.mp4')? 'online-video': 'online-images',
        )
      ),
    );
  }

  addLikesToNotification() async {
    bool isNotMe = currentUserId() != widget.post!.ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(widget.post!.ownerId)
          .collection('notifications')
          .doc(widget.post!.postId)
          .set({
        "type": "like",
        "username": user!.username!,
        "userId": currentUserId(),
        "userDp": user!.photoUrl,
        "postId": widget.post!.postId,
        "mediaUrl": widget.post!.mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromNotification() async {
    bool isNotMe = currentUserId() != widget.post!.ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(widget.post!.ownerId)
          .collection('notifications')
          .doc(widget.post!.postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
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
          //       removeLikeFromNotification();
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
          ///added animated like button
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
              removeLikeFromNotification();
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
              dotLastColor: Color(0xffff8c00),
            ),
            likeBuilder: (bool isLiked) {
              return Icon(
                docs.isEmpty ? Ionicons.heart_outline : Ionicons.heart,
                color: docs.isEmpty ? Colors.grey : Colors.red,
                size: 25,
              );
            },
          );
        }
        return Container();
      },
    );
  }
}
