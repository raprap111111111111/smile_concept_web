import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/auth/auth_provider.dart';
import '../../route/route_names.dart';
import 'auth_page_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authStateProvider.notifier).register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthPageScaffold(
      title: 'Create your account',
      subtitle:
          'Book visits faster and keep your SmileConcept dental information in one secure place.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 440;
                final firstName = AuthTextField(
                  controller: _firstNameController,
                  label: 'First name',
                  hint: 'John',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'First name'),
                  prefixIcon: Icons.person_outline,
                );
                final lastName = AuthTextField(
                  controller: _lastNameController,
                  label: 'Last name',
                  hint: 'Doe',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'Last name'),
                  prefixIcon: Icons.person_outline,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      firstName,
                      const SizedBox(height: 16),
                      lastName,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: firstName),
                    const SizedBox(width: 14),
                    Expanded(child: lastName),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: '+1234567890',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.validatePhone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a secure password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: Validators.validatePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              obscureText: _obscureConfirmPassword,
              validator: (v) => Validators.validateConfirmPassword(
                v,
                _passwordController.text,
              ),
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip:
                    _obscureConfirmPassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 18),
              AuthErrorMessage(message: authState.errorMessage!),
            ],
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Create account',
              loadingLabel: 'Creating account...',
              isLoading: authState.isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 22),
            Center(
              child: AuthSwitchPrompt(
                text: 'Already have an account?',
                action: 'Login',
                onPressed: () => context.goNamed(RouteNames.login),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
