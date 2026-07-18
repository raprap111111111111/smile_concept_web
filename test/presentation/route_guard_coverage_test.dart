// Source-level guards against the two mistakes that produced the
// "new patient lands on /unauthorized" bug:
//
//   1. a post-auth destination hardcoded to /dashboard, bypassing permissions;
//   2. a route that exists but has no entry in RoutePermissions, which
//      `allows()` waves through unchecked.
//
// These read the source rather than exercising widgets on purpose: the failure
// mode is someone adding a *new* file or route months from now, and no
// behavioural test can cover code that doesn't exist yet.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smile_concept_web/presentation/route/route_permissions.dart';

/// Paths reachable without being logged in; the redirect guard handles them
/// before permissions ever come up.
const _publicPaths = {
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/splash',
};

/// Navigating to the dashboard is legitimate *here*: the sidebar renders it as
/// a nav item and already hides it behind `Perm.dashboardView`.
const _dashboardNavigationAllowlist = {
  'lib/presentation/layouts/widgets/sidebar/sidebar_nav_config.dart',
};

List<File> _dartFilesUnder(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _relative(File file) =>
    file.path.replaceAll(r'\', '/').split('smile_concept_web/').last;

void main() {
  test('no page navigates to the dashboard by hand', () {
    // Matches context.go('/dashboard'), goNamed(RouteNames.dashboard) and the
    // `?? '/dashboard'` fallback that caused the original bug.
    final hardcoded = RegExp(
      r"""(go|goNamed|push|pushNamed|replace)\s*\(\s*[^)]*?(['"]/dashboard['"]|RouteNames\.dashboard)""",
      dotAll: true,
    );
    final fallback = RegExp(r"""\?\?\s*['"]/dashboard['"]""");

    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final relative = _relative(file);
      if (_dashboardNavigationAllowlist.contains(relative)) continue;

      final source = file.readAsStringSync();
      if (hardcoded.hasMatch(source) || fallback.hasMatch(source)) {
        offenders.add(relative);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'A hardcoded dashboard destination ignores permissions, and a '
          'patient has no dashboard.view — they land on /unauthorized. Use '
          'postAuthDestination() from router_redirect.dart, or '
          'RoutePermissions.landingFor() when there is no `next` to honour.',
    );
  });

  test('every registered route declares its permissions', () {
    final pathLiteral = RegExp(r"""path:\s*'(/[^']*)'""");

    final undeclared = <String>[];
    for (final file in _dartFilesUnder('lib/presentation/route/routes')) {
      final source = file.readAsStringSync();
      for (final match in pathLiteral.allMatches(source)) {
        final path = match.group(1)!;
        if (_publicPaths.contains(path)) continue;

        // Null means no rule matched: allows() lets the path through, so the
        // page is reachable by direct URL regardless of role.
        if (RoutePermissions.requirementsFor(path) == null) {
          undeclared.add('$path (${_relative(file)})');
        }
      }
    }

    expect(
      undeclared,
      isEmpty,
      reason: 'Add these paths to RoutePermissions. An unregistered path is '
          'not guarded — use an empty list to mean "any authenticated user".',
    );
  });

  test('the landing fallback is a page every authenticated user can open', () {
    expect(RoutePermissions.requirementsFor('/profile'), isEmpty);
  });
}
