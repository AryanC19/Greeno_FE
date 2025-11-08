import 'package:flutter/material.dart';

/// Unified gradient app bar (visual only, no business logic).
/// Safe for older Flutter SDKs (uses withOpacity, not withValues).
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final List<Widget>? extraActions;
  final Widget? leadingOverride;
  final Color gradientStart;
  final Color gradientEnd;
  final double elevation;

  const GradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.actionIcon,
    this.onAction,
    this.extraActions,
    this.leadingOverride,
    this.gradientStart = const Color(0xFF1E88E5),
    this.gradientEnd = const Color(0xFF42A5F5),
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: elevation,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: leadingOverride ?? (showBack
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            )
          : null),
      title: titleWidget ?? Text(
        title ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
            fontWeight: FontWeight.w600,
          letterSpacing: .4,
        ),
      ),
      actions: [
        if (actionIcon != null)
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              child: IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon, color: gradientStart, size: 22),
              ),
            ),
          ),
        if (extraActions != null) ...extraActions!,
      ],
    );
  }
}

/// Helper builder for convenience.
PreferredSizeWidget buildGradientAppBar({
  String? title,
  Widget? titleWidget,
  bool showBack = true,
  IconData? actionIcon,
  VoidCallback? onAction,
  List<Widget>? extraActions,
  Widget? leadingOverride,
  Color gradientStart = const Color(0xFF1E88E5),
  Color gradientEnd = const Color(0xFF42A5F5),
  double elevation = 0,
}) {
  return GradientAppBar(
    title: title,
    titleWidget: titleWidget,
    showBack: showBack,
    actionIcon: actionIcon,
    onAction: onAction,
    extraActions: extraActions,
    leadingOverride: leadingOverride,
    gradientStart: gradientStart,
    gradientEnd: gradientEnd,
    elevation: elevation,
  );
}
