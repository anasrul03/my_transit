import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Settings screen for user account management
/// 
/// This screen displays user information and provides options to manage
/// the account, including signing out. It uses Riverpod for state management
/// to comply with project standards.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Handles the logout action
  /// 
  /// Shows a confirmation dialog before signing out, then calls the
  /// signOut method from the auth provider. Navigation back to login
  /// is handled automatically by the router when auth state changes.
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog before logging out
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            // Cancel button - closes dialog without logging out
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            // Confirm button - proceeds with logout
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    // Only proceed with logout if user confirmed
    if (shouldLogout == true && context.mounted) {
      // Show success message before calling signOut since state will be cleared
      // This provides immediate feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Call signOut from auth provider
      await ref.read(authStateProvider.notifier).signOut();
      
      // Show error message if logout failed (state won't be cleared on error)
      if (context.mounted) {
        final authState = ref.read(authStateProvider);
        if (authState.error != null) {
          // Clear the success message we just showed since there was an error
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to get current user information
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    // Watch theme mode to show current selection
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Appearance section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Text(
                        'Appearance',
                        style: AppTypography.heading3.copyWith(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Theme mode selector
                      Text(
                        'Theme',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Light mode option
                      RadioListTile<ThemeMode>(
                        title: Row(
                          children: [
                            const Icon(Icons.light_mode, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Light',
                              style: AppTypography.body.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        value: ThemeMode.light,
                        groupValue: currentThemeMode,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          }
                        },
                      ),
                      // Dark mode option
                      RadioListTile<ThemeMode>(
                        title: Row(
                          children: [
                            const Icon(Icons.dark_mode, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Dark',
                              style: AppTypography.body.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        value: ThemeMode.dark,
                        groupValue: currentThemeMode,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          }
                        },
                      ),
                      // System mode option
                      RadioListTile<ThemeMode>(
                        title: Row(
                          children: [
                            const Icon(Icons.brightness_auto, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'System',
                              style: AppTypography.body.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Follow device settings',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        value: ThemeMode.system,
                        groupValue: currentThemeMode,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // User information section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Text(
                        'Account Information',
                        style: AppTypography.heading3.copyWith(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // User email display
                      if (user?.email != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.email, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                user!.email!,
                                style: AppTypography.body.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      // User name display (if available)
                      if (user?.name != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                user!.name!,
                                style: AppTypography.body.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      // Guest user indicator
                      if (user?.isGuest == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Guest User',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Sign In CTA button for guest users
              // This encourages guests to create an account to access full features
              if (authState.isGuest || !authState.isAuthenticated) ...[
                SizedBox(
                  height: 50, // Minimum 44pt height for better UX
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to login screen using GoRouter
                      context.go('/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              // Logout button section
              // Only show logout button for authenticated users (not guests)
              if (authState.isAuthenticated) ...[
                ElevatedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleLogout(context, ref),
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ],
              // App version section (optional)
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'MyTransit',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Version 1.0.0',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

