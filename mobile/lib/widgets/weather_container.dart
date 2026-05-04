import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../services/weather_service.dart';

class WeatherContainer extends StatefulWidget {
  const WeatherContainer({super.key});

  @override
  State<WeatherContainer> createState() => _WeatherContainerState();
}

class _WeatherContainerState extends State<WeatherContainer> {
  WeatherSnapshot? _weather;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _loadWeather(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final snapshot = await WeatherService.fetchWeather();
      if (!mounted) return;
      setState(() {
        _weather = snapshot;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      final cached = await WeatherService.loadCachedWeather();
      if (!mounted) return;
      setState(() {
        _weather = cached;
        _loading = false;
        _error = cached == null ? 'Weather unavailable' : null;
      });
    }
  }

  IconData _iconForCode(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Color _accentForCode(int code) {
    switch (code) {
      case 0:
        return const Color(0xFFF59E0B);
      case 1:
      case 2:
      case 3:
        return const Color(0xFF4F46E5);
      case 45:
      case 48:
        return const Color(0xFF64748B);
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return const Color(0xFF0EA5E9);
      case 71:
      case 73:
      case 75:
      case 85:
      case 86:
        return const Color(0xFF38BDF8);
      case 95:
      case 96:
      case 99:
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final accent = _accentForCode(weather?.weatherCode ?? 0);
    final gradient = LinearGradient(
      colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.72)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(AppStyles.cardPadding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppStyles.radiusCard),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForCode(weather?.weatherCode ?? 0),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            weather?.city ?? 'Fetching weather...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loading ? null : _loadWeather,
                          icon: const Icon(Icons.refresh_rounded),
                          color: Colors.white,
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather?.condition ?? (_loading ? 'Updating...' : 'No weather data'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                weather?.temperatureLabel ?? '--°C',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Feels like ${weather?.feelsLikeC.round() ?? '--'}°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WeatherStat(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${weather?.humidity ?? '--'}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeatherStat(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: weather?.windLabel ?? '-- km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loading
                    ? 'Refreshing latest data...'
                    : (_error ?? 'Updated ${weather?.updatedLabel ?? 'recently'}'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                ),
              ),
              if (weather != null)
                Text(
                  'Live weather',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
