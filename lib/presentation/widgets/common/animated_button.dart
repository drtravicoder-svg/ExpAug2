import 'package:flutter/material.dart';

/// An animated button with loading states and smooth transitions
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Duration animationDuration;
  final ButtonStyle? style;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.animationDuration = const Duration(milliseconds: 200),
    this.style,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.isLoading || widget.isDisabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isLoading || widget.isDisabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (widget.isLoading || widget.isDisabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              opacity: widget.isDisabled ? 0.5 : _opacityAnimation.value,
              duration: widget.animationDuration,
              child: SizedBox(
                width: widget.width,
                height: widget.height ?? 48,
                child: ElevatedButton(
                  onPressed: isEnabled ? widget.onPressed : null,
                  style: widget.style ?? ElevatedButton.styleFrom(
                    backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
                    foregroundColor: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                    padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                    ),
                    elevation: _isPressed ? 2 : 4,
                  ),
                  child: AnimatedSwitcher(
                    duration: widget.animationDuration,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.foregroundColor ?? theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A floating action button with animation
class AnimatedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;
  final Duration animationDuration;

  const AnimatedFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: widget.isExtended && widget.label != null
                ? FloatingActionButton.extended(
                    onPressed: widget.onPressed,
                    icon: Icon(widget.icon),
                    label: Text(widget.label!),
                    tooltip: widget.tooltip,
                    backgroundColor: widget.backgroundColor,
                    foregroundColor: widget.foregroundColor,
                  )
                : FloatingActionButton(
                    onPressed: widget.onPressed,
                    tooltip: widget.tooltip,
                    backgroundColor: widget.backgroundColor,
                    foregroundColor: widget.foregroundColor,
                    child: Icon(widget.icon),
                  ),
          ),
        );
      },
    );
  }
}

/// A toggle button with smooth animation
class AnimatedToggleButton extends StatefulWidget {
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final String label;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Duration animationDuration;

  const AnimatedToggleButton({
    super.key,
    required this.isSelected,
    required this.onChanged,
    required this.label,
    this.selectedIcon,
    this.unselectedIcon,
    this.selectedColor,
    this.unselectedColor,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _updateAnimations();

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    _updateAnimations();
  }

  void _updateAnimations() {
    final theme = Theme.of(context);
    _colorAnimation = ColorTween(
      begin: widget.unselectedColor ?? theme.colorScheme.surfaceVariant,
      end: widget.selectedColor ?? theme.colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isSelected),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: widget.animationDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? (widget.selectedColor ?? theme.colorScheme.primary)
                      : theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.selectedIcon != null && widget.unselectedIcon != null)
                    AnimatedSwitcher(
                      duration: widget.animationDuration,
                      child: Icon(
                        widget.isSelected ? widget.selectedIcon : widget.unselectedIcon,
                        key: ValueKey(widget.isSelected),
                        size: 18,
                        color: widget.isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (widget.selectedIcon != null && widget.unselectedIcon != null)
                    const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: widget.isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
