import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/permission_provider.dart';
import '../../route/auth_redirect.dart';
import '../../route/router_redirect.dart';
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
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// The emergency contact fields live inside a collapsed tile, so a
  /// validation error down there would otherwise be invisible.
  bool _emergencyExpanded = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // A collapsed ExpansionTile doesn't build its children, so the emergency
    // phone field isn't in the form and the form can't validate it. Check it
    // here, then open the section so the error is visible.
    final emergencyPhoneError =
        Validators.validatePhone(_emergencyPhoneController.text);
    if (emergencyPhoneError != null && !_emergencyExpanded) {
      setState(() => _emergencyExpanded = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _formKey.currentState?.validate(),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await ref.read(authStateProvider.notifier).register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
        );

    if (!mounted) return;

    // Navigating explicitly rather than leaning on the router's redirect: the
    // redirect only fires if the location is still /register when auth flips,
    // which is a race we don't need to depend on. Same destination logic as the
    // guard, so a patient lands on a page they can actually open.
    if (ref.read(authStateProvider).isAuthenticated) {
      context.go(
        postAuthDestination(
          ref.read(permissionServiceProvider),
          GoRouterState.of(context).uri.queryParameters,
        ),
      );
    }
  }

  /// Login URL that keeps whatever destination sent the user here.
  String _loginPath(BuildContext context) {
    final next = AuthRedirect.resolve(
      GoRouterState.of(context).uri.queryParameters,
    );
    return next == null ? '/login' : AuthRedirect.path('/login', next);
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
            _buildEmergencyContactSection(),
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
                onPressed: () => context.go(_loginPath(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optional emergency contact, tucked away so it doesn't lengthen the form
  /// for the people who skip it.
  Widget _buildEmergencyContactSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AuthDesign.line),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // The default tile paints its own dividers over the border above.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Rebuilding with a new key is how the tile gets opened from
          // _handleRegister when a hidden field fails validation.
          key: ValueKey(_emergencyExpanded),
          initiallyExpanded: _emergencyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _emergencyExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          iconColor: AuthDesign.primary,
          collapsedIconColor: AuthDesign.muted,
          leading: const Icon(
            Icons.contact_emergency_outlined,
            color: AuthDesign.muted,
            size: 20,
          ),
          title: const Text(
            'Emergency contact',
            style: TextStyle(
              color: AuthDesign.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text(
            'Optional — you can add this later',
            style: TextStyle(color: AuthDesign.muted, fontSize: 12.5),
          ),
          children: [
            AuthTextField(
              controller: _emergencyNameController,
              label: 'Contact name',
              hint: 'Jane Doe',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emergencyPhoneController,
              label: 'Contact phone',
              hint: '+1234567890',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.validatePhone,
              prefixIcon: Icons.phone_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
