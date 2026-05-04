import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'camera_screen.dart';
import 'forum_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_notification.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';
import 'welcome_screen.dart';

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
  void initState() {
    super.initState();
    _fetchProfileIfAuthenticated();
  }

  Future<void> _fetchProfileIfAuthenticated() async {
    if (AuthService.isAuthenticated) {
      try {
        final profile = await AuthService.getProfile();
        if (!mounted) return;
        AgroAppScope.of(context).setProfile(profile);
      } catch (e) {
        debugPrint('Error fetching profile on init: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(
        key: const ValueKey(0),
        onOpenForum: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 4),
      ),
      ForumScreen(
        key: const ValueKey(1),
        initialDraftQuestion: widget.initialForumQuestion,
      ),
      const SizedBox(key: ValueKey(2)),
      const HistoryScreen(key: ValueKey(3)),
      const ProfileScreen(key: ValueKey(4)),
    ];

    final profile = AgroAppScope.of(context).profile;

    return Scaffold(
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF00A36C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Text(
                      profile?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    profile?.username ?? 'Guest User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profile?.email ?? 'Join the community',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    Icons.person_outline,
                    'View Profile',
                    () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 4);
                    },
                  ),
                  _buildDrawerItem(
                    Icons.star_outline,
                    'Subscriptions',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    Icons.settings_outlined,
                    'Settings',
                    () {
                      Navigator.pop(context);
                      CustomNotification.show(context, 'Settings available soon.');
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _buildDrawerItem(
                    Icons.help_outline,
                    'Help & Support',
                    () {
                      Navigator.pop(context);
                      CustomNotification.show(context, 'Support channel is offline.');
                    },
                  ),
                  _buildDrawerItem(
                    AuthService.isAuthenticated ? Icons.logout : Icons.login,
                    AuthService.isAuthenticated ? 'Logout' : 'Login',
                    () => AuthService.isAuthenticated 
                      ? _handleLogout(context) 
                      : _handleLoginPrompt(context),
                    color: AuthService.isAuthenticated ? Colors.redAccent : const Color(0xFF00A36C),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'v1.0.0 Stable Build',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12, // Increased round space around it
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surface,
        elevation: 8, // Added subtle shadow to emphasize the cutout
        shadowColor: Colors.black.withValues(alpha: 0.1),
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
      floatingActionButtonLocation: const _LoweredCenterDockedFabLocation(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CameraScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.camera_alt_outlined,
          color: AppColors.textLight,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700], size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); // Close drawer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear state and navigate
      await AuthService.logout();
      if (!mounted) return;
      AgroAppScope.of(context).clearProfile();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleLoginPrompt(BuildContext context) async {
    Navigator.pop(context); // Close drawer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Required'),
        content: const Text('You need an account to access this feature. Would you like to login or create an account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            child: const Text('Login / Register'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    }
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

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

class _LoweredCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _LoweredCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the standard center docked offset.
    final Offset standardOffset = FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
    // Shift the Y-axis down by 15 pixels to embed the FAB deeper into the navigation bar.
    return Offset(standardOffset.dx, standardOffset.dy + 15.0);
  }
}
