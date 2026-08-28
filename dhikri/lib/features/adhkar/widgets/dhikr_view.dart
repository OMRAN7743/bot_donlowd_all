import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../../../data/models/dhikr.dart';

/// عرض نص ذكر واحد في بطاقة مركّزة.
///
/// لا خلفيات صور خلف النص، ولا ذهبي للفقرات — وضوح القراءة أولًا.
class DhikrView extends StatelessWidget {
  const DhikrView({
    super.key,
    required this.dhikr,
    required this.showSource,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Dhikr dhikr;
  final bool showSource;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;

    final dhikrStyle = AppTypography.styled(
      fontSize: AppTypography.dhikrFontSize(
        scale: tokens.textScale,
        seniorMode: tokens.seniorMode,
        screenWidth: width,
      ),
      weight: FontWeight.w500,
      height: AppTypography.dhikrLineHeight,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.seniorMode ? 18 : 20,
        vertical: tokens.seniorMode ? 22 : 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  dhikr.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleFavorite,
                tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'نص الذكر',
            child: SelectionArea(
              child: Text(
                dhikr.text,
                style: dhikrStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (showSource && dhikr.hasSource) ...<Widget>[
            const SizedBox(height: 18),
            SourceReferenceTile(
              sourceLine: dhikr.sourceLine,
              note: dhikr.note,
              initiallyExpanded: !tokens.seniorMode,
            ),
          ],
        ],
      ),
    );
  }
}
