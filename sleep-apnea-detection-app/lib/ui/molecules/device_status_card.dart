import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum DeviceConnectionState {
  connected,
  disconnected,
  lowBattery,
  permissionMissing,
}

class DeviceStatusCard extends StatelessWidget {
  final DeviceConnectionState state;
  final int batteryLevel;
  final String lastSyncText;
  final VoidCallback? onTap;

  const DeviceStatusCard({
    super.key,
    this.state = DeviceConnectionState.connected,
    this.batteryLevel = 84,
    this.lastSyncText = "Last sync 7:02 AM",
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String primaryText;
    String detailText;
    bool isActionable = state != DeviceConnectionState.connected;

    switch (state) {
      case DeviceConnectionState.connected:
        dotColor = AppColors.accentGreen;
        primaryText = "D-BAND connected";
        detailText = "$batteryLevel% · $lastSyncText";
        break;
      case DeviceConnectionState.disconnected:
        dotColor = AppColors.dangerRed;
        primaryText = "D-BAND not found";
        detailText = "Tap to attempt pairing";
        break;
      case DeviceConnectionState.lowBattery:
        dotColor = AppColors.warningAmber;
        primaryText = "Battery low — $batteryLevel%";
        detailText = "Charge sensor before tonight's session";
        break;
      case DeviceConnectionState.permissionMissing:
        dotColor = AppColors.dangerRed;
        primaryText = "Bluetooth access needed";
        detailText = "Tap to allow access in Settings";
        break;
    }

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detailText,
                  style: AppTheme.tabularTextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isActionable)
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
        ],
      ),
    );

    if (isActionable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
