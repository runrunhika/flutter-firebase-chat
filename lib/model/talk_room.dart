import 'package:firebase_chat2_app/model/user.dart';

class TalkRoom {
  String roomId;
  User talkUser;
  String lastMessage;
  TalkRoom({
    this.roomId = '',
    required this.talkUser,
    required this.lastMessage,
  });
  
}
