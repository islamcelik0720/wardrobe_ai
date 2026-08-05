class WeatherInfo {
  final double temperature;
  final double apparentTemperature;
  final double precipitation;
  final double windSpeed;
  final int weatherCode;

  const WeatherInfo({
    required this.temperature,
    required this.apparentTemperature,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
  });

  factory WeatherInfo.fromMap(Map<String, dynamic> map) {
    return WeatherInfo(
      temperature: (map['temperature_2m'] as num?)?.toDouble() ?? 0,
      apparentTemperature:
          (map['apparent_temperature'] as num?)?.toDouble() ?? 0,
      precipitation: (map['precipitation'] as num?)?.toDouble() ?? 0,
      windSpeed: (map['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (map['weather_code'] as num?)?.toInt() ?? 0,
    );
  }

  String get description {
    if (weatherCode == 0) return "Açık";
    if (weatherCode == 1) return "Çoğunlukla açık";
    if (weatherCode == 2) return "Parçalı bulutlu";
    if (weatherCode == 3) return "Kapalı";

    if (weatherCode == 45 || weatherCode == 48) {
      return "Sisli";
    }

    if (weatherCode >= 51 && weatherCode <= 57) {
      return "Çiseli";
    }

    if (weatherCode >= 61 && weatherCode <= 67) {
      return "Yağmurlu";
    }

    if (weatherCode >= 71 && weatherCode <= 77) {
      return "Karlı";
    }

    if (weatherCode >= 80 && weatherCode <= 82) {
      return "Sağanak yağışlı";
    }

    if (weatherCode >= 85 && weatherCode <= 86) {
      return "Kar sağanaklı";
    }

    if (weatherCode >= 95 && weatherCode <= 99) {
      return "Gök gürültülü";
    }

    return "Bilinmeyen hava durumu";
  }

  bool get isRainy {
    return precipitation > 0 ||
        (weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82) ||
        (weatherCode >= 95 && weatherCode <= 99);
  }

  bool get isSnowy {
    return (weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86);
  }
}
