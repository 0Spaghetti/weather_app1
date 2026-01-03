import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _selectedLocation = const LatLng(32.8872, 13.1913); // Default city
  String? _resolvedCity;
  String? _resolutionError;
  bool _resolving = false;

  final MapController _mapController = MapController();
  double _zoom = 6;

  @override
  void initState() {
    super.initState();
    _resolveCity(_selectedLocation);
  }

  // ================= CITY ONLY RESOLUTION =================
  Future<void> _resolveCity(LatLng point) async {
    setState(() {
      _resolving = true;
      _resolvedCity = null;
      _resolutionError = null;
    });

    try {
      final placemarks =
      await placemarkFromCoordinates(point.latitude, point.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality;
        final countryCode = place.isoCountryCode; // 🔑 VERY IMPORTANT

        if (city != null &&
            city.isNotEmpty &&
            countryCode != null &&
            countryCode.isNotEmpty) {
          // ✅ City formatted correctly for OpenWeather
          setState(() {
            _resolvedCity = '$city,$countryCode';
          });
        } else {
          // If no city is found, provide feedback
          setState(() {
            _resolutionError = "No city found at this location.";
          });
        }
      }
    } catch (e) {
      // ignore
      debugPrint("Geocoding Error: \$e");
      setState(() {
        _resolutionError = "Could not connect to the service.";
      });
    } finally {
      setState(() => _resolving = false);
    }
  }


  // ================= ZOOM CONTROLS =================
  void _zoomIn() {
    setState(() {
      _zoom++;
      _mapController.move(_selectedLocation, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom--;
      _mapController.move(_selectedLocation, _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canSelect =
        !_resolving && _resolvedCity != null && _resolvedCity!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Select City")),
      body: Stack(
        children: [
          // ================= MAP =================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _zoom,
              onTap: (_, point) {
                setState(() => _selectedLocation = point);
                _resolveCity(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'weather.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ================= ZOOM BUTTONS =================
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // ================= BOTTOM PANEL =================
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _resolving
                          ? 'Finding nearest city...'
                          : (_resolutionError ?? _resolvedCity ?? 'Tap on a city'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _resolutionError != null ? Colors.redAccent : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ BUTTON ENABLED ONLY IF A CITY EXISTS
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Use this city"),
                      onPressed: canSelect
                          ? () {
                        Navigator.pop(context, {
                          'lat': _selectedLocation.latitude,
                          'lon': _selectedLocation.longitude,
                          'city': _resolvedCity,
                        });

                      }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
