import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Integer field with -/+ steppers, clamped to [min]..[max].
///
/// Value flows down from the parent (the settings draft) and every change
/// flows back up through [onChanged] — no internal state beyond the text
/// controller, which is re-synced whenever the parent value moves.
class NumberStepperField extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? suffix;
  final String? helper;
  final String? errorText;
  final IconData? icon;

  const NumberStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.suffix,
    this.helper,
    this.errorText,
    this.icon,
  });

  @override
  State<NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<NumberStepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(NumberStepperField old) {
    super.didUpdateWidget(old);
    // Parent value changed (stepper tap, discard, reload): re-sync the text,
    // but never while the user is mid-edit in this exact field.
    if (old.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(int raw) {
    final clamped = raw.clamp(widget.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
    _controller.text = clamped.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.inputText,
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
          widget.onChanged(parsed);
        }
      },
      onEditingComplete: () {
        _commit(int.tryParse(_controller.text) ?? widget.value);
        FocusScope.of(context).unfocus();
      },
      onTapOutside: (_) {
        _commit(int.tryParse(_controller.text) ?? widget.value);
      },
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixText: widget.suffix,
        border: const OutlineInputBorder(),
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              enabled: widget.value > widget.min,
              onTap: () => _commit(widget.value - 1),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              enabled: widget.value < widget.max,
              onTap: () => _commit(widget.value + 1),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: enabled ? AppColors.primary : AppColors.textMuted,
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
      tooltip: null,
    );
  }
}
