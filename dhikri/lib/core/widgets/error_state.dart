import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../errors/app_exception.dart';

/// شاشة خطأ برسالة عربية واضحة، وتفاصيل تقنية في وضع التطوير فقط.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
  });

  final AppException error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.pagePadding + 8,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 18),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (kDebugMode && error.debugDetail != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                error.debugDetail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
