import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smile_concept_web/data/models/consent/consent_form_data.dart';
import 'package:smile_concept_web/presentation/theme/app_colors.dart';
import 'package:smile_concept_web/presentation/theme/app_dimensions.dart';
import 'package:smile_concept_web/presentation/theme/app_text_styles.dart';
import 'package:smile_concept_web/presentation/pages/consent/widgets/section_title.dart';
import 'package:smile_concept_web/presentation/providers/consent/sign_consent_form_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PSGC Provider — fetches Philippine addresses from GitHub (cached in memory)
// ═══════════════════════════════════════════════════════════════════════════
final _psgcProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = Dio();
  final response = await dio.get<String>(
    'https://raw.githubusercontent.com/flores-jacob/'
    'philippine-regions-provinces-cities-municipalities-barangays/master/'
    'philippine_provinces_cities_municipalities_and_barangays_2019v2.json',
    options: Options(
      responseType: ResponseType.plain,
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final decoded = json.decode(response.data ?? '{}') as Map<String, dynamic>;
  debugPrint('✅ PSGC loaded: ${decoded.keys.length} regions');
  return decoded;
});

// ═══════════════════════════════════════════════════════════════════════════
// Religions
// ═══════════════════════════════════════════════════════════════════════════
const List<String> _kReligions = [
  'Roman Catholic',
  'Iglesia ni Cristo',
  'Islam',
  'Born Again Christian',
  'Seventh-day Adventist',
  'Baptist',
  'Methodist',
  'Buddhist',
  'Hindu',
  "Jehovah's Witness",
  'Other',
  'Prefer not to say',
];

// ═══════════════════════════════════════════════════════════════════════════
// Step 1
// ═══════════════════════════════════════════════════════════════════════════
class Step1PatientInfo extends ConsumerStatefulWidget {
  const Step1PatientInfo({super.key});

  @override
  ConsumerState<Step1PatientInfo> createState() => _Step1PatientInfoState();
}

class _Step1PatientInfoState extends ConsumerState<Step1PatientInfo> {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _dentalInsuranceCtrl;
  late final TextEditingController _effectiveDateCtrl;
  late final TextEditingController _parentGuardianNameCtrl;
  late final TextEditingController _parentGuardianOccupationCtrl;
  late final TextEditingController _guardianNameCtrl;
  late final TextEditingController _guardianRelationCtrl;
  late final TextEditingController _guardianOccupationCtrl;
  late final TextEditingController _guardianAddressCtrl;

  // ── Non-text fields ──────────────────────────────────────────────────────
  String? _religion;
  String? _region;
  String? _province;
  String? _city;
  String? _barangay;
  DateTime? _birthdate;
  DateTime? _effectiveDate;

  PatientRelation? _lastRelation;

  @override
  void initState() {
    super.initState();
    final s = ref.read(consentFormProvider);

    _nameCtrl = TextEditingController(text: s.name);
    _birthdateCtrl = TextEditingController(text: s.birthdate);
    _streetCtrl = TextEditingController(text: s.street);
    _occupationCtrl = TextEditingController(text: s.occupation);
    _dentalInsuranceCtrl = TextEditingController(text: s.dentalInsurance);
    _effectiveDateCtrl = TextEditingController(text: s.effectiveDate);
    _parentGuardianNameCtrl =
        TextEditingController(text: s.parentGuardianName);
    _parentGuardianOccupationCtrl =
        TextEditingController(text: s.parentGuardianOccupation);
    _guardianNameCtrl = TextEditingController(text: s.guardianName);
    _guardianRelationCtrl = TextEditingController(text: s.guardianRelation);
    _guardianOccupationCtrl =
        TextEditingController(text: s.guardianOccupation);
    _guardianAddressCtrl = TextEditingController(text: s.guardianAddress);

    _religion = s.religion.isEmpty ? null : s.religion;
    _region = s.region.isEmpty ? null : s.region;
    _province = s.province.isEmpty ? null : s.province;
    _city = s.city.isEmpty ? null : s.city;
    _barangay = s.barangay.isEmpty ? null : s.barangay;

    _birthdate = _tryParse(s.birthdate);
    _effectiveDate = _tryParse(s.effectiveDate);
    _lastRelation = s.patientRelation;
  }

