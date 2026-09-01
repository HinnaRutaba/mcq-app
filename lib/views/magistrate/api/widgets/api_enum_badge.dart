import 'package:flutter/material.dart';

import '../../../../core/utils/status_style.dart';
import '../../../../models/common/api_enum.dart';
import '../../../../widgets/widgets.dart';

/// A status pill for an enum the API sent.
///
/// The label is the server's — already translated — and the colour comes
/// from the server's own `tone`. Never map a value to a string of our own:
/// that is a second source of truth and it drifts from the web application.
class ApiEnumBadge extends StatelessWidget {
  const ApiEnumBadge(this.value, {super.key, this.fallbackLabel});

  final ApiEnum value;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty && fallbackLabel == null) {
      return const SizedBox.shrink();
    }
    return AppStatusBadge(
      label: value.isEmpty ? fallbackLabel! : value.label,
      tone: StatusStyle.apiTone(value.tone),
    );
  }
}
