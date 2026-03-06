import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/theme_provider.dart';

/// Styled bottom navigation bar with glassmorphism effect.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.lightSurface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.ultraViolet.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor:
              isDark ? AppColors.lemonChiffon : AppColors.ultraViolet,
          unselectedItemColor: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

/// Builds a circular button with glass effect.
Widget buildCircleButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  double size = 56,
}) {
  final isDark = context.watch<ThemeProvider>().isDark(context);

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isDark
          ? AppColors.darkSurface.withValues(alpha: 0.9)
          : AppColors.lightSurface.withValues(alpha: 0.9),
      boxShadow: [
        BoxShadow(
          color: AppColors.ultraViolet.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: IconButton(
      icon: Icon(
        icon,
        color: isDark ? AppColors.lemonChiffon : AppColors.ultraViolet,
      ),
      onPressed: onPressed,
    ),
  );
}

/// Builds a floating action button with glass effect.
Widget buildGlassFAB({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  String? tooltip,
}) {
  final isDark = context.watch<ThemeProvider>().isDark(context);

  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isDark
          ? AppColors.darkSurface.withValues(alpha: 0.9)
          : AppColors.lightSurface.withValues(alpha: 0.9),
      boxShadow: [
        BoxShadow(
          color: AppColors.ultraViolet.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Icon(
        icon,
        color: isDark ? AppColors.lemonChiffon : AppColors.ultraViolet,
      ),
    ),
  );
}

/// Builds an app bar with glass effect.
PreferredSizeWidget buildGlassAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
}) {
  final isDark = context.watch<ThemeProvider>().isDark(context);
  final textColor = isDark ? AppColors.lemonChiffon : AppColors.ultraViolet;

  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.lightSurface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.ultraViolet.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        actions: actions,
        iconTheme: IconThemeData(color: textColor),
      ),
    ),
  );
}

/// A card with glass effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.lightSurface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.ultraViolet.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
