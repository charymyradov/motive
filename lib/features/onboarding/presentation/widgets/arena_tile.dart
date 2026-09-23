import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../game/domain/entities/psych_field.dart';
import '../../../game/presentation/widgets/card_styles.dart';

/// Selectable field ("arena") row used in onboarding and settings.
class ArenaTile extends StatelessWidget {
  const ArenaTile({super.key, required this.field, required this.selected, required this.onTap});

  final PsychField field;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final fc = FieldStyle.color(field.id);
    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: .98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? fc : c.line),
          boxShadow: selected
              ? [BoxShadow(color: fc.withValues(alpha: .45), blurRadius: 40, spreadRadius: -12, offset: const Offset(0, 10))]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: fc.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: fc, blurRadius: 24, spreadRadius: -4)],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.name, style: AppText.sans(16, weight: FontWeight.w700, color: c.ink)),
                  const SizedBox(height: 3),
                  Text(field.description, style: AppText.sans(13, color: c.ink2, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? fc : Colors.transparent,
                border: Border.all(color: c.line, width: 1.5),
              ),
              alignment: Alignment.center,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: selected ? 1 : 0,
                child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.onSolid, shape: BoxShape.circle)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
