// lib/screens/unauthorized_screen.dart
import 'package:flutter/material.dart';

import '/../../../presentation/pages/unauthorized/unauthorized_page.dart';

/// The 403 screen, kept under its original name.
///
/// Display only — this is what a blocked user *sees*. The blocking happens
/// earlier, in `handleRedirect` + `RoutePermissions`, which is what sends a user
/// without the required permission to `/unauthorized` in the first place.
///
/// Delegates to [UnauthorizedPage] instead of repeating its markup. This file
/// used to hold a second copy whose "back" button was hardcoded to /dashboard,
/// which strands anyone lacking `dashboard.view` — a patient, for one — on the
/// page they were just refused. One implementation, one behaviour.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) => const UnauthorizedPage();
}
