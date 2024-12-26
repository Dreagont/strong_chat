import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final List<String> imageUrls;
  final bool isVideo;
  final int initialIndex;

  const FullScreenImageView({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
    required this.isVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // Add download functionality here
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.contain,
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
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
