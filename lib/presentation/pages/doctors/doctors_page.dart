import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../../data/repositories/doctor_repository.dart';
import '../../../data/repositories/user_repository.dart';

class DoctorsPage extends ConsumerStatefulWidget {
  const DoctorsPage({super.key});

  @override
  ConsumerState<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends ConsumerState<DoctorsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearch(),
            const SizedBox(height: 24),
            Expanded(
              child: doctorsAsync.when(
                data: (doctors) {
                  final filtered = doctors.where((d) {
                    final user = d['user'] as Map? ?? {};
                    final name = (user['name'] ?? '').toString().toLowerCase();
                    final spec = (d['specialization'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_search.toLowerCase()) ||
                        spec.contains(_search.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) return _emptyState();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildDoctorCard(filtered[i]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medical_services_outlined,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 4),
                Text('Manage doctor profiles and specializations',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showDoctorDialog(),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Doctor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => _search = val),
        decoration: const InputDecoration(
          hintText: 'Search by name or specialization...',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.search, color: Colors.white38),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DOCTOR CARD
  // ═══════════════════════════════════════════
  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final user = doctor['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? '-';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '-';
    final specialization =
        doctor['specialization']?.toString() ?? 'General';
    final license = doctor['license_number']?.toString() ?? '';
    final branches = (user['branches'] as List? ?? []).cast<dynamic>();
    final isActive = user['is_active'] == true;
    final schedules = doctor['schedules_count'] ?? 0;
    final appointments = doctor['appointments_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(specialization,
                        style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (license.isNotEmpty)
            _infoRow(Icons.badge_outlined, 'License: $license'),
          const SizedBox(height: 4),
          _infoRow(Icons.email_outlined, email),
          const SizedBox(height: 4),
          _infoRow(Icons.phone_outlined, phone),

          if (branches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: branches.map((b) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    b['name']?.toString() ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statChip(Icons.schedule, schedules.toString(),
                    'Schedules', const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statChip(Icons.event, appointments.toString(),
                    'Appts', const Color(0xFF10B981)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDoctorDialog(doctor: doctor),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _confirmDelete(doctor),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String v, String l, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(v,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(width: 4),
          Text(l,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No doctors found',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ═══════════════════════════════════════════
  // ADD/EDIT DIALOG
  // ═══════════════════════════════════════════
  void _showDoctorDialog({Map<String, dynamic>? doctor}) {
    final isEdit = doctor != null;

    int? selectedUserId =
        doctor?['user_id'] is int ? doctor!['user_id'] as int : null;
    final specCtrl = TextEditingController(
        text: doctor?['specialization']?.toString() ?? '');
    final licenseCtrl = TextEditingController(
        text: doctor?['license_number']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          // Load only users with 'dentist' role for the dropdown
          final usersAsync = ref.watch(FutureProvider.autoDispose(
              (ref) => ref
                  .read(userRepositoryProvider)
                  .getStaffUsers(role: 'dentist')));

          return Dialog(
            backgroundColor: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setDialogState) => Container(
                width: 500,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEdit
                                ? Icons.edit
                                : Icons.add_moderator_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit
                                ? 'Edit Doctor'
                                : 'Create New Doctor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isEdit) ...[
                            _label('Select User (must have dentist role)'),
                            const SizedBox(height: 8),
                            usersAsync.when(
                              loading: () =>
                                  const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e',
                                  style: const TextStyle(
                                      color: Colors.red)),
                              data: (users) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.05),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child:
                                    DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    dropdownColor:
                                        AppColors.surfaceDark,
                                    value: selectedUserId,
                                    hint: const Text('Select a user',
                                        style: TextStyle(
                                            color: Colors.white38)),
                                    items: users.map((u) {
                                      return DropdownMenuItem<int>(
                                        value: u['id'] as int,
                                        child: Text(
                                          '${u['name']}  ·  ${u['email']}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) =>
                                        setDialogState(
                                            () => selectedUserId = v),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _label('Specialization'),
                          const SizedBox(height: 8),
                          _field(specCtrl,
                              'e.g. Orthodontist, Endodontist'),
                          const SizedBox(height: 14),
                          _label('License Number'),
                          const SizedBox(height: 8),
                          _field(licenseCtrl,
                              'PRC or license reference'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color:
                                  Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final repo =
                                    ref.read(doctorRepositoryProvider);
                                final data = {
                                  if (!isEdit)
                                    'user_id': selectedUserId,
                                  'specialization': specCtrl.text,
                                  'license_number': licenseCtrl.text,
                                };

                                if (isEdit) {
                                  await repo.updateDoctor(
                                      doctor['id'] as int, data);
                                } else {
                                  await repo.createDoctor(data);
                                }

                                ref.invalidate(doctorsProvider);
                                if (!mounted) return;
                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    content: Text(isEdit
                                        ? 'Doctor updated'
                                        : 'Doctor created'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('Error: $e'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isEdit ? 'Update' : 'Create',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF06B6D4)),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> doctor) {
    final user = doctor['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? 'this doctor';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Doctor',
            style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete '$name'? This won't delete their user account.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final repo = ref.read(doctorRepositoryProvider);
                await repo.deleteDoctor(doctor['id'] as int);
                ref.invalidate(doctorsProvider);
                if (!mounted) return;
                Navigator.pop(dialogContext);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}