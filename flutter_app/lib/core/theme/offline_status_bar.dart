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

        return Container(
          width: double.infinity,
          color: cache.isOffline ? RuralCareColors.warningBg : RuralCareColors.infoBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                cache.isOffline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                size: 18,
                color: cache.isOffline ? RuralCareColors.warning : RuralCareColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cache.isOffline
                      ? 'Offline Mode — Records saved locally (ऑफलाइन मोड - सुरक्षित सेव्ह केले)'
                      : 'Syncing ${cache.pendingSyncCount} records to cloud...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cache.isOffline ? RuralCareColors.warning : RuralCareColors.info,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => cache.toggleOfflineMode(),
                child: Text(
                  cache.isOffline ? 'Go Online' : 'Sync Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: cache.isOffline ? RuralCareColors.warning : RuralCareColors.info,
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
