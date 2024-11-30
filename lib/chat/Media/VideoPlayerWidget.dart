import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'FullscreenVideoPlayer.dart';
import 'VideoPlayerControllerManager.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(false);
    _controller.addListener(_handleVideoEnd);
  }

  void _handleVideoEnd() {
    if (_controller.value.position == _controller.value.duration) {
      _controller.seekTo(Duration.zero);
      _controller.pause();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoEnd);
    VideoPlayerControllerManager.disposeController(_controller);
    _controller.dispose();
    super.dispose();
  }

  void _toggleFullscreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: widget.videoUrl,
          controller: _controller,
        ),
      ),
    );

    // When exiting fullscreen, reset the fullscreen state.
    if (result == 'exit_fullscreen') {
      setState(() {
        isFullscreen = false;
      });
    } else {
      setState(() {
        isFullscreen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  VideoPlayerControllerManager.setActiveController(_controller);
                  _controller.play();
                }
              });
            },
            child: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleFullscreen,
            child: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ],
    )
        : Center(child: CircularProgressIndicator());
  }
}
