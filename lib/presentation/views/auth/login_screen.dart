import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// 
/// Design follows Apple Human Interface Guidelines with:
/// - Proper typography scale (Title 1, Body, Callout, etc.)
/// - Minimum 44pt touch targets for all interactive elements
/// - Proper spacing and visual hierarchy
/// - Enhanced accessibility and user feedback
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
  
  /// Focus node for email field
  final FocusNode _emailFocusNode = FocusNode();
  
  /// Focus node for password field
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    // Clean up text controllers and focus nodes to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Handles the login form submission
  /// 
  /// Validates the form, attempts to sign in with the provided credentials,
  /// and shows success or error messages based on the authentication result.
  Future<void> _handleLogin() async {
    // Unfocus any active text fields to dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form before attempting login
    if (_formKey.currentState!.validate()) {
      final bool success = await ref.read(authStateProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

      // Check auth state for success or error messages
      if (mounted) {
        final authState = ref.read(authStateProvider);
        
        if (success && authState.successMessage != null) {
          // Show success message with green background
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.successMessage!),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          // Navigation is handled by the router based on auth state
        } else if (authState.error != null) {
          // Show error message if login failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
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
    
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double maxWidth = screenSize.width > 600 ? 500 : screenSize.width;
    
    // Calculate proper padding based on screen size
    final double horizontalPadding = screenSize.width > 600 ? 40.0 : AppSpacing.lg;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Add padding to prevent content from being hidden by keyboard
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App title - Title 1 per Apple HIG (34pt, bold)
                    Text(
                      'MyTransit',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.2,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Welcome message - Subhead per Apple HIG (15pt, regular)
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    // Form container with card background
                    Card(
                      color: Theme.of(context).cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email input field
                            // Minimum 56pt height for better touch target
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) {
                                // Move focus to password field when user presses next
                                _passwordFocusNode.requestFocus();
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                // Ensure minimum height of 56pt
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                // Better border styling
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 17, // Body per Apple HIG
                                color: Colors.white,
                              ),
                              validator: (String? value) {
                                // Validate email is not empty
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                // Basic email format validation
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Password input field with visibility toggle
                            // Minimum 56pt height for better touch target
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) {
                                // Submit form when user presses done
                                _handleLogin();
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // Toggle password visibility using Riverpod provider
                                    ref.read(passwordVisibilityProvider.notifier).toggle();
                                  },
                                  // Ensure touch target is at least 44pt
                                  padding: const EdgeInsets.all(12),
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                                // Ensure minimum height of 56pt
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                // Better border styling
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                labelStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 17, // Body per Apple HIG
                                color: Colors.white,
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
                            
                            // Sign in button - Primary action
                            // Minimum 44pt height per Apple HIG
                            SizedBox(
                              height: 50, // Slightly larger than 44pt for better UX
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  // Disabled state styling
                                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 17, // Body per Apple HIG
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Navigation to sign up screen - Secondary action
                    // Minimum 44pt height per Apple HIG
                    SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => const SignUpScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 17, // Body per Apple HIG
                              color: Colors.white70,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Divider with "or" text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 15, // Subhead per Apple HIG
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Guest mode button - Tertiary action
                    // Minimum 44pt height per Apple HIG
                    SizedBox(
                      height: 50, // Slightly larger than 44pt for better UX
                      child: OutlinedButton(
                        onPressed: authState.isLoading ? null : _handleGuestMode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // Disabled state styling
                          disabledForegroundColor: Colors.white.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: 17, // Body per Apple HIG
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
