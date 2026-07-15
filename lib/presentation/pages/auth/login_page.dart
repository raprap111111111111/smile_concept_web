// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'auth_page_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthPageScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in to manage appointments, patient records, prescriptions, and clinic updates.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              obscureText: _obscurePassword,
              validator: Validators.validatePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: null,
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              AuthErrorMessage(message: authState.errorMessage!),
            ],
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: 'Login',
              loadingLabel: 'Logging in...',
              isLoading: authState.isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 22),
            Center(
              child: AuthSwitchPrompt(
                text: "Don't have an account?",
                action: 'Create account',
                  onPressed: () {
                    debugPrint('success');
                    context.pushNamed(RouteNames.register);
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }
}