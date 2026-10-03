import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  LoginType _selectedAuthType = LoginType.firebase;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fName = _fNameController.text.trim();
    final lName = _lNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final contactNo = _contactNoController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success = false;

    if (_selectedAuthType == LoginType.firebase) {
      success = await userProvider.signUpWithFirebase(
        email: email,
        password: password,
        username: username,
        firstName: fName,
        lastName: lName,
        age: age,
        contactNo: contactNo,
      );
    } else {
      success = await userProvider.signUpWithDummyJson(
        username: username,
        email: email,
        password: password,
        firstName: fName,
        lastName: lName,
        age: age,
        contactNo: contactNo,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully (${_selectedAuthType == LoginType.firebase ? "Firebase" : "DummyJSON"})!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Join us today!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the required information to register.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),

                // Auth Platform Selector
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: const Center(child: Text('Firebase Auth')),
                          selected: _selectedAuthType == LoginType.firebase,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedAuthType = LoginType.firebase;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: const Center(child: Text('DummyJSON')),
                          selected: _selectedAuthType == LoginType.dummyJson,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedAuthType = LoginType.dummyJson;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // fName and lName row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _fNameController,
                        label: 'First Name',
                        hint: 'e.g. Francis',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) => AppValidators.validateRequired(val, 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _lNameController,
                        label: 'Last Name',
                        hint: 'e.g. Arillo',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) => AppValidators.validateRequired(val, 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // age and contactNo row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age',
                        hint: 'e.g. 25',
                        prefixIcon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        validator: AppValidators.validateAge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _contactNoController,
                        label: 'Contact No',
                        hint: '09754703724',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validateContactNo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // username
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'e.g. emilys',
                  prefixIcon: Icons.person_outline,
                  validator: AppValidators.validateUsername,
                ),
                const SizedBox(height: 16),

                // emailAddress
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'e.g. emily.johnson@x.dummyjson.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.validateEmail,
                ),
                const SizedBox(height: 16),

                // password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: AppValidators.validatePassword,
                ),
                const SizedBox(height: 16),

                // confirm password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-type password',
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Sign Up Button
                CustomButton(
                  text: _selectedAuthType == LoginType.firebase
                      ? 'Sign Up with Firebase'
                      : 'Sign Up with DummyJSON',
                  icon: Icons.person_add_alt_1,
                  isLoading: userProvider.isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
