import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  IconData get _icon => switch (role) {
        'super-admin' => Icons.admin_panel_settings_outlined,
        'admin' => Icons.manage_accounts_outlined,
        'dentist' => Icons.medical_services_outlined,
        'receptionist' => Icons.support_agent_outlined,
        'patient' => Icons.person_outlined,
        _ => Icons.person_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            role.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}