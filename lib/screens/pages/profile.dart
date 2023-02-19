import 'dart:ffi';

import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/screens/auth/register/register.dart';
import 'package:social_media_app/components/stream_grid_wrapper.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/landing/landing_page.dart';
import 'package:social_media_app/screens/chats/conversation.dart';
import 'package:social_media_app/screens/profile/edit_profile.dart';
import 'package:social_media_app/screens/profile/list_friends.dart';
import 'package:social_media_app/screens/posts/list_posts.dart';
import 'package:social_media_app/screens/search.dart';
import 'package:social_media_app/screens/profile/settings.dart';
import 'package:social_media_app/services/user_service.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/view_models/user/user_view_model.dart';
import 'package:social_media_app/widgets/post_tiles.dart';

class Profile extends StatefulWidget {
  final profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? user;
  bool isLoading = false;
  int postCount = 0;
  int friendsCount = 0;
  int followingCount = 0;
  bool isFriends = false;
  bool isRequesting = false;
  bool isRequested = false;
  bool isBlocked = false;
  UserModel? users;
  final DateTime timestamp = DateTime.now();
  ScrollController controller = ScrollController();

  UserService userService = UserService();

  currentUserId() {
    return firebaseAuth.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    checkIfFriendsOrRequest();
  }

  checkIfFriendsOrRequest() async {
    DocumentSnapshot friendDoc = await friendsRef
        .doc(widget.profileId)
        .collection('userFriends')
        .doc(currentUserId())
        .get();
    DocumentSnapshot requestSenderDoc = await friendRequests_SenderRef
        .doc(currentUserId()) 
        .collection('requests')
        .doc(widget.profileId)
        .get();
    DocumentSnapshot requestReceiverDoc = await friendRequests_ReceiverRef
        .doc(currentUserId())
        .collection('requests')
        .doc(widget.profileId) 
        .get();
    DocumentSnapshot blockDoc = await blockRef
        .doc(currentUserId()) 
        .collection('userBlock')
        .doc(widget.profileId)
        .get();
    setState(() {
      isFriends = friendDoc.exists;
      isRequesting = requestSenderDoc.exists;
      isRequested = requestReceiverDoc.exists;
      isBlocked = blockDoc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 40,
          child: 
            widget.profileId == firebaseAuth.currentUser!.uid?
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  alignment: FractionalOffset(0.0, 0.0),
                  image: ExactAssetImage("assets/images/belp.png"),
                )),
              )
            : GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Icon(Icons.keyboard_backspace),
            ),
        ),
        titleSpacing: 10.0,
        actions: [
          widget.profileId == firebaseAuth.currentUser!.uid
              ? IconButton(
                onPressed: () async {
                  userService.setUserStatus(false);
                  await firebaseAuth.signOut();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => Landing(),
                    ),
                  );
                },
                icon: Icon(
                  Ionicons.log_out,
                  color: Constants.lightAccent,
                )
              ): SizedBox(width: 10),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            toolbarHeight: 5.0,
            collapsedHeight: 6.0,
            expandedHeight: height,
            flexibleSpace: FlexibleSpaceBar(
              background: StreamBuilder(
                stream: usersRef.doc(widget.profileId).snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    UserModel user = UserModel.fromJson(
                      snapshot.data!.data() as Map<String, dynamic>,
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Scaffold(
                          backgroundColor: Colors.transparent,
                          body: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 43),
                              child: Column(
                                children: [
                                  Container(
                                    height: 320,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        double innerHeight = constraints.maxHeight;
                                        double innerWidth = constraints.maxWidth;
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: innerHeight * 0.74,
                                                width: innerWidth,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30),
                                                  color: Theme.of(context).colorScheme.onBackground
                                                ),
                                                child: Column(
                                                  children: [
                                                    SizedBox(height: 60,),
                                                    Text(
                                                      user.email!,
                                                      style: TextStyle(
                                                        color: Color.fromRGBO(39, 105, 171, 1),
                                                        fontFamily: 'Nunito',
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    SizedBox(height: 5,),
                                                    user.bio != "1"?
                                                      Text(
                                                        user.bio!,
                                                        style: TextStyle(
                                                          color: Color.fromRGBO(39, 105, 171, 1),
                                                          fontFamily: 'Nunito',
                                                          fontSize: 15,
                                                        ),
                                                      ) : SizedBox(height: 0,),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        SizedBox(width: 15),
                                                        StreamBuilder(
                                                          stream: postRef
                                                              .where('ownerId',
                                                                  isEqualTo: widget.profileId)
                                                              .snapshots(),
                                                          builder: (context,
                                                              AsyncSnapshot<QuerySnapshot> snapshot) {
                                                            if (snapshot.hasData) {
                                                              QuerySnapshot<Object?>? snap =
                                                                  snapshot.data;
                                                              List<DocumentSnapshot> docs = snap!.docs;
                                                              return buildCount(
                                                                label: "POSTS",
                                                                count: docs.length ?? 0,
                                                                function: (){});
                                                            } else {
                                                              return buildCount(
                                                                label: "POSTS",
                                                                count: 0,
                                                                function: (){});
                                                            }
                                                          },
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 25,
                                                            vertical: 8,
                                                          ),
                                                          child: Container(
                                                            height: 50,
                                                            width: 3,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(100),
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                        StreamBuilder(
                                                          stream: friendsRef
                                                              .doc(widget.profileId)
                                                              .collection('userFriends')
                                                              .snapshots(),
                                                          builder: (context,
                                                              AsyncSnapshot<QuerySnapshot> snapshot) {
                                                            if (snapshot.hasData) {
                                                              QuerySnapshot<Object?>? snap =
                                                                  snapshot.data;
                                                              List<DocumentSnapshot> docs = snap!.docs;
                                                              return buildCount(
                                                                  label: "FRIENDS",
                                                                  count: docs.length ?? 0,
                                                                  function: (){
                                                                    showFriendList(context);
                                                                  });
                                                            } else {
                                                              return buildCount(
                                                                  label: "FRIENDS",
                                                                  count: 0,
                                                                  function: (){
                                                                    showFriendList(context);
                                                                  });
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 10,),
                                                    // buildProfileButton(user),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            widget.profileId == firebaseAuth.currentUser!.uid?
                                            // settings
                                            Positioned(
                                              top: 110,
                                              right: 20,
                                              child: IconButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    CupertinoPageRoute(
                                                      builder: (_) => Setting(),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Ionicons.settings,
                                                  color: Constants.lightAccent,
                                                  size: 30,
                                                )
                                              ),
                                            ): Text(""),
                                            // avt
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: user.photoUrl!.isEmpty
                                                  ? CircleAvatar(
                                                      radius: 75.0,
                                                      backgroundColor: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
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
                                                      radius: 75.0,
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                        '${user.photoUrl}',
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            // username
                                            Positioned(
                                              top: 0,
                                              left: 160,
                                              right: 0,
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  '${user.username!.toUpperCase()}',
                                                  style: TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w900,
                                                    color: Constants.lightAccent,
                                                  ),
                                                )
                                              ),
                                            ),
                                            Positioned(
                                              top: 250,
                                              left: 0,
                                              right: 0,
                                              child: buildProfileButton(user)
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    width: width,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Colors.white,
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'All Posts',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w900
                                                  ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: () async {
                                                  DocumentSnapshot doc =
                                                      await usersRef.doc(widget.profileId).get();
                                                  var currentUser = UserModel.fromJson(
                                                    doc.data() as Map<String, dynamic>,
                                                  );
                                                  Navigator.push(
                                                    context,
                                                    CupertinoPageRoute(
                                                      builder: (_) => ListPosts(
                                                        userId: widget.profileId,
                                                        username: currentUser.username,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Ionicons.grid_outline,
                                                  color: Colors.black,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        buildPostView(),
                                        SizedBox(height: 20,)
                                      ],
                                    )
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    );}
                  return Container();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  showFriendList(BuildContext context){
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ListFriends()
      ),
    );
  }

  buildCount({String? label, int? count, Function()? function}) {
    return Column(
      children: <Widget>[
        Text(
          label.toString(),
          style: TextStyle(
            color: Colors.grey[700],
            fontFamily: 'Nunito',
            fontSize: 22,
          ),
        ),
        SizedBox(height: 3.0),
        GestureDetector(
          onTap: function!,
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Color.fromRGBO(39, 105, 171, 1),
              fontFamily: 'Nunito',
              fontSize: 25,
            ),
          )
        ),
        
      ],
    );
  }

  buildProfileButton(user) {
    UserViewModel viewmodel = Provider.of<UserViewModel>(context);
    //if isMe then display "edit profile"
    bool isMe = widget.profileId == firebaseAuth.currentUser!.uid;
    if (isMe) {
      return buildButton(
        text: "Edit Profile",
        width: 200,
        function: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => EditProfile(
                user: user,
              ),
            ),
          );
        });
      //if you are already following the user then "unfollow"
    } else if (isFriends) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          new Spacer(),
          SizedBox(width: 40),
          buildButton(
            text: "Unfriend",
            width: 200,
            function: () => confirmUnfriend(context)
          ),
          new Spacer(),
          IconButton(
              icon: Icon(Ionicons.ellipsis_vertical_outline),
              onPressed: () => buildChooseOption(context)
            )
      ],) ;
      //if you are not following the user then "follow"
    } else if (!isFriends) {
      if (isRequesting){
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Spacer(),
            SizedBox(width: 40),
            buildButton(
              text: "Remove Request",
              width: 200,
              function: handleRemoveFriendRequest,
            ),
            new Spacer(),
            IconButton(
              icon: Icon(Ionicons.ellipsis_vertical_outline),
              onPressed: () => buildChooseOption(context)
            )
        ],) ;
      }
      else if (isRequested){
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Spacer(),
            SizedBox(width: 40),
            buildButton(
              text: "Accept Request",
              width: 120,
              function: handleAcceptFriendRequest,
            ),
            SizedBox(width: 10),
            buildButton(
              text: "Delete Request",
              width: 120,
              function: handleDeleteFriendRequest,
            ),
            new Spacer(),
            IconButton(
              icon: Icon(Ionicons.ellipsis_vertical_outline),
              onPressed: () => buildChooseOption(context)
            )
        ],) ;
      }
      else{
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Spacer(),
            SizedBox(width: 40),
            buildButton(
              text: "Add Friend",
              width: 200,
              function: handleSendFriendRequest,
            ),
            new Spacer(),
            IconButton(
              icon: Icon(Ionicons.ellipsis_vertical_outline),
              onPressed: () => buildChooseOption(context)
            )
          ],
        ) ;
      }
    }
  }

  buildChooseOption(BuildContext context) {
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
              ListTile(
                leading: Icon(
                  Ionicons.chatbubble_ellipses_outline,
                  size: 25.0,
                ),
                title: Text('Message'),
                onTap: () => handleMessage(),
              ),
              
              isBlocked?
              ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Unblock User'),
                onTap: () async {
                  Navigator.pop(context, true);
                  handleUnBlock();
                },
              )
              : ListTile(
                leading: Icon(
                  CupertinoIcons.camera_on_rectangle,
                  size: 25.0,
                ),
                title: Text('Block User'),
                onTap: () async {
                  Navigator.pop(context, true);
                  await confirmBlock(context);
                },
              )
            ],
          ),
        );
      },
    );
  }

  buildButton({String? text, double? width, Function()? function}) {
    return Center(
      child: GestureDetector(
        onTap: function!,
        child: Container(
          height: 40.0,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Theme.of(context).colorScheme.secondary,
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

  confirmUnfriend(BuildContext context) {
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
                    'Confirm Unfriend',
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
                title: Text('Unfriend this person!'),
                onTap: () async{
                  Navigator.pop(context);
                  Flushbar(
                    message: "Unfriended successfully!",
                    icon: Icon(
                      Icons.info_outline,
                      size: 28.0,
                      color: Colors.blue[300],
                      ),
                    duration: Duration(seconds: 2),
                    leftBarIndicatorColor: Colors.blue[300],
                  )..show(context);
                  handleUnfriend();
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
      isFriends = false;
      isRequesting = false;
      isRequested = false;
      isBlocked = false;
    });
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.profileId)
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
      isFriends = false;
      isRequesting = false;
      isRequested = false;
      isBlocked = true;
    });
    //updates the following collection of the currentUser
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.profileId)
        .set({
          "blockId": widget.profileId,
          "timestamp": timestamp
        });
    //update the notification feeds
    friendRequests_SenderRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //unfriends
    friendsRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleUnfriend() async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    setState(() {
      isFriends = false;
      isRequesting = false;
      isRequested = false;
    });
    friendsRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // notificationRef
    //     .doc(widget.profileId)
    //     .collection('notifications')
    //     .doc(currentUserId())
    //     .get()
    //     .then((doc) {
    //   if (doc.exists) {
    //     doc.reference.delete();
    //   }
    // });
  }
  handleSendFriendRequest() async{
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    setState(() {
      isFriends = false;
      isRequesting = true;
      isRequested = false;
    });
    // Unblock
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //updates the friends collection of the followed user
    friendRequests_SenderRef
        .doc(currentUserId())
        .collection('requests')
        .doc(widget.profileId)
        .set({
          "senderId": currentUserId(),
          "receiverId": widget.profileId
        });
    //updates the following collection of the currentUser
    friendRequests_ReceiverRef
        .doc(widget.profileId)
        .collection('requests')
        .doc(currentUserId())
        .set({
          "senderId": currentUserId(),
          "receiverId": widget.profileId
        });
    //update the notification feeds
    notificationRef
        .doc(widget.profileId)
        .collection('notifications')
        .doc(currentUserId())
        .set({
      "type": "sendFriendRequest",
      "ownerId": widget.profileId,
      "username": users?.username,
      "userId": users?.id,
      "userDp": users?.photoUrl,
      "timestamp": timestamp,
    });
  }
  handleRemoveFriendRequest() async{
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    setState(() {
      isFriends = false;
      isRequesting = false;
      isRequested = false;
    });
    //updates the friends collection of the followed user
    friendRequests_ReceiverRef
        .doc(widget.profileId)
        .collection('requests')
        .doc(currentUserId())
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //updates the following collection of the currentUser
    friendRequests_SenderRef
        .doc(currentUserId())
        .collection('requests')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }
  handleAcceptFriendRequest() async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    setState(() {
      isFriends = true;
      isRequesting = false;
      isRequested = false;
    });
    // Unblock
    blockRef
        .doc(currentUserId())
        .collection('userBlock')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //updates the friends collection of the followed user
    friendsRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .set({
          "friendId": widget.profileId,
          "timestamp": timestamp
        });
    //update the notification feeds
    friendRequests_SenderRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    notificationRef
        .doc(widget.profileId)
        .collection('notifications')
        .doc(currentUserId())
        .set({
      "type": "acceptFriendRequest",
      "ownerId": widget.profileId,
      "username": users?.username,
      "userId": users?.id,
      "userDp": users?.photoUrl,
      "timestamp": timestamp,
    });

    notificationRef
        .doc(currentUserId())
        .collection('notifications')
        .doc(widget.profileId)
        .get()
        .then((doc) {
                if (doc.exists) {
                  doc.reference.delete();
                }
              });
  }

  handleDeleteFriendRequest() async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    users = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    setState(() {
      isFriends = false;
      isRequesting = false;
      isRequested = false;
    });
    friendRequests_SenderRef
        .doc(widget.profileId)
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
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
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

  handleMessage() {
    Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => StreamBuilder(
            stream: chatRef
                .where(
                      "chatId",
                      isEqualTo: getUser(
                        firebaseAuth.currentUser!.uid,
                        widget.profileId,
                      ),
                    )
                .snapshots(),
            builder: (context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                var snap = snapshot.data;
                List docs = snap!.docs;
                return docs.isEmpty
                    ? Conversation(
                        userId: widget.profileId,
                        chatId: docs[0].get('chatId').toString(),
                        newChat: true,
                      )
                    : Conversation(
                        userId: widget.profileId,
                        chatId:
                            docs[0].get('chatId').toString(),
                        newChat: false,
                      );
              }
              return Conversation(
                userId: widget.profileId,
                chatId: getUser(
                        firebaseAuth.currentUser!.uid,
                        widget.profileId,
                      ),
                newChat: true
              );
            },
          ),
        ),
      );
  }

  buildPostView() {
    return buildGridPost();
  }

  buildGridPost() {
    return StreamGridWrapper(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      stream: postRef
          .where('ownerId', isEqualTo: widget.profileId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (_, DocumentSnapshot snapshot) {
        PostModel posts =
            PostModel.fromJson(snapshot.data() as Map<String, dynamic>);
        return PostTile(
          post: posts,
        );
      },
    );
  }

  buildLikeButton() {
    return StreamBuilder(
      stream: favUsersRef
          .where('postId', isEqualTo: widget.profileId)
          .where('userId', isEqualTo: currentUserId())
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
          return GestureDetector(
            onTap: () {
              if (docs.isEmpty) {
                favUsersRef.add({
                  'userId': currentUserId(),
                  'postId': widget.profileId,
                  'dateCreated': Timestamp.now(),
                });
              } else {
                favUsersRef.doc(docs[0].id).delete();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3.0,
                    blurRadius: 5.0,
                  )
                ],
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: Icon(
                  docs.isEmpty
                      ? CupertinoIcons.heart
                      : CupertinoIcons.heart_fill,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
