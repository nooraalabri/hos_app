import 'dart:convert';
import 'package:http/http.dart' as http;

class FaceService {
  static const String baseUrl = "http://192.168.31.57:5000";

  // --------------------------
  // REGISTER FACE
  // --------------------------
  static Future<bool> registerFace({
    required String uid,
    required String base64Image,
  }) async {
    final url = Uri.parse("$baseUrl/face-register");

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uid": uid,
        "image": base64Image,
      }),
    );

    final data = jsonDecode(resp.body);

    return data["success"] == true;
  }

  // --------------------------
  // LOGIN FACE
  // --------------------------
  static Future<bool> loginFace({
    required String uid,
    required String base64Image,
  }) async {
    final url = Uri.parse("$baseUrl/face-login");

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uid": uid,
        "image": base64Image,
      }),
    );

    final data = jsonDecode(resp.body);

    return data["success"] == true;
  }
}
