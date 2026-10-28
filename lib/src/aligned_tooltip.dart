import 'dart:async';

import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_tooltip/src/models/target_information.dart';
import 'package:aligned_tooltip/src/positioned_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

part 'aligned_tooltip_entry.dart';

/// Signature of [AlignedTooltipController.showTooltip].
///
/// If `immediately` is true, the tooltip is shown on the next frame instead of
/// after [AlignedTooltipInterface.waitDuration].
typedef ShowTooltip = Future<void> Function({
  bool immediately,

  /// If set to true, this will set the timer for the tooltip to close.
  bool autoClose,
});

/// Signature of [AlignedTooltipController.hideTooltip].
///
/// If `immediately` is true, the tooltip is removed without waiting and
/// without a fade out animation.
typedef HideTooltip = Future<void> Function({bool immediately});

/// {@macro aligned_tooltip.overlay.constructor}
///
/// The tooltip is inserted in the closest [Overlay] (for example the one of
/// the [Navigator] of a [MaterialApp]). Use [AlignedTooltipEntry] together
/// with an [AlignedTooltipArea] to place the tooltip somewhere else in the
/// widget tree.
///
/// {@tool snippet}
///
/// ```dart
/// AlignedTooltip(
///   preferredDirection: AxisDirection.up,
///   content: const Padding(
///     padding: EdgeInsets.all(8.0),
///     child: Text('Some helpful text'),
///   ),
///   child: const Icon(Icons.info),
/// )
/// ```
/// {@end-tool}
class AlignedTooltip extends StatefulWidget implements AlignedTooltipInterface {
  /// Creates a tooltip that shows [content] next to [child].
  ///
  /// By default the tooltip is shown when [child] is long pressed or hovered
  /// with a mouse, below [child] if there is enough space and above it
  /// otherwise.
  const AlignedTooltip({
    super.key,
    required this.content,
    required this.child,
    this.onDismiss,
    this.onShow,
    this.controller,
    // TODO: With the new [triggerMode] field isModal's only function is to keep
    // the tooltip open. But in that case, it seems like we can create a new
    // more narrow field in favor.
    this.isModal = false,
    this.waitDuration,
    this.showDuration,
    this.triggerMode,
    this.barrierDismissible = true,
    this.barrierColor = Colors.transparent,
    this.barrierBuilder,
    this.enableFeedback,
    this.hoverShowDuration,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.fadeOutDuration = const Duration(milliseconds: 75),
    this.preferredDirection = AxisDirection.down,
    this.curve = Curves.easeInOut,
    this.reverseCurve = Curves.easeInOut,
    this.margin = const EdgeInsets.all(8.0),
    this.offset = 0.0,
    this.elevation = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.tailLength = 16.0,
    this.tailBaseWidth = 32.0,
    this.tailBuilder = AlignedTooltipInterface.defaultTailBuilder,
    this.animatedTransitionBuilder =
        AlignedTooltipInterface.defaultAnimatedTransitionBuilder,
    this.backgroundColor,
    this.textDirection = TextDirection.ltr,
    this.shadow,
    this.showWhenUnlinked = false,
    this.scrollController,
  });

  @override
  final AlignedTooltipController? controller;

  @override
  final Widget content;

  @override
  final Widget child;

  @override
  final VoidCallback? onDismiss;

  @override
  final VoidCallback? onShow;

  @override
  final bool isModal;

  @override
  final Duration? waitDuration;

  @override
  final Duration? showDuration;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final TooltipTriggerMode? triggerMode;

  @override
  final bool? enableFeedback;

  @override
  final Widget Function(BuildContext, Animation<double>, VoidCallback)?
      barrierBuilder;

  @override
  final Duration? hoverShowDuration;

  @override
  final AxisDirection preferredDirection;

  @override
  final Duration fadeInDuration;

  @override
  final Duration fadeOutDuration;

  @override
  final Curve curve;

  @override
  final Curve reverseCurve;

  @override
  final EdgeInsetsGeometry margin;

  @override
  final double offset;

  @override
  final double elevation;

  @override
  final BorderRadiusGeometry borderRadius;

  @override
  final double tailLength;

  @override
  final double tailBaseWidth;

  @override
  final TailBuilder tailBuilder;

  @override
  final AnimatedTransitionBuilder animatedTransitionBuilder;

