////////////////////////////////////////////////////////////////////////////////
//
// Canvas Confetti QML
// See https://github.com/MeldStudio/canvas-confetti-qml for documentation.
//
// Based on: https://github.com/catdad/canvas-confetti
//   Commit: 6526a575752d5ebc879b40d74e2bc705014888fd
//
////////////////////////////////////////////////////////////////////////////////
//
// ISC License
//
// Copyright (c) 2020, Kiril Vatev
// Copyright (c) 2024, Meld Studio, Inc.
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick as QtQ

QtQ.Canvas {
  id: root

  // The number of new fetti objects to create on each "fire" call.
  property int particleCount: 50;

  // The angle in which to launch the confetti, in degrees. 90 is straight up.
  property real angle: 90;

  // How far off center the confetti can go, in degrees. 45 means the confetti
  // will launch at the defined angle plus or minus 22.5 degrees.
  property real spread: 45;

  // How fast the confetti will start going, in pixels.
  property real startVelocity: 45;

  // How quickly the confetti will lose speed. Keep this number between 0 and 1,
  // otherwise the confetti will gain speed.
  property real decay: 0.9;

  // How quickly the particles are pulled down. 1 is full gravity, 0.5 is half
  // gravity, etc., but there are no limits. You can even make particles go up
  // if you'd like.
  property real gravity: 1;

  // How much to the side the confetti will drift. The default is 0, meaning
  // that they will fall straight down. Use a negative number for left and
  // positive number for right.
  property real drift: 0;

  // A list of colors that will be used when creating the fetti objects. A new
  // fetti has an equal propbablility of using any of these values.
  property list<QtQ.color> colors: [
    Qt.color('#26ccff'),
    Qt.color('#a25afd'),
    Qt.color('#ff5e7e'),
    Qt.color('#88ff5a'),
    Qt.color('#fcff42'),
    Qt.color('#ffa62d'),
    Qt.color('#ff36ff')
  ];

  // The number of render frames that a fetti should live for.
  property int ticks: 200;

  // A list of shape types that should be rendered, each shape will have an
  // equal probability of being used for a given fetti.
  // Accepted values are:
  // - 'square'
  // - 'circle'
  // - 'star'
  // - ItemGrabResultShape <- obtained through "loadItemGrabResultAsShape".
  property list<string> shapes: ['square', 'circle'];

  // A factor that will scale the size of the fetti objects uniformly.
  property real scalar: 1;

  // Optionally turns off the tilt and wobble that three dimensional confetti
  // would have in the real world. Yeah, they look a little sad, but y'all asked
  // for them, so don't blame me.
  property bool flat: false;

  // The default origin for fetti objects to be created at. This position is
  // relative to the canvas size.
  property QtQ.point origin: Qt.point(0.5, 0.5);

  // Try if there are fetti still alive to be animated.
  readonly property bool animatingConfetti: !!root._animationObj

  // Set to limit the FPS to a given value. If set to zero then rendering will
  // not be capped.
  property real maxFps: 60

  // The Current FPS calculated based on the last render interval.
  readonly property real currentFPS: {
    if (root._lastRenderIntervals.length <= 0) {
      return Nan;
    }
    const lastRenderInterval = root._lastRenderIntervals[0];
    if (lastRenderInterval === 0) {
      return Number.Infinity;
    }
    return 1000 / lastRenderInterval;
  }

  // A average FPS metric that will compute the average FPS based on the last
  // "averageFpsSamples" frames.
  property int averageFpsSamples: root.maxFps > 0 ? root.maxFps : 60
  readonly property real averageFPS: {
    const sampleCount = root._lastRenderIntervals.length
    if (sampleCount <= 0) {
      return NaN
    }
    const meanRenderInterval = root._lastRenderIntervals.reduce(function (sum, value) {
        return sum + value;
    }, 0) / sampleCount;

    if (meanRenderInterval === 0) {
      return 0;
    }
    return 1000 / meanRenderInterval;
  }

  // Call "fire" to fire a confetti explosion!
  //
  // options: A Javascript object that allows you to override the default
  //          confetti options.
  // done:    A callback function that will be called when all fettis have
  //          disappeared
  function fire(options: var, done: var) : var {
    const particleCount = root._prop(options, 'particleCount', root._onlyPositiveInt);
    const angle = root._prop(options, 'angle', Number);
    const spread = root._prop(options, 'spread', Number);
    const startVelocity = root._prop(options, 'startVelocity', Number);
    const decay = root._prop(options, 'decay', Number);
    const gravity = root._prop(options, 'gravity', Number);
    const drift = root._prop(options, 'drift', Number);
    const colors = root._prop(options, 'colors', root._varToColor);
    const ticks = root._prop(options, 'ticks', Number);
    const shapes = root._prop(options, 'shapes');
    const scalar = root._prop(options, 'scalar', Number);
    const flat = !!root._prop(options, 'flat');
    const origin = root._prop(options, 'origin');

    const fettis = [];
    const startPos = Qt.point(root.width * origin.x,
                              root.height * origin.y);

    // Create "particleCount" fetti objects.
    for (let i = 0; i < particleCount; i++) {
      fettis.push(
        root._randomPhysics({
          x: startPos.x,
          y: startPos.y,
          angle: angle,
          spread: spread,
          startVelocity: startVelocity,
          color: colors[root._randomInt(0, colors.length)],
          shape: shapes[root._randomInt(0, shapes.length)],
          ticks: ticks,
          decay: decay,
          gravity: gravity,
          drift: drift,
          scalar: scalar,
          flat: flat
        })
      );
    }

    // if we have a previous canvas already animating,
    // add to it
    if (root._animationObj) {
      return root._animationObj.addFettis(fettis);
    }

    function _done() {
      root._animationObj = null;
      if (done) {
        done();
      }
    }

    root._animationObj = root._animate(fettis, _done);
    return root._animationObj.promise;
  }

  // Provided an "ItemGrabResult" this method will load the image into the
  // canvas so that it can be rendered and then either call the
  // "onLoadedCallback" or "onLoadFailedCallback" depending on whether the
  // image loaded successfully.
  //
  // "onLoadedCallback" will return a "ItemGrabResultShape" that can be passed
  // into the "shapes" array property and unloaded by calling
  // "unloadItemGrabResultShape".
  //
  // "onLoadFailedCallback" will return the original "itemGrabResult" if the
  // canvas fails to load the image successfully.
  function loadItemGrabResultAsShape(itemGrabResult: QtQ.QtObject,
                                     size: QtQ.size,
                                     onLoadedCallback: var,
                                     onLoadFailedCallback: var) : void {
    const scale = 1;
    const loadingItemGrabResultShape = itemGrabResultShapeComponent.createObject(root, {
      itemGrabResult: itemGrabResult,
      url: itemGrabResult.url,
      size: size,
      matrix: root._convertDOMMatrixtoMatrix4x4(scale, 0, 0, scale, -width * scale / 2, -height * scale / 2),
      onLoadedCallback: onLoadedCallback,
      onLoadFailedCallback: onLoadFailedCallback,
    })

    if (!loadingItemGrabResultShape) {
      console.log("Failed to create ItemGrabResultShape: " + itemGrabResultShapeComponent.errorString)
      return;
    }

    root._loadingItemGrabResultShapes.push(loadingItemGrabResultShape);
    root.loadImage(loadingItemGrabResultShape.itemGrabResult.url);

    // Canvas.imageLoaded is not emitted if the image was loaded immediantly
    // so manually call "onImageLoaded" in that case.
    // See this bug for details:
    // https://bugreports.qt.io/browse/QTBUG-128480
    if (root.isImageLoaded(loadingItemGrabResultShape.itemGrabResult.url)) {
      root._canvasConnections.onImageLoaded();
    }
  }

  // This method will release the "ItemGrabResultShape" reference held
  // internally for "loadItemGrabResultAsShape" calls that completed
  // successfully.
  //
  // The provided "ItemGrabResultShape" value should only be a
  // "ItemGrabResultShape" reference that was returned from the
  // "onLoadedCallback" of "loadItemGrabResultAsShape". Images that are in the
  // progress of being loaded can not be unloaded.
  function unloadItemGrabResultShape(itemGrabResultShape: ItemGrabResultShape) : void {
    const index = root._loadedItemGrabResultShapes.indexOf(itemGrabResultShape)
    if (index < 0) {
      console.warn("Unable to unload itemGrabResultShape shape. Shape not" +
                   "found, has it already been unloaded?");
      return;
    }
    const removedItemGrabResultShapes = root._loadedItemGrabResultShapes.splice(index, 1);
    for (let removedItemGrabResultShape of removedItemGrabResultShapes) {
      removedItemGrabResultShape.destroy();
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Start private impl
  //////////////////////////////////////////////////////////////////////////////

  property var _animationObj;

  component ItemGrabResultShape: QtQ.QtObject {
    // We must hold onto ItemGrabResult reference otherwise the image will
    // become invalid. Unfortunatly this is impossible due to:
    // https://bugreports.qt.io/browse/QTBUG-128483
    //
    // So as a workaroud we also hold onto an internal Image item that uses
    // the ItemGrabResult url to prevent the internal pixmap cache from being
    // released.
    //
    // Once the above bug is fixed we can hold onto just the "itemGrabResult".
    required property QtQ.QtObject itemGrabResult
    readonly property QtQ.Image _image: QtQ.Image { source: url}
    required property url url

    // The size to render the provided image.
    required property QtQ.size size

    required property QtQ.matrix4x4 matrix

    // Called when the ItemGrabResultShape is finished being loaded by the canvas.
    required property var onLoadedCallback

    // Called if the canvas fails to load the ItemGrabResultShape's url.
    required property var onLoadFailedCallback
  }
  readonly property QtQ.Component _itemGrabResultShapeComponent: QtQ.Component {
    id: itemGrabResultShapeComponent
    ItemGrabResultShape {}
  }

  property list<ItemGrabResultShape> _loadingItemGrabResultShapes: []
  property list<ItemGrabResultShape> _loadedItemGrabResultShapes: []

  readonly property QtQ.Connections _canvasConnections: QtQ.Connections {
    target: root
    function onImageLoaded() {
      // Any time the canvas emits it's "imageLoaded" signal check to see if
      // any of the loading ItemGrabResultShape have finished loading or encountered
      // an error.
      const canvas = root
      const loadingItemGrabResultShapes = [...root._loadingItemGrabResultShapes]
      const failedItemGrabResultShapes = []
      const loadedItemGrabResultShapes = []

      let i = 0
      while (i < loadingItemGrabResultShapes.length) {
        const loadingItemGrabResultShape = loadingItemGrabResultShapes[i]
        if (canvas.isImageError(loadingItemGrabResultShape.itemGrabResult.url)) {
          // If the image failed to load then remove from the loading list and
          // add to the failed list.
          failedItemGrabResultShapes.push(loadingItemGrabResultShape)
          loadingItemGrabResultShapes.splice(i, 1)
        } else if (canvas.isImageLoaded(loadingItemGrabResultShape.itemGrabResult.url)) {
          // If the image loaded successfully then remove it from the loading
          // list and add to the loaded list.
          loadedItemGrabResultShapes.push(loadingItemGrabResultShape)
          loadingItemGrabResultShapes.splice(i, 1)
        } else {
          // If the image is still loading then check the next image.
          i++
        }
      }

      if (failedItemGrabResultShapes.length || loadedItemGrabResultShapes.length) {
        root._loadingItemGrabResultShapes = loadingItemGrabResultShapes

        for (let failedItemGrabResultShape of failedItemGrabResultShapes) {
          failedItemGrabResultShape.onLoadFailedCallback(failedItemGrabResultShape.itemGrabResult)
          failedItemGrabResultShape.destroy()
        }

        for (let loadedItemGrabResultShape of loadedItemGrabResultShapes) {
          root._loadedItemGrabResultShapes.push(loadedItemGrabResultShape)
          loadedItemGrabResultShape.onLoadedCallback(loadedItemGrabResultShape)
        }
      }
      root.printLoadedItemGrabResults()
    }
  }

  // Time of last render in milliseconds.
  property var _lastFrameTime: null
  property list<int> _lastRenderIntervals: []
  function _requestNextAnimationFrame(cb: var) : void {
    root.requestAnimationFrame(function onFrame(time) {
      const requested_frame_interval = root.maxFps > 0 ? Math.floor(1000 / root.maxFps) : 0;
      const lastFrameTime = root._lastFrameTime
      const noPreviousRender = lastFrameTime === null;
      if (!noPreviousRender && lastFrameTime + requested_frame_interval  > time) {
        // If it is not yet time to render then request another animation frame.
        root.requestAnimationFrame(onFrame);
        return;
      }

      // Else perform the requested callback after updating metrics.
      if (!noPreviousRender) {
        const lastRenderIntervals = [...root._lastRenderIntervals];
        lastRenderIntervals.unshift(time - lastFrameTime);
        if (lastRenderIntervals.length > root.averageFpsSamples) {
          lastRenderIntervals.pop();
        }
        root._lastRenderIntervals = lastRenderIntervals;
      }

      root._lastFrameTime = time;

      cb();
    });
  }

  // Applies the "transform" function to "val" if provided, otherwise just
  // returns "val" as is.
  function _convert(val: var, transform: var) : var {
    return transform ? transform(val) : val;
  }

  function _isOk(val: var) : bool {
    return !(val === null || val === undefined);
  }

  // options - A dictionary of option values
  // name - The name of the property to return
  // transform -
  function _prop(options: var, name: string, transform: var): var {
    if (options && root._isOk(options[name])) {
      return root._convert(options[name], transform);
    }
    return root[name];
  }

  function _onlyPositiveInt(number: var) : int {
    if (isNaN(number)) {
      return 0;
    }
    return number < 0 ? 0 : Math.floor(number);
  }

  function _randomInt(min: int, max: int) : int {
    // [min, max)
    return Math.floor(Math.random() * (max - min)) + min;
  }

  function _varToColor(colors) : list<QtQ.color> {
    return colors.map((color) => {
      if (color instanceof QtQ.color) {
        return color;
      } else {
        return Qt.color(color)
      }
    });
  }

  // DOMMatrix style 6-element array values to Qt matrix4x4.
  // "e_" instead of "e" as qmltc will internally create a variable "e" for the engine...
  function _convertDOMMatrixtoMatrix4x4(a: real, b: real, c: real, d: real, e_: real, f: real) : QtQ.matrix4x4 {
    return Qt.matrix4x4(
      a, b, 0, 0,
      c, d, 0, 0,
      0, 0, 1, 0,
      e_, f, 0, 1
    )
  }

  // Qt matrix4x4 to DOMMatrix style 6-element array.
  function _convertMatrix4x4ToDOMMatrix(m: QtQ.matrix4x4) : var {
    return [m.m11, m.m12, m.m21, m.m22, m.m41, m.m42]
  }

  function _randomPhysics(opts: var) : var {
    const radAngle = opts.angle * (Math.PI / 180);
    const radSpread = opts.spread * (Math.PI / 180);

    return {
      x: opts.x,
      y: opts.y,
      wobble: Math.random() * 10,
      wobbleSpeed: Math.min(0.11, Math.random() * 0.1 + 0.05),
      velocity: (opts.startVelocity * 0.5) + (Math.random() * opts.startVelocity),
      angle2D: -radAngle + ((0.5 * radSpread) - (Math.random() * radSpread)),
      tiltAngle: (Math.random() * (0.75 - 0.25) + 0.25) * Math.PI,
      color: opts.color,
      shape: opts.shape,
      tick: 0,
      totalTicks: opts.ticks,
      decay: opts.decay,
      drift: opts.drift,
      random: Math.random() + 2,
      tiltSin: 0,
      tiltCos: 0,
      wobbleX: 0,
      wobbleY: 0,
      gravity: opts.gravity * 3,
      ovalScalar: 0.6,
      scalar: opts.scalar,
      flat: opts.flat
    };
  }

  function _drawFettiItemGrabResult(context: var,
                                    fetti: var,
                                    x1: real,
                                    y1: real,
                                    x2: real,
                                    y2: real) : void {
    const progress = (fetti.tick++) / fetti.totalTicks;
    const width = fetti.shape.size.width * fetti.scalar;
    const height = fetti.shape.size.height * fetti.scalar;

    // Nb(ollie-dawes): This is old logic from up stream. QML does not
    // implement "CanvasPattern.setTransform" so just show the images as flat
    // images for now.
    //
    // const rotation = Math.PI / 10 * fetti.wobble;
    // const scaleX = Math.abs(x2 - x1) * 0.1;
    // const scaleY = Math.abs(y2 - y1) * 0.1;
    //
    // const matrix = new DOMMatrix([
    //   Math.cos(rotation) * scaleX,
    //   Math.sin(rotation) * scaleX,
    //   -Math.sin(rotation) * scaleY,
    //   Math.cos(rotation) * scaleY,
    //   fetti.x,
    //   fetti.y
    // ]);
    //
    // // apply the transform matrix from the confetti shape
    // matrix.multiplySelf(new DOMMatrix(fetti.shape.matrix));
    //
    // const pattern = context.createPattern(bitmapMapper.transform(fetti.shape.bitmap), 'no-repeat');
    // pattern.setTransform(matrix);
    //
    // context.globalAlpha = (1 - progress);
    // context.fillStyle = pattern;
    // context.fillRect(
    //   fetti.x - (width / 2),
    //   fetti.y - (height / 2),
    //   width,
    //   height
    // );
    // context.globalAlpha = 1;

    context.globalAlpha = (1 - progress);
    context.drawImage(fetti.shape.url, fetti.x -(width / 2), fetti.y -(height / 2), width, height)
    context.globalAlpha = 1;
  }

  function _drawFettiCircle(context: var,
                            fetti: var,
                            x1: real,
                            y1: real,
                            x2: real,
                            y2: real) : void {
    context.ellipse(fetti.x, fetti.y, Math.abs(x2 - x1) * fetti.ovalScalar, Math.abs(y2 - y1) * fetti.ovalScalar, Math.PI / 10 * fetti.wobble, 0, 2 * Math.PI);
  }

  function _drawFettiStar(context: var,
                          fetti: var,
                          x1: real,
                          y1: real,
                          x2: real,
                          y2: real) : void {
    let rot = Math.PI / 2 * 3;
    const innerRadius = 4 * fetti.scalar;
    const outerRadius = 8 * fetti.scalar;
    let x = fetti.x;
    let y = fetti.y;
    let spikes = 5;
    const step = Math.PI / spikes;

    while (spikes--) {
      x = fetti.x + Math.cos(rot) * outerRadius;
      y = fetti.y + Math.sin(rot) * outerRadius;
      context.lineTo(x, y);
      rot += step;

      x = fetti.x + Math.cos(rot) * innerRadius;
      y = fetti.y + Math.sin(rot) * innerRadius;
      context.lineTo(x, y);
      rot += step;
    }
  }

  function _drawFettiSquare(context: var,
                            fetti: var,
                            x1: real,
                            y1: real,
                            x2: real,
                            y2: real) : void {
    context.moveTo(Math.floor(fetti.x), Math.floor(fetti.y));
    context.lineTo(Math.floor(fetti.wobbleX), Math.floor(y1));
    context.lineTo(Math.floor(x2), Math.floor(y2));
    context.lineTo(Math.floor(x1), Math.floor(fetti.wobbleY));
  }

  function _drawFettiShapeInner(context: var,
                                fetti: var,
                                x1: real,
                                y1: real,
                                x2: real,
                                y2: real) : void {
    context.beginPath();

    if (fetti.shape instanceof ItemGrabResultShape) {
      root._drawFettiItemGrabResult(context, fetti, x1, y1, x2, y2);
    } else if (fetti.shape === 'circle') {
      root._drawFettiCircle(context, fetti, x1, y1, x2, y2);
    } else if (fetti.shape === 'star') {
      root._drawFettiStar(context, fetti, x1, y1, x2, y2);
    } else if (fetti.shape === 'square'){
      root._drawFettiSquare(context, fetti, x1, y1, x2, y2);
    } else {
      console.assert(false, "Unknown fetti shape '%0'".arg(fetti.shape))
    }

    context.closePath();
  }

  function _drawFettiShape(context: var,
                           fetti: var,
                           x1: real,
                           y1: real,
                           x2: real,
                           y2: real) : void {
    const progress = (fetti.tick++) / fetti.totalTicks;
    context.fillStyle = Qt.rgba(fetti.color.r, fetti.color.g, fetti.color.b, 1 - progress);
    root._drawFettiShapeInner(context, fetti, x1, y1, x2, y2)
    context.fill();
  }

  function _drawFetti(context: var, fetti: var) : void {
    const x1 = fetti.x + (fetti.random * fetti.tiltCos);
    const y1 = fetti.y + (fetti.random * fetti.tiltSin);
    const x2 = fetti.wobbleX + (fetti.random * fetti.tiltCos);
    const y2 = fetti.wobbleY + (fetti.random * fetti.tiltSin);
    root._drawFettiShape(context, fetti, x1, y1, x2, y2);
  }

  // Performs a full redraw of the confetti scene.
  function _drawScene(context: var, animatingFettis: var, size: QtQ.size) : void {
    context.clearRect(0, 0, size.width, size.height);
    animatingFettis.forEach((fetti) => _drawFetti(context, fetti));
  }

  function _updateFetti(fetti: var) : bool {
    fetti.x += Math.cos(fetti.angle2D) * fetti.velocity + fetti.drift;
    fetti.y += Math.sin(fetti.angle2D) * fetti.velocity + fetti.gravity;
    fetti.velocity *= fetti.decay;

    if (fetti.flat) {
      fetti.wobble = 0;
      fetti.wobbleX = fetti.x + (10 * fetti.scalar);
      fetti.wobbleY = fetti.y + (10 * fetti.scalar);

      fetti.tiltSin = 0;
      fetti.tiltCos = 0;
      fetti.random = 1;
    } else {
      fetti.wobble += fetti.wobbleSpeed;
      fetti.wobbleX = fetti.x + ((10 * fetti.scalar) * Math.cos(fetti.wobble));
      fetti.wobbleY = fetti.y + ((10 * fetti.scalar) * Math.sin(fetti.wobble));

      fetti.tiltAngle += 0.1;
      fetti.tiltSin = Math.sin(fetti.tiltAngle);
      fetti.tiltCos = Math.cos(fetti.tiltAngle);
      fetti.random = Math.random() + 2;
    }

    return fetti.tick < fetti.totalTicks;
  }

  function _animate(fettis: var, done: var) : var {
    let animatingFettis = fettis.slice();

    const canvas = root;
    const context = canvas.getContext('2d');
    let destroy = null;

    var prom = new Promise(function (resolve) {
      function onDone() {
        destroy = null;

        context.clearRect(0, 0, canvas.width, canvas.height);
        root._lastFrameTime = null;
        root._lastRenderIntervals = [];

        done();
        resolve();
      }

      function update() {
        animatingFettis = animatingFettis.filter(function (fetti) {
          return _updateFetti(fetti);
        });

        _drawScene(context, animatingFettis, Qt.size(canvas.width, canvas.height));

        if (animatingFettis.length) {
          root._requestNextAnimationFrame(update);
        } else {
          onDone();
        }
      }

      root._requestNextAnimationFrame(update);
      destroy = onDone;
    });

    return {
      addFettis: function (fettis) {
        animatingFettis = animatingFettis.concat(fettis);
        return prom;
      },
      canvas: canvas,
      promise: prom
    };
  }
}
