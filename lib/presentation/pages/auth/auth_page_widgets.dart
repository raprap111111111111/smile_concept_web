import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../route/route_names.dart';

class AuthDesign {
  AuthDesign._();

  static const ink = Color(0xFF12313A);
  static const muted = Color(0xFF5F7480);
  static const line = Color(0xFFDDE9ED);
  static const surface = Color(0xFFF7FBFC);
  static const primary = Color(0xFF0E8FA3);
  static const primaryDark = Color(0xFF096577);
  static const accent = Color(0xFF8BCBC1);
  static const error = Color(0xFFB42318);
}

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthDesign.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 18 : 32,
                vertical: isCompact ? 18 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AuthTopBar(isCompact: isCompact),
                      SizedBox(height: isCompact ? 24 : 34),
                      if (isCompact)
                        _AuthCard(
                          title: title,
                          subtitle: subtitle,
                          child: child,
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _AuthCard(
                                title: title,
                                subtitle: subtitle,
                                child: child,
                              ),
                            ),
                            const SizedBox(width: 28),
                            const Expanded(child: _ClinicPanel()),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: AuthDesign.ink,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AuthDesign.muted),
        hintStyle: const TextStyle(color: Color(0xFF91A4AD)),
        prefixIconColor: AuthDesign.primaryDark,
        suffixIconColor: AuthDesign.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: _border(AuthDesign.line),
        enabledBorder: _border(AuthDesign.line),
        focusedBorder: _border(AuthDesign.primary, width: 1.6),
        errorBorder: _border(AuthDesign.error),
        focusedErrorBorder: _border(AuthDesign.error, width: 1.6),
        errorStyle: const TextStyle(
          color: AuthDesign.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthDesign.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthDesign.primary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingLabel),
                ],
              )
            : Text(label),
      ),
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5B6AE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AuthDesign.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AuthDesign.error,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(color: AuthDesign.muted)),
        TextButton(
          onPressed: onPressed,
          child: Text(
            action,
            style: const TextStyle(
              color: AuthDesign.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/smile.jpg',
                height: 42,
                width: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SmileConcept',
              style: TextStyle(
                color: AuthDesign.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => context.goNamed(RouteNames.landing),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(isCompact ? 'Home' : 'Back to website'),
          style: TextButton.styleFrom(
            foregroundColor: AuthDesign.primaryDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuthDesign.line),
        boxShadow: [
          BoxShadow(
            color: AuthDesign.ink.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Pill(text: 'Secure patient access'),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AuthDesign.ink,
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: AuthDesign.muted,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _ClinicPanel extends StatelessWidget {
  const _ClinicPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 620,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AuthDesign.primaryDark),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1400',
                fit: BoxFit.cover,
              ),
              Container(color: AuthDesign.primaryDark.withValues(alpha: 0.72)),
              Padding(
                padding: const EdgeInsets.all(34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Dental care made easier before you arrive.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Manage appointments, treatment details, records, and clinic communication through one secure SmileConcept account.',
                      style: TextStyle(
                        color: Color(0xFFD7F1F3),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 26),
                    _PanelHighlights(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHighlights extends StatelessWidget {
  const _PanelHighlights();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _PanelChip(icon: Icons.calendar_month_outlined, label: 'Appointments'),
        _PanelChip(icon: Icons.verified_user_outlined, label: 'Secure records'),
        _PanelChip(icon: Icons.receipt_long_outlined, label: 'Billing'),
      ],
    );
  }
}

class _PanelChip extends StatelessWidget {
  const _PanelChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuthDesign.accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuthDesign.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AuthDesign.primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
