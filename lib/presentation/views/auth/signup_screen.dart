import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// 
/// Design follows Apple Human Interface Guidelines with:
/// - Proper typography scale (Title 2, Body, Callout, etc.)
/// - Minimum 44pt touch targets for all interactive elements
/// - Proper spacing and visual hierarchy
/// - Enhanced accessibility and user feedback
/// - Password strength validation
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
  
  /// Focus node for name field
  final FocusNode _nameFocusNode = FocusNode();
  
  /// Focus node for email field
  final FocusNode _emailFocusNode = FocusNode();
  
  /// Focus node for password field
  final FocusNode _passwordFocusNode = FocusNode();
  
  /// Focus node for confirm password field
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    // Clean up text controllers and focus nodes to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Calculates password strength based on length and complexity
  /// 
  /// Returns: A value between 0.0 and 1.0 representing password strength
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length factor (up to 0.4)
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    
    // Complexity factors (up to 0.6)
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;
    
    return strength.clamp(0.0, 1.0);
  }

  /// Gets password strength label
  /// 
  /// Returns: Human-readable strength label
  String _getPasswordStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }

  /// Gets password strength color
  /// 
  /// Returns: Color representing password strength
  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow;
    return Colors.green;
  }

  /// Handles the sign up form submission
  /// 
  /// Validates the form, attempts to create a new account with the provided
  /// credentials, and shows success or error messages based on the registration result.
  Future<void> _handleSignUp() async {
    // Unfocus any active text fields to dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form before attempting sign up
    if (_formKey.currentState!.validate()) {
      final bool success = await ref.read(authStateProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
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
          
          // If user is automatically signed in (email confirmation disabled),
          // the router will automatically redirect to home screen
          // If user needs to confirm email, navigate back to login screen
          if (authState.isAuthenticated) {
            // User is signed in, router will handle navigation
            // Don't pop - let the router redirect to home
          } else {
            // User needs to confirm email, navigate back to login screen
            Navigator.pop(context);
          }
        } else if (authState.error != null) {
          // Show error message if sign up failed
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

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading indicators and error messages
    final authState = ref.watch(authStateProvider);
    
    // Watch password visibility states instead of using local setState
    final bool obscurePassword = !ref.watch(passwordVisibilityProvider).isVisible;
    final bool obscureConfirmPassword = !ref.watch(confirmPasswordVisibilityProvider).isVisible;
    
    // Calculate password strength
    final double passwordStrength = _calculatePasswordStrength(_passwordController.text);
    final String strengthLabel = _getPasswordStrengthLabel(passwordStrength);
    final Color strengthColor = _getPasswordStrengthColor(passwordStrength);
    
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double maxWidth = screenSize.width > 600 ? 500 : screenSize.width;
    
    // Calculate proper padding based on screen size
    final double horizontalPadding = screenSize.width > 600 ? 40.0 : AppSpacing.lg;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                    // Screen title - Title 2 per Apple HIG (28pt, bold)
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            height: 1.2,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Subtitle - Subhead per Apple HIG (15pt, regular)
                    Text(
                      'Sign up to save your favorites and preferences',
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
                            // Name input field (optional)
                            // Minimum 56pt height for better touch target
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              onFieldSubmitted: (_) {
                                // Move focus to email field when user presses next
                                _emailFocusNode.requestFocus();
                              },
                              decoration: InputDecoration(
                                labelText: 'Name (Optional)',
                                hintText: 'Enter your name',
                                prefixIcon: const Icon(Icons.person_outlined),
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
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Email input field
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
                            
                            // Password input field with visibility toggle and strength indicator
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) {
                                // Move focus to confirm password field when user presses next
                                _confirmPasswordFocusNode.requestFocus();
                              },
                              onChanged: (_) {
                                // Update password strength indicator
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a password',
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
                            
                            // Password strength indicator (only show when password is being entered)
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Strength bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: passwordStrength,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  // Strength label
                                  Text(
                                    'Password strength: $strengthLabel',
                                    style: TextStyle(
                                      fontSize: 12, // Caption 1 per Apple HIG
                                      color: strengthColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: AppSpacing.md),
                            
                            // Confirm password input field with visibility toggle
                            TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) {
                                // Submit form when user presses done
                                _handleSignUp();
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // Toggle confirm password visibility using Riverpod provider
                                    ref.read(confirmPasswordVisibilityProvider.notifier).toggle();
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
                            
                            // Sign up button - Primary action
                            // Minimum 44pt height per Apple HIG
                            SizedBox(
                              height: 50, // Slightly larger than 44pt for better UX
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _handleSignUp,
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
                                        'Sign Up',
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
                    
                    // Navigation back to login screen - Secondary action
                    // Minimum 44pt height per Apple HIG
                    SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
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
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
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
                  ],
                ),
              ),
            ),
          ),
        ),
            // Back button positioned at top-left
            // This allows users to navigate back to the login screen
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                // Ensure minimum 44pt touch target per Apple HIG
                padding: const EdgeInsets.all(AppSpacing.sm),
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
