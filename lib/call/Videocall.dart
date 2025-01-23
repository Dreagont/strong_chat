import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:strong_chat/services/notification_service.dart';

import '../services/Signalling.dart';

class VideoCallPage extends StatefulWidget {
  final int number;
  final String notificationToken;
  final String CaleeName;
  final String CallerName;
  final String roomId;

  const VideoCallPage({
    super.key,
    required this.number,
    required this.notificationToken,
    required this.CaleeName,
    required this.CallerName,
    required this.roomId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool isRemoteConnected = false;
  bool isCameraOn = true;
  bool isMicOn = true;
  String? roomId;

  @override
  void initState() {
    super.initState();
    _initializeMediaAndHandleRoom();
  }

  Future<void> _initializeMediaAndHandleRoom() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      await signaling.openUserMedia(_localRenderer, _remoteRenderer);

      signaling.onAddRemoteStream = (stream) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          isRemoteConnected = true;
        });
      };

      toggleCamera();
      toggleCamera();
      print("hello ${widget.CallerName}");
      print("hello ${widget.notificationToken}");

      signaling.onRemoveRemoteStream = () {
        setState(() {
          _remoteRenderer.srcObject = null;
          isRemoteConnected = false;
        });
      };

      signaling.onHangUp = () {
        _endCall();
      };

      if (widget.number == 1) {
        roomId = await signaling.createRoom(_remoteRenderer);
        NotificationService().pushCallNotification(
          title: "Calling",
          body: "From ${widget.CallerName}",
          token: widget.notificationToken,
          roomId: roomId!,
        );
      } else if (widget.number == 2) {
        roomId = widget.roomId;
        signaling.joinRoom(widget.roomId, _remoteRenderer);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize media: $e')),
      );
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void toggleCamera() {
    if (isCameraOn) {
      signaling.stopCamera();
    } else {
      signaling.startCamera(_localRenderer);
    }
    setState(() {
      isCameraOn = !isCameraOn;
    });
  }

  void toggleMic() {
    if (isMicOn) {
      signaling.stopMic();
    } else {
      signaling.startMic();
    }
    setState(() {
      isMicOn = !isMicOn;
    });
  }

  void _endCall() {
    signaling.hangUp(_localRenderer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16, // Standard phone aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: RTCVideoView(
                    isRemoteConnected ? _remoteRenderer : _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: !isRemoteConnected,
                  ),
                ),
                if (isRemoteConnected)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: toggleCamera,
                        icon: Icon(
                          isCameraOn ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white,
                        ),
                        iconSize: 32,
                      ),
                      IconButton(
                        onPressed: toggleMic,
                        icon: Icon(
                          isMicOn ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                        ),
                        iconSize: 32,
                      ),
                      IconButton(
                        onPressed: _endCall,
                        icon: Icon(Icons.call_end, color: Colors.red),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}