import 'package:cloud_firestore/cloud_firestore.dart';

class Message{
  final String senderId;
  final String friendId;
  final String message;
  final String messType;
  final Timestamp timestamp;
  final String fileName;
  bool isSynced;
  bool isNoti_isDeliver;
  bool isRead;
  bool isChecked;

  Message({
    required this.senderId,
    required this.friendId,
    required this.message,
    required this.messType,
    required this.timestamp,
    required this.fileName,
    this.isSynced = false,
    this.isNoti_isDeliver = false,
    this.isRead = false,
    this.isChecked = false
  });

  Map<String, dynamic> MessToMap() {
    return{
      'senderId': senderId,
      'friendId': friendId,
      'message': message,
      'messType': messType,
      'timeStamp' : timestamp,
      'fileName': fileName,
      'isNoti_isDeliver': isNoti_isDeliver,
      'isRead': isRead,
      'isChecked': isChecked
    };
  }
}