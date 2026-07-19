import 'package:flutter/material.dart';

import '../services/strings.dart';
import '../theme/tokens.dart';

/// Label + value pair for pack facts. Values use the data face (mono) so
/// batch numbers and dates align and read as record data. An absent value
/// shows a dash placeholder by design.
///
/// [fromRegister] marks a value the camera did not read but the matched
/// register entry supplies: shown muted with a tag, so the card stays an
/// honest record of what came from where.
class FactRow extends StatelessWidget {
  final String label;
  final String value;
  final bool fromRegister;

  const FactRow(
      {super.key,
      required this.label,
      required this.value,
      this.fromRegister = false});

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
            child: value.isEmpty
                ? Text('—', style: T.data.copyWith(color: c.inkFaint))
                : Text.rich(TextSpan(
                    text: value,
                    style: T.data.copyWith(
                        color: fromRegister ? c.inkMuted : c.ink),
                    children: [
                      if (fromRegister)
                        TextSpan(
                            text: '  ${S.fromRegisterTag}',
                            style: T.caption.copyWith(color: c.inkFaint)),
                    ])),
          ),
        ],
      ),
    );
  }
}
