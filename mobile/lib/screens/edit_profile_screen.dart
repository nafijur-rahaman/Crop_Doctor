import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/custom_notification.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _emailCtrl = TextEditingController(text: widget.profile.email);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (username.isEmpty || email.isEmpty) {
      CustomNotification.show(context, 'Username and Email are required.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Assuming AuthService.updateProfile exists or we'll create it
      final updatedProfile = await AuthService.updateProfile(
        username: username,
        email: email,
        phone: phone,
      );
      if (!mounted) return;
      AgroAppScope.of(context).setProfile(updatedProfile);
      CustomNotification.show(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) CustomNotification.show(context, e.message);
    } catch (e) {
      if (mounted) CustomNotification.show(context, 'An error occurred. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _handleSave,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF00A36C),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A36C)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildField('Username', _usernameCtrl, Icons.person_outline),
            const SizedBox(height: 20),
            _buildField('Email Address', _emailCtrl, Icons.email_outlined,
                enabled: false), // Usually email is not editable directly
            const SizedBox(height: 20),
            _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined,
                keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = true, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00A36C)),
            filled: true,
            fillColor: enabled ? const Color(0xFFF5F6F8) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
