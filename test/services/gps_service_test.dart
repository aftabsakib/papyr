import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/services/gps_service.dart';

void main() {
  group('GpsService distance calculation', () {
    test('calculates distance between two points', () {
      // ~500m north of Kathmandu city center
      final distance = GpsService.distanceBetween(
        27.7172, 85.3240,
        27.7217, 85.3240,
      );
      expect(distance, closeTo(500, 50));
    });

    test('returns 0 for same point', () {
      final distance = GpsService.distanceBetween(
        27.7172, 85.3240,
        27.7172, 85.3240,
      );
      expect(distance, 0.0);
    });

    test('isWithinRadius returns true when inside', () {
      expect(
        GpsService.isWithinRadius(
          currentLat: 27.7172, currentLng: 85.3240,
          targetLat: 27.7172, targetLng: 85.3240,
          radiusMeters: 100,
        ),
        isTrue,
      );
    });

    test('isWithinRadius returns false when outside', () {
      expect(
        GpsService.isWithinRadius(
          currentLat: 27.7172, currentLng: 85.3240,
          targetLat: 27.7500, targetLng: 85.3240,
          radiusMeters: 100,
        ),
        isFalse,
      );
    });
  });
}
