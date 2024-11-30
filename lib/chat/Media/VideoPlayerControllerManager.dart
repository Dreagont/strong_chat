import 'package:video_player/video_player.dart';

class VideoPlayerControllerManager {
  static VideoPlayerController? _activeController;

  static void setActiveController(VideoPlayerController controller) {
    if (_activeController != null && _activeController != controller) {
      _activeController!.pause();
    }
    _activeController = controller;
  }

  static void disposeController(VideoPlayerController controller) {
    if (_activeController == controller) {
      _activeController = null;
    }
  }
}
