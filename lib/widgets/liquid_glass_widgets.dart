import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/theme_provider.dart';

/// Zero-duration page route — instant transition matching the LiquidGlass
/// design language (no slide / fade animation).
Route<T> noAnimRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
    opaque: true,
  );
}

/// Helper to detect dark mode from the current [Theme] without subscribing
/// to a provider.  Safe to call from top-level builder functions where the
/// passed-in [context] may belong to a different widget.
bool _isDarkFromTheme(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Builds a circular button with glass effect.
Widget buildCircleButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  double size = 56,
}) {
  final isDark = _isDarkFromTheme(context);

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
        color: isDark ? Colors.white : AppColors.ultraViolet,
      ),
      onPressed: onPressed,
    ),
  );
}

/// Builds an app bar with LiquidGlass effect.
///
/// Returns a [Positioned] widget — must be placed inside a [Stack] that fills
/// the [Scaffold.body].  The body content needs top padding of
/// `MediaQuery.of(context).padding.top + kToolbarHeight` so it doesn't hide
/// behind the glass bar.
Widget buildLiquidGlassAppBar(
  BuildContext context, {
  required String title,
  bool showBackButton = true,
  List<Widget>? actions,
}) {
  final double statusBar = MediaQuery.of(context).padding.top;
  final double height = statusBar + kToolbarHeight;
  final settings = liquidGlassSettings(context);

  const double overscan = 40.0;

  return Positioned(
    top: -overscan,
    left: -overscan,
    right: -overscan,
    height: height + overscan,
    child: LiquidGlassLayer(
      settings: settings,
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 0),
        child: Stack(
          children: [
            Positioned(
              top: -overscan,
              left: 0,
              right: 0,
              height: height + overscan * 2,
              child: Container(),
            ),
            Positioned(
              left: overscan,
              right: overscan,
              top: statusBar + overscan,
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (showBackButton) ...[
                    const BackButton(),
                  ] else ...[
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).appBarTheme.titleTextStyle ??
                          Theme.of(context).textTheme.titleLarge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Text(title),
                    ),
                  ),
                  if (actions != null) ...actions,
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Top inset for body content placed below a [buildLiquidGlassAppBar].
double liquidGlassAppBarHeight(BuildContext context) =>
    MediaQuery.of(context).padding.top + kToolbarHeight;

/// Shared LiquidGlass rendering settings for nav bar and buttons.
LiquidGlassSettings liquidGlassSettings(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LiquidGlassSettings(
    thickness: 30,
    blur: 1.4,
    glassColor:
        isDark ? const Color(0x33000000) : const Color(0x18E1E1E1),
  );
}

/// Builds a circular button using real LiquidGlass renderer.
Widget buildLiquidCircleButton({
  required Widget child,
  required double size,
  required LiquidGlassSettings settings,
  VoidCallback? onTap,
  Key? key,
}) {
  final btn = SizedBox(
    key: onTap == null ? key : null,
    width: size,
    height: size,
    child: LiquidGlassLayer(
      settings: settings,
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 100),
        child: Center(child: child),
      ),
    ),
  );

  if (onTap == null) return btn;
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    key: key,
    child: btn,
  );
}

/// Bottom navigation bar with LiquidGlass pill shape and separate circular
/// FAB button outside the pill — matching the XFin reference design.
///
/// Layout: [center nav pill (expanded)] + [right circle button (64px)]
///
/// The active tab is indicated by color/tint change (brighter color on icon
/// and label) — no dot indicator is rendered.
class LiquidGlassBottomNav extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final List<Key> keys;
  final int currentIndex;
  final ValueChanged<int> onTap;

  // RIGHT circular button (separate element outside pill)
  final IconData rightIcon;
  final VoidCallback? onRightTap;
  final Set<int>? rightVisibleForIndices; // null = always visible

  final double height;
  final double horizontalPadding;

  const LiquidGlassBottomNav({
    super.key,
    required this.icons,
    required this.labels,
    required this.keys,
    required this.currentIndex,
    required this.onTap,
    this.rightIcon = Icons.more_horiz,
    this.onRightTap,
    this.rightVisibleForIndices,
    this.height = 56.0,
    this.horizontalPadding = 16.0,
  }) : assert(
            icons.length == labels.length, 'icons and labels must be same length');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final settings = liquidGlassSettings(context);
    const double circleSize = 64.0;
    final double navHeight = height < circleSize ? circleSize : height;

    final bool showRight = rightVisibleForIndices == null ||
        rightVisibleForIndices!.contains(currentIndex);
    const double itemHorizontalPadding = 12.0;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
        child: SizedBox(
          width: double.infinity,
          height: navHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left spacer (mirrors right FAB area for symmetry)
              const SizedBox(width: 76),

              // Center pill (LiquidGlass superellipse)
              Expanded(
                child: SizedBox(
                  height: navHeight,
                  child: LiquidGlassLayer(
                    settings: settings,
                    child: LiquidGlass.grouped(
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: circleSize / 2,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: itemHorizontalPadding,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(circleSize / 2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final int itemCount = icons.length;
                            final double totalAvailable =
                                constraints.maxWidth.isFinite
                                    ? constraints.maxWidth
                                    : MediaQuery.of(context).size.width;

                            const double minItemWidth = 56.0;
                            const double maxItemWidth = 140.0;

                            double perItemWidth = totalAvailable / itemCount;
                            perItemWidth =
                                perItemWidth.clamp(minItemWidth, maxItemWidth);

                            final bool fits =
                                perItemWidth * itemCount <=
                                    totalAvailable + 0.5;

                            if (fits) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    List.generate(itemCount, (index) {
                                  final bool isSelected =
                                      index == currentIndex;
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(index),
                                    key: keys[index],
                                    child: SizedBox(
                                      width: perItemWidth,
                                      height: navHeight,
                                      child: _buildNavColumn(
                                        icon: icons[index],
                                        label: labels[index],
                                        isSelected: isSelected,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            } else {
                              return Row(
                                children:
                                    List.generate(itemCount, (index) {
                                  final bool isSelected =
                                      index == currentIndex;
                                  return Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => onTap(index),
                                      key: keys[index],
                                      child: _buildNavColumn(
                                        icon: icons[index],
                                        label: labels[index],
                                        isSelected: isSelected,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right circular button (separate LiquidGlass circle)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: showRight
                    ? buildLiquidCircleButton(
                        child: Icon(
                          rightIcon,
                          size: 26,
                          color: theme.iconTheme.color,
                        ),
                        size: circleSize,
                        onTap: onRightTap,
                        settings: settings,
                        key: const Key('right_fab'),
                      )
                    : const SizedBox(width: circleSize, height: circleSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavColumn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = isDark ? Colors.white : Colors.black;
    final Color unselectedColor = isDark ? Colors.grey : Colors.black54;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: isSelected ? selectedColor : unselectedColor),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isSelected ? selectedColor : unselectedColor,
              ) ??
              TextStyle(
                fontSize: 11,
                color: isSelected ? selectedColor : unselectedColor,
              ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A card with glass effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);
    final baseColor = color ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : AppColors.lightSurface.withValues(alpha: 0.9));

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: baseColor,
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
