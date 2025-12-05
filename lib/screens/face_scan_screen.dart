import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class FaceScanScreen extends StatefulWidget {
  final String apiUrl;     // example: http://192.168.1.12:5000/face-login
  final String uid;        // المستخدم الحالي
  final bool isRegister;   // true = register, false = login

  const FaceScanScreen({
    super.key,
    required this.apiUrl,
    required this.uid,
    required this.isRegister,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _controller;
  late FaceDetector _detector;

  bool loading = false;
  bool faceDetected = false;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _initCamera();
  }

  // ========================= ML KIT SETUP
  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // ========================= CAMERA INIT
  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() {});
  }

  // ========================= CAPTURE & DETECT FACE
  Future<void> _captureAndSend() async {
    if (loading || processing) return;
    processing = true;

    try {
      // 1) التقط صورة
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // 2) تحويل للصيغة التي يفهمها MLKit
      final inputImage = InputImage.fromFilePath(file.path);

      // 3) تحقق من وجود وجه
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        faceDetected = false;
        processing = false;
        setState(() {});
        return;
      }

      // -------------------- Face OK
      faceDetected = true;
      setState(() {});

      // 4) إرسال إلى السيرفر
      await _sendToServer(bytes);

    } catch (e) {
      print("ERROR: $e");
    }

    processing = false;
  }

  // ========================= SEND TO SERVER
  Future<void> _sendToServer(Uint8List bytes) async {
    setState(() => loading = true);

    final base64Img = base64Encode(bytes);

    final body = widget.isRegister
        ? {"uid": widget.uid, "image": base64Img}
        : {"uid": widget.uid, "image": base64Img};

    try {
      final resp = await http.post(
        Uri.parse(widget.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final json = jsonDecode(resp.body);

      if (json["success"] == true) {
        Navigator.pop(context, {"success": true, "uid": widget.uid});
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Face not recognized")),
        );
      }
    } catch (e) {
      print("SEND ERROR: $e");
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  // ========================= UI
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),

          // Middle Circle Frame
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: faceDetected ? Colors.green : Colors.white,
                  width: 4,
                ),
              ),
            ),
          ),

          // Text status
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                faceDetected
                    ? "Face Detected ✓"
                    : "Align your face inside the circle",
                style: TextStyle(
                  color: faceDetected ? Colors.green : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: loading ? null : _captureAndSend,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isRegister ? "Register Face" : "Login"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
