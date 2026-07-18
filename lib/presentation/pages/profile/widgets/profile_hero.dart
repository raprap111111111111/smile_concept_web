// lib/presentation/pages/profile/widgets/profile_hero.dart
import 'package:flutter/material.dart';

import '../../../../data/models/profile/profile_model.dart';
import 'info_card.dart';
import 'profile_theme.dart';

/// Identity header: avatar, name, email, and the role/status markers.
///
/// Deliberately flat — no gradient wash or decorative blobs. The page is a
/// record of who the account belongs to, so the data does the work.
class ProfileHero extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onEdit;

  const ProfileHero({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileTokens.card,
        borderRadius: BorderRadius.circular(ProfileTokens.radius),
        border: Border.all(color: ProfileTokens.border),
        boxShadow: ProfileTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this the avatar + text + button row gets cramped, so the
          // header stacks and centres instead.
          final isNarrow = constraints.maxWidth < 520;

          final avatar = _Avatar(profile: profile);
          final identity = _Identity(profile: profile, centered: isNarrow);
          final editButton = _EditButton(onPressed: onEdit);

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(height: 16),
                identity,
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: editButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(child: identity),
              const SizedBox(width: 16),
              editButton,
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final ProfileModel profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.profilePhotoUrl != null;
    final initial =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';

    return Semantics(
      label: hasPhoto ? 'Profile photo of ${profile.name}' : null,
      image: hasPhoto,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ProfileTokens.border, width: 1),
        ),
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(
          radius: 38,
          backgroundColor: ProfileTokens.brandSubtle,
          backgroundImage:
              hasPhoto ? NetworkImage(profile.profilePhotoUrl!) : null,
          child: hasPhoto
              ? null
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 30,
                    color: ProfileTokens.brandText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final ProfileModel profile;
  final bool centered;

  const _Identity({required this.profile, required this.centered});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: ProfileTokens.text,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: ProfileTokens.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            StatusPill(
              label: _titleCase(profile.role),
              foreground: ProfileTokens.brandText,
              background: ProfileTokens.brandSubtle,
              icon: Icons.shield_outlined,
            ),
            StatusPill(
              label: profile.isActive ? 'Active' : 'Inactive',
              foreground: profile.isActive
                  ? ProfileTokens.success
                  : ProfileTokens.neutral,
              background: profile.isActive
                  ? ProfileTokens.successSubtle
                  : ProfileTokens.neutralSubtle,
              icon: profile.isActive
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
            ),
            if (profile.isEmailVerified)
              const StatusPill(
                label: 'Email verified',
                foreground: ProfileTokens.brandText,
                background: ProfileTokens.brandSubtle,
                icon: Icons.verified_outlined,
              ),
          ],
        ),
      ],
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Labelled edit action. The previous icon-only square gave no hint at what
/// it did until hover, which is a problem on touch.
class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: const Text('Edit profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ProfileTokens.brandText,
        backgroundColor: ProfileTokens.card,
        side: const BorderSide(color: ProfileTokens.border),
        minimumSize: const Size(0, ProfileTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
        ),
      ).copyWith(
        // Hover/press tint only — no scale transform, so nothing shifts.
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return ProfileTokens.hover;
          }
          return ProfileTokens.card;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return const BorderSide(color: ProfileTokens.brand);
          }
          return const BorderSide(color: ProfileTokens.border);
        }),
      ),
    );
  }
}
