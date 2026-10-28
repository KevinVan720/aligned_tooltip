# aligned_tooltip

`aligned_tooltip` gives you more flexibility over the Flutter standard `Tooltip` by allowing you to set arbitrary content. It also expands on their single axis layout algorithm to fit both vertically and horizontally. The tooltip can be positioned along any axis and will fall back to the opposite side if overflowed.

## Breaking

Right now this package is a direct fork of this package: https://pub.dev/packages/just_the_tooltip. We will update this package to support more features in the future.

## Getting Started

```dart
AlignedTooltip(
  content: const Padding(
    padding: EdgeInsets.all(8.0),
    child: Text(
      'Bacon ipsum dolor amet kevin turducken brisket pastrami, salami ribeye spare ribs tri-tip sirloin shoulder venison shank burgdoggen chicken pork belly. Short loin filet mignon shoulder rump beef ribs meatball kevin.',
    ),
  ),
  child: Material(
    color: Colors.grey.shade800,
    shape: const CircleBorder(),
    elevation: 4.0,
    child: const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
    ),
  ),
)
```

AlignedTooltip needs two arguments. The direct child widget and the content (of the tooltip).  The `child` widget will be wrapped with a `GestureDetector` and a `MouseRegion` that are responsible for showing and hiding the content. By default, the tooltip is shown when the `child` is long pressed or hovered with a mouse; use `triggerMode` (or the ambient `TooltipTheme`) to show it on tap instead. Further handling of the tooltip state can be managed explicitly through a controller:

If you'd like to create a controller to manage the state of the tooltip, you can do so by defining an instance of a `AlignedTooltipController` and pass it through to constructor. Like other controllers, dispose it when you no longer need it.

```dart
final tooltipController = AlignedTooltipController();

child: AlignedTooltip(
  controller: tooltipController,
  // ...
)

void showTooltip() {
  tooltipController.showTooltip();
}
```

The controller itself is a `ValueNotifier` that carries the open/close state of the tooltip. To listen to these changes, add a listener to your controller.

```dart
@override
void initState() {
  super.initState();
  // Programatically display tooltip after two seconds
  Future.delayed(const Duration(seconds: 2), () {
    tooltipController.showTooltip(immediately: false);
  });

  tooltipController.addListener(() {
    // Prints the enum value of [TooltipStatus.isShowing] or [TooltipStatus.isHidden]
    print('controller: ${tooltipController.value}');
  });
}

@override
void dispose() {
  tooltipController.dispose();
  super.dispose();
}
```

If you'd like to simply react to open or close states, you can pass through `onDismiss` or `onShow` callbacks to the default constructor.

```dart
AlignedTooltip(
  onDismiss: () {
    // Maybe continue tutorial?
  },
  onShow: () {
    // Start animation?
  },
  content: const Text('Tooltip content'),
  child: const Icon(Icons.info),
),
```

Tapping the barrier (the scrim area around a modal tooltip) always hides the tooltip. `barrierDismissible` only changes how the default barrier is hit tested (`HitTestBehavior.translucent` when `true`, the default, `HitTestBehavior.deferToChild` when `false`); with the default barrier, the tap does not reach the widgets behind it in either case. A barrier that cannot be dismissed by tapping it may come as a separate option in a future version; until then you can build your own barrier with `barrierBuilder`.

## Customization

* Modal

You can further define how a `Tooltip` will show by defining the `isModal` property. A modal will only open through clicking on the `child` and close by clicking on the background area (referred to as the `skrim` here). A non-modal (the default) is a more traditional tooltip opens and closes on hovers.

__Note, phone emulators do not implement mouse controls. To test hover states, use a browser.__

The fallback used when no mouse region is present but `isModal` is false is to only open when long pressed.

<p>  
 <img src="https://raw.githubusercontent.com/KevinVan720/aligned_tooltip/main/screenshots/ezgif-2-f7d77a21f161.gif" width="320" height="568"/>
</p>

* Tail Builder

If you'd like a custom tail (the nub on the end dialog bubble) drawn on your tooltip, you can pass through your own tailBuilder. The `AlignedTooltipInterface.defaultTailBuilder` (default) shows how to simply draw and return a path for your custom tails:

```dart
Path defaultTailBuilder(Offset tip, Offset point2, Offset point3) {
  return Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(point2.dx, point2.dy)
    ..lineTo(point3.dx, point3.dy)
    ..close();
}
```

The library also provides a simple bezier curved tailbuilder `AlignedTooltipInterface.defaultBezierTailBuilder`.


* ListViews

The tooltip should also work in lists and follow the target through scrolling. For even more consideration of the available space in ListViews, a `ScrollController` may be passed to the `AlignedTooltip` (as `scrollController`) to give the layout algorithm a hint as to how much space is before and after the scroll axis. This allows tooltips that would otherwise overflow to use up space offscreen in one of the scroll directions.

* Non-Overlay Tooltip

For use cases where the tooltip must be a part the widget tree rather than an overlay there is a `AlignedTooltipEntry`, which must be placed below an `AlignedTooltipArea`.

```dart
Scaffold(
  appBar: AppBar(title: const Text('It goes under me')),
  body: AlignedTooltipArea(
    builder: (context, tooltip, scrim) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          ListView.builder(
            itemCount: 30,
            itemBuilder: (context, index) {
              if (index == 15) {
                return AlignedTooltipEntry(
                  tailLength: 10.0,
                  preferredDirection: AxisDirection.down,
                  isModal: true,
                  margin: const EdgeInsets.all(20.0),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 120,
                        color: Colors.blue,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Quia ducimus eius magni voluptatibus ut veniam ducimus. Ullam ab qui voluptatibus quos est in. Maiores eos ab magni tempora praesentium libero. Voluptate architecto rerum vel sapiente ducimus aut cumque quibusdam. Consequatur illo et quos vel cupiditate quis dolores at.',
                      ),
                    ],
                  ),
                  child: const Material(
                    color: Colors.blue,
                    shape: CircleBorder(),
                    elevation: 4.0,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }

              return ListTile(title: Text('Item $index'));
            },
          ),
          // In the case of no scrim showing, this will return an SizedBox.shrink
          scrim,
          // In the case of no scrim showing, this will return an SizedBox.shrink
          tooltip,
        ],
      );
    },
  ),
);
```

This will give you the positioned tooltip and scrim (an empty gesture detector that catches tap events and closes the tooltip, only used by modal tooltips) for you to enter into the tree however you like. By doing this, you can make tooltips that are visually "under" other parts of the UI such as the appbar in the above example. An area shows one tooltip at a time.

<p>  
 <img src="https://raw.githubusercontent.com/KevinVan720/aligned_tooltip/main/screenshots/scrolling_example.gif" width="320" height="568"/>
</p>

API subject to change.

## Contributing

Issues and PRs welcome. Unless otherwise specified, all contributions to this lib will be under MIT license.

## Help wanted

If you're interested in becoming a contributor with push rights please ping me and we can talk about how to get you started ! :)