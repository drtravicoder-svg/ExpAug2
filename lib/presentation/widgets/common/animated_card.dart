import 'package:flutter/material.dart';

/// An animated card widget with hover effects and smooth transitions
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final bool enableHoverEffect;
  final bool enableScaleAnimation;
  final double hoverScale;
  final double? width;
  final double? height;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHoverEffect = true,
    this.enableScaleAnimation = true,
    this.hoverScale = 1.02,
    this.width,
    this.height,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHoverEnter() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = true);
    _animationController.forward();
  }

  void _handleHoverExit() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = false);
    _animationController.reverse();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    if (widget.enableScaleAnimation) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) => _handleHoverEnter(),
        onExit: (_) => _handleHoverExit(),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.enableScaleAnimation || widget.enableHoverEffect
                    ? _scaleAnimation.value
                    : 1.0,
                child: Card(
                  elevation: widget.enableHoverEffect
                      ? _elevationAnimation.value
                      : widget.elevation ?? 2.0,
                  color: widget.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  ),
                  child: AnimatedContainer(
                    duration: widget.animationDuration,
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                      boxShadow: _isPressed
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A specialized animated card for expense items
class ExpenseCard extends StatelessWidget {
  final String title;
  final String amount;
  final String category;
  final String date;
  final String paidBy;
  final VoidCallback? onTap;
  final bool isApproved;
  final bool isPending;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paidBy,
    this.onTap,
    this.isApproved = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor = theme.colorScheme.surface;
    IconData statusIcon = Icons.check_circle;
    
    if (isPending) {
      statusColor = theme.colorScheme.warning;
      statusIcon = Icons.pending;
    } else if (isApproved) {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.check_circle;
    }

    return AnimatedCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Paid by $paidBy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Extension for theme colors
extension ThemeExtension on ColorScheme {
  Color get warning => const Color(0xFFFF9800);
  Color get success => const Color(0xFF4CAF50);
  Color get info => const Color(0xFF2196F3);
}
