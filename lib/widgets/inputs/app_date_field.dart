import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'app_text_field.dart';

/// A tap-to-pick date input styled like [AppTextField].
class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    this.label,
    this.hint = 'Select date',
    this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  final String? label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller = TextEditingController(
    text: _textFor(widget.value),
  );

  String _textFor(DateTime? date) => date == null ? '' : Formatters.date(date);

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _textFor(widget.value);
    if (_controller.text != text) _controller.text = text;
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: widget.firstDate ?? DateTime(now.year - 1),
      lastDate: widget.lastDate ?? DateTime(now.year + 2),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: AbsorbPointer(
        child: AppTextField(
          label: widget.label,
          hint: widget.hint,
          controller: _controller,
          prefixIcon: Icons.calendar_today_rounded,
          validator: widget.validator,
        ),
      ),
    );
  }
}
