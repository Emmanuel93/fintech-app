import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class DsOtpField extends StatelessWidget {
  const DsOtpField({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hasError = false,
  });

  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return _OtpInput(
      length: length,
      onCompleted: onCompleted,
      onChanged: onChanged,
      controller: controller,
      focusNode: focusNode,
      hasError: hasError,
    );
  }
}

class _OtpInput extends StatefulWidget {
  const _OtpInput({
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hasError = false,
  });

  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasError;

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    _currentValue = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(_currentValue);
    if (_currentValue.length == widget.length) {
      widget.onCompleted(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula celda relativa al ancho disponible
        const gapPerCell = 8.0;
        final totalGaps = (widget.length + 1) * gapPerCell;
        final cellWidth = (constraints.maxWidth - totalGaps) / widget.length;
        final cellHeight = (cellWidth * 1.22).clamp(48.0, 64.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            return _OtpCell(
              width: cellWidth,
              height: cellHeight,
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              hasError: widget.hasError,
              onChanged: (v) => _onDigitEntered(i, v),
            );
          }),
        );
      },
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: hasError ? AppColors.error : AppColors.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primary,
              width: 2.5,
            ),
          ),
          filled: true,
          fillColor: hasError
              ? AppColors.errorContainer.withValues(alpha: 0.3)
              : AppColors.surface,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
