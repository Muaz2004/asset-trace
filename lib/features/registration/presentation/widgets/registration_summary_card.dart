import 'dart:io';

import 'package:flutter/material.dart';

/// Reusable summary card displaying entered registration information for final review.
class RegistrationSummaryCard extends StatelessWidget {
  const RegistrationSummaryCard({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.phoneNumber,
    required this.pcBrand,
    required this.pcModel,
    required this.serialNumber,
    required this.pcPhotoFile,
    required this.studentWithPcPhotoFile,
  });

  final String studentName;
  final String studentId;
  final String phoneNumber;
  final String pcBrand;
  final String pcModel;
  final String serialNumber;
  final File? pcPhotoFile;
  final File? studentWithPcPhotoFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded,
                    color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Registration Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Student section
            Text(
              'STUDENT INFORMATION',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Full Name', value: studentName),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Student ID', value: studentId.toUpperCase()),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Phone Number', value: phoneNumber),
            const SizedBox(height: 16),

            // Computer section
            Text(
              'COMPUTER SPECIFICATIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Brand & Model', value: '$pcBrand $pcModel'),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Serial Number',
              value: serialNumber.toUpperCase(),
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Photos section
            Text(
              'VERIFICATION PHOTOGRAPHS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PhotoThumbnail(
                    label: 'Computer Photo',
                    file: pcPhotoFile,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoThumbnail(
                    label: 'Student with PC',
                    file: studentWithPcPhotoFile,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.label,
    required this.file,
    required this.colorScheme,
  });

  final String label;
  final File? file;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90,
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            child: file != null
                ? Image.file(file!, fit: BoxFit.cover)
                : const Icon(Icons.broken_image_outlined),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
