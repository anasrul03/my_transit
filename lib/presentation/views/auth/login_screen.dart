import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/password_visibility_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'signup_screen.dart';

/// Screen for user authentication (login)
/// 
/// This screen provides a form for users to sign in with their email
/// and password. It also offers options to sign up or continue as a guest.
/// Uses Riverpod for state management to comply with project standards.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  /// Controller for email input field
  final TextEditingController _emailController = TextEditingController();
  
  /// Controller for password input field
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login form submission
  /// 
  /// Validates the form, attempts to sign in with the provided credentials,
  /// and shows error messages if authentication fails.
  Future<void> _handleLogin() async {
    // Validate form before attempting login
    if (_formKey.currentState!.validate()) {
      final bool success = await ref.read(authStateProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

      // Navigation is handled by the router based on auth state
      if (success && mounted) {
        // Success - router will handle navigation
      } else if (mounted) {
        // Show error message if login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authStateProvider).error ?? 'Login failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles guest mode continuation
  /// 
  /// Allows users to use the app without creating an account.
  /// Navigation is handled by the router after guest user is created.
  Future<void> _handleGuestMode() async {
    await ref.read(authStateProvider.notifier).continueAsGuest();
    if (mounted) {
      // Navigation is handled by the router
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading indicators and error messages
    final authState = ref.watch(authStateProvider);
    
    // Watch password visibility state instead of using local setState
    final bool obscurePassword = !ref.watch(passwordVisibilityProvider).isVisible;

    return Scaffold(
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
                  // App title
                  Text(
                    'MyTransit',
                    style: AppTypography.heading1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Welcome message
                  Text(
                    'Welcome back',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
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
                  const SizedBox(height: AppSpacing.lg),
                  // Sign in button with loading state
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Navigation to sign up screen
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text('Don\'t have an account? Sign Up'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Guest mode button
                  OutlinedButton(
                    onPressed: authState.isLoading ? null : _handleGuestMode,
                    child: const Text('Continue as Guest'),
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

