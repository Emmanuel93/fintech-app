import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DsTextField extends StatelessWidget {
  const DsTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.helperText,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final int? maxLength;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? helperText;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        helperText: helperText,
        counterText: '',
      ),
    );
  }
}
