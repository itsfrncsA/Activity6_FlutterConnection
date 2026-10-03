import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginType _selectedAuthType = LoginType.firebase;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoDummyJsonCredentials() {
    setState(() {
      _selectedAuthType = LoginType.dummyJson;
      _emailOrUsernameController.text = 'emilys';
      _passwordController.text = 'emilyspass';
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text;

    bool success = false;

    if (_selectedAuthType == LoginType.firebase) {
      success = await userProvider.signInWithFirebase(
        email: input,
        password: password,
      );
    } else {
      success = await userProvider.signInWithDummyJson(
        username: input,
        password: password,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, ${userProvider.user?.fullName ?? "User"}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Login failed. Please check your credentials.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with Firebase Auth or DummyJSON API',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auth Type Selector
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

                  // Input field
                  CustomTextField(
                    controller: _emailOrUsernameController,
                    label: _selectedAuthType == LoginType.firebase ? 'Email Address' : 'Username',
                    hint: _selectedAuthType == LoginType.firebase ? 'e.g. user@example.com' : 'e.g. emilys',
                    prefixIcon: _selectedAuthType == LoginType.firebase ? Icons.email_outlined : Icons.person_outline,
                    keyboardType: _selectedAuthType == LoginType.firebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    validator: (val) {
                      if (_selectedAuthType == LoginType.firebase) {
                        return AppValidators.validateEmail(val);
                      } else {
                        return AppValidators.validateUsername(val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: _selectedAuthType == LoginType.firebase
                        ? 'Sign In with Firebase'
                        : 'Sign In with DummyJSON',
                    icon: Icons.login,
                    isLoading: userProvider.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 12),

                  // Quick Demo Helper for DummyJSON
                  if (_selectedAuthType == LoginType.dummyJson) ...[
                    OutlinedButton.icon(
                      onPressed: _fillDemoDummyJsonCredentials,
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('Use DummyJSON Demo Account (emilys)'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Go to Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
