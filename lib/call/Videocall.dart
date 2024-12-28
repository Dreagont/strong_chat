import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class VideoCallPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isCameraOn; // Add this parameter

  const VideoCallPage({
    Key? key,
    required this.cameras,
    this.isCameraOn = true, // Default value is true
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  CameraController? _controller;
  late bool _isFrontCamera;
  late bool _isMicMuted;
  late bool _isCameraOn;

  @override
  void initState() {
    super.initState();
    _isFrontCamera = true;
    _isMicMuted = false;
    _isCameraOn = widget.isCameraOn; // Initialize from the parameter

    if (_isCameraOn) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    if (!_isCameraOn) return;

    _controller = CameraController(
      widget.cameras[_isFrontCamera ? 1 : 0],
      ResolutionPreset.high,
    );

    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    }).catchError((e) {
      print("Camera initialization error: $e");
    });
  }

  void _switchCamera() {
    if (!_isCameraOn || _controller == null) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    _initializeCamera();
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
      if (_isCameraOn) {
        _initializeCamera();
      } else {
        _controller?.dispose();
        _controller = null;
      }
    });
  }

  void _hangUp() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraOn && (_controller == null || !_controller!.value.isInitialized)) {
      return const Center(child: CircularProgressIndicator());
    }

    final cameraPreview = _controller != null
        ? AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    )
        : Container(color: Colors.black);

    final transformedCameraPreview = _isFrontCamera
        ? Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(3.14159),
      child: cameraPreview,
    )
        : cameraPreview;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _isCameraOn
                ? transformedCameraPreview
                : Container(color: Colors.black),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _toggleMic,
                    backgroundColor: _isMicMuted ? Colors.red : Colors.green,
                    child: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                  ),
                  FloatingActionButton(
                    onPressed: _hangUp,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    onPressed: _toggleCamera,
                    backgroundColor: _isCameraOn ? Colors.green : Colors.red,
                    child: Icon(
                        _isCameraOn ? Icons.videocam : Icons.videocam_off),
                  ),
                ],
              ),
            ),
          ),
          if (_isCameraOn)
            Positioned(
              top: 60,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: _switchCamera,
                child: Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
