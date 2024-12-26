import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class MediaItem {
  final String url;
  final bool isVideo;
  final String fileName;
  MediaItem({required this.url, required this.isVideo, required this.fileName});
}

class FullScreenMediaView extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const FullScreenMediaView({
    Key? key,
    required this.mediaItems,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenMediaViewState createState() => _FullScreenMediaViewState();
}

class _FullScreenMediaViewState extends State<FullScreenMediaView> {
  late PageController _pageController;
  Map<int, VideoPlayerController> _videoControllers = {};
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoControllers();
  }

  void _initializeVideoControllers() async {
    // Initialize controllers for current and adjacent pages
    for (int i = -1; i <= 1; i++) {
      int index = _currentIndex + i;
      if (index >= 0 && index < widget.mediaItems.length) {
        await _initializeControllerAtIndex(index);
      }
    }
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (widget.mediaItems[index].isVideo && !_videoControllers.containsKey(index)) {
      final controller = VideoPlayerController.network(widget.mediaItems[index].url);
      _videoControllers[index] = controller;
      await controller.initialize();
      if (index == _currentIndex) {
        controller.play();
      }
      if (mounted) setState(() {});
    }
  }

  void _cleanupControllers(int exceptIndex) {
    _videoControllers.forEach((index, controller) {
      if (index != exceptIndex) {
        controller.pause();
        controller.dispose();
        _videoControllers.remove(index);
      }
    });
  }

  Future<void> _onPageChanged(int index) async {
    // Pause all videos when switching pages
    _videoControllers.values.forEach((controller) => controller.pause());

    setState(() {
      _currentIndex = index;
    });

    // Initialize controllers for new adjacent pages
    for (int i = -1; i <= 1; i++) {
      int adjacentIndex = index + i;
      if (adjacentIndex >= 0 && adjacentIndex < widget.mediaItems.length) {
        await _initializeControllerAtIndex(adjacentIndex);
      }
    }

    // Clean up controllers that are no longer needed
    _cleanupControllers(index);

    // Play the current video if it's a video
    if (widget.mediaItems[index].isVideo && _videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
    }
  }

  Future<void> _downloadMedia(BuildContext context, MediaItem mediaItem) async {
    if (await Permission.storage.request().isGranted) {
      try {
        final response = await http.get(Uri.parse(mediaItem.url));
        final bytes = response.bodyBytes;

        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/${mediaItem.isVideo ? '${mediaItem.fileName}.mp4' : '${mediaItem.fileName}.jpg'}';

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${mediaItem.isVideo ? 'Video' : 'Image'} downloaded to $filePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download ${mediaItem.isVideo ? 'video' : 'image'}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required')),
      );
    }
  }

  @override
  void dispose() {
    _videoControllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildMediaWidget(MediaItem mediaItem, int index) {
    if (mediaItem.isVideo) {
      final controller = _videoControllers[index];
      if (controller == null || !controller.value.isInitialized) {
        return Center(child: CircularProgressIndicator());
      }
      return Stack(
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
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              child: Icon(
                controller.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      return Image.network(
        mediaItem.url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadMedia(context, widget.mediaItems[_currentIndex]),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaItems.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _buildMediaWidget(widget.mediaItems[index], index);
        },
      ),
    );
  }
}