import 'package:flutter/material.dart';

import 'app_state.dart';
import 'core/theme.dart';
import 'screens/main_layout.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore any saved auth token from SharedPreferences before the UI loads.
  await AuthService.init();
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
        title: 'Crop Doctor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // If a token was restored, go straight to MainLayout, else WelcomeScreen.
        home: AuthService.isAuthenticated
            ? const MainLayout()
            : const WelcomeScreen(),
      ),
    );
  }
}
