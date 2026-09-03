import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BleSensorStatusOrganism extends StatelessWidget {
  final bool isConnected;
  final String deviceName;
  final String serviceDetails;

  const BleSensorStatusOrganism({
    super.key,
    required this.isConnected,
    this.deviceName = "D-BAND",
    this.serviceDetails = "Service: 0x180D · AES-128 Encrypted",
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? AppColors.accentGreen : AppColors.warningAmber;
    final statusIcon = isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching;
    final statusText = isConnected
        ? "$deviceName Sensor Connected ✓"
        : "Scanning for $deviceName (BLE 5.0+)...";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  serviceDetails,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
