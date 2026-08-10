import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../providers/auth/permission_provider.dart';
import '../../providers/consent/patient_consents_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/error_display_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/consent_card.dart';
import 'widgets/sign_consent_dialog.dart';

class MyConsentsPage extends ConsumerWidget {
  const MyConsentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm       = ref.watch(permissionServiceProvider);
    final canSign    = perm.can(Perm.consentFormSign);
    final canViewAny = perm.can(Perm.consentFormViewAny);

    final consentsAsync =
        ref.watch(patientConsentsProvider(const PatientConsentsParams()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(canViewAny ? 'All Consent Forms' : 'My Consent Forms'),
        actions: [
          IconButton(
            icon: consentsAsync.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(patientConsentsProvider),
          ),
        ],
      ),

      // 🎯 FAB — Only shown if user can sign
      floatingActionButton: canSign
          ? FloatingActionButton.extended(
              onPressed: () => _onSignPressed(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Sign New Consent'),
            )
          : null,

      body: consentsAsync.when(
        loading: () => const LoadingWidget(
          message: 'Loading your consent forms...',
        ),
        error: (e, _) => ErrorDisplayWidget(
          error: e.toString(),
          onRetry: () => ref.invalidate(patientConsentsProvider),
        ),
        data: (result) {
          if (result.records.isEmpty) {
            return _buildEmpty(context, ref, canSign);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(patientConsentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              itemCount: result.records.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSmall),
              itemBuilder: (context, index) => ConsentCard(
                consent: result.records[index],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Empty state with sign CTA ───────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, WidgetRef ref, bool canSign) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text('No consent forms yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              canSign
                  ? 'Get started by signing a new consent form.'
                  : 'Signed consent forms will appear here.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (canSign) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              FilledButton.icon(
                onPressed: () => _onSignPressed(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Sign New Consent'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Handle sign button tap ──────────────────────────────────────────────
  // SignConsentDialog now has a built-in patient picker (Step 0),
  // so we simply open it — staff picks the patient inside the dialog.
  Future<void> _onSignPressed(BuildContext context, WidgetRef ref) async {
    final result = await SignConsentDialog.show(context);

    if (result == true) {
      ref.invalidate(patientConsentsProvider);
    }
  }
}