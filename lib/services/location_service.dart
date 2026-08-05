import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        "Konum servisi kapalı. Lütfen cihaz ayarlarından konumu aç.",
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Konum izni reddedildi.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Konum izni kalıcı olarak reddedildi. "
        "Uygulama ayarlarından konum iznini açmalısın.",
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        return lastPosition;
      }

      throw Exception(
        "Konum zamanında alınamadı. "
        "Emülatöre bir konum tanımlayıp tekrar dene.",
      );
    }
  }
}