  @override
  final Color? backgroundColor;

  @override
  final TextDirection textDirection;

  @override
  final Shadow? shadow;

  @override
  final bool showWhenUnlinked;

  @override
  final ScrollController? scrollController;

  @override
  AlignedTooltipState<OverlayEntry> createState() =>
      _AlignedTooltipOverlayState();
}

class _AlignedTooltipOverlayState extends AlignedTooltipState<OverlayEntry> {
  @override
  OverlayEntry? entry;

  @override
  OverlayEntry? skrim;

  @override
  Future<bool> ensureTooltipVisible() async {
    cancelShowTimer();

    if (!mounted) {
      return false;
    }

    // Already visible.
    if (hasEntry) {
      cancelHideTimer();

      await _animationController.forward();
      return false;
    }

    _createNewEntries();
    await _animationController.forward();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      Overlay.maybeOf(context) != null,
      '${widget.runtimeType} require an Overlay widget ancestor for correct operation.',
    );

    return super.build(context);
  }

  @override
  void _createNewEntries() {
    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      throw StateError('Cannot find the overlay for the context $context');
    }

    final entryOverlay = OverlayEntry(builder: (context) => _createEntry());
    entry = entryOverlay;

    // In the case of a modal, we enter a skrim overlay to catch taps.
    if (widget.isModal) {
      final skrimOverlay = OverlayEntry(builder: (context) => _createSkrim());
      skrim = skrimOverlay;

      overlay.insert(skrimOverlay);
      overlay.insert(entryOverlay, above: skrimOverlay);
    } else {
      overlay.insert(entryOverlay);
    }
  }

  @override
  void _removeEntries() {
    cancelHideTimer();
    cancelShowTimer();

    final entry = this.entry;
    final skrim = this.skrim;
    this.entry = null;
    this.skrim = null;

    // The skrim is removed even if the tooltip is no longer modal: it might
    // have been inserted before [AlignedTooltip.isModal] changed.
    for (final overlayEntry in [entry, skrim]) {
      overlayEntry
        ?..remove()
        ..dispose();
    }
  }

  @override
  void _markEntriesNeedsBuild() {
    // The entries live in the overlay and are not rebuilt when this widget
    // rebuilds. The overlay cannot be marked as dirty during the build of this
    // widget, so it is done right after.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      entry?.markNeedsBuild();
      skrim?.markNeedsBuild();
    });
  }
}

