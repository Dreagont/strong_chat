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

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 6;
    } else if (screenWidth > 900) {
      return 4;
    } else if (screenWidth > 600) {
      return 3;
    } else {
      return 2;
    }
  }

  double _calculateChildAspectRatio(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return 1.1;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Items'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: GridView.builder(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width > 600 ? 16 : 8,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calculateCrossAxisCount(context),
                  crossAxisSpacing: MediaQuery.of(context).size.width > 600 ? 16 : 8,
                  mainAxisSpacing: MediaQuery.of(context).size.width > 600 ? 16 : 8,
                  childAspectRatio: _calculateChildAspectRatio(context),
                ),
                itemCount: mediaItems.length,
                itemBuilder: (context, index) {
                  final item = mediaItems.reversed.toList()[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (MediaQuery.of(context).size.width > 600)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          item.isVideo
                              ? VideoPlayerWidget(
                            videoUrl: item.url,
                            mediaUrls: mediaItems,
                          )
                              : ImageWithPlaceholder(
                            imageUrl: item.url,
                            mediaUrls: mediaItems,
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.width > 600 ? 8 : 4,
                                horizontal: MediaQuery.of(context).size.width > 600 ? 12 : 8,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                                  fontWeight: MediaQuery.of(context).size.width > 600
                                      ? FontWeight.w500
                                      : FontWeight.normal,
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
            ),
          );
        },
      ),
    );
  }
}