  DateTime? _tryParse(String s) {
    if (s.trim().isEmpty) return null;
    try {
      return DateFormat('MM/dd/yyyy').parseStrict(s.trim());
    } catch (_) {
      return DateTime.tryParse(s);
    }
  }

  @override
  void dispose() {
    _flush();
    for (final ctrl in [
      _nameCtrl,
      _birthdateCtrl,
      _streetCtrl,
      _occupationCtrl,
      _dentalInsuranceCtrl,
      _effectiveDateCtrl,
      _parentGuardianNameCtrl,
      _parentGuardianOccupationCtrl,
      _guardianNameCtrl,
      _guardianRelationCtrl,
      _guardianOccupationCtrl,
      _guardianAddressCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _flush() {
    ref.read(consentFormProvider.notifier).updatePatientInfo(
          name: _nameCtrl.text,
          birthdate: _birthdateCtrl.text,
          religion: _religion ?? '',
          homeAddress: _fullAddress(),
          occupation: _occupationCtrl.text,
          dentalInsurance: _dentalInsuranceCtrl.text,
          effectiveDate: _effectiveDateCtrl.text,
          parentGuardianName: _parentGuardianNameCtrl.text,
          parentGuardianOccupation: _parentGuardianOccupationCtrl.text,
          guardianName: _guardianNameCtrl.text,
          guardianRelation: _guardianRelationCtrl.text,
          guardianOccupation: _guardianOccupationCtrl.text,
          guardianAddress: _guardianAddressCtrl.text,
          region: _region ?? '',
          province: _province ?? '',
          city: _city ?? '',
          barangay: _barangay ?? '',
          street: _streetCtrl.text,
        );
  }

  String _fullAddress() {
    final parts = [
      _streetCtrl.text.trim(),
      _barangay ?? '',
      _city ?? '',
      _province ?? '',
      _region ?? '',
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  void _reactToRelationChange(PatientRelation next, dynamic patient) {
    if (_lastRelation == next) return;
    _lastRelation = next;

    if (next == PatientRelation.self && patient != null) {
      setState(() => _nameCtrl.text = patient.name ?? '');
      _flush();
    } else if (next == PatientRelation.minorDependent) {
      setState(() => _nameCtrl.text = '');
      _flush();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consentFormProvider);
    final isGuardian =
        state.patientRelation == PatientRelation.minorDependent;
    final isSelf = state.patientRelation == PatientRelation.self;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reactToRelationChange(state.patientRelation, state.selectedPatient);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Patient Information Record',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          // ── Name ────────────────────────────────────────────────────────
          _NameField(
            controller: _nameCtrl,
            readOnly: isSelf,
            hint: isSelf
                ? 'Loaded from patient profile'
                : 'Enter patient full name',
            onChanged: (_) => _flush(),
          ),
          if (isSelf)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                '🔒  Locked — Patient signs for themselves.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),

          // ── Birthdate + Religion ────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _DateField(
                label: 'Birthdate',
                controller: _birthdateCtrl,
                initialDate: _birthdate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onPicked: (d) {
                  setState(() {
                    _birthdate = d;
                    _birthdateCtrl.text = DateFormat('MM/dd/yyyy').format(d);
                  });
                  _flush();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _kReligions.contains(_religion) ? _religion : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Religion',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.church_outlined),
                ),
                items: _kReligions
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _religion = v);
                  _flush();
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Home Address (REAL PSGC — cascading) ─────────────────────────
          const SectionTitle(
            title: 'Home Address',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 8),
          _buildPsgcAddressPicker(),
          const SizedBox(height: 8),
          TextField(
            controller: _streetCtrl,
            onChanged: (_) => _flush(),
            decoration: const InputDecoration(
              labelText: 'Street / Unit / Building',
              hintText: 'e.g. #123 Rizal Street, Purok 4',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // ── Occupation + Insurance ──────────────────────────────────────
          Row(children: [
            Expanded(
              child: TextField(
                controller: _occupationCtrl,
                onChanged: (_) => _flush(),
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _dentalInsuranceCtrl,
                onChanged: (_) => _flush(),
                decoration: const InputDecoration(
                  labelText: 'Dental Insurance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.health_and_safety_outlined),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Effective Date ──────────────────────────────────────────────
          _DateField(
            label: 'Effective Date',
            controller: _effectiveDateCtrl,
            initialDate: _effectiveDate,
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
            onPicked: (d) {
              setState(() {
                _effectiveDate = d;
                _effectiveDateCtrl.text = DateFormat('MM/dd/yyyy').format(d);
              });
              _flush();
            },
          ),
          const SizedBox(height: 20),

          // ── Minors ──────────────────────────────────────────────────────
          const Divider(),
          const SizedBox(height: 8),
          Text('For Minors / Dependent Patients',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _parentGuardianNameCtrl,
            onChanged: (_) => _flush(),
            decoration: const InputDecoration(
              labelText: "Parent / Guardian's Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.family_restroom),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _parentGuardianOccupationCtrl,
            onChanged: (_) => _flush(),
            decoration: const InputDecoration(
              labelText: "Guardian's Occupation",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // ── Guardian Profile ────────────────────────────────────────────
          if (isGuardian) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('Guardian Profile (Signing Authority)',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _guardianNameCtrl,
              onChanged: (_) => _flush(),
              decoration: const InputDecoration(
                labelText: "Guardian's Full Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _guardianRelationCtrl,
              onChanged: (_) => _flush(),
              decoration: const InputDecoration(
                labelText: 'Relationship to Patient',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _guardianOccupationCtrl,
              onChanged: (_) => _flush(),
              decoration: const InputDecoration(
                labelText: "Guardian's Occupation",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _guardianAddressCtrl,
              onChanged: (_) => _flush(),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Guardian's Address",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PSGC Address Picker — REAL cascading dropdowns
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPsgcAddressPicker() {
    final psgcAsync = ref.watch(_psgcProvider);

    return psgcAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading Philippine addresses (~2MB)…'),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('❌ Failed to load addresses',
                style: TextStyle(color: Colors.red)),
            const SizedBox(height: 4),
            Text('$e', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(_psgcProvider),
            ),
          ],
        ),
      ),
      data: (data) {
        // ── Extract lists based on current cascade ────────────────────
        final regions = _extractRegions(data);
        final provinces =
            _region == null ? <String>[] : _extractProvinces(data, _region!);
        final cities = (_region == null || _province == null)
            ? <String>[]
            : _extractCities(data, _region!, _province!);
        final barangays =
            (_region == null || _province == null || _city == null)
                ? <String>[]
                : _extractBarangays(data, _region!, _province!, _city!);

        debugPrint('🗺 PSGC cascade: '
            'region=$_region, provinces=${provinces.length}, '
            'province=$_province, cities=${cities.length}, '
            'city=$_city, barangays=${barangays.length}');

        return Column(
          children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: regions.contains(_region) ? _region : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: regions
                      .map((r) => DropdownMenuItem<String>(
                            value: r,
                            child: Text(
                              r,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    debugPrint('🗺 Region SELECTED: "$v"');
                    setState(() {
                      _region = v;
                      _province = null;
                      _city = null;
                      _barangay = null;
                    });
                    _flush();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provinces.contains(_province) ? _province : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Province',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.terrain_outlined),
                    helperText: _region == null
                        ? 'Select Region first'
                        : '${provinces.length} available',
                    helperStyle: const TextStyle(fontSize: 10),
                  ),
                  items: provinces
                      .map((p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(
                              p,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (_region == null || provinces.isEmpty)
                      ? null
                      : (v) {
                          debugPrint('🗺 Province SELECTED: "$v"');
                          setState(() {
                            _province = v;
                            _city = null;
                            _barangay = null;
                          });
                          _flush();
                        },
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: cities.contains(_city) ? _city : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'City / Municipality',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    helperText: _province == null
                        ? 'Select Province first'
                        : '${cities.length} available',
                    helperStyle: const TextStyle(fontSize: 10),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (_province == null || cities.isEmpty)
                      ? null
                      : (v) {
                          debugPrint('🗺 City SELECTED: "$v"');
                          setState(() {
                            _city = v;
                            _barangay = null;
                          });
                          _flush();
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: barangays.contains(_barangay) ? _barangay : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        const Icon(Icons.holiday_village_outlined),
                    helperText: _city == null
                        ? 'Select City first'
                        : '${barangays.length} available',
                    helperStyle: const TextStyle(fontSize: 10),
                  ),
                  items: barangays
                      .map((b) => DropdownMenuItem<String>(
                            value: b,
                            child: Text(
                              b,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (_city == null || barangays.isEmpty)
                      ? null
                      : (v) {
                          debugPrint('🗺 Barangay SELECTED: "$v"');
                          setState(() => _barangay = v);
                          _flush();
                        },
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PSGC Extraction helpers
  // ═════════════════════════════════════════════════════════════════════════
  List<String> _extractRegions(Map<String, dynamic> data) {
    return data.values
        .map((r) => (r as Map)['region_name'] as String)
        .toList()
      ..sort();
  }

  List<String> _extractProvinces(
      Map<String, dynamic> data, String regionName) {
    final region = _findRegion(data, regionName);
    if (region == null) return [];
    final provList = region['province_list'];
    if (provList is! Map) return [];
    return provList.keys.cast<String>().toList()..sort();
  }

  List<String> _extractCities(
      Map<String, dynamic> data, String regionName, String provinceName) {
    final region = _findRegion(data, regionName);
    if (region == null) return [];
    final province = (region['province_list'] as Map?)?[provinceName];
    if (province == null) return [];
    final muniList = province['municipality_list'];
    if (muniList is! Map) return [];
    return muniList.keys.cast<String>().toList()..sort();
  }

  List<String> _extractBarangays(
    Map<String, dynamic> data,
    String regionName,
    String provinceName,
    String cityName,
  ) {
    final region = _findRegion(data, regionName);
    if (region == null) return [];
    final province = (region['province_list'] as Map?)?[provinceName];
    if (province == null) return [];
    final city = (province['municipality_list'] as Map?)?[cityName];
    if (city == null) return [];
    final brgyList = city['barangay_list'];
    if (brgyList is! List) return [];
    return brgyList.cast<String>().toList()..sort();
  }

  Map<String, dynamic>? _findRegion(
      Map<String, dynamic> data, String regionName) {
    for (final r in data.values) {
      if (r is Map<String, dynamic> && r['region_name'] == regionName) {
        return r;
      }
    }
    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════
// _NameField
// ═════════════════════════════════════════════════════════════════════════
class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final String hint;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.controller,
    required this.readOnly,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person_outline),
        suffixIcon: readOnly
            ? const Icon(Icons.lock,
                size: 18, color: AppColors.textSecondary)
            : null,
        filled: readOnly,
        fillColor: readOnly ? AppColors.surface : null,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// _DateField
// ═════════════════════════════════════════════════════════════════════════
class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    required this.controller,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      canRequestFocus: false,
      onTap: () async {
        final initial = initialDate ?? DateTime.now();
        final safe = initial.isAfter(lastDate)
            ? lastDate
            : (initial.isBefore(firstDate) ? firstDate : initial);
        final picked = await showDatePicker(
          context: context,
          initialDate: safe,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: 'Select $label',
        );
        if (picked != null) onPicked(picked);
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        hintText: 'Tap to pick a date',
      ),
    );
  }
}