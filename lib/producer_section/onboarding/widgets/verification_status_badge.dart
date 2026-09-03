import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum VerificationBadgeState {
  notVerified,
  checking,
  verified,
  couldNotVerify,
  comingSoon,
}

class VerificationStatusBadge extends StatelessWidget {
  final VerificationBadgeState state;
  final String? customLabel;

  const VerificationStatusBadge({
    super.key,
    required this.state,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (state) {
      case VerificationBadgeState.notVerified:
        bg = AppColors.border.withValues(alpha: 0.5);
        fg = AppColors.textSecondary;
        icon = Icons.info_outline;
        label = customLabel ?? 'Not Verified';
        break;
      case VerificationBadgeState.checking:
        bg = Colors.amber.withValues(alpha: 0.12);
        fg = Colors.amber.shade800;
        icon = Icons.hourglass_top_outlined;
        label = customLabel ?? 'Checking...';
        break;
      case VerificationBadgeState.verified:
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        icon = Icons.verified;
        label = customLabel ?? 'Verified';
        break;
      case VerificationBadgeState.couldNotVerify:
        bg = AppColors.error.withValues(alpha: 0.1);
        fg = AppColors.error;
        icon = Icons.error_outline;
        label = customLabel ?? 'Could Not Verify';
        break;
      case VerificationBadgeState.comingSoon:
        bg = AppColors.primary.withValues(alpha: 0.08);
        fg = AppColors.primary;
        icon = Icons.schedule_outlined;
        label = customLabel ?? 'Coming Soon';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
