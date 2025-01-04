import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';


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
    _videoControllers.values.forEach((controller) => controller.pause());

    setState(() {
      _currentIndex = index;
    });

    for (int i = -1; i <= 1; i++) {
      int adjacentIndex = index + i;
      if (adjacentIndex >= 0 && adjacentIndex < widget.mediaItems.length) {
        await _initializeControllerAtIndex(adjacentIndex);
      }
    }

    _cleanupControllers(index);

    if (widget.mediaItems[index].isVideo && _videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
    }
  }

  Future<void> _downloadMedia(BuildContext context, MediaItem mediaItem) async {
    if (kIsWeb) {
      try {
        final anchor = html.AnchorElement(href: mediaItem.url)
          ..target = 'blank'
          ..download = mediaItem.fileName;
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        print("File download initiated in web environment");
      } catch (e) {
        print("Error handling file download for web: $e");
      }
    } else {
      if (await Permission.storage.request().isGranted) {
        try {
          final response = await http.get(Uri.parse(mediaItem.url));
          final bytes = response.bodyBytes;

          final directory = await getExternalStorageDirectory();
          final downloadDir = Directory('${directory!.path}/StrongChat');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = mediaItem.isVideo ? 'mp4' : 'jpg';
          final filename = '${mediaItem.fileName}_$timestamp.$extension';
          final filePath = '${downloadDir.path}/$filename';

          final file = File(filePath);
          await file.writeAsBytes(bytes);

          final result = await GallerySaver.saveImage(filePath);
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${mediaItem.isVideo ? 'Video' : 'Image'} saved to gallery')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save ${mediaItem.isVideo ? 'video' : 'image'}')),
            );
          }
        } catch (e) {
          print("Download error: $e");
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
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
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
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Image.network(
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
          ),
        ),
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
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaItems.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildMediaWidget(widget.mediaItems[index], index);
            },
          ),
          if (kIsWeb)
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  if (_currentIndex > 0) {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          if (kIsWeb)
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: () {
                  if (_currentIndex < widget.mediaItems.length - 1) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

}