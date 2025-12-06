import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class FaceScanRegisterScreen extends StatefulWidget {
  final String uid;

  const FaceScanRegisterScreen({super.key, required this.uid});

  @override
  State<FaceScanRegisterScreen> createState() => _FaceScanRegisterScreenState();
}

class _FaceScanRegisterScreenState extends State<FaceScanRegisterScreen> {
  CameraController? _controller;
  late FaceDetector _detector;

  bool faceDetected = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _initCamera();
  }

  // ------------------- MLKit detector
  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // ------------------- Camera setup
  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front =
    cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

    _controller = CameraController(front, ResolutionPreset.medium,
        enableAudio: false);

    await _controller!.initialize();
    setState(() {});
  }

  // ------------------- Capture photo
  Future<void> _capture() async {
    if (loading) return;
    loading = true;
    setState(() {});

    try {
      final pic = await _controller!.takePicture();
      final bytes = await pic.readAsBytes();

      final input = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(input);

      if (faces.isEmpty) {
        loading = false;
        faceDetected = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face detected, try again")),
        );
        return;
      }

      faceDetected = true;
      setState(() {});

      await _sendToServer(bytes);

    } catch (e) {
      loading = false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ------------------- Send Base64 to Python server
  Future<void> _sendToServer(Uint8List bytes) async {
    final base64Img = base64Encode(bytes);

    try {
      final resp = await http.post(
        Uri.parse("http://192.168.31.57:5000/face-register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uid": widget.uid, "image": base64Img}),
      );

      print("📥 SERVER RAW RESPONSE: ${resp.body}");

      final data = jsonDecode(resp.body);

      // -------- SUCCESS RESPONSE
      if (resp.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face registered successfully ✓")),
        );

        Navigator.pop(context, {
          "success": true,
          "faceUrl": data["faceUrl"],
          "embedding": data["embedding"],
        });
        return;
      }

      // -------- FAILED
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face registration failed, try again")),
      );

      setState(() => loading = false);

    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  // ------------------- UI
  @override
  Widget build(BuildContext context) {
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // ----- Face circle indicator -----
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: faceDetected ? Colors.green : Colors.white,
                  width: 4,
                ),
              ),
            ),
          ),

          // ----- Status text -----
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Text(
              faceDetected ? "Face Detected ✓" : "Align your face inside the circle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: faceDetected ? Colors.green : Colors.white,
              ),
            ),
          ),

          // ----- Button -----
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: loading ? null : _capture,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register Face", style: TextStyle(fontSize: 20)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
