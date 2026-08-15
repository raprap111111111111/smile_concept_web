// lib/core/utils/money.dart

import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat('#,##0.00');

/// Clinic-wide peso formatting. Matches the invoice pages' existing idiom
/// (`₱${NumberFormat('#,##0.00').format(v)}`) so totals read the same
/// everywhere instead of drifting between `$` and `₱` per screen.
String formatMoney(double value) => '₱${_moneyFormat.format(value)}';

/// Amount without the currency symbol — for use next to a separate `₱` glyph.
String formatAmount(double value) => _moneyFormat.format(value);
