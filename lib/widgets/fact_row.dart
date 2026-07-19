import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Label + value pair for pack facts. Values use the data face (mono) so
/// batch numbers and dates align and read as record data. An absent value
/// shows a dash placeholder by design.
class FactRow extends StatelessWidget {
  final String label;
  final String value;

  const FactRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: T.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: T.small.copyWith(color: c.inkMuted)),
          ),
          const SizedBox(width: T.s3),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: T.data
                  .copyWith(color: value.isEmpty ? c.inkFaint : c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
