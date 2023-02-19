import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:video_player/video_player.dart';

Widget cachedNetworkImage(String imgUrl) {
  return CachedNetworkImage(
    imageUrl: imgUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => circularProgress(context),
    errorWidget: (context, url, error) => Center(
      child: Text(
        'Không thể tải ảnh!',
        style: TextStyle(fontSize: 10.0),
      ),
    ),
  );
}