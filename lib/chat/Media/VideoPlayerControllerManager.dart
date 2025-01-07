import 'package:video_player/video_player.dart';

class VideoPlayerControllerManager {
  static final List<VideoPlayerController> _controllers = [];

  static void registerController(VideoPlayerController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  static void disposeController(VideoPlayerController controller) {
    _controllers.remove(controller);
    controller.dispose();
  }

  static void setActiveController(VideoPlayerController activeController) {
    for (var controller in _controllers) {
      if (controller != activeController && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }
}
