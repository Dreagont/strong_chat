import 'package:flutter/material.dart';
import 'package:strong_chat/chat/Media/FullScreenMediaView.dart';
import 'FullScreenImageView.dart';

class ImageWithPlaceholder extends StatefulWidget {
  final String imageUrl;
  final List<MediaItem> mediaUrls;

  const ImageWithPlaceholder({
    Key? key,
    required this.imageUrl,
    required this.mediaUrls
  }) : super(key: key);

  @override
  _ImageWithPlaceholderState createState() => _ImageWithPlaceholderState();
}

class _ImageWithPlaceholderState extends State<ImageWithPlaceholder> {
  double? _width;
  double? _height;
  bool _isLoaded = false;
  bool _isError = false;
  ImageStreamListener? _listener;

  void _resolveImageSize() {
    if (_listener != null) return;

    final ImageStream stream = NetworkImage(widget.imageUrl).resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
          (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _width = info.image.width.toDouble();
            _height = info.image.height.toDouble();
            _isLoaded = true;
            _isError = false;
          });
        }
      },
      onError: (exception, stackTrace) {
        setState(() {
          _isError = true;
        });
        Future.delayed(Duration(seconds: 2), () => _resolveImageSize());
      },
    );
    stream.addListener(_listener!);
  }

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void dispose() {
    if (_listener != null) {
      final ImageStream stream = NetworkImage(widget.imageUrl).resolve(ImageConfiguration.empty);
      stream.removeListener(_listener!);
    }
    super.dispose();
  }

  void _openFullScreen(BuildContext context, List<MediaItem> mediaItems, String imageUrl) {
    final int currentIndex = mediaItems.indexWhere((mediaItem) => mediaItem.url == imageUrl);

    if (currentIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenMediaView(
            mediaItems: mediaItems,
            initialIndex: currentIndex,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Media item not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, widget.mediaUrls, widget.imageUrl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_isLoaded) {
            double aspectRatio = _width! / _height!;
            double targetHeight = constraints.maxWidth / aspectRatio;

            // Ensure the height doesn't exceed constraints
            targetHeight = targetHeight.clamp(0.0, constraints.maxHeight);

            return SizedBox(
              width: constraints.maxWidth,
              height: targetHeight,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            );
          } else if (_isError) {
            return Center(
              child: Text(
                "Failed to load image, retrying...",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}