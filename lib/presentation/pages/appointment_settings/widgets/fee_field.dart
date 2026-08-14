import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_text_styles.dart';

/// Peso amount field. Same value-down / change-up contract as
/// NumberStepperField, but for money (two decimals).
class FeeField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? helper;
  final String? errorText;

  const FeeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.errorText,
  });

  @override
  State<FeeField> createState() => _FeeFieldState();
}

class _FeeFieldState extends State<FeeField> {
  late final TextEditingController _controller;

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(FeeField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        double.tryParse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}(\.\d{0,2})?$')),
      ],
      style: AppTextStyles.inputText,
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null && parsed >= 0) widget.onChanged(parsed);
      },
      onTapOutside: (_) {
        final parsed = double.tryParse(_controller.text) ?? widget.value;
        _controller.text = _format(parsed);
        widget.onChanged(parsed);
      },
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 3,
        prefixText: '₱ ',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
