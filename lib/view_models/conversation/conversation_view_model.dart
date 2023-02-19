import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/services/chat_service.dart';

class ConversationViewModel extends ChangeNotifier {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ChatService chatService = ChatService();
  bool uploadingImage = false;
  final picker = ImagePicker();
  File? image;

  sendMessage(String chatId, Message message) {
    chatService.sendMessage(
      message,
      chatId,
    );
  }

  Future setupFirstChat(String recipient) async {
    await chatService.setupFirstChat(
      recipient,
    );
  }

  setReadCount(String chatId, var user, int count) {
    chatService.setUserRead(chatId, user, count);
  }

  setUserTyping(String chatId, var user, bool typing) {
    chatService.setUserTyping(chatId, user, typing);
  }

  pickImage({int? source, BuildContext? context, String? chatId}) async {
    PickedFile? pickedFile = source == 0
        ? await picker.getImage(
            source: ImageSource.camera,
          )
        : await picker.getImage(
            source: ImageSource.gallery,
          );

    if (pickedFile != null) {
      Navigator.of(context!).pop();

      uploadingImage = true;
      image = File(pickedFile.path);
      notifyListeners();
      showInSnackBar("Uploading image...", context);
      String imageUrl = await chatService.uploadImage(image!, chatId!);
      return imageUrl;
    }
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
      ),
    );
  }
}
