# Canvas Confetti QML

<img src="./images/banner.gif"/>

Fork of [catdad/canvas-confetti](https://github.com/catdad/canvas-confetti) but
rewritten to support Qt's QML.

Main changes from above are:
- Converted from JS module to QML canvas component.
- QML does not support `WebWorkers` so removes worker logic.
- Adds QML type hints and refactors to make API more declarative.
- Includes support for Item based confetti by using `ItemGrabResult` and
  `loadItemGrabResultAsShape`.
- Removes unsupported path `'path'` and `'bitmap'` shape types (both use cases
  covered by new `ItemGrabResultShape` type).

## Examples

> Build the project in QtCreator to see more examples like emoji, Item or star
> based confetti!

First create a `ConfettiCanvas` with:

```qml
import Confetti as Confetti

Confetti.ConfettiCavnas {
  id: confetti
}
```

Then launch some confetti the default way with:
```qml
confetti.fire()
```

Launch a bunch of confetti:
```qml
confetti.fire({
  particleCount: 150
});
```

Launch some confetti really wide:
```qml
confetti.fire({
  spread: 180
});
```

Get creative. Launch a small poof of confetti from a random part of the page:
```qml
confetti.fire({
  particleCount: 100,
  startVelocity: 30,
  spread: 360,
  origin: {
    x: Math.random(),
    // since they fall down, start a bit higher than random
    y: Math.random() - 0.2
  }
});
```

## Known Issues

Performance in debug builds is pretty choppy but release builds work well.
Upstream uses a [WebWorker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers)
to render in a separate thread but QML does not support this. [`WorkerScript`](https://doc.qt.io/qt-6/qml-qtqml-workerscript-workerscript.html)
may be an alternative but I would like to keep this as a single file library if
possible and that only supports passing a separate script.