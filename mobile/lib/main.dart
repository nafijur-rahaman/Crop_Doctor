import 'package:flutter/material.dart';

import 'app_state.dart';
import 'core/theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const CropDiseaseDetection());
}

class CropDiseaseDetection extends StatefulWidget {
  const CropDiseaseDetection({super.key});

  @override
  State<CropDiseaseDetection> createState() => _CropDiseaseDetectionState();
}

class _CropDiseaseDetectionState extends State<CropDiseaseDetection> {
  final AgroAppState _appState = AgroAppState();

  @override
  Widget build(BuildContext context) {
    return AgroAppScope(
      notifier: _appState,
      child: MaterialApp(
        title: 'crop disease detection',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
