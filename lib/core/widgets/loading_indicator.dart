import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const LoadingIndicator({
    super.key, 
    this.size = 24.0, 
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
