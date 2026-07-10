// lib/presentation/pages/appointments/widgets/patient_search_field.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/patient/patient_model.dart';
import '../../../providers/patient/patient_search_provider.dart';

class PatientSearchField extends ConsumerStatefulWidget {
  final int? selectedPatientId;
  final String? selectedPatientName;
  final ValueChanged<PatientModel?> onPatientSelected;

  const PatientSearchField({
    super.key,
    this.selectedPatientId,
    this.selectedPatientName,
    required this.onPatientSelected,
  });

  @override
  ConsumerState<PatientSearchField> createState() =>
      _PatientSearchFieldState();
}

class _PatientSearchFieldState extends ConsumerState<PatientSearchField> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedPatientName != null) {
      _searchController.text = widget.selectedPatientName!;
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1E293B),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Consumer(
                builder: (context, ref, _) {
                  final patientsAsync =
                      ref.watch(patientSearchProvider(_query));

                  return patientsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (patients) {
                      if (patients.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha:0.05),
                        ),
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return _PatientListItem(
                            patient: patient,
                            onTap: () => _selectPatient(patient),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectPatient(PatientModel patient) {
    setState(() {
      _searchController.text = patient.name;
    });

    widget.onPatientSelected(patient);
    _focusNode.unfocus();
    _removeOverlay();
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _query = '';
    });
    widget.onPatientSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), () {
            setState(() => _query = v);
            _showOverlay();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patient by name or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSelection,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Patient List Item ────────────────────────────────────────────────────────
class _PatientListItem extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientListItem({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (patient.email.isNotEmpty) patient.email,
      if (patient.phone != null && patient.phone!.isNotEmpty) patient.phone!,
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  const Color(0xFF6366F1).withValues(alpha: 0.2),
              backgroundImage: patient.profilePhotoUrl != null &&
                      patient.profilePhotoUrl!.isNotEmpty
                  ? NetworkImage(patient.profilePhotoUrl!)
                  : null,
              child: (patient.profilePhotoUrl == null ||
                      patient.profilePhotoUrl!.isEmpty)
                  ? Text(
                      patient.name.isNotEmpty
                          ? patient.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // ── Info ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // ── Medical Alert Icons ───────────────────────────
            if (patient.hasCardiacConditions ||
                patient.isPregnant ||
                patient.hasBleedingDisorders ||
                patient.requiresEpinephrineFreeAnesthesia)
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}