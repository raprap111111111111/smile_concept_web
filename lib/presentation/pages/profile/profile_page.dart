// lib/presentation/pages/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile/profile_provider.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/medical_info_card.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_theme.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  /// Cards stack below this width; above it the account and medical cards
  /// sit side by side.
  static const double _twoColumnBreakpoint = 780;
  static const double _maxContentWidth = 960;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadProfile();
    });
  }

  Future<void> _openEditDialog() async {
    final profile = ref.read(profileNotifierProvider).profile;
    if (profile == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditProfileDialog(profile: profile),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Profile updated'),
            ],
          ),
          backgroundColor: ProfileTokens.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _refresh() {
    return ref
        .read(profileNotifierProvider.notifier)
        .loadProfile(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);

    // The app root is still ThemeData.dark(); this subtree opts into light so
    // Material-owned surfaces don't render dark text on light cards.
    return Theme(
      data: buildProfileTheme(context),
      child: Scaffold(
        backgroundColor: ProfileTokens.canvas,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: ProfileTokens.brand,
          backgroundColor: ProfileTokens.card,
          child: _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(ProfileState state) {
    if (state.isLoading && state.profile == null) {
      return const _ProfileSkeleton();
    }

    if (state.error != null && state.profile == null) {
      return _ErrorView(message: state.error!, onRetry: _refresh);
    }

    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    final showMedical = profile.isPatient && profile.patientProfile != null;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: _PageFrame(
        maxWidth: _maxContentWidth,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn =
                showMedical && constraints.maxWidth >= _twoColumnBreakpoint;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PageTitle(),
                const SizedBox(height: 18),
                ProfileHero(profile: profile, onEdit: _openEditDialog),
                const SizedBox(height: 16),
                if (twoColumn)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ProfileInfoCard(profile: profile)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MedicalInfoCard(
                          patientProfile: profile.patientProfile!,
                        ),
                      ),
                    ],
                  )
                else ...[
                  ProfileInfoCard(profile: profile),
                  if (showMedical) ...[
                    const SizedBox(height: 16),
                    MedicalInfoCard(
                      patientProfile: profile.patientProfile!,
                    ),
                  ],
                ],
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Centres and pads page content to a consistent measure.
class _PageFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const _PageFrame({required this.child, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
          child: child,
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My profile',
          style: TextStyle(
            color: ProfileTokens.text,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Your account details and how the clinic can reach you.',
          style: TextStyle(
            color: ProfileTokens.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Placeholder blocks matching the real layout, so nothing jumps when the
/// profile lands.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: _PageFrame(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SkeletonBox(height: 28, width: 180),
            SizedBox(height: 10),
            _SkeletonBox(height: 16, width: 300),
            SizedBox(height: 22),
            _SkeletonBox(height: 138),
            SizedBox(height: 16),
            _SkeletonBox(height: 320),
            SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;

  const _SkeletonBox({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: ProfileTokens.subtle,
        borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
        border: Border.all(color: ProfileTokens.border),
      ),
    );

    // Parent column stretches its children; a fixed-width box needs to opt
    // out of that or it gets forced to full width.
    if (width == null) return box;
    return Align(alignment: Alignment.centerLeft, child: box);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Stays scrollable so pull-to-refresh still works in the error state.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: ProfileTokens.dangerSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_outlined,
                          size: 26,
                          color: ProfileTokens.danger,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "We couldn't load your profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ProfileTokens.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ProfileTokens.textMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try again'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ProfileTokens.brand,
                          foregroundColor: Colors.white,
                          minimumSize:
                              const Size(0, ProfileTokens.minTouchTarget),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ProfileTokens.radiusSm,
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
        );
      },
    );
  }
}
