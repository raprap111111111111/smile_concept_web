// lib/presentation/pages/patient_attachments/patient_attachment_create_page.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/presentation/providers/patient_attachment/patient_attachment_provider.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import 'widgets/patient_selector_field.dart'; // ✅ NEW

class PatientAttachmentCreatePage extends ConsumerStatefulWidget {
  /// Optional pre-selected patient (e.g. when uploading from patient's folder)
  final int? initialUserId;

  const PatientAttachmentCreatePage({super.key, this.initialUserId});

  @override
  ConsumerState<PatientAttachmentCreatePage> createState() =>
      _PatientAttachmentCreatePageState();
}

class _PatientAttachmentCreatePageState
    extends ConsumerState<PatientAttachmentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _fileNameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedUserId; // ✅ NEW
  String _category = 'other';
  bool _isXray = false;
  bool _isSubmitting = false;

  PlatformFile? _pickedFile;

  static const _categories = [
    ('X-Ray', 'xray'),
    ('Photo', 'photo'),
    ('Consent Form', 'consent_form'),
    ('Treatment Plan', 'treatment_plan'),
    ('Lab Report', 'lab_report'),
    ('Prescription', 'prescription'),
    ('Referral', 'referral'),
    ('Other', 'other'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialUserId; // ✅ pre-fill if provided
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Upload Attachment', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ UPLOAD AREA ═══
              _buildUploadArea(),

              const SizedBox(height: AppDimensions.paddingLarge),

              // ═══ ✅ PATIENT SELECTOR ═══
              PatientSelectorField(
                selectedUserId: _selectedUserId,
                onChanged: (id) => setState(() => _selectedUserId = id),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // ═══ FILE NAME ═══
              _buildLabel('File Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Panoramic X-Ray Jan 2025',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'File name is required' : null,
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // ═══ CATEGORY ═══
              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c.$2, child: Text(c.$1)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _category = v ?? 'other';
                    _isXray = _category == 'xray';
                  });
                },
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // ═══ AI SCAN TOGGLE (only for X-rays) ═══
              if (_category == 'xray') ...[
                _buildAiScanToggle(),
                const SizedBox(height: AppDimensions.paddingMedium),
              ],

              // ═══ NOTES ═══
              _buildLabel('Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add any relevant notes...',
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // ═══ SUBMIT ═══
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isXray
                          ? 'Upload & Start AI Scan'
                          : 'Upload Attachment'),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Scan Toggle ────────────────────────────────────────
  Widget _buildAiScanToggle() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: AppColors.info, size: 24),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI X-Ray Analysis',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.info)),
                Text('Automatically detect dental conditions',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _isXray,
            onChanged: (v) => setState(() => _isXray = v),
            activeColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  // ─── Upload Area ───────────────────────────────────────────
  Widget _buildUploadArea() {
    final hasFile = _pickedFile != null;

    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(
            color: hasFile
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_outline
                    : Icons.cloud_upload_outlined,
                size: 40,
                color: hasFile ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            if (hasFile) ...[
              Text('File Selected',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.success)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _pickedFile!.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatFileSize(_pickedFile!.size)} • '
                '${_pickedFile!.extension?.toUpperCase() ?? "FILE"}',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text('Tap to change file',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted)),
            ] else ...[
              Text('Tap to select file',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('JPG, PNG, PDF, DICOM supported',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
    );
  }

  // ─── Pick file ─────────────────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'dcm'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;

          if (_fileNameController.text.isEmpty) {
            _fileNameController.text =
                _pickedFile!.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }

          final lower = _pickedFile!.name.toLowerCase();
          if (lower.contains('xray') ||
              lower.contains('x-ray') ||
              lower.contains('pano')) {
            _category = 'xray';
            _isXray = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to pick file: $e');
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Submit ────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validate patient selected
    if (_selectedUserId == null) {
      _showError('Please select a patient');
      return;
    }

    if (_pickedFile == null) {
      _showWarning('Please select a file first');
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(patientAttachmentProvider.notifier)
        .create(
          userId: _selectedUserId!, // ✅ dynamic now
          file: _pickedFile!,
          fileName: _fileNameController.text.trim(),
          category: _category,
          isXray: _isXray,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _isXray
                    ? 'Uploaded! AI scan started...'
                    : 'Attachment uploaded successfully',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
      );
    } else {
      final error = ref.read(patientAttachmentProvider).error;
      _showError(error ?? 'Upload failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
    );
  }
}