import 'package:flutter/material.dart';

/// An animated list view with staggered animations
class AnimatedListView extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final Duration staggerDelay;
  final Curve curve;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AnimatedListView({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutBack,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<AnimatedListView> createState() => _AnimatedListViewState();
}

class _AnimatedListViewState extends State<AnimatedListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _slideAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 50.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animationControllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimations[index].value),
              child: Opacity(
                opacity: _fadeAnimations[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}

/// An animated grid view with staggered animations
class AnimatedGridView extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final Duration animationDuration;
  final Duration staggerDelay;
  final Curve curve;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AnimatedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutBack,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<AnimatedGridView> createState() => _AnimatedGridViewState();
}

class _AnimatedGridViewState extends State<AnimatedGridView>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animationControllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Opacity(
                opacity: _fadeAnimations[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}

/// A reorderable animated list with smooth transitions
class ReorderableAnimatedList extends StatefulWidget {
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Duration animationDuration;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const ReorderableAnimatedList({
    super.key,
    required this.children,
    this.onReorder,
    this.animationDuration = const Duration(milliseconds: 300),
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  State<ReorderableAnimatedList> createState() => _ReorderableAnimatedListState();
}

class _ReorderableAnimatedListState extends State<ReorderableAnimatedList> {
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);
  }

  @override
  void didUpdateWidget(ReorderableAnimatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children) {
      _children = List.from(widget.children);
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _children.removeAt(oldIndex);
      _children.insert(newIndex, item);
    });
    widget.onReorder?.call(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: widget.scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      onReorder: _handleReorder,
      itemCount: _children.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          key: ValueKey(index),
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          child: _children[index],
        );
      },
    );
  }
}

/// A pull-to-refresh animated list
class PullToRefreshAnimatedList extends StatefulWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Duration animationDuration;
  final Duration staggerDelay;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const PullToRefreshAnimatedList({
    super.key,
    required this.children,
    this.onRefresh,
    this.animationDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  State<PullToRefreshAnimatedList> createState() => _PullToRefreshAnimatedListState();
}

class _PullToRefreshAnimatedListState extends State<PullToRefreshAnimatedList>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _refreshController.forward();
    try {
      await widget.onRefresh?.call();
    } finally {
      _refreshController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: AnimatedBuilder(
        animation: _refreshAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_refreshAnimation.value * 0.02),
            child: AnimatedListView(
              children: widget.children,
              animationDuration: widget.animationDuration,
              staggerDelay: widget.staggerDelay,
              scrollController: widget.scrollController,
              padding: widget.padding,
              shrinkWrap: widget.shrinkWrap,
            ),
          );
        },
      ),
    );
  }
}
