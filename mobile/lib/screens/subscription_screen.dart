import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models/subscription_plan.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../widgets/custom_notification.dart';
import 'welcome_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  List<SubscriptionPlan> _plans = [];
  String? _error;
  bool _checkingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchPlans();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // After returning from external payment page, refresh profile/role.
      _refreshRoleAfterPayment();
    }
  }

  Future<void> _fetchPlans() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _loading = false;
        _plans = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await SubscriptionService.getPlans();
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _refreshRoleAfterPayment() async {
    if (!mounted || !AuthService.isAuthenticated) return;
    if (_checkingPayment) return;

    setState(() {
      _checkingPayment = true;
    });

    try {
      // Try a few times; IPN may take a moment.
      for (int i = 0; i < 6; i++) {
        final profile = await AuthService.refreshProfileAndRole();
        if (!mounted) return;
        AgroAppScope.of(context).setProfile(profile);
        if (AuthService.isPremiumUser) {
          CustomNotification.show(context, 'Premium activated!');
          if (mounted) Navigator.pop(context);
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (_) {
      // Ignore; user can manually refresh / revisit.
    } finally {
      if (!mounted) return;
      setState(() {
        _checkingPayment = false;
      });
    }
  }

  Future<void> _handleSubscribe(SubscriptionPlan plan) async {
    if (AuthService.isPremiumUser) {
      if (!mounted) return;
      CustomNotification.show(context, 'You already have an active subscription.');
      return;
    }
    if (!AuthService.isAuthenticated) {
      if (!mounted) return;
      CustomNotification.show(context, 'Please login or register to upgrade.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WelcomeScreen()),
      );
      return;
    }
    try {
      CustomNotification.show(context, 'Redirecting to payment gateway...');
      final init = await SubscriptionService.createPayment(plan.id);
      if (init.paymentUrl.isNotEmpty) {
        final uri = Uri.parse(init.paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) CustomNotification.show(context, 'Could not open payment URL.');
        }
      } else {
        if (mounted) CustomNotification.show(context, 'Failed to generate payment link.');
      }
    } on ApiException catch (e) {
      if (mounted) CustomNotification.show(context, e.message);
    } catch (e) {
      if (mounted) CustomNotification.show(context, 'An unexpected error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A191E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)))
          : _error != null
              ? _buildErrorView()
              : (!AuthService.isAuthenticated
                  ? _buildLoginRequiredView()
                  : Stack(
                      children: [
                        _buildPlansList(),
                        if (_checkingPayment)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF00A36C),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Checking payment status...',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )),
    );
  }

  Widget _buildLoginRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Login Required',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To upgrade to premium, please login or create an account first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WelcomeScreen()),
                  ).then((_) => _fetchPlans());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Login / Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 20),
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchPlans,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    if (_plans.isEmpty) {
      return const Center(
        child: Text('No active plans available.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A36C).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${plan.durationDays} Days',
                  style: const TextStyle(
                    color: Color(0xFF00A36C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '৳${plan.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '/period',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handleSubscribe(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(Icons.check_circle_outline, 'Full scan access'),
          _buildBenefitItem(Icons.check_circle_outline, 'Detailed organic & chemical solutions'),
          _buildBenefitItem(Icons.check_circle_outline, 'Expert forum access'),
          _buildBenefitItem(Icons.check_circle_outline, 'Priority diagnosis'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00A36C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
