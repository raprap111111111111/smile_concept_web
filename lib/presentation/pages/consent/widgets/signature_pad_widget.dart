import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class SignaturePadWidget extends StatefulWidget {
  final double height;

  const SignaturePadWidget({super.key, this.height = 220});

  @override
  State<SignaturePadWidget> createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: AppColors.ink,
      exportBackgroundColor: AppColors.background,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isEmpty => _controller.isEmpty;

  Future<String?> exportBase64() async {
    if (_controller.isEmpty) return null;
    final Uint8List? bytes = await _controller.toPngBytes();
    if (bytes == null) return null;
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  void clear() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadius),
            child: Signature(
              controller: _controller,
              backgroundColor: AppColors.background,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: AppDimensions.iconSizeSmall,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.paddingXS),
                Text(
                  'Sign here with finger or stylus',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear'),
              onPressed: () => setState(() => _controller.clear()),
            ),
          ],
        ),
      ],
    );
  }
}