import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social_media_app/screens/chats/recent_chats.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/screens/search.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:social_media_app/widgets/userpost.dart';
import 'package:mobx_widget/mobx_widget.dart';

class Feeds extends StatefulWidget {
  @override
  _FeedsState createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> with AutomaticKeepAliveClientMixin{
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  static const routeName = '/feeds';

  int page = 5;
  int _countOfReload = 0;
  bool loadingMore = false;
  ScrollController scrollController = ScrollController();

  bool loading = true;


  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  getPosts() async {
    QuerySnapshot snap = await postRef.orderBy('timestamp', descending: true).get();
    List<DocumentSnapshot> doc = snap.docs;
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    getPosts();
    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          page = page + 5;
          loadingMore = true;
        });
      }
    });
    super.initState();
  }

  @override
  void autoReload() {
    getPosts();
    _countOfReload += 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      loading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
        actions: [
          IconButton(
            color: Constants.lightAccent,
            icon: Icon(
              Ionicons.search,
              size: 30.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Search(),
                ),
              );
            },
          ),
          IconButton(
            color: Constants.lightAccent,
            icon: Icon(
              Ionicons.chatbubble_ellipses,
              size: 30.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Chats(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () => getPosts(),
        child: Stack(
          // controller: scrollController,
          children:[
            Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // StoryWidget(),
              Container(
                height: MediaQuery.of(context).size.height - 150,
                child: StreamBuilder(
                  stream: postRef
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      var snap = snapshot.data;
                      List docs = snap!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          PostModel posts = PostModel.fromJson(docs[index].data());
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: UserPost(
                              feeds: this.widget, post: posts),
                          );
                        },
                      );
                    } else if (snapshot.connectionState == ConnectionState.waiting) {
                      return circularProgress(context);
                    } else
                      return Center(
                        child: Text(
                          'No Feeds',
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
          ] 
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

typedef RefreshCallback = void Function(bool refresh);