/// This is almost a one to one mapping to [Tooltip]'s state except for the
/// fact it is setup to handle two Tooltip cases. Abstract methods are replaced
/// with implementations that are specific to the tooltip type.
///
/// [T] is the type of the entries inserted in the tree to show the tooltip:
/// [OverlayEntry] for [AlignedTooltip] and [Widget] for [AlignedTooltipEntry].
// TODO: This looks more idiomatic as a mixin.
abstract class AlignedTooltipState<T> extends State<AlignedTooltipInterface>
    with SingleTickerProviderStateMixin {
  /// Abstract constructor, for the states of [AlignedTooltip] and
  /// [AlignedTooltipEntry].
  AlignedTooltipState();

  /// The entry showing the tooltip content, if any.
  T? get entry;

  /// The entry showing the barrier behind the tooltip, if any.
  T? get skrim;

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible or if the context has
  /// become null.
  ///
  /// Copied from [Tooltip]
  Future<bool> ensureTooltipVisible();

  /// Creates both the tooltip entry and the tooltip entry. How they are
  /// inserted into the tree is dependent on tooltip strategy of using
  /// overlays or widgets.
  // ignore: unused_element
  void _createNewEntries();

  /// Removes the tooltip entry and tooltip entry.
  void _removeEntries();

  /// Rebuilds the visible entries with the current configuration.
  void _markEntriesNeedsBuild();

  /// Whether this tooltip is currently shown.
  bool get hasEntry => entry != null;

  /// A key derived from the key of the widget, if any.
  Key? get entryKey {
    final key = widget.key;
    return key == null ? null : ValueKey('__entry_${key}__');
  }

  /// A key derived from the key of the widget used for the barrier, if any.
  Key? get skrimKey {
    final key = widget.key;
    return key == null ? null : Key('__skrim_${key}__');
  }

  // All of these are taken from default tooltip
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultHoverShowDuration = Duration(milliseconds: 100);
  static const Duration _defaultWaitDuration = Duration.zero;
  static const TooltipTriggerMode _defaultTriggerMode =
      TooltipTriggerMode.longPress;
  static const bool _defaultEnableFeedback = true;

  late final AnimationController _animationController;
  late final CurvedAnimation _fadeAnimation;
  Timer? _hideTimer;
  Timer? _showTimer;

  /// How long the tooltip stays visible after a long press or a tap is
  /// released. Resolved in [build].
  late Duration showDuration;

  /// How long the tooltip stays visible after the mouse exits the target or
  /// after the tooltip is hidden without `immediately`. Resolved in [build].
  late Duration hoverShowDuration;

  /// How long a pointer must hover the target before the tooltip is shown.
  /// Resolved in [build].
  late Duration waitDuration;

  bool _pressActivated = false;

  /// The resolved trigger mode. Resolved in [build].
  late TooltipTriggerMode triggerMode;

  /// Whether feedback is provided when the tooltip is triggered. Resolved in
  /// [build].
  late bool enableFeedback;

  /// The value of [AlignedTooltipInterface.barrierDismissible].
  late bool barrierDismissible;

  /// The value of [AlignedTooltipInterface.barrierColor].
  late Color barrierColor;

  /// The value of [AlignedTooltipInterface.barrierBuilder].
  late Widget Function(BuildContext, Animation<double>, VoidCallback)?
      barrierBuilder;

  // These properties are specific to aligned_tooltip
  late AlignedTooltipController _controller;
  bool _hasBindingListeners = false;
  final _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    // Handles global tap gestures.
    if (!widget.isModal) {
      _addBindingListeners();
    }

    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      reverseDuration: widget.fadeOutDuration,
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );

    _controller = widget.controller ?? AlignedTooltipController();
    _attachController(_controller);
  }

  /// This sucker just gives the controller the newest versions of the
  /// callbacks we have in this state.
  void _attachController(AlignedTooltipController controller) {
    controller.attach(
      showTooltip: _showTooltip,
      hideTooltip: _hideTooltip,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The entries use the theme of this widget.
    _markEntriesNeedsBuild();
  }

  @override
  void didUpdateWidget(covariant AlignedTooltipInterface oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldController = oldWidget.controller;
    final newController = widget.controller;

    if (oldController != newController) {
      // If we did not have a controller before, we created one that must now
      // be disposed.
      if (oldController == null) {
        _controller.dispose();
      }
      _controller = newController ??
          AlignedTooltipController(
            value: hasEntry ? TooltipStatus.isShowing : TooltipStatus.isHidden,
          );
    }

    // Update the functions on our controller
    _attachController(_controller);

    if (oldWidget.isModal != widget.isModal) {
      if (widget.isModal) {
        _removeBindingListeners();
      } else {
        _addBindingListeners();
      }
    }

    _animationController
      ..duration = widget.fadeInDuration
      ..reverseDuration = widget.fadeOutDuration;
    _fadeAnimation
      ..curve = widget.curve
      ..reverseCurve = widget.reverseCurve;

    _markEntriesNeedsBuild();
  }

  void _addBindingListeners() {
    if (_hasBindingListeners) return;

    _hasBindingListeners = true;

    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  void _removeBindingListeners() {
    if (!_hasBindingListeners) return;

    _hasBindingListeners = false;

    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && hasEntry) {
      _hideTooltip(immediately: true);
    }
  }

  /// Hides the tooltip if it is currently visible. If [immediately] is true,
  /// the tooltip will be hidden immediately. Otherwise, the tooltip will be
  /// hidden after the current animation completes. In either case,
  /// this future will complete once the tooltip has been completely hidden.
  Future<void> _hideTooltip({bool immediately = false}) {
    cancelShowTimer();

    final completer = Completer<void>();
    final future = completer.future;

    if (immediately) {
      final wasShowing = hasEntry;

      if (wasShowing) {
        widget.onDismiss?.call();
      }

      if (mounted) {
        _controller.value = TooltipStatus.isHidden;
      }

      _removeEntries();

      // Next time the tooltip is shown, it fades in again.
      if (mounted) {
        _animationController.reset();
      }

      completer.complete();
      return future;
    }

    Future<void> reverse() async {
      if (mounted) {
        await _animationController.reverse();
      }
      completer.complete();
    }

    if (_pressActivated) {
      _hideTimer ??= Timer(showDuration, reverse);
    } else {
      _hideTimer ??= Timer(hoverShowDuration, reverse);
    }

    _pressActivated = false;

    return future;
  }

  Future<void> _showTooltip({
    bool immediately = false,

    /// This will usually be only true in the case of a controller requesting
    /// to show the tooltip as a regular pointer event will cause a pointer up
    /// event to be fired, which in turn will set a hide timer.
    bool autoClose = false,
  }) {
    if (!mounted) {
      return Future<void>.value();
    }

    cancelHideTimer();

    final completer = Completer<void>();
    final future = completer.future.then((_) {
      if (!mounted) {
        return;
      }

      _handleShown();

      if (autoClose) {
        _hideTooltip();
      }
    });

    if (immediately) {
      // We add a postFrameCallback here because we need run *after* the global
      // _handlePointerEvent has been called (which happens after every tap
      // event).
      SchedulerBinding.instance
        ..addPostFrameCallback((_) async {
          if (mounted) {
            await ensureTooltipVisible();
          }
          completer.complete();
        })
        // Post frame callbacks do not schedule a frame by themselves.
        ..ensureVisualUpdate();

      return future;
    }

    _showTimer ??= Timer(waitDuration, () async {
      if (mounted) {
        await ensureTooltipVisible();
      }
      completer.complete();
    });

    return future;
  }

  /// Called once the tooltip is fully visible.
  void _handleShown() {
    widget.onShow?.call();
    _controller.value = TooltipStatus.isShowing;
  }

  /// Cancels the timer that will show the tooltip, if any.
  void cancelShowTimer() {
    _showTimer?.cancel();
    _showTimer = null;
  }

  /// Cancels the timer that will hide the tooltip, if any.
  void cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _handlePointerEvent(PointerEvent event) {
    if (!hasEntry) {
      return;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _hideTooltip();
    } else if (event is PointerDownEvent) {
      _hideTooltip(immediately: true);
    }
  }

  @override
  void deactivate() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasEntry) {
        _hideTooltip(immediately: true);
      }

      cancelShowTimer();
    });

    super.deactivate();
  }

  @override
  void dispose() {
    _removeBindingListeners();
    cancelShowTimer();
    cancelHideTimer();

    _fadeAnimation.dispose();
    _animationController.dispose();

    // If we've made our own controller because the user's is null, we need to
    // dispose of it.
    if (widget.controller == null) {
      _controller.dispose();
    }

    // The entries are removed after the frame, see [deactivate]. This makes
    // sure they are removed even if they were not shown anymore by then.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _removeEntries();
    });

    super.dispose();
  }

  Future<void> _handlePress() async {
    _pressActivated = true;

    final tooltipCreated = !hasEntry;
    if (tooltipCreated && enableFeedback) {
      if (triggerMode == TooltipTriggerMode.longPress) {
        Feedback.forLongPress(context);
      } else {
        Feedback.forTap(context);
      }
    }

    await ensureTooltipVisible();

    if (mounted) {
      _handleShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltipTheme = TooltipTheme.of(context);

    waitDuration = widget.waitDuration ??
        tooltipTheme.waitDuration ??
        _defaultWaitDuration;
    showDuration = widget.showDuration ??
        tooltipTheme.showDuration ??
        _defaultShowDuration;
    hoverShowDuration = widget.hoverShowDuration ??
        widget.showDuration ??
        tooltipTheme.showDuration ??
        _defaultHoverShowDuration;
    triggerMode =
        widget.triggerMode ?? tooltipTheme.triggerMode ?? _defaultTriggerMode;
    enableFeedback = widget.enableFeedback ??
        tooltipTheme.enableFeedback ??
        _defaultEnableFeedback;
    barrierDismissible = widget.barrierDismissible;
    barrierColor = widget.barrierColor;
    barrierBuilder = widget.barrierBuilder;

    Widget result;

    if (triggerMode == TooltipTriggerMode.manual) {
      result = widget.child;
    } else {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: widget.isModal
            ? null
            : (triggerMode == TooltipTriggerMode.longPress)
                ? _handlePress
                : null,
        onTap: widget.isModal
            ? _showTooltip
            : (triggerMode == TooltipTriggerMode.tap)
                ? _handlePress
                : null,
        excludeFromSemantics: true,
        child: widget.child,
      );

      // The mouse region is always present for non modal tooltips, even
      // without a mouse, so that the subtree is not rebuilt from scratch when
      // a mouse is connected or disconnected.
      if (!widget.isModal) {
        result = MouseRegion(
          onEnter: (PointerEnterEvent event) => _showTooltip(),
          onExit: (PointerExitEvent event) => _hideTooltip(),
          child: result,
        );
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: result,
    );
  }

  Widget _createSkrim() {
    if (barrierBuilder != null) {
      return Container(
        key: skrimKey,
        child: barrierBuilder!(context, _animationController, _hideTooltip),
      );
    }
    return GestureDetector(
      key: skrimKey,
      behavior: barrierDismissible
          ? HitTestBehavior.translucent
          : HitTestBehavior.deferToChild,
      onTap: _hideTooltip,
      child: Container(color: barrierColor),
    );
  }

  Widget _createEntry() {
    // This is single use because after we've gotten the size and position,
    // if that child changes then this information will be stale.
    final targetInformation = _getTargetInformation(context);
    final theme = Theme.of(context);
    final defaultShadow = Shadow(
      offset: Offset.zero,
      blurRadius: 0.0,
      color: theme.shadowColor,
    );

    return CompositedTransformFollower(
      showWhenUnlinked: widget.showWhenUnlinked,
      offset: targetInformation.offsetToTarget,
      link: _layerLink,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Directionality(
          textDirection: widget.textDirection,
          child: Builder(
            builder: (context) {
              final scrollController = widget.scrollController;
              final wrappedChild = Material(
                type: MaterialType.transparency,
                child: widget.content,
              );

              if (scrollController != null) {
                return AnimatedBuilder(
                  animation: scrollController,
                  child: wrappedChild,
                  builder: (context, child) {
                    return PositionedTooltip(
                      animatedTransitionBuilder:
                          widget.animatedTransitionBuilder,
                      margin: widget.margin,
                      targetSize: targetInformation.size,
                      target: targetInformation.target,
                      offset: widget.offset,
                      preferredDirection: widget.preferredDirection,
                      offsetToTarget: targetInformation.offsetToTarget,
                      borderRadius: widget.borderRadius,
                      tailBaseWidth: widget.tailBaseWidth,
                      tailLength: widget.tailLength,
                      tailBuilder: widget.tailBuilder,
                      backgroundColor:
                          widget.backgroundColor ?? theme.cardColor,
                      textDirection: widget.textDirection,
                      shadow: widget.shadow ?? defaultShadow,
                      elevation: widget.elevation,
                      scrollPosition: scrollController.position,
                      child: child!,
                    );
                  },
                );
              }

              return PositionedTooltip(
                animatedTransitionBuilder: widget.animatedTransitionBuilder,
                margin: widget.margin,
                targetSize: targetInformation.size,
                target: targetInformation.target,
                offset: widget.offset,
                preferredDirection: widget.preferredDirection,
                offsetToTarget: targetInformation.offsetToTarget,
                borderRadius: widget.borderRadius,
                tailBaseWidth: widget.tailBaseWidth,
                tailLength: widget.tailLength,
                tailBuilder: widget.tailBuilder,
                backgroundColor: widget.backgroundColor ?? theme.cardColor,
                textDirection: widget.textDirection,
                shadow: widget.shadow ?? defaultShadow,
                elevation: widget.elevation,
                scrollPosition: null,
                child: wrappedChild,
              );
            },
          ),
        ),
      ),
    );
  }

  /// This assumes the caller itself is the target
  TargetInformation _getTargetInformation(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;

    if (box == null) {
      throw StateError(
        'Cannot find the box for the given object with context $context',
      );
    }

    final targetSize = box.getDryLayout(const BoxConstraints.tightForFinite());
    final target = box.localToGlobal(box.size.center(Offset.zero));
    // TODO: Instead of this, change the alignment on
    // [CompositedTransformFollower]. That way we can allow a user configurable
    // alignment on where the tooltip ends up.
    final offsetToTarget = Offset(
      -target.dx + box.size.width / 2,
      -target.dy + box.size.height / 2,
    );

    return TargetInformation(
      targetSize,
      target,
      offsetToTarget,
    );
  }
}
