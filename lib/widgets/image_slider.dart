import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/widgets/cached_image.dart';
import 'package:social_media_app/widgets/video_player_screen.dart';
import 'package:video_player/video_player.dart';


class ImageSlider extends StatefulWidget {
  final int maxImages;
  final String imageUrls;
  final Function(int) onImageClicked;
  final Function onExpandClicked;
  final String type;

  ImageSlider(
      {required this.imageUrls,
      required this.onImageClicked,
      required this.onExpandClicked,
      required this.type,
      this.maxImages = 4,
      Key? key})
      : super(key: key);

  @override
  createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int activeIndex = 0;
  @override
  Widget build(BuildContext context) {
    var urls = widget.imageUrls.split('-imagesplit-');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 400,
            viewportFraction: 1,
            initialPage: 0,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            onPageChanged: ((index, reason) => 
              setState(() => activeIndex = index))
          ),
          itemCount: urls.length, 
          itemBuilder: (context, index, realIndex) {
              final imageUrl = urls[index];
              return buildImage(imageUrl, index);
          }
        ),
        SizedBox(height: 10,),
        urls.length > 1?
        builderIndicator(): SizedBox()
      ],
    );
  }

  Widget buildImage(String imageUrl, int index)
  => Container(
    margin: EdgeInsets.symmetric(horizontal: 5),
    color: Colors.grey,
    child: widget.type.contains('offline')?
      widget.type.contains('images')?
        Image.file(
          File(imageUrl)
        )
        : VideoPlayerScreen(video_path: imageUrl, isOnline: false)
      : widget.type.contains('images')?
        cachedNetworkImage(
          imageUrl,
        )
        : VideoPlayerScreen(video_path: imageUrl, isOnline: true)
  );

  Widget builderIndicator() => AnimatedSmoothIndicator(
    activeIndex: activeIndex,
    count: widget.imageUrls.split('-imagesplit-').length,
    effect: ExpandingDotsEffect(
      activeDotColor: Constants.lightAccent,
      dotHeight: 10,
      dotWidth: 10
    ),
  );
}