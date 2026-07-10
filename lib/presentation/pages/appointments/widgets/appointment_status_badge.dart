// lib/presentation/pages/appointments/widgets/appointment_status_badge.dart

import 'package:flutter/material.dart';
import '../../../../data/models/appointment/appointment_model.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  final bool canUpdate;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onCancel;

  const AppointmentStatusBadge({
    super.key,
    required this.status,
    this.canUpdate = false,
    this.onStatusChanged,
    this.onCancel,
  });

  /// Get next status in hierarchy
  /// Pending → Confirmed → Completed
  String? get _nextStatus {
    switch (status) {
      case AppointmentStatus.pending:
        return 'confirmed';
      case AppointmentStatus.confirmed:
        return 'completed';
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return null; // Terminal states
    }
  }

  /// Get label for next status action
  String? get _nextLabel {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Tap to Confirm';
      case AppointmentStatus.confirmed:
        return 'Tap to Complete';
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return null;
    }
  }

  bool get _canCancel =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  @override
  Widget build(BuildContext context) {
    final isClickable = canUpdate && (_nextStatus != null || _canCancel);

    if (!isClickable) {
      // Just display the badge - no action available
      return _buildBadge();
    }

    // Clickable badge - shows menu on tap
    return PopupMenuButton<String>(
      tooltip: 'Change status',
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (context) => [
        if (_nextStatus != null)
          PopupMenuItem<String>(
            value: _nextStatus,
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(_nextStatus!),
                  size: 16,
                  color: _getColorForStatus(_nextStatus!),
                ),
                const SizedBox(width: 8),
                Text(_nextLabel!),
              ],
            ),
          ),
        if (_canCancel)
          const PopupMenuItem<String>(
            value: 'cancelled',
            child: Row(
              children: [
                Icon(Icons.close, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Cancel Appointment'),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'cancelled') {
          onCancel?.call();
        } else {
          onStatusChanged?.call(value);
        }
      },
      child: _buildBadge(isClickable: true),
    );
  }

  Widget _buildBadge({bool isClickable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isClickable
            ? Border.all(
                color: _textColor.withOpacity(0.4),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: _textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isClickable) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: _textColor,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color get _bgColor {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange.withOpacity(0.15);
      case AppointmentStatus.confirmed:
        return Colors.blue.withOpacity(0.15);
      case AppointmentStatus.completed:
        return Colors.green.withOpacity(0.15);
      case AppointmentStatus.cancelled:
        return Colors.red.withOpacity(0.15);
    }
  }

  Color get _textColor {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }
}