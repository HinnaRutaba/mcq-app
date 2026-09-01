import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widgets.dart';

/// The server's own 422 message for one field, under that field.
///
/// Shown verbatim — it is already translated into the officer's language.
///
/// This exists as a widget rather than an inline `Obx(...)` around the input
/// itself for a reason: an `Obx` whose builder only touches an observable
/// inside a callback (`validator:`, `onChanged:`) reads nothing at build
/// time, and GetX throws "improper use of a GetX" for it. The observable
/// has to be read where the widget is built, which is here.
class ServerFieldError extends StatelessWidget {
  const ServerFieldError({
    super.key,
    required this.errors,
    required this.field,
  });

  /// The controller's 422 map, keyed by field name.
  final RxMap<String, List<String>> errors;

  final String field;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = errors[field]?.firstOrNull;
      if (message == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 0),
        child: AppText.caption(
          message,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
