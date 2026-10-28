import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:flutter/material.dart';

/// Whether a tooltip is shown or hidden.
enum TooltipStatus {
  /// The tooltip is shown.
  isShowing,

  /// The tooltip is hidden.
  isHidden,
}

/// This controller provides basic controls over the Tooltip widget.
/// It is just a shell class that is given functionality by the
/// [StatefulWidget]. This idea was copied from a [FocusNode] whose attach
/// method is called to give the focusNode the context and state of its parent.
///
/// The [value] of the controller is the [TooltipStatus] of the tooltip it is
/// attached to. Pass it to [AlignedTooltip.controller] or
/// [AlignedTooltipEntry.controller] to show and hide that tooltip
/// programmatically. The controller must be disposed by its owner.
class AlignedTooltipController extends ValueNotifier<TooltipStatus> {
  /// Creates a controller, hidden by default.
  // TODO: This value is not refelected in the initial state of the tooltip
  AlignedTooltipController({TooltipStatus? value})
      : super(value ?? TooltipStatus.isHidden) {
    showTooltip = defaultShowTooltip;
    hideTooltip = defaultHideTooltip;
  }

  /// The [showTooltip] of a controller that is not attached to a tooltip.
  ///
  /// Throws a [StateError].
  static Future<void> defaultShowTooltip({
    bool immediately = false,
    bool autoClose = false,
  }) {
    throw StateError('This controller has not been attached to a tooltip yet.');
  }

  /// The [hideTooltip] of a controller that is not attached to a tooltip.
  ///
  /// Throws a [StateError].
  static Future<void> defaultHideTooltip({bool immediately = false}) {
    throw StateError('This controller has not been attached to a tooltip yet.');
  }

  /// Called by the tooltip using this controller to provide the
  /// implementations of [showTooltip] and [hideTooltip].
  @mustCallSuper
  void attach({
    required ShowTooltip showTooltip,
    required HideTooltip hideTooltip,
  }) {
    this.showTooltip = showTooltip;
    this.hideTooltip = hideTooltip;
  }

  /// Shows the tooltip. Completes when the tooltip is fully visible.
  late ShowTooltip showTooltip;

  /// Hides the tooltip. Completes when the tooltip is fully hidden.
  late HideTooltip hideTooltip;
}
