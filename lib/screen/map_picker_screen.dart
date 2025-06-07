import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng? selectedPosition;
  String selectedAddress = '';

  Future<void> _onTapMap(LatLng position) async {
    setState(() {
      selectedPosition = position;
    });

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        selectedAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
      });
    }
  }

  Future<LatLng> _getInitialLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _getInitialLocation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        return Scaffold(
          appBar: AppBar(title: Text("Pilih Lokasi di Peta")),
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: snapshot.data!,
                  zoom: 15,
                ),
                onTap: _onTapMap,
                markers: selectedPosition == null
                    ? {}
                    : {
                        Marker(
                          markerId: MarkerId("selected"),
                          position: selectedPosition!,
                        )
                      },
              ),
              if (selectedAddress.isNotEmpty)
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(selectedAddress),
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                right: 16,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedAddress.isNotEmpty) {
                      Navigator.pop(context, selectedAddress);
                    }
                  },
                  child: Text("Pilih Lokasi Ini"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
