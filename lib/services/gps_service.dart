import 'package:geolocator/geolocator.dart';

class GpsService {
  static const double _minAccuracyMeters = 50.0;

  static double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static bool isWithinRadius({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) {
    final distance = distanceBetween(currentLat, currentLng, targetLat, targetLng);
    return distance <= radiusMeters;
  }

  static Stream<Position> trackLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).where((pos) => pos.accuracy <= _minAccuracyMeters);
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
