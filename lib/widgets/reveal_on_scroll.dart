import 'package:flutter/material.dart';

class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll> {
  bool _revealed = false;
  bool _queued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    Scrollable.maybeOf(context)?.position.isScrollingNotifier
        .addListener(_checkVisibility);
  }

  @override
  void dispose() {
    Scrollable.maybeOf(context)?.position.isScrollingNotifier
        .removeListener(_checkVisibility);
    super.dispose();
  }

  void _checkVisibility() {
    if (_revealed || _queued || !mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      return;
    }

    final viewportHeight = MediaQuery.of(context).size.height;
    final offset = renderObject.localToGlobal(Offset.zero).dy;
    final height = renderObject.size.height;
    final isInViewport = offset < viewportHeight * 0.95 && offset + height > 0;

    if (isInViewport) {
      _queued = true;
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _revealed = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      offset: _revealed ? Offset.zero : widget.beginOffset,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: Curves.easeOut,
        opacity: _revealed ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
