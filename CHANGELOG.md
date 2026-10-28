## [0.0.2] - October 28, 2026

Requires Dart 3.6 and Flutter 3.27 or later.

### Fixed

* `onShow` is now called, and the controller value set to `TooltipStatus.isShowing`, when the tooltip is shown by a long press or a tap (`triggerMode`). Previously this only happened for hover, modal and controller-triggered tooltips.
* `hoverShowDuration` is no longer ignored: it sets how long the tooltip stays visible after the mouse leaves the target (and after a barrier tap or `hideTooltip()`). It falls back to `showDuration`, then to 100ms, as before.
* Changing the content or any other property of a tooltip while it is visible now updates it.
* Passing a different `controller` after the first build now attaches the new controller, and a controller passed by the app is no longer disposed by the tooltip when the `controller` is later set to null.
* Left and right tooltips near the top or bottom of the screen now respect `margin` (they could be up to `margin / 2` closer to the edge). Asymmetric and directional margins are now applied on the correct sides.
* Connecting or disconnecting a mouse no longer recreates the state of the `child`.
* `showTooltip(immediately: true)` now schedules a frame, so the tooltip appears even when the app is otherwise idle.
* A tooltip shown again after being dismissed immediately (for example by a tap elsewhere) now fades in again, and its `onShow` is no longer called after it was dismissed.
* `onDismiss` is no longer called when hiding a tooltip that is not shown.
* Haptic and acoustic feedback is provided as soon as the tooltip is triggered instead of after the fade in animation, and no longer uses a `BuildContext` after it was unmounted.
* Fixed exceptions when a tooltip is disposed while it is about to be shown, or when its controller is used after the tooltip was disposed.
* Fixed memory leaks: overlay entries, animations and the notifiers of `AlignedTooltipArea` are now disposed.
* Changing `isModal` while a modal tooltip is visible no longer leaves its barrier on screen.
* Changes to `fadeInDuration`, `fadeOutDuration`, `curve` and `reverseCurve` are now applied.
* `AlignedTooltipArea` / `AlignedTooltipEntry`:
  * Rebuilding an entry that is not shown no longer inserts an invisible tooltip and barrier that block the taps in the area.
  * Disposing an entry (for example when it is scrolled out of a list) no longer hides the tooltip of another entry.
  * Non-modal entries no longer insert a barrier. This fixes tooltips that endlessly showed and hid when hovered with a mouse, and taps outside of a non-modal tooltip now reach the widgets below it, like with `AlignedTooltip`.
  * Showing an entry while another entry of the same area is shown now replaces it (`onDismiss` is called for the replaced one). Previously the new tooltip was not shown.

### Changed

* Updated the SDK constraints for Dart 3, and the lints to `flutter_lints` 6.
* Documented the public API and fixed the README examples.
* The example app is now included in the published package.

## [0.0.1] - May 30, 2023

initial release
