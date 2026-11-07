import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Inline banner for offline/cached states.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.isError = false,
    this.icon = Icons.wifi_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isError;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isError ? AppColors.live : AppColors.warning;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.retry,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}
