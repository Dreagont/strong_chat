import 'package:flutter/material.dart';

class ImageWithPlaceholder extends StatefulWidget {
  final String imageUrl;

  const ImageWithPlaceholder({Key? key, required this.imageUrl}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? Column(
      children: [
        Text(
          '${_width?.toInt()}x${_height?.toInt()}',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Image.network(
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
      ],
    )
        : _isError
        ? Center(
      child: Text(
        "Failed to load image, retrying...",
        style: TextStyle(color: Colors.red),
      ),
    )
        : SizedBox(
      width: _width ?? 100.0, // Default width if _width is null
      height: _height ?? 100.0, // Default height if _height is null
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
