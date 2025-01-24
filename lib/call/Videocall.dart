import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/notification_service.dart';
import '../services/Signalling.dart';

class VideoCallPage extends StatefulWidget {
  final int number;
  final String notificationToken;
  final String CaleeName;
  final String CallerName;
  final String roomId;
  final String callerId;
  final String calleeId;
  final bool isVoice;

  const VideoCallPage({
    super.key,
    required this.number,
    required this.notificationToken,
    required this.CaleeName,
    required this.CallerName,
    required this.roomId,
    required this.callerId,
    required this.calleeId,
    required this.isVoice
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

  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  String? friendAvatar;

  @override
  void initState() {
    super.initState();
    _initializeMediaAndHandleRoom();
    _fetchFriendAvatar();
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

      signaling.onRemoveRemoteStream = () {
        setState(() {
          _remoteRenderer.srcObject = null;
          isRemoteConnected = false;
        });
      };

      if (widget.isVoice) {
        toggleCamera();
      }

      if (widget.number == 1) {
        roomId = await signaling.createRoom(_remoteRenderer,_localRenderer, context,widget.callerId,widget.calleeId);
        NotificationService().pushCallNotification(
          title: widget.isVoice ? 'Voice Call' : "Video Call",
          body: "From ${widget.CallerName}",
          token: widget.notificationToken,
          roomId: roomId!,
          callerId: widget.callerId,
          calleeId: widget.calleeId,
          isVoice: widget.isVoice.toString()
        );
      } else if (widget.number == 2) {
        roomId = widget.roomId;
        signaling.joinRoom(widget.roomId, _remoteRenderer, _localRenderer, context,widget.callerId,widget.calleeId);
      }
      signaling.onCallDurationUpdate = (duration) {
        setState(() {
          _elapsedTime = duration;
        });
      };
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize media: $e')),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${minutes}:${seconds}';
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _endCall(bool isMine) {
    _timer?.cancel();
    signaling.hangUp(_localRenderer, widget.callerId, widget.calleeId, isMine, context, true, widget.roomId, "VideoCall");
  }

  Future<void> _fetchFriendAvatar() async {
    try {
      String userIdToFetch = widget.callerId == AuthService().getCurrentUserId()
          ? widget.calleeId
          : widget.callerId;

      print('fetched id : ${widget.CallerName}');

      final DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection("Users").doc(userIdToFetch).get();

      setState(() {
        friendAvatar = userSnapshot.get('avatar') ?? 'default_avatar.png';
      });
    } catch (e) {
      print('Error fetching avatar: $e');
      setState(() {
        friendAvatar = 'default_avatar.png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                if (widget.isVoice && friendAvatar != null)
                  Positioned.fill(
                    child: Center(
                      child: CircleAvatar(
                        radius: 100,
                        backgroundImage: NetworkImage(friendAvatar!),
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: RTCVideoView(
                      isRemoteConnected ? _remoteRenderer : _localRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: !isRemoteConnected,
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _formatDuration(_elapsedTime),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isRemoteConnected && !widget.isVoice)
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
                      if(!widget.isVoice)
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
                        onPressed: () => _endCall(true),
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
