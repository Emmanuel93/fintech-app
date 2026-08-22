import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DsDocumentUploadCard extends StatelessWidget {
  const DsDocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.fileBytes,
    this.fileName,
    this.onTap,
    this.acceptedFormats,
    this.isRequired = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  /// Raw bytes of the selected file (replaces dart:io File).
  final Uint8List? fileBytes;
  /// File name, used to determine extension for preview.
  final String? fileName;
  final VoidCallback? onTap;
  final String? acceptedFormats;
  final bool isRequired;

  bool get _hasFile => fileBytes != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _hasFile
              ? AppColors.successContainer.withValues(alpha: 0.3)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasFile ? AppColors.success : AppColors.outlineVariant,
            width: _hasFile ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _FilePreview(
                fileBytes: fileBytes,
                fileName: fileName,
                icon: icon,
                hasFile: _hasFile,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Requerido',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasFile ? 'Documento cargado ✓' : subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _hasFile ? AppColors.success : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (acceptedFormats != null && !_hasFile) ...[
                      const SizedBox(height: 6),
                      Text(
                        acceptedFormats!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.disabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                _hasFile ? Icons.check_circle : Icons.chevron_right,
                color: _hasFile ? AppColors.success : AppColors.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({
    required this.fileBytes,
    required this.fileName,
    required this.icon,
    required this.hasFile,
  });

  final Uint8List? fileBytes;
  final String? fileName;
  final IconData icon;
  final bool hasFile;

  bool get _isImage {
    if (fileName == null) return false;
    final ext = fileName!.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    if (hasFile && _isImage && fileBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          fileBytes!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          // Un archivo corrupto o en un formato que el decoder no soporta no
          // debe tumbar la pantalla — se degrada al ícono genérico de abajo.
          errorBuilder: (_, __, ___) => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description, color: AppColors.success, size: 28),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: hasFile ? AppColors.successContainer : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        hasFile ? Icons.description : icon,
        color: hasFile ? AppColors.success : AppColors.primary,
        size: 28,
      ),
    );
  }
}
