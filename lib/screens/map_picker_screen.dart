import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedPos;
  GoogleMapController? mapController;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // =====================================================
  //   Load Current Location (with fallback to Muscat)
  // =====================================================
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        selectedPos = const LatLng(23.5880, 58.3829);
        setState(() => loading = false);
        return;
      }

      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        selectedPos = const LatLng(23.5880, 58.3829);
        setState(() => loading = false);
        return;
      }

      Position pos = await Geolocator.getCurrentPosition();
      selectedPos = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      selectedPos = const LatLng(23.5880, 58.3829);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // =====================================================
  //   Free Reverse Geocoding (OpenStreetMap + User-Agent)
  // =====================================================
  Future<String> _getAddress(LatLng pos) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1";

    try {
      final uri = Uri.parse(url);
      final client = HttpClient();

      // 🔥 IMPORTANT: Nominatim requires a User-Agent!
      client.userAgent =
      "Mozilla/5.0 (compatible; HosApp/1.0; +https://your-domain.com)";

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) return "Unknown";

      final jsonStr = await response.transform(utf8.decoder).join();
      final data = jsonDecode(jsonStr);

      // Get readable address
      if (data["display_name"] != null) {
        return data["display_name"];
      }
    } catch (e) {
      debugPrint("Reverse Geocode Error: $e");
    }

    return "Unknown";
  }

  // =====================================================
  //                       UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pickLocationOnMap),
      ),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedPos!,
          zoom: 15,
        ),
        onMapCreated: (c) => mapController = c,
        onTap: (pos) {
          setState(() => selectedPos = pos);
        },
        markers: {
          Marker(
            markerId: const MarkerId("selected"),
            position: selectedPos!,
          )
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (selectedPos == null) return;

          final address = await _getAddress(selectedPos!);

          if (!mounted) return;

          Navigator.pop(context, {
            "lat": selectedPos!.latitude,
            "lng": selectedPos!.longitude,
            "address": address,
          });
        },
        label: Text(t.confirmLocation),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
