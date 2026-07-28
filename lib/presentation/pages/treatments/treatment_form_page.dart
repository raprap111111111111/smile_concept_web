// lib/presentation/pages/treatments/treatment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/treatment/treatment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class TreatmentFormPage extends ConsumerStatefulWidget {
  final int? treatmentId;

  const TreatmentFormPage({
    super.key,
    this.treatmentId,
  });

  @override
  ConsumerState<TreatmentFormPage> createState() => _TreatmentFormPageState();
}

class _TreatmentFormPageState extends ConsumerState<TreatmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isSubmitting = false;
  bool get _isEditing => widget.treatmentId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final duration = int.tryParse(_durationController.text.trim()) ?? 30;

      if (_isEditing) {
        await ref.read(treatmentProvider.notifier).updateTreatment(
              id: widget.treatmentId!,
              name: name,
              description: description,
              price: price,
              estimatedDurationMinutes: duration,
            );
      } else {
        await ref.read(treatmentProvider.notifier).createTreatment(
              name: name,
              description: description,
              price: price,
              estimatedDurationMinutes: duration,
            );
      }

      if (mounted) {
        _showSnack(
          _isEditing
              ? 'Treatment updated successfully'
              : 'Treatment created successfully',
          AppColors.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          children: [
            _SectionCard(
              children: [
                _SectionHeader(
                  icon: Icons.medical_services_rounded,
                  label: 'Basic Information',
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildNameField(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildDescriptionField(),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _SectionCard(
              children: [
                _SectionHeader(
                  icon: Icons.tune_rounded,
                  label: 'Pricing & Duration',
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPriceField()),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(child: _buildDurationField()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildSubmitButton(),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.divider),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Treatment' : 'New Treatment',
            style: AppTextStyles.titleLarge,
          ),
          Text(
            _isEditing
                ? 'Update treatment details'
                : 'Add a new treatment to your catalog',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingSmall),
            child: TextButton.icon(
              onPressed: _submit,
              icon: const Icon(
                Icons.check_rounded,
                size: AppDimensions.iconSizeSmall,
                color: AppColors.primary,
              ),
              label: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Treatment Name',
        hintText: 'e.g. Teeth Whitening',
        prefixIcon: const Icon(
          Icons.medical_services_rounded,
          size: AppDimensions.iconSizeMedium,
          color: AppColors.primary,
        ),
        suffixText: '*',
        suffixStyle: const TextStyle(color: AppColors.error),
      ),
      validator: (v) => (v == null || v.trim().isEmpty)
          ? 'Treatment name is required'
          : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Brief description of the treatment...',
        prefixIcon: Icon(
          Icons.description_rounded,
          size: AppDimensions.iconSizeMedium,
          color: AppColors.primary,
        ),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Price',
        hintText: '0.00',
        prefixIcon: Icon(
          Icons.payments_rounded,
          size: AppDimensions.iconSizeMedium,
          color: AppColors.primary,
        ),
        prefixText: '₱ ',
        suffixText: '*',
        suffixStyle: TextStyle(color: AppColors.error),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Price is required';
        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Duration',
        hintText: '30',
        prefixIcon: Icon(
          Icons.timer_rounded,
          size: AppDimensions.iconSizeMedium,
          color: AppColors.primary,
        ),
        suffixText: 'min',
      ),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
        child: _isSubmitting
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
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(
                    _isEditing ? 'Updating...' : 'Creating...',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: AppDimensions.iconSizeSmall),
                  const SizedBox(width: AppDimensions.paddingXS),
                  Text(
                    _isEditing ? 'Update Treatment' : 'Create Treatment',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconSizeSmall,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingXS),
        Text(label, style: AppTextStyles.titleSmall),
      ],
    );
  }
}