import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UserHeaderOrganism extends StatelessWidget {
  final String firstName;
  final String? lastName;
  final String? customTitle;
  final String? avatarUrl;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onNotificationTap;
  final bool showNotificationBell;
  final bool showCardBackground;

  const UserHeaderOrganism({
    super.key,
    required this.firstName,
    this.lastName,
    this.customTitle,
    this.avatarUrl,
    this.subtitle,
    this.onTap,
    this.onNotificationTap,
    this.showNotificationBell = true,
    this.showCardBackground = false,
  });

  String get initials {
    final firstInitial = firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : '';
    final lastInitial = (lastName != null && lastName!.trim().isNotEmpty) ? lastName!.trim()[0].toUpperCase() : '';
    final combined = '$firstInitial$lastInitial';
    return combined.isNotEmpty ? combined : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatarImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final displayTitle = customTitle ?? "Good Morning, $firstName!";

    final Widget innerContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accentGreen,
                    backgroundImage: hasAvatarImage ? NetworkImage(avatarUrl!) : null,
                    child: !hasAvatarImage
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle ?? "Sep. 28, 2026",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showNotificationBell)
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: onNotificationTap,
          ),
      ],
    );

    if (showCardBackground) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: innerContent,
      );
    }

    return innerContent;
  }
}
