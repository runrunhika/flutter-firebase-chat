import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat2_app/model/talk_room.dart';
import 'package:firebase_chat2_app/model/user.dart';
import 'package:firebase_chat2_app/pages/settings_profile.dart';
import 'package:firebase_chat2_app/pages/talk_room_page.dart';
import 'package:firebase_chat2_app/utils/firebase.dart';
import 'package:firebase_chat2_app/utils/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TopPage extends StatefulWidget {
  const TopPage({Key? key}) : super(key: key);

  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  List<TalkRoom> talkUserList = [];

  Future<void> createRooms() async {
    String myUid = SharedPrefs.getUid();
    talkUserList = await Firestore.getRooms(myUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャットアプリ"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsProfile()));
              },
              icon: Icon(Icons.settings))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
          //roomコレクションに処理が走ると、処理開始
          stream: Firestore.roomSnapshot,
          builder: (context, snapshot) {
            return FutureBuilder(
                //非同期：時間のかかる処理を入れる
                future: createRooms(),
                builder: (context, snapshot) {
                  //処理が完了した時=true
                  if (snapshot.connectionState == ConnectionState.done) {
                    return ListView.builder(
                        itemCount: talkUserList.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              print(talkUserList[index].roomId);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          //引数：トークユーザーの情報もルームIDも送れる
                                          TalkRoomPage(talkUserList[index])));
                            },
                            child: Container(
                              height: 70,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(
                                          talkUserList[index]
                                              .talkUser
                                              .imagePath),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        talkUserList[index].talkUser.name,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        talkUserList[index].lastMessage,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                });
          }),
    );
  }
}
