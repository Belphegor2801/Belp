import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/components/custom_image.dart';
import 'package:social_media_app/components/description_text_field.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/validation.dart';
import 'package:social_media_app/view_models/post/posts_view_model.dart';
import 'package:social_media_app/widgets/image_slider.dart';
import 'package:social_media_app/widgets/indicators.dart';

class EditPost extends StatefulWidget {
  final PostModel post;
  EditPost({required this.post});
  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  @override
  Widget build(BuildContext context) {
    currentUserId() {
      return firebaseAuth.currentUser!.uid;
    }

    PostsViewModel viewModel = Provider.of<PostsViewModel>(context);
    return WillPopScope(
      onWillPop: () async {
        await viewModel.resetPost();
        return true;
      },
      child: LoadingOverlay(
        progressIndicator: circularProgress(context),
        isLoading: viewModel.loading,
        child: Scaffold(
          key: viewModel.scaffoldKey,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Ionicons.close_outline),
              onPressed: () {
                viewModel.resetPost();
                Navigator.pop(context);
              },
            ),
            title: Text('BELP'.toUpperCase()),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () async {
                  String valid = checkImagesValid(context, viewModel);
                  if (valid == ""){
                    bool success = await viewModel.editPost(context, widget.post.postId!);
                    if (success){
                      Navigator.pop(context);
                      viewModel.resetPost();
                    }
                  }
                  else{
                    Flushbar(
                      message: valid,
                      icon: Icon(
                        Icons.info_outline,
                        size: 28.0,
                        color: Colors.blue[300],
                        ),
                      duration: Duration(seconds: 3),
                      leftBarIndicatorColor: Colors.blue[300],
                    )..show(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Edit'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              )
            ],
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            children: [
              SizedBox(height: 15.0),
              StreamBuilder(
                stream: usersRef.doc(currentUserId()).snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    UserModel user = UserModel.fromJson(
                      snapshot.data!.data() as Map<String, dynamic>,
                    );
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25.0,
                        backgroundImage: NetworkImage(user.photoUrl!),
                      ),
                      title: Text(
                        user.username!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        user.email!,
                      ),
                    );
                  }
                  return Container();
                },
              ),
              InkWell(
                onTap: () => showImageChoices(context, viewModel),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  child: viewModel.mediaUrl == null?
                          widget.post!.mediaUrl! != null
                            ? ImageSlider(
                              imageUrls: widget.post!.mediaUrl!, 
                              onImageClicked: (i){}, 
                              onExpandClicked: (){},
                              type: widget.post!.mediaUrl!.contains('.mp4')? 'online-video': 'online-images',
                            )
                            :Center(
                                child: Text(
                                  'Upload a Photo',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              )
                      : ImageSlider(
                            imageUrls: viewModel.mediaUrl!, 
                            onImageClicked: (i){}, 
                            onExpandClicked: (){},
                            type: viewModel.mediaUrl!.contains('.mp4')? 'offline-video': 'offline-images',
                          )
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Post Caption'.toUpperCase(),
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Form(
                key: viewModel.formKey,
                autovalidateMode: null,
                child: DescriptionFormBuilder(
                  initialValue: widget.post.description,
                  enabled: !viewModel.loading,
                  prefix: Ionicons.mail_outline,
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).backgroundColor,
                    filled: true,
                    focusedBorder: UnderlineInputBorder(),
                    errorStyle: TextStyle(height: 2.0, fontSize: 0.0),
                  ),
                  textInputAction: TextInputAction.next,
                  validateFunction: Validations.validateDescription,
                  onSaved: (String val) {
                    viewModel.setDescription(val);
                  },
                ),
              ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  showImageChoices(BuildContext context, PostsViewModel viewModel) {
    showModalBottomSheet(
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
              SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Select Image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Ionicons.camera_outline),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickImage(camera: true);
                },
              ),
              ListTile(
                leading: Icon(Ionicons.image),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickImage();
                },
              ),
              ListTile(
                leading: Icon(Ionicons.film_outline),
                title: Text('Video'),
                onTap: () async{
                  Navigator.pop(context);
                  await viewModel.pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  checkImagesValid(BuildContext context, PostsViewModel viewModel){
    String valid = "";
    if (viewModel.mediaUrl != null){
      valid = Validations.validateImages(value: viewModel.mediaUrl, isEdit: true);
    }
    return valid;
  }
}
