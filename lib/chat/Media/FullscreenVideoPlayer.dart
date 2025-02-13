import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class FullscreenVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final VideoPlayerController controller;

  const FullscreenVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.controller,
  }) : super(key: key);

  Future<void> _downloadVideo(BuildContext context) async {
    if (await Permission.storage.request().isGranted) {
      try {
        final response = await http.get(Uri.parse(videoUrl));
        final bytes = response.bodyBytes;

        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/downloaded_video.mp4';

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        print(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video downloaded to $filePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download video')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to download the video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Fullscreen Video Player'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadVideo(context),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragStart: (_) {
          Navigator.of(context).pop('exit_fullscreen');
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
                child: Icon(
                  controller.value.isPlaying
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
                onTap: () {
                  Navigator.of(context).pop('exit_fullscreen');
                },
                child: Icon(
                  Icons.fullscreen_exit,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
