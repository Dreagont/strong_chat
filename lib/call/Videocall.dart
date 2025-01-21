import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:strong_chat/services/notification_service.dart';

import '../services/Signalling.dart';

class VideoCallPage extends StatefulWidget {

  final number;
  final String notificationToken;
  final String CaleeName;
  final String CallerName;
  final String roomId;
  const VideoCallPage({super.key, required this.number, required this.notificationToken, required this.CaleeName, required this.CallerName, required this.roomId});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool isRemoteConnected = false;
  bool isCameraOn = true;
  bool isMicOn = true;
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();

    _initializeMediaAndCreateRoom();
  }

  Future<void> _initializeMediaAndCreateRoom() async {
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

      print("hello ${widget.notificationToken}");
      print("hello ${widget.CaleeName}");

      signaling.onRemoveRemoteStream = () {
        setState(() {
          _remoteRenderer.srcObject = null;
          isRemoteConnected = false;
        });
      };

      if(widget.number == 1){
        roomId = await signaling.createRoom(_remoteRenderer);
        setState(() {
          textEditingController.text = roomId!;
        });
        NotificationService().pushCallNotification(
            title: "Calling",
            body: "From ${widget.CallerName}",
            token: widget.notificationToken,
            roomId: roomId!
        );
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

  // Toggle microphone on/off
  void toggleMic() {
    if (isMicOn) {
      signaling.stopMic(); // Mute the microphone
    } else {
      signaling.startMic(); // Unmute the microphone
    }
    setState(() {
      isMicOn = !isMicOn;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Hiển thị video full màn hình nếu không có kết nối remote
          Positioned.fill(
            child: RTCVideoView(
              isRemoteConnected ? _remoteRenderer : _localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: !isRemoteConnected, // Chỉ mirror khi là local
            ),
          ),
          // Khi có remote, thu nhỏ local video
          if (isRemoteConnected)
            Positioned(
              top: 40,
              right: 20,
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
          // Thanh nhập roomId
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Room ID',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    signaling.joinRoom(
                      textEditingController.text.trim(),
                      _remoteRenderer,
                    );
                  },
                  icon: Icon(Icons.meeting_room, color: Colors.white),
                  iconSize: 32,
                ),
              ],
            ),
          ),
          // Thanh điều khiển
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: toggleCamera, // Toggle camera on/off
                  icon: Icon(
                    isCameraOn ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),
                IconButton(
                  onPressed: toggleMic, // Toggle mic on/off
                  icon: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),
                IconButton(
                  onPressed: () {
                    signaling.hangUp(_localRenderer);
                    setState(() {
                      isRemoteConnected = false;
                    });
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.call_end, color: Colors.red),
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
