import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/widgets/cached_image.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String video_path;
  final bool isOnline;
  const VideoPlayerScreen({required this.video_path, required this.isOnline});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    loadVideoPlayer();
    super.initState();
  }

  loadVideoPlayer(){
    if (widget.isOnline){
      _controller = VideoPlayerController.network(widget.video_path)..setLooping(true);
    }
    else{
      _controller = VideoPlayerController.asset(widget.video_path)..setLooping(true);
    }
    

    _initializeVideoPlayerFuture =  _controller.initialize().then((value) => {
        _controller.addListener(() {                       //custom Listner
          setState(() {
            if (_controller.value.duration ==_controller.value.position) { //checking the duration and position every time
              setState(() {});
            }
          });
        })
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Use the VideoPlayer widget to display the video.
                child: VideoPlayer(_controller) 
              )
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 53, 165, 62),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.value.position == _controller.value.duration){
              _initializeVideoPlayerFuture =  _controller.initialize();
              _controller.seekTo(Duration(seconds: 0));
            }
            else{
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                // If the video is paused, play it.
                _controller.play();
              }
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.value.position == _controller.value.duration? Icons.restart_alt
            :_controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}