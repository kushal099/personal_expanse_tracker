import 'package:flutter/material.dart';

/// Custom text input field with validation
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(String)? onChanged;
  final TextInputAction textInputAction;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        label: Text(widget.label),
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}

/// Custom dropdown field
class CustomDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T?) onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: widget.value,
      items: widget.items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(widget.itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(label: Text(widget.label)),
    );
  }
}

/// Custom date picker field
class CustomDatePicker extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.label,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        label: Text(widget.label),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          widget.onDateSelected(date);
        }
      },
      controller: TextEditingController(
        text: widget.selectedDate != null
            ? '${widget.selectedDate?.year}-${widget.selectedDate?.month}-${widget.selectedDate?.day}'
            : '',
      ),
    );
  }
}
