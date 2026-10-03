import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userData;
  LoginType? _loginType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final data = await userService.value.getUserData();
    final type = await userService.value.getLoginType();
    if (mounted) {
      setState(() {
        _userData = data;
        _loginType = type;
        _isLoading = false;
      });
    }
  }

  void _showUpdateUsernameDialog() {
    final controller = TextEditingController(text: _userData?.username ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Update Username'),
          content: Form(
            key: formKey,
            child: CustomTextField(
              controller: controller,
              label: 'New Username',
              prefixIcon: Icons.person_outline,
              validator: AppValidators.validateUsername,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newUsername = controller.text.trim();
                Navigator.pop(dialogCtx);

                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final success = await userProvider.updateUsername(newUsername);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Username updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _fetchUserData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.errorMessage ?? 'Failed to update username'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    prefixIcon: Icons.lock_reset,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    prefixIcon: Icons.lock_reset,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Confirm password';
                      if (val != newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final curPass = currentPasswordController.text;
                final newPass = newPasswordController.text;
                final email = _userData?.email ?? '';
                Navigator.pop(dialogCtx);

                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final success = await userProvider.changePassword(
                  currentPassword: curPass,
                  newPassword: newPass,
                  email: email,
                );
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.errorMessage ?? 'Failed to change password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final emailController = TextEditingController(text: _userData?.email ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This action is irreversible. Please confirm your credentials to delete your account.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    label: 'Email / Username',
                    prefixIcon: Icons.email_outlined,
                    validator: (val) => AppValidators.validateRequired(val, 'Email / Username'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: passwordController,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final email = emailController.text.trim();
                final pass = passwordController.text;
                Navigator.pop(dialogCtx);

                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final success = await userProvider.deleteAccount(email: email, password: pass);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.errorMessage ?? 'Failed to delete account'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out? Session and tokens will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _fetchUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar & Name Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          UserAvatar(
                            imageUrl: _userData?.image,
                            fallbackName: _userData?.fullName ?? 'User',
                            radius: 46,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _userData?.fullName ?? 'Anonymous User',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${_userData?.username ?? "unknown"}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Login Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (_loginType == LoginType.firebase)
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_loginType == LoginType.firebase)
                                    ? Colors.amber.shade800
                                    : Colors.blue.shade700,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (_loginType == LoginType.firebase)
                                      ? Icons.local_fire_department
                                      : Icons.api,
                                  size: 16,
                                  color: (_loginType == LoginType.firebase)
                                      ? Colors.amber.shade900
                                      : Colors.blue.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (_loginType == LoginType.firebase)
                                      ? 'Login Type: Firebase Auth'
                                      : 'Login Type: DummyJSON API',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (_loginType == LoginType.firebase)
                                        ? Colors.amber.shade900
                                        : Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.email_outlined,
                            'Email Address',
                            _userData?.email.isNotEmpty == true ? _userData!.email : 'Not specified',
                          ),
                          _buildDetailRow(
                            Icons.badge_outlined,
                            'User ID / UID',
                            _userData?.id.isNotEmpty == true ? _userData!.id : 'N/A',
                          ),
                          if (_userData?.age != null)
                            _buildDetailRow(
                              Icons.calendar_today_outlined,
                              'Age',
                              '${_userData!.age} years old',
                            ),
                          if (_userData?.contactNo != null && _userData!.contactNo!.isNotEmpty)
                            _buildDetailRow(
                              Icons.phone_outlined,
                              'Contact Number',
                              _userData!.contactNo!,
                            ),
                          if (_userData?.gender != null && _userData!.gender!.isNotEmpty)
                            _buildDetailRow(
                              Icons.person_outline,
                              'Gender',
                              _userData!.gender!,
                            ),
                          if (_userData?.token != null)
                            _buildDetailRow(
                              Icons.key_outlined,
                              'Session Token',
                              '${_userData!.token!.substring(0, _userData!.token!.length > 16 ? 16 : _userData!.token!.length)}...',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Account Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Update Username',
                            icon: Icons.edit,
                            isOutlined: true,
                            onPressed: _showUpdateUsernameDialog,
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: 'Change Password',
                            icon: Icons.lock_reset,
                            isOutlined: true,
                            onPressed: _showChangePasswordDialog,
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: 'Delete Account',
                            icon: Icons.delete_forever,
                            backgroundColor: Colors.red.shade50,
                            textColor: Colors.red,
                            isOutlined: true,
                            onPressed: _showDeleteAccountDialog,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Logout Button
                          CustomButton(
                            text: 'Logout',
                            icon: Icons.logout,
                            backgroundColor: Colors.redAccent,
                            textColor: Colors.white,
                            onPressed: _handleLogout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
