import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class PatientFaceLoginScreen extends StatefulWidget {
  final String uid;
  const PatientFaceLoginScreen({super.key, required this.uid});

  @override
  State<PatientFaceLoginScreen> createState() => _PatientFaceLoginScreenState();
}

class _PatientFaceLoginScreenState extends State<PatientFaceLoginScreen> {
  CameraController? _controller;
  late FaceDetector _detector;

  bool loading = false;
  bool faceDetected = false;
  String? error;

  // ------------------------------ INIT
  @override
  void initState() {
    super.initState();
    _initDetector();
    _initCamera();
  }

  // ------------------------------ MLKit DETECTOR
  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // ------------------------------ CAMERA
  Future<void> _initCamera() async {
    try {
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
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => error = "Camera error: $e");
    }
  }

  // ------------------------------ CAPTURE
  Future<void> _capture() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      final pic = await _controller!.takePicture();
      final bytes = await pic.readAsBytes();

      // Detect face
      final input = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(input);

      if (faces.isEmpty) {
        setState(() {
          faceDetected = false;
          loading = false;
          error = "No face detected. Try again.";
        });
        return;
      }

      faceDetected = true;

      await _sendToServer(bytes);

    } catch (e) {
      setState(() => error = "Error: $e");
    }

    setState(() => loading = false);
  }

  // ------------------------------ SEND IMAGE TO FLASK
  Future<void> _sendToServer(Uint8List bytes) async {
    final base64Img = base64Encode(bytes);

    try {
      final resp = await http.post(
        Uri.parse("http://192.168.31.56:5000/face-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": widget.uid,
          "image": base64Img,
        }),
      );

      if (resp.statusCode != 200) {
        setState(() => error = "Server error: ${resp.statusCode}");
        return;
      }

      final json = jsonDecode(resp.body);

      if (json["success"] == true) {
        Navigator.pop(context, {"success": true, "uid": widget.uid});
      } else {
        setState(() => error = "Face not recognized");
      }
    } catch (e) {
      setState(() => error = "Network error: $e");
    }
  }

  // ------------------------------ DISPOSE
  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  // ------------------------------ UI
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

          // ------------------ CIRCLE
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

          // ------------------ TEXT
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                faceDetected ? "Face Detected ✓" : "Align your face",
                style: TextStyle(
                  fontSize: 22,
                  color: faceDetected ? Colors.green : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ------------------ ERROR MSG
          if (error != null)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                ),
              ),
            ),

          // ------------------ LOGIN BUTTON
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: loading ? null : _capture,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login with Face"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
