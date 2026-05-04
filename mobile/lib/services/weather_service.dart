import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeedKph,
    required this.weatherCode,
    required this.updatedAt,
  });

  final String city;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windSpeedKph;
  final int weatherCode;
  final DateTime updatedAt;

  String get condition => WeatherService.conditionFromCode(weatherCode);
  String get temperatureLabel => '${temperatureC.round()}°C';
  String get windLabel => '${windSpeedKph.round()} km/h';
  String get updatedLabel => WeatherService.timeAgo(updatedAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'city': city,
        'temperatureC': temperatureC,
        'feelsLikeC': feelsLikeC,
        'humidity': humidity,
        'windSpeedKph': windSpeedKph,
        'weatherCode': weatherCode,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      city: (json['city'] as String?) ?? 'Current location',
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (json['feelsLikeC'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windSpeedKph: (json['windSpeedKph'] as num?)?.toDouble() ?? 0,
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class WeatherService {
  static const String _cacheKey = 'cached_weather_snapshot';

  static Future<WeatherSnapshot> fetchWeather() async {
    final location = await _fetchLocation();
    final weather = await _fetchCurrentWeather(location.latitude, location.longitude);
    final snapshot = WeatherSnapshot(
      city: location.city,
      temperatureC: weather.temperatureC,
      feelsLikeC: weather.feelsLikeC,
      humidity: weather.humidity,
      windSpeedKph: weather.windSpeedKph,
      weatherCode: weather.weatherCode,
      updatedAt: DateTime.now(),
    );
    await _saveCache(snapshot);
    return snapshot;
  }

  static Future<WeatherSnapshot?> loadCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return WeatherSnapshot.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _saveCache(WeatherSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(snapshot.toJson()));
  }

  static Future<_LocationResult> _fetchLocation() async {
    final res = await http
        .get(Uri.parse('https://ipwho.is/'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to determine location');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unable to determine location');
    }

    final success = decoded['success'] as bool?;
    if (success == false) {
      throw Exception('Unable to determine location');
    }

    final latitude = (decoded['latitude'] as num?)?.toDouble();
    final longitude = (decoded['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw Exception('Unable to determine location');
    }

    final city = _formatCity(decoded);
    return _LocationResult(latitude: latitude, longitude: longitude, city: city);
  }

  static Future<_CurrentWeatherResult> _fetchCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,apparent_temperature',
      'timezone': 'auto',
    });

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to load weather');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unable to load weather');
    }

    final current = decoded['current'];
    if (current is! Map<String, dynamic>) {
      throw Exception('Unable to load weather');
    }

    return _CurrentWeatherResult(
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (current['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeedKph: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
    );
  }

  static String _formatCity(Map<String, dynamic> decoded) {
    final city = (decoded['city'] as String?) ?? '';
    final region = (decoded['region'] as String?) ?? '';
    final country = (decoded['country'] as String?) ?? '';

    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (region.isNotEmpty && region != city) parts.add(region);
    if (parts.isEmpty && country.isNotEmpty) parts.add(country);
    return parts.isEmpty ? 'Current location' : parts.join(', ');
  }

  static String conditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Weather update';
    }
  }

  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}

class _LocationResult {
  const _LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
  });

  final double latitude;
  final double longitude;
  final String city;
}

class _CurrentWeatherResult {
  const _CurrentWeatherResult({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeedKph,
    required this.weatherCode,
  });

  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windSpeedKph;
  final int weatherCode;
}
