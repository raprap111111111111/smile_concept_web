import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/consent/consent_template_model.dart';
import '../../../data/repositories/consent_repository.dart';

/// Loads active consent templates for the sign dialog picker.
final consentTemplatesProvider =
    FutureProvider<List<ConsentTemplateModel>>((ref) async {
  return ref.watch(consentRepositoryProvider).getTemplates();
});