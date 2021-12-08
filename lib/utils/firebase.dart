import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat2_app/model/message.dart';
import 'package:firebase_chat2_app/model/talk_room.dart';
import 'package:firebase_chat2_app/model/user.dart';
import 'package:firebase_chat2_app/utils/shared_prefs.dart';

class Firestore {
  static FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  static final userRef = _firestoreInstance.collection("user");
  static final roomRef = _firestoreInstance.collection("room");
  /*roomコレクションに値が追加された時UIを更新するのに使用*/
  // snapshots とは、ある時点における特定のデータベース参照にあるデータの全体像を写し取ったもの
  static final roomSnapshot = roomRef.snapshots();

  static Future<void> addUser() async {
    try {
      //データ追加
      final newDoc = await userRef.add({
        'name': '天才',
        'image_path': 'https://pbs.twimg.com/media/E_0dqE_UUAYfTTJ.jpg'
      });
      print("アカウント作成 ");

      //端末にアカウントIDを保存
      await SharedPrefs.setUid(newDoc.id);

      List<String>? userIds = await getUser();
      //ユーザーの数だけForEachを回す
      userIds!.forEach((user) async {
        ///*自分ではない場合
        ///ユーザーCがアカウントを作成した場合
        ///＜AとC＆BとCのトークルームを作る
        ///＜CとCのトークルームを作る必要がないため
        if (user != newDoc.id) {
          /* ルームを作成 */
          //await: 時間のかかる処理の場合に付与
          await roomRef.add({
            ///トーク相手と自分自身のIDを追加
            ///ex) user(相手(A))  newDoc(自分(C))
            'joined_user_ids': [user, newDoc.id],
            'updated_time': Timestamp.now()
          });
        }
      });
      print('ルーム作成完了');
    } catch (e) {
      print("アカウント作成Error: $e");
    }
  }

  static Future<List<String>?> getUser() async {
    try {
      //データ取得
      final snapshot = await userRef.get();
      //データを返すようのリスト
      List<String> userIds = [];

      ///snapshotに"user"コレクションのデータが入る
      ///＜その内ドキュメントのデータを取得し(user)に入る
      ///＜ForEachで(user)分、回す
      ///＜(user)から、IdやNameなどの特定のデータ(プロパティ)を抽出
      snapshot.docs.forEach((user) {
        userIds.add(user.id);
        print("ドキュメント：${user.id} --- 名前:${user.data()['name']}");
      });
      return userIds;
    } catch (e) {
      print('取得失敗 $e');
      return null;
    }
  }

  //FireStoreからユーザーの情報を取得
  static Future<User> getProfile(String uid) async {
    //特定のドキュメントを取得
    final profile = await userRef.doc(uid).get();
    User myProfile = User(
        name: profile.data()!['name'],
        uid: uid,
        imagePath: profile.data()!['image_path']);
    return myProfile;
  }

  static Future<void> updateProfile(User newProfile) async {
    String myUid = SharedPrefs.getUid();
    //'user'コレクションへアクセス
    userRef
        //自身のドキュメントへアクセス
        .doc(myUid)
        //名前とプロフィール画像を更新
        .update({'name': newProfile.name, 'image_path': newProfile.imagePath});
  }

  //Room検索
  static Future<List<TalkRoom>> getRooms(String myUid) async {
    //'room'コレクションを取得
    final snapshot = await roomRef.get();
    List<TalkRoom> roomList = [];
    //相手のインスタンスを生成する前にForEachが次の検査を始めることを防ぐために *Future.forEach
    //型を明示
    //await Future.forEachの処理を終わらせてから、次の処理を開始されるため
    await Future.forEach<QueryDocumentSnapshot<Map<String, dynamic>>>(
        snapshot.docs, (doc) async {
      //myUidが含まれている場合  Cloud FireStore＜joined_user_idsにmyUidが含まれている=true
      if (doc.data()['joined_user_ids'].contains(myUid)) {
        //ルーム相手のIDを取得
        String? yourUid;
        doc.data()['joined_user_ids'].forEach((id) {
          if (id != myUid) {
            yourUid = id;
            return;
          }
        });
        //相手の情報のユーザーとインスタンスを生成
        User yourProfile = await getProfile(yourUid!);
        TalkRoom room = TalkRoom(
            roomId: doc.id,
            talkUser: yourProfile,
            lastMessage: doc.data()['last_message'] ?? '');
        roomList.add(room);
      }
    });
    //Room数 -1(自分自身) = roomList.length 成功
    print(roomList.length);
    return roomList;
  }

  //FireStore<roomコレクションからメッセージを取得する
  static Future<List<Message>> getMessage(String roomId) async {
    //room<messageコレクションへアクセス
    final messageRef = roomRef.doc(roomId).collection('message');
    List<Message> messageList = [];
    //room<messageドキュメントから値を取得
    final snapshot = await messageRef.get();
    //型を明示　＊忘れずに！
    await Future.forEach<QueryDocumentSnapshot<Map<String, dynamic>>>(
        //取得したmessageドキュメントの数だけ処理を回す
        snapshot.docs, (doc) {
      bool isMe;
      //自身のIdを取得
      String myUid = SharedPrefs.getUid();
      //メッセージを自身が送信した場合
      if (doc.data()['sender_id'] == myUid) {
        isMe = true;
      } else {
        isMe = false;
      }
      Message message = Message(
          message: doc.data()['message'],
          isMe: isMe,
          sendTime: doc.data()['send_time']);
      //リストに追加
      messageList.add(message);
    });
    /*messageドキュメントの値を送信時間順に並び替える*/
    //a と bの　sendTime　を比べて、進んでいたら順番を入れ替える
    messageList.sort((a, b) => b.sendTime.compareTo(a.sendTime));
    //値を返す
    return messageList;
  }

  //トーク画面でメッセージをFireStoreに送信する
  static Future<void> sendMessage(String roomId, String message) async {
    //room<messageコレクションへアクセス
    final messageRef = roomRef.doc(roomId).collection('message');
    String myUid = SharedPrefs.getUid();
    //messageコレクションへ値を追加
    await messageRef.add(
        {'message': message, 'sender_id': myUid, 'send_time': Timestamp.now()});
    //last_message　を更新
    roomRef.doc(roomId).update({'last_message': message});
  }

  static Stream<QuerySnapshot> messageSnapshot(String roomId) {
    return roomRef.doc(roomId).collection('message').snapshots();
  }
}
