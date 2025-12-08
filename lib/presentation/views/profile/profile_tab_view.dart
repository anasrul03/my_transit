import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Profile tab view that displays user account information in a Discord-style layout
/// 
/// This widget displays user profile information with a modern, card-based layout
/// including profile picture, name, username, member since date, and personal note.
/// It uses Riverpod for state management to comply with project standards and follows
/// Apple Human Interface Guidelines for spacing and touch targets.
class ProfileTabView extends ConsumerStatefulWidget {
  const ProfileTabView({super.key});

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  // Text editing controller for the personal note field
  // This allows us to manage the text input state for the user's personal note
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    // Dispose the text controller when the widget is disposed
    // This prevents memory leaks
    _noteController.dispose();
    super.dispose();
  }

  /// Generates a username from the user's email or ID
  /// 
  /// Extracts the username from email (part before @) or generates one from user ID.
  /// Returns a formatted username with @ prefix for display.
  String _generateUsername(String? email, String id) {
    // If email exists, extract the part before @
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }
    // Fallback: use first 8 characters of user ID
    return 'user_${id.substring(0, id.length > 8 ? 8 : id.length)}';
  }

  /// Formats a date as "MMM d, yyyy" (e.g., "Sep 2, 2025")
  /// 
  /// Uses the current date as a placeholder since we don't have signup date yet.
  String _formatMemberSinceDate() {
    // Use current date as placeholder - in future, this should come from user entity
    final now = DateTime.now();
    // Format date manually: "MMM d, yyyy" (e.g., "Sep 2, 2025")
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  /// Handles navigation to the edit profile/settings screen
  /// 
  /// Navigates to the settings screen where users can edit their profile information.
  void _handleEditProfile(BuildContext context) {
    // Navigate to settings screen using GoRouter
    context.push('/settings');
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to get current user information
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Generate username from email or user ID
    final String username = user != null
        ? _generateUsername(user.email, user.id)
        : 'guest';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section: Profile Picture, Name, Username, Edit Button
                  _buildHeaderSection(context, user, username, authState.isAuthenticated),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Information Cards Section
              if (authState.isAuthenticated) ...[
                // Member Since Card
                _buildMemberSinceCard(),
                const SizedBox(height: AppSpacing.md),
                // Note Card
                _buildNoteCard(),
              ] else ...[
                // Guest user message card
                _buildGuestUserCard(context),
              ],
              
              const SizedBox(height: AppSpacing.lg),
              
              // Footer Section: App name and version
                  const SizedBox(height: AppSpacing.xxl),
                  _buildFooterSection(),
                ],
              ),
            ),
            // Settings icon button positioned in top right corner
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.lg,
              child: _buildSettingsButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with profile picture, name, username, and edit button
  /// 
  /// This section displays the user's profile picture with online status indicator,
  /// their display name, username, and a prominent Edit Profile button.
  Widget _buildHeaderSection(
    BuildContext context,
    dynamic user,
    String username,
    bool isAuthenticated,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile picture with online status indicator
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Profile picture - circular avatar
              CircleAvatar(
                radius: 50, // 100px diameter, meets Apple HIG minimum touch target
                backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                child: user?.name != null
                    ? Text(
                        user!.name!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                      ),
              ),
              // Online status indicator - green dot at bottom-right
              if (isAuthenticated)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // User name with dropdown arrow icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.name ?? 'Guest User',
              style: AppTypography.heading1.copyWith(
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
            if (isAuthenticated) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ],
        ),
        
        const SizedBox(height: AppSpacing.xs),
        
        // Username with @ prefix
        Center(
          child: Text(
            '@$username',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Edit Profile button - full width, prominent
        SizedBox(
          height: 48, // Minimum 44pt for Apple HIG compliance
          child: ElevatedButton.icon(
            onPressed: isAuthenticated
                ? () => _handleEditProfile(context)
                : null,
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the Member Since card showing when the user joined
  /// 
  /// Displays the account creation date in a card format with an icon.
  Widget _buildMemberSinceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Calendar icon
            Icon(
              Icons.calendar_today,
              size: 24,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppSpacing.md),
            // Member since text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member Since',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatMemberSinceDate(),
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Note card with editable text field
  /// 
  /// Allows users to save a personal note that is only visible to them.
  Widget _buildNoteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 20,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Note (only visible to you)',
                  style: AppTypography.heading3.copyWith(
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Note text field
            TextField(
              controller: _noteController,
              maxLines: 4,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Add a personal note...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for guest users encouraging them to sign in
  /// 
  /// Shows a message explaining that certain features require authentication.
  Widget _buildGuestUserCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign In Required',
              style: AppTypography.heading3.copyWith(
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Info message
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 24,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Sign in to access all profile features and save your preferences',
                      style: AppTypography.body.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Sign In button
            SizedBox(
              height: 48, // Minimum 44pt for Apple HIG compliance
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the settings icon button
  /// 
  /// Displays a settings icon button in the top right corner that navigates
  /// to the settings screen. Meets Apple HIG minimum touch target requirements.
  Widget _buildSettingsButton(BuildContext context) {
    return SizedBox(
      width: 48, // Minimum 44pt for Apple HIG compliance
      height: 48, // Minimum 44pt for Apple HIG compliance
      child: IconButton(
        onPressed: () => _handleEditProfile(context),
        icon: const Icon(Icons.settings),
        iconSize: 24,
        color: Theme.of(context).iconTheme.color,
        tooltip: 'Settings',
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds the footer section with app name and version
  /// 
  /// Displays the app branding and version information at the bottom.
  Widget _buildFooterSection() {
    return Column(
      children: [
        Text(
          'MyTransit',
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Version 1.0.0',
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

