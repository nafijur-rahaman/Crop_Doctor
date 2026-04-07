import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../widgets/farm_card.dart';
import '../widgets/tool_icon.dart';
import '../widgets/custom_notification.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenForum,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenForum;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    Text(
                      'Tanjid Nafis',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'TN',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(AppStyles.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppStyles.radiusCard),
                boxShadow: AppStyles.defaultShadow,
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '28 C, Sunny',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Perfect for spraying',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.water_drop_outlined, size: 16, color: Colors.blue),
                  Text(' 45%', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  SizedBox(width: 10),
                  Icon(Icons.air, size: 16, color: Colors.grey),
                  Text(' 12km/h', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            InkWell(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const CameraScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                  boxShadow: AppStyles.highlightShadow,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.camera_enhance_outlined,
                            color: AppColors.textLight,
                            size: 40,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Scan Crop',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Instantly detect diseases using AI.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 25,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textLight,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'QUICK TOOLS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToolIcon(
                  icon: Icons.calculate_outlined,
                  label: 'Fertilizer Calc',
                  color: Colors.blue,
                  onTap: () => _showMessage(
                    context,
                    'Fertilizer calculator will be updated later.',
                  ),
                ),
                ToolIcon(
                  icon: Icons.eco_outlined,
                  label: 'Seed Guide',
                  color: Colors.purple,
                  onTap: () => _showMessage(
                    context,
                    'Seed guide will be updated later.',
                  ),
                ),
                ToolIcon(
                  icon: Icons.help_center_outlined,
                  label: 'Expert Chat',
                  color: Colors.orange,
                  onTap: onOpenForum,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Farm',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onOpenProfile,
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            FarmCard(
              cropName: 'Tomato',
              stage: 'Fruiting',
              healthScore: 0.92,
              accentColor: Colors.redAccent,
              onTap: onOpenForum,
            ),
            FarmCard(
              cropName: 'Potato',
              stage: 'Vegetative',
              healthScore: 0.98,
              accentColor: Colors.brown,
              onTap: onOpenForum,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    CustomNotification.show(context, message);
  }
}
