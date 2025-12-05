import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class FaceScanRegisterScreen extends StatefulWidget {
  // تقدرِين حالياً تخلي uid اختياري أو ترسلي أي قيمة مؤقتة
  final String uid;

  const FaceScanRegisterScreen({
    super.key,
    required this.uid,
  });

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

  // -------------------- MLKit Setup
  void _initDetector() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // -------------------- Camera Setup
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
    if (mounted) {
      setState(() {});
    }
  }

  // -------------------- Capture & Detect
  Future<void> _capture() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      // 1) خذ صورة من الكاميرا
      final pic = await _controller!.takePicture();

      // بعض الأجهزة تحتاج delay بسيط
      await Future.delayed(const Duration(milliseconds: 200));

      final bytes = await pic.readAsBytes();

      // 2) ML Kit face detection
      final input = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(input);

      if (faces.isEmpty) {
        setState(() {
          faceDetected = false;
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face detected")),
        );
        return;
      }

      // على الأقل وجه واحد
      faceDetected = true;
      setState(() {});

      // 3) أرسل الصورة للسيرفر
      await _sendToServer(bytes);
    } catch (e) {
      debugPrint("ERROR in _capture: $e");
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error capturing face: $e")),
        );
      }
    }
  }

  // -------------------- Send to server
  Future<void> _sendToServer(Uint8List bytes) async {
    final base64Img = base64Encode(bytes);

    try {
      final resp = await http.post(
        Uri.parse("http://192.168.31.56:5000/face-register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": widget.uid, // لو السيرفر ما يحتاجه بيطنّشه
          "image": base64Img,
        }),
      );

      if (resp.statusCode != 200) {
        if (mounted) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${resp.statusCode}")),
          );
        }
        return;
      }

      final data = jsonDecode(resp.body);
      debugPrint("FACE REGISTER RESPONSE: $data");

      if (data["success"] == true) {
        // 👈 هنا أهم نقطة:
        // لازم نرجع faceUrl و embedding إلى RegisterPatientScreen
        Navigator.pop(context, {
          "success": true,
          "faceUrl": data["faceUrl"],       // تأكدي السيرفر يرجع نفس الإسم
          "embedding": data["embedding"],   // نفس الشي هنا
        });
      } else {
        if (mounted) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to register face")),
          );
        }
      }
    } catch (e) {
      debugPrint("ERROR in _sendToServer: $e");
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  // -------------------- UI
  @override
  Widget build(BuildContext context) {
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),

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

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: loading ? null : _capture,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register Face"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
