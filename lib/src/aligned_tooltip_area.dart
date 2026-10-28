import 'package:aligned_tooltip/src/aligned_tooltip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The interface for a tooltip builder. This is useful when the user wants to
/// insert the tooltip into a stack rather than an overlay
typedef TooltipBuilder = Widget Function(
  BuildContext context,
  Widget tooltip,

  /// This widget should be placed behind the tooltip. When tapped, it will
  /// collapse the tooltip. When, isModal is set to false, this will always be
  /// an empty widget.
  Widget scrim,
);

/// Makes the [AlignedTooltipAreaState] of an [AlignedTooltipArea] available
/// to its descendants. Use [AlignedTooltipArea.of] to retrieve it.
class InheritedTooltipArea extends InheritedWidget {
  /// The state of the [AlignedTooltipArea] that manages the tooltips of its
  /// [AlignedTooltipEntry] descendants.
  final AlignedTooltipAreaState data;

  /// Creates a widget that provides [data] to its descendants.
  const InheritedTooltipArea({
    super.key,
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedTooltipArea oldWidget) =>
      data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignedTooltipAreaState>('data', data));
  }
}

/// Shows the tooltips of its [AlignedTooltipEntry] descendants in the widget
/// tree instead of in an [Overlay].
///
/// The [builder] receives the tooltip and the scrim (a barrier that hides
/// modal tooltips when tapped) and decides where they are placed, typically
/// in a [Stack] above the content that contains the [AlignedTooltipEntry]s:
///
/// {@tool snippet}
///
/// ```dart
/// AlignedTooltipArea(
///   builder: (context, tooltip, scrim) {
///     return Stack(
///       fit: StackFit.passthrough,
///       children: [
///         ListView(
///           children: [
///             AlignedTooltipEntry(
///               isModal: true,
///               content: const Text('Some helpful text'),
///               child: const Icon(Icons.info),
///             ),
///           ],
///         ),
///         scrim,
///         tooltip,
///       ],
///     );
///   },
/// )
/// ```
/// {@end-tool}
///
/// This makes it possible to have tooltips that are visually below other
/// parts of the UI, such as an app bar. Only one tooltip of the area is shown
/// at a time.
class AlignedTooltipArea extends StatefulWidget {
  /// Builds the content of the area with the tooltip and scrim to show.
  ///
  /// When no tooltip is shown, `tooltip` and `scrim` are empty widgets.
  final TooltipBuilder builder;

  /// Creates an area that shows the tooltips of its [AlignedTooltipEntry]
  /// descendants where [builder] places them.
  const AlignedTooltipArea({super.key, required this.builder});

  /// Used to retrieve the scope of the tooltip. This scope is responsible for
  /// managing the children `AlignedTooltip`s
  static AlignedTooltipAreaState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<InheritedTooltipArea>();

    assert(
      () {
        if (scope == null) {
          throw FlutterError(
            'AlignedTooltipArea operation requested with a context that does not '
            'include a AlignedTooltipArea.\n Make sure you wrapped your '
            'AlignedTooltipEntry widgets inside a AlignedTooltipArea',
          );
        }
        return true;
      }(),
    );

    return scope!.data;
  }

  /// Returns the state of the closest [AlignedTooltipArea] ancestor, or null
  /// if there is none.
  static AlignedTooltipAreaState? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<InheritedTooltipArea>();

    return scope?.data;
  }

  @override
  State<AlignedTooltipArea> createState() => AlignedTooltipAreaState();
}

// TODO: Change the logic here eventually to something cleaner.
/// This parent child works around the fact that the [AlignedTooltipEntry] will
/// send updates to here and thus manage the state. We must create listenable
/// wrappers aruond the skrim and entry as otherwise, when we update this parent
/// from the child, that would trigger a rebuild of the child... Which, without
/// fancy logic, would cause this parent to rebuild again. To avoid that, we
/// instead update the listeners and they then only update their state.
class AlignedTooltipAreaState extends State<AlignedTooltipArea> {
  /// The tooltip currently shown by this area, if any.
  var entry = ValueNotifier<Widget?>(null);

  /// The scrim currently shown by this area, if any.
  var skrim = ValueNotifier<Widget?>(null);

  /// Shows [entry] and [skrim], replacing the ones currently shown.
  void setEntries({required Widget entry, required Widget? skrim}) {
    if (mounted) {
      setState(() {
        this.entry.value = entry;
        this.skrim.value = skrim;
      });
    }
  }

  /// Replaces the [entry] and [skrim] currently shown.
  void updateEntries({required Widget entry, required Widget? skrim}) {
    if (mounted) {
      this.entry.value = entry;
      this.skrim.value = skrim;
    }
  }

  /// Hides the [entry] and [skrim] currently shown.
  void removeEntries() {
    if (mounted) {
      entry.value = null;
      skrim.value = null;
    }
  }

  @override
  void dispose() {
    entry.dispose();
    skrim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedTooltipArea(
      data: this,
      // This Builder allows direct children to call `AlignedTooltipArea.of`
      // without requiring a builder themselves.
      child: Builder(
        builder: (context) {
          return widget.builder(
            context,
            ValueListenableBuilder<Widget?>(
              valueListenable: entry,
              builder: (context, widget, child) => widget ?? child!,
              child: const SizedBox.shrink(),
            ),
            ValueListenableBuilder<Widget?>(
              valueListenable: skrim,
              builder: (context, widget, child) => widget ?? child!,
              child: const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
