import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SpaceSwitcherHeader extends StatelessWidget {
  final String activeSpaceName;
  final String activeSpaceType; // 'personal' or 'business'
  final VoidCallback onSwitchSpace;
  final VoidCallback onOpenNotifications;

  const SpaceSwitcherHeader({
    super.key,
    required this.activeSpaceName,
    required this.activeSpaceType,
    required this.onSwitchSpace,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusiness = activeSpaceType == 'business';

    final badgeColor = isBusiness
        ? (isDark ? AppColors.businessDark : AppColors.businessAccent)
        : (isDark ? AppColors.accentDark : AppColors.accent);

    final badgeBg = isBusiness
        ? (isDark ? AppColors.businessDark.withOpacity(0.2) : AppColors.businessSoft)
        : (isDark ? AppColors.accentDark.withOpacity(0.2) : AppColors.accentSoft);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Space Switcher Dropdown Capsule
        InkWell(
          onTap: onSwitchSpace,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Type Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBusiness ? Icons.storefront_outlined : Icons.person_outline,
                        size: 13,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBusiness ? 'Bisnis' : 'Personal',
                        style: AppTypography.labelSmall(color: badgeColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  activeSpaceName,
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // Notifications & Settings Icon
        Row(
          children: [
            IconButton(
              onPressed: onOpenNotifications,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
