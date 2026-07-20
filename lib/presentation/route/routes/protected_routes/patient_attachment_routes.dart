// lib/presentation/route/routes/protected_routes/patient_attachment_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/data/models/patient_attachment/patient_with_attachments.dart';
import '../../../pages/patient_attachments/patient_attachment_list_page.dart';
import '../../../pages/patient_attachments/patient_attachment_create_page.dart';
import '../../../pages/patient_attachments/patient_attachment_detail_page.dart';
import '../../../pages/patient_attachments/patient_folders_page.dart';
import '../../route_names.dart';
import '../../page_transitions.dart';

final List<RouteBase> patientAttachmentRoutes = [
  // ═══════════════════════════════════════════════════════
  // Patient Folders (main entry point) — fade-through
  // ═══════════════════════════════════════════════════════
  GoRoute(
    path: '/patient-folders',
    name: RouteNames.patientFolders,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const PatientFoldersPage(),
    ),
    routes: [
      // ── Folder detail: no transition ──────────────────
      GoRoute(
        path: ':userId',
        name: RouteNames.patientAttachmentsByPatient,
        pageBuilder: (context, state) {
          final userId =
              int.tryParse(state.pathParameters['userId'] ?? '') ?? 0;
          final patient = state.extra as PatientWithAttachments?;

          return NoTransitionPage(
            child: PatientAttachmentListPage(
              filterUserId: userId,
              patientName: patient?.name,
            ),
          );
        },
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════
  // All Attachments — fade-through
  // ═══════════════════════════════════════════════════════
  GoRoute(
    path: '/patient-attachments',
    name: RouteNames.patientAttachments,
    pageBuilder: (context, state) => FadeThroughPage(
      key: state.pageKey,
      child: const PatientAttachmentListPage(),
    ),
    routes: [
      // ── Upload: no transition ─────────────────────────
      GoRoute(
        path: 'upload',
        name: RouteNames.attachmentUpload,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PatientAttachmentCreatePage(),
        ),
      ),

      // ── Detail: no transition ─────────────────────────
      GoRoute(
        path: ':id',
        name: RouteNames.patientAttachmentDetail,
        pageBuilder: (context, state) {
          final attachment = state.extra as PatientAttachment?;

          if (attachment == null) {
            return NoTransitionPage(
              child: _AttachmentFallbackPage(
                id: state.pathParameters['id'] ?? '',
              ),
            );
          }

          return NoTransitionPage(
            child: PatientAttachmentDetailPage(attachment: attachment),
          );
        },
      ),
    ],
  ),
];

// ── Fallback for direct URL / bookmark ────────────────────
class _AttachmentFallbackPage extends StatelessWidget {
  final String id;

  const _AttachmentFallbackPage({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title:
            Text('Attachment #$id', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Attachment not available',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Please open this from the attachments list',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            OutlinedButton.icon(
              onPressed: () =>
                  context.goNamed(RouteNames.patientAttachments),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Attachments'),
            ),
          ],
        ),
      ),
    );
  }
}