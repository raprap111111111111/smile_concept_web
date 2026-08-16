import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/activity_log/activity_log_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class ActivityLogDetailDialog extends StatelessWidget {
  final ActivityLogModel log;

  const ActivityLogDetailDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.paddingLarge),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Details'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _DetailRow(
                          icon: Icons.person_outline,
                          label: 'User',
                          value: log.userName ?? 'System'),
                      _DetailRow(
                          icon: Icons.bolt_outlined,
                          label: 'Action',
                          value: log.action ?? '—'),
                      _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Subject',
                          value: log.subjectLabel),
                      if (log.description != null &&
                          log.description!.isNotEmpty)
                        _DetailRow(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          value: log.description!,
                        ),
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: 'Timestamp',
                        value: log.createdAt != null
                            ? DateFormat('MMM d, y • h:mm:ss a')
                                .format(log.createdAt!)
                            : '—',
                        isLast: log.ipAddress == null &&
                            log.userAgent == null &&
                            log.url == null,
                      ),
                    ]),

                    if (log.ipAddress != null ||
                        log.userAgent != null ||
                        log.url != null) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Request Info'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        if (log.ipAddress != null)
                          _DetailRow(
                            icon: Icons.wifi,
                            label: 'IP Address',
                            value: log.ipAddress!,
                            mono: true,
                          ),
                        if (log.userAgent != null)
                          _DetailRow(
                            icon: Icons.devices_outlined,
                            label: 'User Agent',
                            value: log.userAgent!,
                          ),
                        if (log.url != null)
                          _DetailRow(
                            icon: Icons.link,
                            label: 'URL',
                            value: log.url!,
                            mono: true,
                            isLast: true,
                          ),
                      ]),
                    ],

                    if (log.properties != null &&
                        log.properties!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildSectionTitle('Properties'),
                          const Spacer(),
                          _CopyButton(
                            data: _prettyJson(log.properties!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildJsonCard(log.properties!),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const Icon(Icons.history,
                color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.displayAction, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text('Activity #${log.id}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─── Footer ──────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildJsonCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: SelectableText(
        _prettyJson(data),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Color(0xFFE0E0E0),
          height: 1.5,
        ),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> map) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (_) {
      return map.toString();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Detail Row
// ══════════════════════════════════════════════════════════════════════════
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: mono
                  ? const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    )
                  : AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Copy Button
// ══════════════════════════════════════════════════════════════════════════
class _CopyButton extends StatefulWidget {
  final String data;

  const _CopyButton({required this.data});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.data));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 14,
        color: _copied ? AppColors.success : AppColors.textSecondary,
      ),
      label: Text(
        _copied ? 'Copied!' : 'Copy',
        style: AppTextStyles.labelSmall.copyWith(
          color: _copied ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      onPressed: _copy,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}