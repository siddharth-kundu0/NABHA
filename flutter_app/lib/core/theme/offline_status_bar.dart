import 'package:flutter/material.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/core/theme/app_theme.dart';

class OfflineStatusBar extends StatelessWidget {
  const OfflineStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cache = LocalCacheService();

    return AnimatedBuilder(
      animation: cache,
      builder: (context, _) {
        if (!cache.isOffline && cache.pendingSyncCount == 0) {
          return const SizedBox.shrink();
        }

        final isOffline = cache.isOffline;
        final bgColor = isOffline ? RuralCareColors.warningSoft : RuralCareColors.primarySoft;
        final fgColor = isOffline ? RuralCareColors.warning : RuralCareColors.primary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: fgColor.withOpacity(0.2), width: 1.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOffline
                      ? 'Offline Mode — Records saved locally'
                      : 'Syncing ${cache.pendingSyncCount} records to cloud...',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => cache.toggleOfflineMode(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: AppDecorations.statusBadge(
                    background: Colors.white,
                    border: fgColor.withOpacity(0.3),
                  ),
                  child: Text(
                    isOffline ? 'Go Online' : 'Sync Now',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
