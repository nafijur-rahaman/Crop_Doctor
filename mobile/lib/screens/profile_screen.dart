import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/user_stats.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import '../widgets/custom_notification.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'subscription_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadingProfile = true;
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!AuthService.isAuthenticated) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final profile = await AuthService.getProfile();
      if (!mounted) return;
      AgroAppScope.of(context).setProfile(profile);
      try {
        _stats = await StatsService.getStats();
      } catch (_) {}
      setState(() => _loadingProfile = false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loadingProfile = false);
        CustomNotification.show(context, e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _showLoginRequiredPrompt(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Required'),
        content: const Text(
          'You need an account to access this feature. Would you like to login or create an account now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Login / Register'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WelcomeScreen()),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content:
            const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.logout();
    if (!mounted) return;
    AgroAppScope.of(context).clearProfile();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AgroAppScope.of(context).profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(profile),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildStatCard(
                          AuthService.isAuthenticated
                              ? ((_stats?.totalScans ?? 0).toString())
                              : '—',
                          'Total Scans',
                          const Color(0xFF00A36C),
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          profile?.displayRole ?? '—',
                          'Account Type',
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          context,
                          Icons.person_outline,
                          'Edit Profile',
                          'Update name & details',
                          const Color(0xFF00A36C),
                          onTap: () {
                            if (AuthService.isAuthenticated) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(profile: profile!),
                                ),
                              );
                            } else {
                              _showLoginRequiredPrompt(context);
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildTile(
                          context,
                          Icons.star_outline,
                          AuthService.isPremiumUser 
                            ? 'Manage Subscription' 
                            : 'Subscription & Billing',
                          AuthService.isPremiumUser 
                            ? 'Your plan: ${profile?.displayRole ?? 'Premium'}' 
                            : 'Upgrade for expert features',
                          Colors.amber[800]!,
                          onTap: () {
                            if (AuthService.isAuthenticated) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                              );
                            } else {
                              _showLoginRequiredPrompt(context);
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildTile(
                          context,
                          Icons.language_outlined,
                          'App Language',
                          'English',
                          Colors.blue,
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildTile(
                          context,
                          Icons.settings_outlined,
                          'Settings',
                          'Notifications & Privacy',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon:
                            const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor:
                              Colors.redAccent.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(UserProfile? profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF00A36C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white24,
            child: Text(
              profile?.initials ?? '?',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile?.username ?? 'Guest',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile?.isVerified == true) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified,
                    color: Colors.white, size: 22),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile?.displayRole ?? 'Free User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (profile?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              profile!.email,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap ??
          () => CustomNotification.show(context, '$title will be expanded later.'),
    );
  }
}
