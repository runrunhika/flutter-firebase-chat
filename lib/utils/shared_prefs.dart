import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* 端末保存 */
class SharedPrefs {
  static SharedPreferences? prefsInstance;

  static Future<void> setInstance() async {
    if (prefsInstance == null) {
      prefsInstance = await SharedPreferences.getInstance();
      print("インスタンスを生成");
    }
  }

  //端末に保存
  static Future<void> setUid(String newUid) async {
    await prefsInstance!.setString('uid', newUid);
    print("保存完了");
  }

  //端末から取得
  static String getUid() {
    //uidがNullの場合　空を返す
    String uid = prefsInstance!.getString('uid') ?? '';
    return uid;
  }
}
