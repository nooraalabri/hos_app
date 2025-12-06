import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class PatientFaceLoginScreen extends StatefulWidget {
  const PatientFaceLoginScreen({super.key});

  @override
  State<PatientFaceLoginScreen> createState() => _PatientFaceLoginScreenState();
}

class _PatientFaceLoginScreenState extends State<PatientFaceLoginScreen> {
  CameraController? _controller;
  late FaceDetector _detector;

  bool loading = false;
  bool faceDetected = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _initCamera();
  }

  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => error = "Camera error: $e");
    }
  }

  Future<void> _capture() async {
    if (loading || _controller == null) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pic = await _controller!.takePicture();
      final bytes = await pic.readAsBytes();

      final input = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(input);

      if (faces.isEmpty) {
        setState(() {
          faceDetected = false;
          error = "No face detected. Try again.";
          loading = false;
        });
        return;
      }

      faceDetected = true;
      await _sendToServer(bytes);
    } catch (e) {
      setState(() {
        error = "Error: $e";
        loading = false;
      });
    }
  }

  Future<void> _sendToServer(Uint8List bytes) async {
    final base64Img = base64Encode(bytes);

    try {
      final resp = await http.post(
        Uri.parse("http://192.168.31.57:5000/face-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Img}),
      );

      final json = jsonDecode(resp.body);

      if (resp.statusCode == 200 && json["success"] == true) {
        final uid = json["uid"];

        Navigator.pop(context, {"success": true, "uid": uid});
      } else {
        setState(() {
          error = json["message"] ?? "Face not recognized";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Network error: $e";
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),

          Align(
            alignment: Alignment.center,
            child: Container(
              width: 500,        // ← تم التكبير
              height: 500,       // ← تم التكبير
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: faceDetected ? Colors.green : Colors.white,
                  width: 5,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                faceDetected ? "Face Detected ✓" : "Align your face",
                style: TextStyle(
                  fontSize: 24,
                  color: faceDetected ? Colors.green : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (error != null)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),

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
