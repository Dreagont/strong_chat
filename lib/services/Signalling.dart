import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';

typedef void StreamStateCallback(MediaStream stream);
typedef void StreamRemoveCallback();
typedef void CallDurationCallback(Duration duration);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      },
      {
        'urls': 'turn:relay1.expressturn.com:3478',
        'username': 'efH7AGCE0TC92OMTXN',
        'credential': 'dJhLxWSwBz01Deh6'
      },
      {
        'urls': 'turn:relay1.expressturn.com:3478',
        'username': 'efGEDLUYAY5WK8HNF1',
        'credential': 'GMgJZWd0dtV7ydUr'
      }
    ]
  };


  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  StreamRemoveCallback? onRemoveRemoteStream;
  DateTime? _callStartTime;
  DateTime? _callEndTime;
  Timer? _durationTimer;
  CallDurationCallback? onCallDurationUpdate;
  Duration _currentCallDuration = Duration.zero;
  Duration get currentCallDuration => _currentCallDuration;

  Future<void> startCamera(RTCVideoRenderer localVideo) async {
    if (localStream != null) {
      localStream?.getVideoTracks().forEach((track) {
        track.enabled = true;
      });
      localVideo.srcObject = localStream;
    }
  }

  Future<void> stopCamera() async {
    if (localStream != null) {
      localStream?.getVideoTracks().forEach((track) {
        track.enabled = false;
      });
    }
  }

  Future<void> startMic() async {
    if (localStream != null) {
      localStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
      });
    }
  }

  Future<void> stopMic() async {
    if (localStream != null) {
      localStream?.getAudioTracks().forEach((track) {
        track.enabled = false;
      });
    }
  }

  Future<String> createRoom(RTCVideoRenderer remoteRenderer, RTCVideoRenderer localRenderer, BuildContext context,String callerId, String calleeId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    try {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners(remoteRenderer,localRenderer,context,callerId,calleeId, false);

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var callerCandidatesCollection = roomRef.collection('callerCandidates');
      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          callerCandidatesCollection.add(candidate.toMap());
        }
      };

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
      await roomRef.set(roomWithOffer);

      roomId = roomRef.id;
      currentRoomText = 'Current room is $roomId - You are the caller!';
      print(currentRoomText);

      remoteStream = await createLocalMediaStream('remoteStream');
      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
          remoteStream = event.streams[0];
          onAddRemoteStream?.call(event.streams[0]);
        }
      };

      roomRef.snapshots().listen((snapshot) async {
        if (snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if ((await peerConnection?.getRemoteDescription()) == null &&
              data['answer'] != null) {
            var answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );
            await peerConnection?.setRemoteDescription(answer);
          }
        }
      });

      roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
            peerConnection?.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        });
      });

      roomRef.snapshots().listen((snapshot) {
        if (snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (data['declined'] == true) {
            print("decline from callee");
            hangUp(localRenderer, callerId, calleeId, true, context, false,"",'declined',true);
            //false là để thông báo nó là hangup hay declined
            // còn true ở cuối để thông báo ai là người tắt true là caller còn false là callee
          }
        }
      });

      roomRef.snapshots().listen((snapshot) {
        if (snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (data['hangUpFromCallee'] == true) {
            print("Hang up from Callee");
            hangUp(localRenderer, callerId, calleeId, true, context, true,"",'hangUpFromCallee',false);
          }
        }
      });

      return roomId!;
    } catch (e) {
      print('Error creating room: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String RoomId, RTCVideoRenderer remoteVideo, RTCVideoRenderer localRenderer, BuildContext context, String callerId, String calleeId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(RoomId);

    try {
      var roomSnapshot = await roomRef.get();
      if (roomSnapshot.exists) {
        peerConnection = await createPeerConnection(configuration);
        registerPeerConnectionListeners(remoteVideo,localRenderer,context,callerId,calleeId,true);

        localStream?.getTracks().forEach((track) {
          peerConnection?.addTrack(track, localStream!);
        });

        var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
        peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
          if (candidate != null) {
            calleeCandidatesCollection.add(candidate.toMap());
          }
        };

        remoteStream = await createLocalMediaStream('remoteStream');
        peerConnection?.onTrack = (RTCTrackEvent event) {
          if (event.streams.isNotEmpty) {
            remoteVideo.srcObject = event.streams[0];
            remoteStream = event.streams[0];
            onAddRemoteStream?.call(event.streams[0]);
          }
        };

        var data = roomSnapshot.data() as Map<String, dynamic>;
        var offer = data['offer'];
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );

        var answer = await peerConnection!.createAnswer();
        await peerConnection!.setLocalDescription(answer);

        Map<String, dynamic> roomWithAnswer = {
          'answer': {'type': answer.type, 'sdp': answer.sdp}
        };
        await roomRef.update(roomWithAnswer);

        roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
          snapshot.docChanges.forEach((change) {
            if (change.type == DocumentChangeType.added) {
              Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
              peerConnection!.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }
          });
        });

        roomRef.snapshots().listen((snapshot) {
          if (snapshot.data() != null) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            if (data['hangUpFromCaller'] == true) {
              print("Hang up from caller");
              hangUp(localRenderer, callerId , calleeId, true, context, true,RoomId,'hangUpFromCaller',true);
            }
          }
        });
      }
    } catch (e) {
      print('Error joining room: $e');
      rethrow;
    }
  }

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    try {
      var stream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true
      });

      localVideo.srcObject = stream;
      localStream = stream;

      remoteVideo.srcObject = null;
    } catch (e) {
      print('Error opening user media: $e');
    }
  }

  String formatDuration(int milliseconds) {
    int totalSeconds = milliseconds ~/ 1000;
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int secs = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }


  Future<void> hangUp(
      RTCVideoRenderer localVideo, String callerId, String calleeId,
      bool isMine, BuildContext context, bool isHangUp,
      String RoomId, String Call, bool hangupPerson) async {
    try {
      _stopCallTimer();
      print('Final Call Duration: ${(_currentCallDuration.inSeconds)}');

      if (callerId == AuthService().getCurrentUserId() && isMine) {
        if (Call == 'declined' || _currentCallDuration.inMilliseconds == 0) {
          FireStoreService().sendMessage(calleeId, 'Missing Call', 'call', '');
        } else {
          FireStoreService().sendMessage(calleeId, formatDuration(_currentCallDuration.inMilliseconds), 'call', '');
        }
      }

      localVideo.srcObject?.getTracks().forEach((track) => track.stop());
      remoteStream?.getTracks().forEach((track) => track.stop());
      peerConnection?.close();

      if (onRemoveRemoteStream != null) {
        onRemoveRemoteStream!();
      }

      if(isHangUp){
        if(hangupPerson)   //true là caller  thông báo cho thằng callee biết
        {
          if (roomId != null && roomId != "") {
            FirebaseFirestore db = FirebaseFirestore.instance;
            var roomRef = db.collection('rooms').doc(roomId);
            await roomRef.update({'hangUpFromCaller': isHangUp});
          }
        }
        if(!hangupPerson) //false là callee thông báo cho thằng caller biết
        {
          if(RoomId != null && RoomId != ""){
            FirebaseFirestore db = FirebaseFirestore.instance;
            var roomRef = db.collection('rooms').doc(RoomId);
            await roomRef.update({'hangUpFromCallee': isHangUp});
          }
        }
      }
      localStream?.dispose();
      remoteStream?.dispose();

      Navigator.pop(context);
    } catch (e) {
      print('Error hanging up: $e');
    }
  }

  void registerPeerConnectionListeners(RTCVideoRenderer remoteVideo, RTCVideoRenderer localRenderer, BuildContext context, String callerId, String calleeId, bool hangupPerson) {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startCallTimer();
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        hangUp(localRenderer, callerId, calleeId, true, context, false, '', 'disconnected', hangupPerson);
      }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

    peerConnection?.onRemoveStream = (MediaStream stream) {
      if (remoteStream != null && remoteStream!.id == stream.id) {
        remoteStream = null;
        if (onRemoveRemoteStream != null) {
          onRemoveRemoteStream!();
        }
      }
    };
  }

  void _startCallTimer() {
    print('start');
    _callStartTime = DateTime.now();
    _durationTimer = Timer.periodic(Duration(milliseconds: 1), (timer) {
      if (_callStartTime != null) {
        _currentCallDuration = DateTime.now().difference(_callStartTime!);
        onCallDurationUpdate?.call(_currentCallDuration);
      }
    });
  }

  void _stopCallTimer() {
    print('stop');
    _durationTimer?.cancel();
    _callEndTime = DateTime.now();
    if (_callStartTime != null) {
      _currentCallDuration = _callEndTime!.difference(_callStartTime!);
    }
  }

}