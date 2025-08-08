import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated input field with floating labels and smooth transitions
class AnimatedInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final Duration animationDuration;
  final bool showCharacterCount;

  const AnimatedInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.animationDuration = const Duration(milliseconds: 200),
    this.showCharacterCount = false,
  });

  @override
  State<AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _errorAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_handleFocusChange);
    
    if (widget.controller != null) {
      widget.controller!.addListener(_handleTextChange);
      _hasText = widget.controller!.text.isNotEmpty;
    }

    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      _currentError = widget.errorText;
      _updateErrorAnimation();
    }
    _updateAnimations();
  }

  void _updateAnimations() {
    final theme = Theme.of(context);
    _borderColorAnimation = ColorTween(
      begin: theme.colorScheme.outline,
      end: _currentError != null
          ? theme.colorScheme.error
          : theme.colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _updateErrorAnimation() {
    if (_currentError != null) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_hasText || _isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColorAnimation.value ?? theme.colorScheme.outline,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  // Input field
                  TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    validator: widget.validator,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onSubmitted,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    enabled: widget.enabled,
                    maxLines: widget.maxLines,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    decoration: InputDecoration(
                      hintText: _isFocused || _hasText ? widget.hint : null,
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: widget.suffixIcon,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(
                        16,
                        widget.prefixIcon != null ? 16 : 20,
                        16,
                        16,
                      ),
                      counterText: widget.showCharacterCount ? null : '',
                    ),
                  ),
                  
                  // Floating label
                  Positioned(
                    left: 16,
                    top: _labelAnimation.value * 4 + 8,
                    child: AnimatedDefaultTextStyle(
                      duration: widget.animationDuration,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: _isFocused
                            ? (_currentError != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary)
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: _isFocused || _hasText ? 12 : 16,
                        fontWeight: _isFocused ? FontWeight.w500 : FontWeight.w400,
                      ),
                      child: Text(widget.label),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Error text with animation
        AnimatedBuilder(
          animation: _errorAnimation,
          builder: (context, child) {
            return AnimatedContainer(
              duration: widget.animationDuration,
              height: _currentError != null ? 24 : 0,
              child: _currentError != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Opacity(
                        opacity: _errorAnimation.value,
                        child: Text(
                          _currentError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
        
        // Character count
        if (widget.showCharacterCount && widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A specialized input field for currency amounts
class CurrencyInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String currencySymbol;
  final bool enabled;

  const CurrencyInputField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.currencySymbol = '\$',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedInputField(
      label: label,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      prefixIcon: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          currencySymbol,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A search input field with animated search icon
class SearchInputField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final Duration animationDuration;

  const SearchInputField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;
  
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.controller != null) {
      widget.controller!.addListener(_handleTextChange);
      _hasText = widget.controller!.text.isNotEmpty;
    }
  }

  void _handleTextChange() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_hasText) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleClear() {
    widget.controller?.clear();
    widget.onClear?.call();
    _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: AnimatedBuilder(
            animation: _iconRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _iconRotationAnimation.value * 0.5,
                child: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          suffixIcon: AnimatedSwitcher(
            duration: widget.animationDuration,
            child: _hasText
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _handleClear,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
