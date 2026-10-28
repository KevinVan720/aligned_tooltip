/// Tooltips that show any widget as their content, aligned to a target widget
/// along any axis.
///
/// * [AlignedTooltip] shows its content in the closest [Overlay].
/// * [AlignedTooltipEntry] shows its content where an enclosing
///   [AlignedTooltipArea] decides, for example under an app bar.
/// * [AlignedTooltipController] shows and hides a tooltip programmatically.
///
/// The tooltip is placed on the [AlignedTooltip.preferredDirection] side of
/// its target and falls back to the opposite side when there is not enough
/// space.
library;

export 'src/aligned_tooltip.dart';
export 'src/aligned_tooltip_area.dart' hide AlignedTooltipAreaState;
export 'src/models/aligned_controller.dart';
export 'src/models/aligned_interface.dart';
