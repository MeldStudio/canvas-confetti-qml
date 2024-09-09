# Canvas Confetti QML

<img src="./images/banner.gif"/>

Single file QML component for canvas based confetti animations.

Import `ConfettiCanvas.qml` into your project, create a `Confetti.ConfettiCanvas` and
call `fire` make confetti appear!

## Based on the well known canvas-confetti JS module!
This library is is based on [catdad/canvas-confetti](https://github.com/catdad/canvas-confetti) but
rewritten to support Qt's QML.

Main changes from above are:
- Converted from JS module to QML canvas component.
- Refactors the API for a more declarative QML experience.
- Adds QML typing and support for QML -> C++ compilation via Qt's [QML type compiler](https://doc.qt.io/qt-6/qtqml-qml-type-compiler.html).
- Includes support for Item based confetti by using `ItemGrabResult` and
  `loadItemGrabResultAsShape`.
- Removes unsupported path `'path'` and `'bitmap'` shape types (both use cases
  covered by new `ItemGrabResultShape` type).
- Removes `WebWorkers` logic as not supported by QML.

## How to use:

Just import [ConfettiCanvas.qml](https://github.com/MeldStudio/canvas-confetti-qml/blob/main/ConfettiExampleProject/Confetti/ConfettiCanvas.qml) into your
project as a QML source and your away! Or import the whole `/ConfettiExampleProject/Confetti/`
CMake library into your source tree as a CMake submodule (See `/ConfettiExampleProject/CMakeLists.txt`
for example) if you want to keep the `Confetti` namespace when importing.

## Examples

> Build the project in QtCreator to see more examples like emoji, Item or star
> based confetti!

First create a `ConfettiCanvas` with:

```qml
import Confetti as Confetti

Confetti.ConfettiCanvas {
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

## Known Limitations

The aim here was to create a simple single file QML component however that does
come with a few limitations.

Performance in debug builds can be pretty choppy though release builds work
well. Upstream uses a [WebWorker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers)
to render in a separate thread but QML does not support this. [`WorkerScript`](https://doc.qt.io/qt-6/qml-qtqml-workerscript-workerscript.html)
may be an alternative it only supports passing a separate script.

For a truly performant implementation render and simulation state should be
separated and a `QQuickPaintedItem` or a QML [ParticleSystem](https://doc.qt.io/qt-6/qml-qtquick-particles-particlesystem.html)
would likely offer better results than a `Canvas`. It might be interesting to do
a similar implementation using both of the above approaches to compare
performance in the future.