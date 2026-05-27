import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';

class MissionSetupScreen extends StatefulWidget {
  const MissionSetupScreen({super.key});

  @override
  State<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends State<MissionSetupScreen> {
  LatLng? _pinned;
  LatLng _center = const LatLng(27.7172, 85.3240);
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = here);
      _mapController.move(here, 15);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      appBar: AppBar(
        title: Text(
          'Pin Target Location',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_pinned != null)
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'lat': _pinned!.latitude,
                'lng': _pinned!.longitude,
              }),
              child: Text(
                'Done',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  color: BedBreakerTheme.accent,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BedBreakerTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: BedBreakerTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Tap anywhere on the map to drop your target pin.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, color: BedBreakerTheme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                  onTap: (_, point) => setState(() => _pinned = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bedbreaker',
                  ),
                  if (_pinned != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _pinned!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: BedBreakerTheme.accent,
                          size: 48,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
