library scroll_loop_auto_scroll;

import 'package:flutter/material.dart';

class ScrollLoopAutoScroll extends StatefulWidget {
  const ScrollLoopAutoScroll({
    required this.child,
    required this.scrollDirection,
    Key? key,
    this.delay = const Duration(seconds: 1),
    this.duration = const Duration(seconds: 50),
    this.gap = 25,
    this.reverseScroll = false,
    this.duplicateChild,
    this.enableScrollInput = true,
    this.delayAfterScrollInput = const Duration(seconds: 1),
  }) : super(key: key);

  /// Widget to display in loop
  final Widget child;

  /// Duration to wait before starting animation
  final Duration delay;

  /// Duration of animation
  final Duration duration;

  /// Spacing between end of one child and beginning of next
  final double gap;

  /// The axis along which the scroll view scrolls
  final Axis scrollDirection;

  /// Reverse scroll direction
  final bool reverseScroll;

  /// The number of times to duplicate the child
  final int? duplicateChild;

  /// Enable user input for scrolling
  final bool enableScrollInput;

  /// Duration to wait before resuming animation after user input
  final Duration delayAfterScrollInput;

  @override
  State<ScrollLoopAutoScroll> createState() => _ScrollLoopAutoScrollState();
}

class _ScrollLoopAutoScrollState extends State<ScrollLoopAutoScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController control;
  late final Animation<Offset> transition;

  final ValueNotifier<bool> triggerScroll = ValueNotifier<bool>(false);
  late final ScrollController controller;

  @override
  void initState() {
    controller = ScrollController();

    controller.addListener(() async {
      if (widget.enableScrollInput) {
        if (control.isAnimating) {
          control.stop();
        } else {
          await Future.delayed(widget.delayAfterScrollInput);
          triggerAnimation();
        }
      }
    });

    control = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    transition = Tween<Offset>(
      begin: Offset.zero,
      end: widget.scrollDirection == Axis.horizontal
          ? widget.reverseScroll
              ? const Offset(.5, 0)
              : const Offset(-.5, 0)
          : widget.reverseScroll
              ? const Offset(0, .5)
              : const Offset(0, -.5),
    ).animate(control);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(widget.delay);
      triggerAnimation();
    });

    super.initState();
  }

  void triggerAnimation() async {
    if (controller.position.maxScrollExtent > 0) {
      triggerScroll.value = true;

      if (triggerScroll.value && mounted) {
        control.forward().then((_) async {
          control.reset();

          if (triggerScroll.value && mounted) {
            triggerAnimation();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: transition,
      child: ValueListenableBuilder<bool>(
        valueListenable: triggerScroll,
        builder: (BuildContext context, bool active, _) {
          return widget.scrollDirection == Axis.horizontal
              ? ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.duplicateChild ?? 0,
                  physics: widget.enableScrollInput
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: active && !widget.reverseScroll ? widget.gap : 0,
                        left: active && widget.reverseScroll ? widget.gap : 0,
                      ),
                      child: widget.child,
                    );
                  },
                )
              : ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.duplicateChild ?? 0,
                  physics: widget.enableScrollInput
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            active && !widget.reverseScroll ? widget.gap : 0,
                        top: active && widget.reverseScroll ? widget.gap : 0,
                      ),
                      child: widget.child,
                    );
                  },
                );
        },
      ),
    );
  }

  @override
  void dispose() {
    control.dispose();
    super.dispose();
  }
}
