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

    readonly property alias canvas: root

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
      required property size size

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
      target: root.canvas
      function onImageLoaded() {
        // Any time the canvas emits it's "imageLoaded" signal check to see if
        // any of the loading ItemGrabResultShape have finished loading or encountered
        // an error.
        const canvas = root.canvas
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

    readonly property var raf: (function () {
      var TIME = Math.floor(1000 / 60);
      var frame, cancel;
      var frames = {};
      var lastFrameTime = 0;

      const canvas = root.canvas
      frame = function (cb) {
        var id = Math.random();

        frames[id] = canvas.requestAnimationFrame(function onFrame(time) {
          if (lastFrameTime === time || lastFrameTime + TIME - 1 < time) {
            lastFrameTime = time;
            delete frames[id];

            cb();
          } else {
            frames[id] = canvas.requestAnimationFrame(onFrame);
          }
        });

        return id;
      };
      cancel = function (id) {
        if (frames[id]) {
          canvas.cancelRequestAnimationFrame(frames[id]);
        }
      };

      return { frame: frame, cancel: cancel };
    }());

    readonly property var defaults: {
      return {
        particleCount: 50,
        angle: 90,
        spread: 45,
        startVelocity: 45,
        decay: 0.9,
        gravity: 1,
        drift: 0,
        ticks: 200,
        x: 0.5,
        y: 0.5,
        shapes: ['square', 'circle'],
        zIndex: 100,
        colors: [
          '#26ccff',
          '#a25afd',
          '#ff5e7e',
          '#88ff5a',
          '#fcff42',
          '#ffa62d',
          '#ff36ff'
        ],
        // probably should be true, but back-compat
        disableForReducedMotion: false,
        scalar: 1
      }
    }

    function convert(val, transform) {
      return transform ? transform(val) : val;
    }

    function isOk(val) {
      return !(val === null || val === undefined);
    }

    function prop(options, name, transform) {
      return convert(
        options && isOk(options[name]) ? options[name] : defaults[name],
        transform
      );
    }

    function onlyPositiveInt(number){
      return number < 0 ? 0 : Math.floor(number);
    }

    function randomInt(min, max) {
      // [min, max)
      return Math.floor(Math.random() * (max - min)) + min;
    }

    function toDecimal(str) {
      return parseInt(str, 16);
    }

    function colorsToRgb(colors) {
      return colors.map(hexToRgb);
    }

    function hexToRgb(str) {
      var val = String(str).replace(/[^0-9a-f]/gi, '');

      if (val.length < 6) {
          val = val[0]+val[0]+val[1]+val[1]+val[2]+val[2];
      }

      return {
        r: toDecimal(val.substring(0,2)),
        g: toDecimal(val.substring(2,4)),
        b: toDecimal(val.substring(4,6))
      };
    }

    // DOMMatrix style 6-element array values to Qt matrix4x4.
    function _DOMMatrixtoMatrix4x4(a: real, b: real, c: real, d: real, e: real, f: real) : QtQ.matrix4x4 {
      return Qt.matrix4x4(
        a, b, 0, 0,
        c, d, 0, 0,
        0, 0, 1, 0,
        e, f, 0, 1
      )
    }

    // Qt matrix4x4 to DOMMatrix style 6-element array.
    function _Matrix4x4ToDOMMatrix(m: QtQ.matrix4x4) : var {

      return [m.m11, m.m12, m.m21, m.m22, m.m41, m.m42]
    }

    function getOrigin(options) {
      var origin = prop(options, 'origin', Object);
      origin.x = prop(origin, 'x', Number);
      origin.y = prop(origin, 'y', Number);

      return origin;
    }

    function randomPhysics(opts) {
      var radAngle = opts.angle * (Math.PI / 180);
      var radSpread = opts.spread * (Math.PI / 180);

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

    function drawFettiItemGrabResult(context, fetti, progress, x1, y1, x2, y2) {
      var rotation = Math.PI / 10 * fetti.wobble;
      var scaleX = Math.abs(x2 - x1) * 0.1;
      var scaleY = Math.abs(y2 - y1) * 0.1;
      var width = fetti.shape.size.width * fetti.scalar;
      var height = fetti.shape.size.height * fetti.scalar;

      // Nb(ollie-dawes): This is old logic from up stream. QML does not
      // implement "CanvasPattern.setTransform" so just show the images as flat
      // images for now.
      //
      // var matrix = new DOMMatrix([
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
      // var pattern = context.createPattern(bitmapMapper.transform(fetti.shape.bitmap), 'no-repeat');
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

    function drawFettiCircle(context, fetti, x1, y1, x2, y2) {
      context.ellipse(fetti.x, fetti.y, Math.abs(x2 - x1) * fetti.ovalScalar, Math.abs(y2 - y1) * fetti.ovalScalar, Math.PI / 10 * fetti.wobble, 0, 2 * Math.PI);
    }

    function drawFettiStar(context, fetti, x1, y1, x2, y2) {
      var rot = Math.PI / 2 * 3;
      var innerRadius = 4 * fetti.scalar;
      var outerRadius = 8 * fetti.scalar;
      var x = fetti.x;
      var y = fetti.y;
      var spikes = 5;
      var step = Math.PI / spikes;

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

    function drawFettiSquare(context, fetti, x1, y1, x2, y2) {
      context.moveTo(Math.floor(fetti.x), Math.floor(fetti.y));
      context.lineTo(Math.floor(fetti.wobbleX), Math.floor(y1));
      context.lineTo(Math.floor(x2), Math.floor(y2));
      context.lineTo(Math.floor(x1), Math.floor(fetti.wobbleY));
    }

    function drawFettiShapeInner(context, fetti, progress, x1, y1, x2, y2) {
      context.beginPath();

      if (fetti.shape instanceof ItemGrabResultShape) {
        root.drawFettiItemGrabResult(context, fetti, progress, x1, y1, x2, y2);
      } else if (fetti.shape === 'circle') {
        root.drawFettiCircle(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape === 'star') {
        root.drawFettiStar(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape === 'square'){
        root.drawFettiSquare(context, fetti, x1, y1, x2, y2);
      } else {
        console.assert(false, "Unknown fetti shape '%0'".arg(fetti.shape))
      }

      context.closePath();
    }

    function drawFettiShape(context, fetti, progress, x1, y1, x2, y2) {
      context.fillStyle = 'rgba(' + fetti.color.r + ', ' + fetti.color.g + ', ' + fetti.color.b + ', ' + (1 - progress) + ')';
      root.drawFettiShapeInner(context, fetti, progress, x1, y1, x2, y2)
      context.fill();
    }

    function drawFetti(context, fetti) {
      var progress = (fetti.tick++) / fetti.totalTicks;

      var x1 = fetti.x + (fetti.random * fetti.tiltCos);
      var y1 = fetti.y + (fetti.random * fetti.tiltSin);
      var x2 = fetti.wobbleX + (fetti.random * fetti.tiltCos);
      var y2 = fetti.wobbleY + (fetti.random * fetti.tiltSin);

      root.drawFettiShape(context, fetti, progress, x1, y1, x2, y2);
    }

    // Performs a full redraw of the confetti scene.
    function drawScene(context, animatingFettis, size: QtQ.size) {
      context.clearRect(0, 0, size.width, size.height);
      animatingFettis.forEach((fetti) => drawFetti(context, fetti));
    }

    function updateFetti(fetti) {
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

    function animate(canvas, fettis, done) {
      var animatingFettis = fettis.slice();
      var context = canvas.getContext('2d');
      var animationFrame;
      var destroy;

      var prom = new Promise(function (resolve) {
        function onDone() {
          animationFrame = destroy = null;

          context.clearRect(0, 0, canvas.width, canvas.height);

          done();
          resolve();
        }

        function update() {
          animatingFettis = animatingFettis.filter(function (fetti) {
            return updateFetti(fetti);
          });

          drawScene(context, animatingFettis, Qt.size(canvas.width, canvas.height))

          if (animatingFettis.length) {
            animationFrame = raf.frame(update);
          } else {
            onDone();
          }
        }

        animationFrame = raf.frame(update);
        destroy = onDone;
      });

      return {
        addFettis: function (fettis) {
          animatingFettis = animatingFettis.concat(fettis);

          return prom;
        },
        canvas: canvas,
        promise: prom,
        reset: function () {
          if (animationFrame) {
            raf.cancel(animationFrame);
          }

          if (destroy) {
            destroy();
          }
        }
      };
    }

    function confettiCannon(canvas, globalOpts) {
      var globalDisableForReducedMotion = prop(globalOpts, 'disableForReducedMotion', Boolean);
      var initialized = false;
      var preferLessMotion = typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion)').matches;
      var animationObj;

      function fireLocal(options, done) {
        var particleCount = prop(options, 'particleCount', onlyPositiveInt);
        var angle = prop(options, 'angle', Number);
        var spread = prop(options, 'spread', Number);
        var startVelocity = prop(options, 'startVelocity', Number);
        var decay = prop(options, 'decay', Number);
        var gravity = prop(options, 'gravity', Number);
        var drift = prop(options, 'drift', Number);
        var colors = prop(options, 'colors', colorsToRgb);
        var ticks = prop(options, 'ticks', Number);
        var shapes = prop(options, 'shapes');
        var scalar = prop(options, 'scalar');
        var flat = !!prop(options, 'flat');
        var origin = getOrigin(options);

        var temp = particleCount;
        var fettis = [];

        var startX = canvas.width * origin.x;
        var startY = canvas.height * origin.y;

        while (temp--) {
          fettis.push(
            randomPhysics({
              x: startX,
              y: startY,
              angle: angle,
              spread: spread,
              startVelocity: startVelocity,
              color: colors[randomInt(0, colors.length)],
              shape: shapes[randomInt(0, shapes.length)],
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
        if (animationObj) {
          return animationObj.addFettis(fettis);
        }

        animationObj = animate(canvas, fettis , done);

        return animationObj.promise;
      }

      function fire(options) {
        var disableForReducedMotion = globalDisableForReducedMotion || prop(options, 'disableForReducedMotion', Boolean);
        var zIndex = prop(options, 'zIndex', Number);

        if (disableForReducedMotion && preferLessMotion) {
          return new Promise(function (resolve) {
            resolve();
          });
        }

        initialized = true;

        function done() {
          animationObj = null;
        }

        return fireLocal(options, done);
      }

      fire.reset = function () {
        if (animationObj) {
          animationObj.reset();
        }
      };

      return fire;
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
        matrix: root._DOMMatrixtoMatrix4x4(scale, 0, 0, scale, -width * scale / 2, -height * scale / 2),
        onLoadedCallback: onLoadedCallback,
        onLoadFailedCallback: onLoadFailedCallback,
      })
      if (loadingItemGrabResultShape) {
        const canvas = root.canvas
        root._loadingItemGrabResultShapes.push(loadingItemGrabResultShape)
        canvas.loadImage(loadingItemGrabResultShape.itemGrabResult.url)

        // Canvas.imageLoaded is not emitted if the image was loaded immediantly
        // so manually call "onImageLoaded" in that case.
        // See this bug for details:
        // https://bugreports.qt.io/browse/QTBUG-128480
        if (canvas.isImageLoaded(loadingItemGrabResultShape.itemGrabResult.url)) {
          root._canvasConnections.onImageLoaded()
        }
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
    function unloadItemGrabResultShape(itemGrabResultShape: ItemGrabResultShape) {
        const index = root._loadedItemGrabResultShapes.indexOf(itemGrabResultShape)
        if (index < 0) {
            console.warn("Unable to unload itemGrabResultShape shape. Shape not
                          found, has it already been unloaded?")
            return
        }
        const removedItemGrabResultShapes = root._loadedItemGrabResultShapes.splice(index, 1)
        for (let removedItemGrabResultShape of removedItemGrabResultShapes) {
            removedItemGrabResultShape.destroy()
        }
    }

    property var confetti: null
    QtQ.Component.onCompleted: {
        root.confetti = root.confettiCannon(root.canvas, {})
    }
}
