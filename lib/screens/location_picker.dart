import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selected = const LatLng(23.5859, 58.4059); // مسقط كنقطة افتراضية
  GoogleMapController? _map;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selected,
          zoom: 14,
        ),
        onMapCreated: (c) => _map = c,
        onTap: (pos) {
          setState(() => _selected = pos);
        },
        markers: {
          Marker(
            markerId: const MarkerId("selected"),
            position: _selected,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _selected);
        },
        label: const Text("Select Location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
