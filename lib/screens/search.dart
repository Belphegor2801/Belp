import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/screens/chats/conversation.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/pages/profile.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  User? user;
  TextEditingController searchController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> users = [];
  List<DocumentSnapshot> filteredUsers = [];
  bool loading = true;

  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  getUsers() async {
    QuerySnapshot snap = await usersRef.get();
    List<DocumentSnapshot> doc = snap.docs;
    users = doc;
    setState(() {
      loading = false;
    });
  }

  search(String query) async {
    if (query == "") {
      filteredUsers = [];
    } else {
      List userSearch = users.where((userSnap) {
        Map user = userSnap.data() as Map<String, dynamic>;
        String userName = user['username'];
        return userName.toLowerCase().contains(query.toLowerCase());
      }).toList();

      List<DocumentSnapshot<Object?>> filter =  userSearch as List<DocumentSnapshot<Object?>>;

      for (int i = 0; i < filter.length; i++){
        UserModel user = UserModel.fromJson(filter[i].data() as Map<String, dynamic>);
        DocumentSnapshot isBlocked_receiverDoc = await blockRef
          .doc(user.id) 
          .collection('userBlock')
          .doc(currentUserId())
          .get();
        if (isBlocked_receiverDoc.exists){
          filter.removeAt(i);
        }
        if (user.id == currentUserId()){
          filter.removeAt(i);
        }
      }

      setState(() {
        filteredUsers = filter;
      });
    }
  }

  removeFromList(index) {
    filteredUsers.removeAt(index);
  }

  @override
  void initState() {
    getUsers();
    super.initState();
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
        title: Text(
          "Search",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () => getUsers(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: buildSearch(),
            ),
            buildUsers(),
          ],
        ),
      ),
    );
  }

  buildSearch() {
    return Row(
      children: [
        Container(
          height: 30.0,
          width: MediaQuery.of(context).size.width - 50,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: TextFormField(
              controller: searchController,
              textAlignVertical: TextAlignVertical.center,
              maxLength: 10,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [
                LengthLimitingTextInputFormatter(20),
              ],
              textCapitalization: TextCapitalization.sentences,
              onChanged: (query) {
                search(query);
              },
              decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    searchController.clear();
                  },
                  child: Icon(
                    Ionicons.close_outline,
                    size: 12.0,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                // contentPadding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                border: InputBorder.none,
                counterText: '',
                hintText: 'Search...',
                hintStyle: TextStyle(
                  fontSize: 13.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildUsers() {
    if (!loading) {
      if (filteredUsers.isEmpty) {
        return Center(
          child: Text("No User Found",
              style: TextStyle(fontWeight: FontWeight.bold),),
        );
      } else {
        return Expanded(
          child: Container(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (BuildContext context, int index) {
                DocumentSnapshot doc = filteredUsers[index];
                UserModel user =
                    UserModel.fromJson(doc.data() as Map<String, dynamic>);
                return ListTile(
                  onTap: () => showProfile(context, profileId: user.id!),
                  leading: user.photoUrl!.isEmpty
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
                  title: Text(
                    user.username!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user.email!,
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => StreamBuilder(
                            stream: chatRef
                                .where(
                                  "chatId",
                                  isEqualTo: getUser(
                                    firebaseAuth.currentUser!.uid,
                                    doc.id,
                                  ),
                                )
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasData) {
                                var snap = snapshot.data;
                                List docs = snap!.docs;
                                print(snapshot.data!.docs.toString());
                                return docs.isEmpty
                                    ? Conversation(
                                        userId: doc.id,
                                        chatId:
                                            docs[0].get('chatId').toString(),
                                        newChat: true,
                                      )
                                    : Conversation(
                                        userId: doc.id,
                                        chatId:
                                            docs[0].get('chatId').toString(),
                                        newChat: false,
                                      );
                              }
                              return Conversation(
                                userId: doc.id,
                                chatId: getUser(
                                    firebaseAuth.currentUser!.uid,
                                    doc.id,
                                  ),
                                newChat: true,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 30.0,
                      width: 62.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      return Center(
        child: circularProgress(context),
      );
    }
  }

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => Profile(profileId: profileId),
      ),
    );
  }

  //get concatenated list of users
  //this will help us query the chat id reference in other
  // to get the correct user id

  String getUser(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    var chatId = "${list[0]}-${list[1]}";
    return chatId;
  }

  @override
  bool get wantKeepAlive => true;
}
