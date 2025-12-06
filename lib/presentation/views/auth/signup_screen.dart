import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/password_visibility_provider.dart';
import '../../providers/confirm_password_visibility_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Screen for user registration (sign up)
/// 
/// This screen provides a form for users to create a new account with
/// email, password, and optional name. It validates password matching
/// and uses Riverpod for state management to comply with project standards.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  /// Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  /// Controller for name input field (optional)
  final TextEditingController _nameController = TextEditingController();
  
  /// Controller for email input field
  final TextEditingController _emailController = TextEditingController();
  
  /// Controller for password input field
  final TextEditingController _passwordController = TextEditingController();
  
  /// Controller for confirm password input field
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the sign up form submission
  /// 
  /// Validates the form, attempts to create a new account with the provided
  /// credentials, and shows error messages if registration fails.
  Future<void> _handleSignUp() async {
    // Validate form before attempting sign up
    if (_formKey.currentState!.validate()) {
      final bool success = await ref.read(authStateProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );

      // Navigation is handled by the router based on auth state
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        // Show error message if sign up failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authStateProvider).error ?? 'Sign up failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading indicators and error messages
    final authState = ref.watch(authStateProvider);
    
    // Watch password visibility states instead of using local setState
    final bool obscurePassword = !ref.watch(passwordVisibilityProvider).isVisible;
    final bool obscureConfirmPassword = !ref.watch(confirmPasswordVisibilityProvider).isVisible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Screen title
                  Text(
                    'Create Account',
                    style: AppTypography.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Name input field (optional)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name (Optional)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Email input field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (String? value) {
                      // Validate email is not empty
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      // Basic email format validation
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Password input field with visibility toggle
                  TextFormField(
                    controller: _passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          // Toggle password visibility using Riverpod provider
                          ref.read(passwordVisibilityProvider.notifier).toggle();
                        },
                      ),
                    ),
                    validator: (String? value) {
                      // Validate password is not empty
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      // Validate minimum password length
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Confirm password input field with visibility toggle
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          // Toggle confirm password visibility using Riverpod provider
                          ref.read(confirmPasswordVisibilityProvider.notifier).toggle();
                        },
                      ),
                    ),
                    validator: (String? value) {
                      // Validate confirm password is not empty
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      // Validate passwords match
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Sign up button with loading state
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSignUp,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Navigation back to login screen
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign In'),
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

