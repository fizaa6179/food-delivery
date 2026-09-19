import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' hide LatLng;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/secrets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

/// Result returned when the user confirms an address.
/// Access via result.address / result.latLng after Navigator.pop.
class SelectedAddress {
  final String address;
  final LatLng latLng;
  SelectedAddress({required this.address, required this.latLng});
}

class SelectAddressScreen extends StatefulWidget {
  const SelectAddressScreen({super.key});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  final _searchController = TextEditingController();
  late final FlutterGooglePlacesSdk _places;
  GoogleMapController? _mapController;

  LatLng? _selectedLatLng;
  String _selectedAddress = '';
  List<AutocompletePrediction> _predictions = [];

  static const LatLng _defaultCenter = LatLng(24.8607, 67.0011); // Karachi fallback

  @override
  void initState() {
    super.initState();
    _places = FlutterGooglePlacesSdk(kGoogleApiKey);
    _useCurrentLocation();
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      await _setSelected(latLng);
      _animateCameraTo(latLng);
    } catch (_) {
      // location unavailable, user can search manually
    }
  }

  Future<void> _setSelected(LatLng latLng, {String? knownAddress}) async {
    String address = knownAddress ?? '${latLng.latitude}, ${latLng.longitude}';

    if (knownAddress == null) {
      try {
        final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [p.street, p.locality, p.administrativeArea]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');
        }
      } catch (_) {
        // keep raw lat/lng string
      }
    }

    setState(() {
      _selectedLatLng = latLng;
      _selectedAddress = address;
      _searchController.text = address;
    });
  }

  void _animateCameraTo(LatLng target) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  Future<void> _onSearchChanged(String input) async {
    if (input.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    final result = await _places.findAutocompletePredictions(input);
    setState(() => _predictions = result.predictions);
  }

  Future<void> _onPredictionSelected(AutocompletePrediction prediction) async {
    final details = await _places.fetchPlace(
      prediction.placeId,
      fields: [PlaceField.Location],
    );
    final loc = details.place?.latLng;
    if (loc == null) return;

    final latLng = LatLng(loc.lat, loc.lng);
    await _setSelected(latLng, knownAddress: prediction.fullText);
    _animateCameraTo(latLng);

    setState(() => _predictions = []);
    FocusScope.of(context).unfocus();
  }

  // Called when the user taps/drags on the map directly to drop a pin manually.
  Future<void> _onMapTapped(LatLng latLng) async {
    await _setSelected(latLng);
    _animateCameraTo(latLng);
  }

  void _confirm() {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    Navigator.of(context).pop(
      SelectedAddress(address: _selectedAddress, latLng: _selectedLatLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Select delivery address'),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.search_rounded, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search delivery address',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- SUGGESTIONS (shown above the map while typing) ---
          if (_predictions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView(
                shrinkWrap: true,
                children: _predictions
                    .map((p) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, size: 20),
                          title: Text(p.fullText, style: const TextStyle(fontSize: 13.5)),
                          onTap: () => _onPredictionSelected(p),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 8),

          // --- MAP ---
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLatLng ?? _defaultCenter,
                    zoom: 14,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: {
                    if (_selectedLatLng != null)
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLatLng!,
                        draggable: true,
                        onDragEnd: _onMapTapped,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                      ),
                  },
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'current_location_btn',
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: _useCurrentLocation,
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // --- CONFIRM BAR ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedAddress.isNotEmpty) ...[
                  Text(
                    _selectedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomButton(text: 'Confirm address', onPressed: _confirm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}