import 'package:flutter/material.dart';

import 'ChatUtils/ImageWithPlaceholder.dart';
import 'Media/FullScreenMediaView.dart';
import 'Media/VideoPlayerWidget.dart';

class MediaGridPage extends StatelessWidget {
  final List<MediaItem> mediaItems;

  const MediaGridPage({
    Key? key,
    required this.mediaItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Items'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final item = mediaItems.reversed.toList()[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Media content
                  item.isVideo
                      ? VideoPlayerWidget(
                    videoUrl: item.url,
                    mediaUrls: mediaItems,
                  )
                      : ImageWithPlaceholder(
                    imageUrl: item.url,
                    mediaUrls: mediaItems,
                  ),

                  // Filename overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        item.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
