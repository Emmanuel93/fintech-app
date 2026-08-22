import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DsStepIndicator extends StatelessWidget {
  const DsStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.labels,
  });

  final int totalSteps;
  final int currentStep;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isCompleted = i < currentStep;
            final isActive = i == currentStep;
            return Expanded(
              child: Row(
                children: [
                  _StepCircle(
                    index: i + 1,
                    isCompleted: isCompleted,
                    isActive: isActive,
                  ),
                  if (i < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? AppColors.stepCompleted
                            : AppColors.stepPending,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        if (labels != null && labels!.length == totalSteps) ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.008),
          Row(
            children: List.generate(totalSteps, (i) {
              final isCompleted = i < currentStep;
              final isActive = i == currentStep;
              return Expanded(
                child: Text(
                  labels![i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == totalSteps - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? AppColors.stepActive
                            : isCompleted
                                ? AppColors.stepCompleted
                                : AppColors.disabled,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isActive,
  });

  final int index;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final size = h * 0.036;

    Color bg;
    Color fg;
    Widget child;

    if (isCompleted) {
      bg = AppColors.stepCompleted;
      fg = Colors.white;
      child = Icon(Icons.check, size: size * 0.5, color: Colors.white);
    } else if (isActive) {
      bg = AppColors.stepActive;
      fg = Colors.white;
      child = Text(
        '$index',
        style: TextStyle(
            color: fg, fontSize: size * 0.43, fontWeight: FontWeight.w700),
      );
    } else {
      bg = AppColors.stepPending;
      fg = AppColors.disabled;
      child = Text(
        '$index',
        style: TextStyle(
            color: fg, fontSize: size * 0.43, fontWeight: FontWeight.w500),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}
