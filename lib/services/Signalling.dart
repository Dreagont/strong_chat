
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef void StreamStateCallback(MediaStream stream);
typedef void StreamRemoveCallback();

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
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

  Future<void> startCamera(RTCVideoRenderer localVideo) async {
    if (localStream != null) {
      localStream?.getVideoTracks().forEach((track) {
        track.enabled = true; // Enable the video track
      });
      localVideo.srcObject = localStream;
    }
  }

  Future<void> stopCamera() async {
    if (localStream != null) {
      localStream?.getVideoTracks().forEach((track) {
        track.enabled = false; // Disable the video track
      });
    }
  }

  Future<void> startMic() async {
    if (localStream != null) {
      localStream?.getAudioTracks().forEach((track) {
        track.enabled = true; // Enable the audio track
      });
    }
  }

  Future<void> stopMic() async {
    if (localStream != null) {
      localStream?.getAudioTracks().forEach((track) {
        track.enabled = false; // Disable the audio track
      });
    }
  }

  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    try {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

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
        print("onTrack called with ${event.streams.length} streams");
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

      return roomId!;
    } catch (e) {
      print('Error creating room: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);

    try {
      var roomSnapshot = await roomRef.get();
      if (roomSnapshot.exists) {
        peerConnection = await createPeerConnection(configuration);
        registerPeerConnectionListeners();

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
          print("onTrack called with ${event.streams.length} streams");
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
      }
    } catch (e) {
      print('Error joining room: $e');
      rethrow;
    }
  }

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      ) async {
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

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    try {
      localVideo.srcObject?.getTracks().forEach((track) => track.stop());
      remoteStream?.getTracks().forEach((track) => track.stop());
      peerConnection?.close();

      if (onRemoveRemoteStream != null) {
        onRemoveRemoteStream!();
      }

      if (roomId != null) {
        FirebaseFirestore db = FirebaseFirestore.instance;
        var roomRef = db.collection('rooms').doc(roomId);
        var calleeCandidates = await roomRef.collection('calleeCandidates').get();
        var callerCandidates = await roomRef.collection('callerCandidates').get();

        for (var doc in calleeCandidates.docs) {
          await doc.reference.delete();
        }
        for (var doc in callerCandidates.docs) {
          await doc.reference.delete();
        }

        await roomRef.delete();
      }

      localStream?.dispose();
      remoteStream?.dispose();
    } catch (e) {
      print('Error hanging up: $e');
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
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
}