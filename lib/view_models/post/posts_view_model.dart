import 'dart:io';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/screens/posts/edit_post.dart';
import 'package:social_media_app/screens/mainscreen.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/services/user_service.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/validation.dart';

class PostsViewModel extends ChangeNotifier {
  FocusNode descriptionFN = FocusNode();
  //Services
  UserService userService = UserService();
  PostService postService = PostService();

  //Keys
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  //Variables
  bool validate = false;
  bool loading = false;
  String? username;
  String? mediaUrl;
  final picker = ImagePicker();
  String? location;
  Position? position;
  Placemark? placemark;
  String? bio;
  String? description;
  String? email;
  String? commentData;
  String? ownerId;
  String? userId;
  String? type;
  File? userDp;
  String? imgLink;
  bool edit = false;
  String? id;

  //controllers
  TextEditingController locationTEC = TextEditingController();

  //Setters
  setEdit(bool val) {
    edit = val;
    notifyListeners();
  }

  setPost(PostModel post) {
    if (post != null) {
      description = post.description;
      imgLink = post.mediaUrl;
      location = post.location;
      edit = true;
      edit = false;
      notifyListeners();
    } else {
      edit = false;
      notifyListeners();
    }
  }

  setUsername(String val) {
    username = val;
    notifyListeners();
  }

  setDescription(String val) {
    description = val;
    notifyListeners();
  }

  //Functions
  pickImage({bool camera = false, BuildContext? context}) async {
    loading = true;
    imgLink = null;
    notifyListeners();
    try {
      if (camera){
        XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera
        );
        mediaUrl = pickedFile!.path;
      }
      else{
        List<XFile?> pickedFiles = await picker.pickMultiImage();
        List<String> imagePaths = [];
        if (pickedFiles.length > 0){
          for (int i = 0; i < pickedFiles.length; i++){
            imagePaths.add(pickedFiles[i]!.path.toString());
          }
          mediaUrl = imagePaths.join("-imagesplit-");
          notifyListeners();                  
        }
        else{
          mediaUrl = null;
        }
      }
      
      loading = false;
      imgLink = null;
      notifyListeners();
    } catch (e) {
      loading = false;
      imgLink = null;
      notifyListeners();
      mediaUrl = null;
      showInSnackBar('Cancelled', context);
    }
  }

  pickVideo({BuildContext? context}) async {
    loading = true;
    imgLink = null;
    notifyListeners();
    try {
        XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
        mediaUrl = pickedFile!.path;
      
      loading = false;
      imgLink = null;
      notifyListeners();
    } catch (e) {
      loading = false;
      imgLink = null;
      notifyListeners();
      mediaUrl = null;
      showInSnackBar('Cancelled', context);
    }
  }

  uploadPosts(BuildContext context) async {
    FormState form = formKey.currentState!;
    form.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar(
          'Please fix the errors in red before submitting.', context);
      return false;
    } 
    else{
      try {
        loading = true;
        notifyListeners();
        await postService.uploadPost(mediaUrl!, description!);
        showInSnackBar('Uploaded successfully!', context);
        loading = false;
        resetPost();
        notifyListeners();
        return true;
      } catch (e) {
        loading = false;
        resetPost();
        notifyListeners();
        return false;
      }
    }
  }

  editPost(BuildContext context, String postId) async {
    FormState form = formKey.currentState!;
    form.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar(
          'Please fix the errors in red before submitting.', context);
      return false;
    } 
    else{
      try {
        loading = true;
        notifyListeners();
        await postService.editPost(
          postId: postId,
          images: mediaUrl,
          description: description
        );
        showInSnackBar('Editted successfully!', context);
        loading = false;
        resetPost();
        notifyListeners();
        return true;
      } catch (e) {
        showInSnackBar(e.toString(), context);
        loading = false;
        resetPost();
        notifyListeners();
        return false;
      }
    } 
  }

  resetPost() {
    imgLink = null;
    mediaUrl = null;
    description = null;
    location = null;
    edit = false;
    notifyListeners();
  }

  deletePost(String postId) async{
    await postService.deletePost(postId);
    notifyListeners();
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
