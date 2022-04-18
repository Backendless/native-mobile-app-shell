import 'dart:io' as io;
import 'dart:convert';
import '../types/system_events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class Coder {
  static Future<String> decodeEnum(SystemEvents se) async {
    return se.systemEvent;
  }

  static Future<dynamic> readJson({required String path}) async {
    final String response = await rootBundle.loadString(path);
    final data = await json.decode(response);

    return data;
  }
}
