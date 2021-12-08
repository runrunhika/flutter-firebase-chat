import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat2_app/model/user.dart';
import 'package:firebase_chat2_app/utils/firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsProfile extends StatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  _SettingsProfileState createState() => _SettingsProfileState();
}

class _SettingsProfileState extends State<SettingsProfile> {
  File? image;
  ImagePicker picker = ImagePicker();
  String? imagePath;
  TextEditingController controller = TextEditingController();

  Future<void> getImagerFromGallery() async {
    //ギャラリーへアクセス
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      //取得した画像を変数imageへ入れる
      image = File(pickedFile.path);
      uploadImage();
      setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    ///*refに画像の名前を付ける
    ///*FireStorage<Rules （
    ///(Default）request.auth != null (Firebase Authで認証されたアカウントからのみアクセス可能)
    ///(After) request.auth == null (誰でもアクセス可能)
    final ref = FirebaseStorage.instance.ref('${Timestamp.now()}');
    //FireStorage に画像を保存
    final storedImage = await ref.putFile(image!);
    imagePath = await loadImage(storedImage);
    return imagePath;
  }

  //FireStorageに保存された画像のURLを取得
  Future<String> loadImage(TaskSnapshot storedImage) async {
    String downloadUrl = await storedImage.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("プロフィール編集"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
                onTap: () async {
                  getImagerFromGallery();
                },
                child: CircleAvatar(
                  foregroundImage: image == null ? null : FileImage(image!),
                  radius: 40,
                  child: Icon(Icons.add),
                )),
            Row(
              children: [
                Container(width: 100, child: Text("名前")),
                Expanded(
                    child: TextField(
                  controller: controller,
                )),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            ElevatedButton(
                onPressed: () {
                  User newProfile =
                      User(name: controller.text, imagePath: imagePath!);
                  Firestore.updateProfile(newProfile);
                },
                child: Text('save'))
            // Row(
            //   children: [
            //     Container(width: 100, child: Text('アイコン')),
            //     Expanded(
            //         child: Container(
            //             alignment: Alignment.center,
            //             width: 150,
            //             height: 40,
            //             child: ElevatedButton(
            //                 onPressed: () {}, child: Text("画像選択"))))
            //   ],
            // )
          ],
        ),
      ),
    );
  }
}
