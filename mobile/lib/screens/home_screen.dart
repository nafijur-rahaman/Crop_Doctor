import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../widgets/tool_icon.dart';
import '../widgets/custom_notification.dart';
import '../widgets/weather_container.dart';
import 'camera_screen.dart';
import '../models/plant.dart';
import '../models/forum_post.dart';
import '../services/catalog_service.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import 'question_detail_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenForum,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenForum;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _hasShownAd = false;
  
  bool _loadingPlants = true;
  List<Plant> _plants = [];
  
  bool _loadingPosts = true;
  List<ForumPost> _recentPosts = [];
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAd();
    });
  }

  void _checkAndShowAd() {
    if (!_hasShownAd && !AuthService.isPremiumUser) {
      _hasShownAd = true;
      _showPremiumAd();
    }
  }

  void _showPremiumAd() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text('Upgrade to Premium'),
          ],
        ),
        content: const Text(
          'Unlock the Expert Forum and get direct help from certified agronomists! '
          'Upgrade your account today to maximize your crop yields.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
            ),
            child: const Text('View Plans', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    _loadPlants();
    _loadRecentPosts();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await CatalogService.fetchPlants();
      if (mounted) {
        setState(() {
          _plants = plants;
          _loadingPlants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPlants = false);
      }
    }
  }

  Future<void> _loadRecentPosts() async {
    if (!AuthService.isAuthenticated || !AuthService.isPremiumUser) {
      setState(() => _loadingPosts = false);
      return;
    }
    try {
      final posts = await ForumService.getAllQuestions();
      if (mounted) {
        setState(() {
          _recentPosts = posts.take(3).toList(); // Show top 3 recent posts
          _loadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = 'Could not load recent posts.';
          _loadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AgroAppScope.of(context).profile;

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingScreen,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good Morning,',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      profile?.username ?? 'Guest User',
                      style: const TextStyle(
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
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile?.initials ?? 'G',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const WeatherContainer(),
            const SizedBox(height: 25),
            InkWell(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const CameraScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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
                  onTap: widget.onOpenForum,
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // --- Supported Plants Section ---
            const Text(
              'PLANTS WE SUPPORT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 15),
            _buildSupportedPlants(),
            
            const SizedBox(height: 30),
            
            // --- Community Feed Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Community Discussions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenForum,
                  child: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildCommunityFeed(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedPlants() {
    if (_loadingPlants) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    
    if (_plants.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Check out the catalog to see supported plants.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _plants.length,
        itemBuilder: (context, index) {
          final plant = _plants[index];
          return Container(
            width: 85,
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://loremflickr.com/200/200/${Uri.encodeComponent(plant.name)},plant/all',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plant.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityFeed() {
    if (!AuthService.isAuthenticated) {
      return _buildFeedMessage(
        icon: Icons.login_outlined,
        message: 'Login to view the community feed.',
      );
    }
    
    if (!AuthService.isPremiumUser) {
      return _buildFeedMessage(
        icon: Icons.lock_outline,
        message: 'Upgrade to premium to access expert discussions.',
      );
    }

    if (_loadingPosts) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_postsError != null) {
      return _buildFeedMessage(
        icon: Icons.error_outline,
        message: _postsError!,
      );
    }

    if (_recentPosts.isEmpty) {
      return _buildFeedMessage(
        icon: Icons.forum_outlined,
        message: 'No recent discussions. Be the first to ask!',
      );
    }

    return Column(
      children: _recentPosts.map((post) => _buildFeedCard(post)).toList(),
    );
  }

  Widget _buildFeedMessage({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.defaultShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(ForumPost post) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (post.backendId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(questionId: post.backendId!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppStyles.defaultShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[100],
                  child: Text(
                    post.initials,
                    style: const TextStyle(
                      color: Colors.blueGrey, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        post.time,
                        style: const TextStyle(
                          color: Colors.grey, 
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.crop != null && post.crop!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.crop!,
                      style: const TextStyle(
                        color: AppColors.primary, 
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14, 
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline, 
                  size: 14, 
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.replies.length} Replies',
                  style: TextStyle(
                    color: Colors.grey[500], 
                    fontSize: 12,
                  ),
                ),
                if (post.hasExpertReply) ...[
                  const Spacer(),
                  const Icon(
                    Icons.verified_user_outlined, 
                    size: 14, 
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Expert Replied',
                    style: TextStyle(
                      color: AppColors.primary, 
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    CustomNotification.show(context, message);
  }
}
