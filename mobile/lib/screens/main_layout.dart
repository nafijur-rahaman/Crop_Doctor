import 'package:flutter/material.dart';

import 'camera_screen.dart';
import 'forum_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
    this.initialIndex = 0,
    this.initialForumQuestion,
  });

  final int initialIndex;
  final String? initialForumQuestion;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(
        onOpenForum: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 4),
      ),
      ForumScreen(initialDraftQuestion: widget.initialForumQuestion),
      const SizedBox(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(Icons.home_filled, 'Home', 0),
              _buildNavButton(Icons.chat_bubble_outline, 'Forum', 1),
              const SizedBox(width: 40),
              _buildNavButton(Icons.history, 'History', 3),
              _buildNavButton(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        backgroundColor: const Color(0xFF00A36C),
        elevation: 5,
        child: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? const Color(0xFF00A36C) : Colors.grey;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
