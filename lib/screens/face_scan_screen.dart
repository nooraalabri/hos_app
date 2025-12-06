import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class FaceScanScreen extends StatefulWidget {
  final String apiUrl;
  final String uid;
  final bool isRegister;

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

  bool faceDetected = false;
  bool processing = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _initCamera();
  }

  // MLKit Setup
  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // Camera Setup
  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(front, ResolutionPreset.high, enableAudio: false);

    await _controller!.initialize();
    setState(() {});
  }

  // Capture + Detect + Send
  Future<void> _captureAndVerify() async {
    if (processing || sending) return;

    processing = true;
    setState(() {});

    try {
      // Capture photo
      final pic = await _controller!.takePicture();
      final bytes = await pic.readAsBytes();

      // Face detection
      final input = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(input);

      if (faces.isEmpty) {
        faceDetected = false;
        processing = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected — try again')),
        );
        return;
      }

      faceDetected = true;
      setState(() {});

      await _sendToServer(bytes);

    } catch (e) {
      print('ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    processing = false;
    setState(() {});
  }

  Future<void> _sendToServer(List<int> bytes) async {
    sending = true;
    setState(() {});

    final base64Img = base64Encode(bytes);

    final body = {
      "uid": widget.uid,
      "image": base64Img,
    };

    try {
      final resp = await http.post(
        Uri.parse(widget.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final json = jsonDecode(resp.body);

      if (json['success'] == true) {
        Navigator.pop(context, true);
      } else {
        _msg("Face not recognized — retry");
      }
    } catch (e) {
      _msg("Server Error: $e");
    }

    sending = false;
    setState(() {});
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Face Circle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
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
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                faceDetected ? "Face Detected ✓" : "Align your face in the circle",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: faceDetected ? Colors.green : Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: sending ? null : _captureAndVerify,
                child: sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isRegister ? "Register Face" : "Login", style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
