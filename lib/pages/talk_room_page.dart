import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat2_app/model/message.dart';
import 'package:firebase_chat2_app/model/talk_room.dart';
import 'package:firebase_chat2_app/utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' as intl;

class TalkRoomPage extends StatefulWidget {
  final TalkRoom room;

  TalkRoomPage(this.room);

  @override
  _TalkRoomPageState createState() => _TalkRoomPageState();
}

class _TalkRoomPageState extends State<TalkRoomPage> {
  List<Message> messageList = [];
  TextEditingController controller = TextEditingController();

  //roomコレクションからmessageドキュメントの値を取得
  Future<void> getMessage() async {
    messageList = await Firestore.getMessage(widget.room.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text(widget.room.talkUser.name),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: StreamBuilder<QuerySnapshot>(
                //messageドキュメントに新しいドキュメントが追加されると、builderが実行される
                stream: Firestore.messageSnapshot(widget.room.roomId),
                builder: (context, snapshot) {
                  return FutureBuilder(
                      future: getMessage(),
                      builder: (context, snapshot) {
                        return ListView.builder(
                            //画面幅を超えた時スクロールが可能になる
                            physics: RangeMaintainingScrollPhysics(),
                            //要素分が高さとなる
                            shrinkWrap: true,
                            //スクロールを逆転
                            reverse: true,
                            itemCount: messageList.length,
                            itemBuilder: (context, index) {
                              Message _message = messageList[index];
                              //Timestamp型からDateTime型へ変換
                              DateTime sendTime = _message.sendTime.toDate();
                              return Padding(
                                padding: EdgeInsets.only(
                                    top: 10.0,
                                    right: 10,
                                    left: 10,
                                    bottom: index == 0 ? 10 : 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  textDirection: messageList[index].isMe
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        //最大値を決める　（画面幅の6割）
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.6),
                                        decoration: BoxDecoration(
                                            color: messageList[index].isMe
                                                ? Colors.green
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child:
                                            Text(messageList[index].message)),
                                    Text(
                                      intl.DateFormat('HH:mm').format(sendTime),
                                      style: TextStyle(fontSize: 12),
                                    )
                                  ],
                                ),
                              );
                            });
                      });
                }),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              color: Colors.white,
              child: Row(
                children: [
                  //表示可能なところまで表示する
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  )),
                  IconButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          //送信が完了するまで次の処理を実行させない
                          await Firestore.sendMessage(
                              widget.room.roomId, controller.text);
                          //送信が完了したら、TextFieldの値を消す
                          controller.clear();
                        }
                      },
                      icon: Icon(Icons.send))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
