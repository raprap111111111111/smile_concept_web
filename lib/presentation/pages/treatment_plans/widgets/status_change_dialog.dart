// lib/presentation/pages/treatment_plans/widgets/status_change_dialog.dart

import 'package:flutter/material.dart';

/// Mirrors the backend state machine in TreatmentPlanStatus enum.
/// Keep in sync with allowedTransitions() on the server.
class _StatusOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _StatusOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _allStatuses = <_StatusOption>[
  _StatusOption(
    value: 'draft',
    label: 'Draft',
    description: 'Editable, not shown to patient',
    icon: Icons.edit_note,
    color: Colors.grey,
  ),
  _StatusOption(
    value: 'proposed',
    label: 'Proposed',
    description: 'Ready to present to the patient',
    icon: Icons.assignment_outlined,
    color: Colors.blue,
  ),
  _StatusOption(
    value: 'accepted',
    label: 'Accepted',
    description: 'Patient agreed to proceed',
    icon: Icons.check_circle_outline,
    color: Colors.green,
  ),
  _StatusOption(
    value: 'completed',
    label: 'Completed',
    description: 'All treatment steps finished',
    icon: Icons.task_alt,
    color: Colors.teal,
  ),
  _StatusOption(
    value: 'rejected',
    label: 'Rejected',
    description: 'Patient declined the plan',
    icon: Icons.cancel_outlined,
    color: Colors.red,
  ),
];

// Same rules as backend enum
const _transitions = <String, List<String>>{
  'draft':     ['proposed', 'rejected'],
  'proposed':  ['accepted', 'rejected', 'draft'],
  'accepted':  ['completed', 'rejected'],
  'rejected':  ['draft'],
  'completed': [], // terminal
};

/// Returns `{status, reason}` on confirm, or null on cancel.
class StatusChangeDialog extends StatefulWidget {
  final String currentStatus;
  const StatusChangeDialog({super.key, required this.currentStatus});

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  String? _selected;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  _StatusOption get _currentOpt =>
      _allStatuses.firstWhere((o) => o.value == widget.currentStatus,
          orElse: () => _allStatuses.first);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowedValues = _transitions[widget.currentStatus] ?? const [];
    final options =
        _allStatuses.where((o) => allowedValues.contains(o.value)).toList();
    final isTerminal = options.isEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _currentOpt.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_currentOpt.icon,
                        color: _currentOpt.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Change Plan Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          'Current: ${_currentOpt.label}',
                          style: TextStyle(
                              fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                color:
                    theme.colorScheme.outline.withValues(alpha: 0.15)),

            // ── Body ───────────────────────────────
            if (isTerminal)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 44, color: theme.hintColor),
                    const SizedBox(height: 12),
                    const Text(
                      'Status is locked',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${_currentOpt.label}" is a terminal state and cannot be changed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: theme.hintColor),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Text(
                  'Choose the new status:',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 68,
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.1)),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    final isSelected = _selected == o.value;
                    return InkWell(
                      onTap: () => setState(() => _selected = o.value),
                      child: Container(
                        color: isSelected
                            ? o.color.withValues(alpha: 0.08)
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    o.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(o.icon,
                                  color: o.color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    o.description,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.hintColor),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? o.color
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? o.color
                                      : theme.hintColor
                                          .withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: TextField(
                    controller: _reasonCtrl,
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Why is this change being made?',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ),
            ],

            // ── Footer ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(isTerminal ? 'Close' : 'Cancel'),
                    ),
                  ),
                  if (!isTerminal) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selected == null
                            ? null
                            : () => Navigator.pop(context, {
                                  'status': _selected!,
                                  'reason': _reasonCtrl.text.trim(),
                                }),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Change Status'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}