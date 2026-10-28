part of 'aligned_tooltip.dart';

/// A Tooltip widget that delegates to creation and use of the tooltip and
/// skrim to the outer [AlignedTooltipArea]. This class is useless if not
/// nested within a [AlignedTooltipArea].
///
/// {@macro aligned_tooltip.overlay.constructor}
///
/// Only one [AlignedTooltipEntry] of an [AlignedTooltipArea] is shown at a
/// time: showing an entry replaces the tooltip of any other entry of the same
/// area.
class AlignedTooltipEntry extends StatefulWidget
    implements AlignedTooltipInterface {
  /// Creates a tooltip that shows [content] next to [child] in the closest
  /// [AlignedTooltipArea].
  ///
  /// The parameters have the same meaning as the ones of [AlignedTooltip].
  const AlignedTooltipEntry({
    super.key,
    required this.content,
    required this.child,
    this.onDismiss,
    this.onShow,
    this.controller,
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
  final TooltipTriggerMode? triggerMode;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final Widget Function(BuildContext, Animation<double>, VoidCallback)?
      barrierBuilder;

  @override
  final bool? enableFeedback;

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
  final EdgeInsets margin;

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
  AlignedTooltipState<Widget> createState() => _AlignedTooltipEntryState();
}

// TODO: I think I want notifications instead... I'm really not sure
// https://stackoverflow.com/a/65854697/8213910
class _AlignedTooltipEntryState extends AlignedTooltipState<Widget> {
  InheritedTooltipArea? area;

  /// The entry this tooltip has given to the [area]. The area only shows one
  /// tooltip at a time, so this tooltip is shown only if the area still shows
  /// this entry.
  Widget? _ownEntry;

  @override
  Widget? get entry => area?.data.entry.value;

  @override
  Widget? get skrim => area?.data.skrim.value;

  @override
  bool get hasEntry => _ownEntry != null && identical(entry, _ownEntry);

  @override
  void didChangeDependencies() {
    // I must save a reference to the ancestor here because this is not callable
    // in dispose.
    final newArea =
        context.dependOnInheritedWidgetOfExactType<InheritedTooltipArea>();
    if (newArea?.data != area?.data) {
      area?.data.entry.removeListener(_handleAreaEntryChanged);
      newArea?.data.entry.addListener(_handleAreaEntryChanged);
    }
    area = newArea;

    super.didChangeDependencies();
  }

  /// Called when the tooltip shown by the [area] changes.
  void _handleAreaEntryChanged() {
    if (_ownEntry == null || identical(entry, _ownEntry)) {
      return;
    }

    // The tooltip of another entry replaced this one.
    _ownEntry = null;
    cancelShowTimer();
    cancelHideTimer();
    widget.onDismiss?.call();
    if (mounted) {
      _controller.value = TooltipStatus.isHidden;
      _animationController.reset();
    }
  }

  @override
  Future<bool> ensureTooltipVisible() async {
    cancelShowTimer();

    if (!mounted) {
      return false;
    }

    if (hasEntry) {
      cancelHideTimer();

      await _animationController.forward();
      return false; // Already visible.
    }

    _createNewEntries();
    await _animationController.forward();
    return true;
  }

  @override
  void _createNewEntries() {
    final tooltipArea = area?.data ?? AlignedTooltipArea.of(context);
    final entry = _createEntry();
    // Only modal tooltips have a skrim, like [AlignedTooltip].
    final skrim = widget.isModal ? _createSkrim() : null;

    _ownEntry = entry;
    tooltipArea.setEntries(entry: entry, skrim: skrim);
  }

  void _updateEntries() {
    final tooltipArea = area?.data;
    if (!mounted || !hasEntry || tooltipArea == null) {
      return;
    }

    final entry = _createEntry();
    final skrim = widget.isModal ? _createSkrim() : null;

    _ownEntry = entry;
    tooltipArea.updateEntries(entry: entry, skrim: skrim);
  }

  @override
  void _removeEntries() {
    cancelHideTimer();
    cancelShowTimer();

    // Never remove the tooltip of another entry of the same area.
    if (hasEntry) {
      _ownEntry = null;
      area?.data.removeEntries();
    }
    _ownEntry = null;
  }

  @override
  void _markEntriesNeedsBuild() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateEntries();
    });
  }

  @override
  void dispose() {
    area?.data.entry.removeListener(_handleAreaEntryChanged);
    super.dispose();
  }
}
