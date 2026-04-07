import 'package:flutter/material.dart';

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    'Tanjid Nafis',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A191E),
                    ),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF00A36C),
                child: Text(
                  'TN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
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
                        ),
                      ),
                      Text(
                        'Perfect for spraying',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.water_drop_outlined, size: 16, color: Colors.blue),
                Text(' 45%', style: TextStyle(fontSize: 12)),
                SizedBox(width: 10),
                Icon(Icons.air, size: 16, color: Colors.grey),
                Text(' 12km/h', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A36C), Color(0xFF008E5D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.camera_enhance_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Scan Crop',
                          style: TextStyle(
                            color: Colors.white,
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
                      color: Colors.white,
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
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToolIcon(
                icon: Icons.calculate_outlined,
                label: 'Fertilizer Calc',
                color: Colors.blue,
                onTap: () => _showMessage(
                  context,
                  'Fertilizer calculator will be updated later.',
                ),
              ),
              _buildToolIcon(
                icon: Icons.eco_outlined,
                label: 'Seed Guide',
                color: Colors.purple,
                onTap: () => _showMessage(
                  context,
                  'Seed guide will be updated later.',
                ),
              ),
              _buildToolIcon(
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onOpenProfile,
                child: const Text(
                  'Edit',
                  style: TextStyle(color: Color(0xFF00A36C)),
                ),
              ),
            ],
          ),
          _buildFarmCard(
            cropName: 'Tomato',
            stage: 'Fruiting',
            healthScore: 0.92,
            accentColor: Colors.redAccent,
          ),
          _buildFarmCard(
            cropName: 'Potato',
            stage: 'Vegetative',
            healthScore: 0.98,
            accentColor: Colors.brown,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildToolIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A191E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmCard({
    required String cropName,
    required String stage,
    required double healthScore,
    required Color accentColor,
  }) {
    final int healthPercentage = (healthScore * 100).round();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpenForum,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.spa_outlined, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cropName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A191E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Growth stage: $stage',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: healthScore,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE9EEF1),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$healthPercentage%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
