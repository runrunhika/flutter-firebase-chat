import 'package:firebase_chat2_app/pages/top_page.dart';
import 'package:firebase_chat2_app/utils/firebase.dart';
import 'package:firebase_chat2_app/utils/shared_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPrefs.setInstance();

  checkerAccount();

  runApp(const MyApp());
}

Future<void> checkerAccount() async {
  String uid = SharedPrefs.getUid();
  //端末にアカウント情報がない場合
  if (uid == '') {
    //アカウントを新規作成
    Firestore.addUser();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Chat2 App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TopPage(),
    );
  }
}
