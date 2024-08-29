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

QtQ.QtObject {
    id: root

    required property QtQ.Canvas canvas

    // QML doesn't support the Path2D interface of the Canvas 2D API.
    // QML doesn't support DOMMatrix.
    readonly property bool canUsePaths: typeof Path2D === 'function' && typeof DOMMatrix === 'function'

    // Not implemented
    readonly property bool canDrawBitmap: false
    // readonly property bool canDrawBitmap: {
    //   // this mostly supports ssr
    //   if (!root.global.OffscreenCanvas) {
    //     return false;
    //   }
    //
    //   var canvas = new OffscreenCanvas(1, 1);
    //   var ctx = canvas.getContext('2d');
    //   ctx.fillRect(0, 0, 1, 1);
    //   var bitmap = canvas.transferToImageBitmap();
    //
    //   try {
    //     ctx.createPattern(bitmap, 'no-repeat');
    //   } catch (e) {
    //     return false;
    //   }
    //
    //   return true;
    // }

    // Not implemented
    readonly property var bitmapMapper: {
        return {
            transform: (bitmap) => {},
            clear: () => {},
        }
    }
    /*
    var bitmapMapper = (function (skipTransform, map) {
      // see https://github.com/catdad/canvas-confetti/issues/209
      // creating canvases is actually pretty expensive, so we should create a
      // 1:1 map for bitmap:canvas, so that we can animate the confetti in
      // a performant manner, but also not store them forever so that we don't
      // have a memory leak
      return {
        transform: function(bitmap) {
          if (skipTransform) {
            return bitmap;
          }

          if (map.has(bitmap)) {
            return map.get(bitmap);
          }

          var canvas = new OffscreenCanvas(bitmap.width, bitmap.height);
          var ctx = canvas.getContext('2d');
          ctx.drawImage(bitmap, 0, 0);

          map.set(bitmap, canvas);

          return canvas;
        },
        clear: function () {
          map.clear();
        }
      };
    })(canDrawBitmap, new Map());
    */

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

    function drawFettiPath(context, fetti, x1, y1, x2, y2) {
      context.fill(transformPath2D(
        fetti.shape.path,
        fetti.shape.matrix,
        fetti.x,
        fetti.y,
        Math.abs(x2 - x1) * 0.1,
        Math.abs(y2 - y1) * 0.1,
        Math.PI / 10 * fetti.wobble
      ));
    }

    function drawFettiBitmap(context, fetti, x1, y1, x2, y2) {
      var rotation = Math.PI / 10 * fetti.wobble;
      var scaleX = Math.abs(x2 - x1) * 0.1;
      var scaleY = Math.abs(y2 - y1) * 0.1;
      var width = fetti.shape.bitmap.width * fetti.scalar;
      var height = fetti.shape.bitmap.height * fetti.scalar;

      var matrix = new DOMMatrix([
        Math.cos(rotation) * scaleX,
        Math.sin(rotation) * scaleX,
        -Math.sin(rotation) * scaleY,
        Math.cos(rotation) * scaleY,
        fetti.x,
        fetti.y
      ]);

      // apply the transform matrix from the confetti shape
      matrix.multiplySelf(new DOMMatrix(fetti.shape.matrix));

      var pattern = context.createPattern(bitmapMapper.transform(fetti.shape.bitmap), 'no-repeat');
      pattern.setTransform(matrix);

      context.globalAlpha = (1 - progress);
      context.fillStyle = pattern;
      context.fillRect(
        fetti.x - (width / 2),
        fetti.y - (height / 2),
        width,
        height
      );
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

    function drawFettiShapeInner(context, fetti, x1, y1, x2, y2) {
      context.beginPath();

      if (canUsePaths && fetti.shape.type === 'path' && typeof fetti.shape.path === 'string' && Array.isArray(fetti.shape.matrix)) {
        root.drawFettiPath(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape.type === 'bitmap') {
        root.drawFettiBitmap(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape === 'circle') {
        root.drawFettiCircle(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape === 'star') {
        root.drawFettiStar(context, fetti, x1, y1, x2, y2);
      } else if (fetti.shape === 'square'){
        root.drawFettiSquare(context, fetti, x1, y1, x2, y2);
      } else {
        console.assert(false, "Unkown fetti shape '%0'".arg(fetti.shape))
      }

      context.closePath();
    }

    function drawFettiShape(context, fetti, progress, x1, y1, x2, y2) {
      context.fillStyle = 'rgba(' + fetti.color.r + ', ' + fetti.color.g + ', ' + fetti.color.b + ', ' + (1 - progress) + ')';
      root.drawFettiShapeInner(context, fetti, x1, y1, x2, y2)
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
          bitmapMapper.clear();

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

    function transformPath2D(pathString, pathMatrix, x, y, scaleX, scaleY, rotation) {
      var path2d = new Path2D(pathString);

      var t1 = new Path2D();
      t1.addPath(path2d, new DOMMatrix(pathMatrix));

      var t2 = new Path2D();
      // see https://developer.mozilla.org/en-US/docs/Web/API/DOMMatrix/DOMMatrix
      t2.addPath(t1, new DOMMatrix([
        Math.cos(rotation) * scaleX,
        Math.sin(rotation) * scaleX,
        -Math.sin(rotation) * scaleY,
        Math.cos(rotation) * scaleY,
        x,
        y
      ]));

      return t2;
    }

    function shapeFromPath(pathData) {
      if (!canUsePaths) {
        throw new Error('path confetti are not supported in this browser');
      }

      var path, matrix;

      if (typeof pathData === 'string') {
        path = pathData;
      } else {
        path = pathData.path;
        matrix = pathData.matrix;
      }

      var path2d = new Path2D(path);
      var tempCanvas = document.createElement('canvas');
      var tempCtx = tempCanvas.getContext('2d');

      if (!matrix) {
        // attempt to figure out the width of the path, up to 1000x1000
        var maxSize = 1000;
        var minX = maxSize;
        var minY = maxSize;
        var maxX = 0;
        var maxY = 0;
        var width, height;

        // do some line skipping... this is faster than checking
        // every pixel and will be mostly still correct
        for (var x = 0; x < maxSize; x += 2) {
          for (var y = 0; y < maxSize; y += 2) {
            if (tempCtx.isPointInPath(path2d, x, y, 'nonzero')) {
              minX = Math.min(minX, x);
              minY = Math.min(minY, y);
              maxX = Math.max(maxX, x);
              maxY = Math.max(maxY, y);
            }
          }
        }

        width = maxX - minX;
        height = maxY - minY;

        var maxDesiredSize = 10;
        var scale = Math.min(maxDesiredSize/width, maxDesiredSize/height);

        matrix = [
          scale, 0, 0, scale,
          -Math.round((width/2) + minX) * scale,
          -Math.round((height/2) + minY) * scale
        ];
      }

      return {
        type: 'path',
        path: path,
        matrix: matrix
      };
    }

    function shapeFromText(textData) {
      var text,
          scalar = 1,
          color = '#000000',
          // see https://nolanlawson.com/2022/04/08/the-struggle-of-using-native-emoji-on-the-web/
          fontFamily = '"Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji", "EmojiOne Color", "Android Emoji", "Twemoji Mozilla", "system emoji", sans-serif';

      if (typeof textData === 'string') {
        text = textData;
      } else {
        text = textData.text;
        scalar = 'scalar' in textData ? textData.scalar : scalar;
        fontFamily = 'fontFamily' in textData ? textData.fontFamily : fontFamily;
        color = 'color' in textData ? textData.color : color;
      }

      // all other confetti are 10 pixels,
      // so this pixel size is the de-facto 100% scale confetti
      var fontSize = 10 * scalar;
      var font = '' + fontSize + 'px ' + fontFamily;

      var canvas = new OffscreenCanvas(fontSize, fontSize);
      var ctx = canvas.getContext('2d');

      ctx.font = font;
      var size = ctx.measureText(text);
      var width = Math.ceil(size.actualBoundingBoxRight + size.actualBoundingBoxLeft);
      var height = Math.ceil(size.actualBoundingBoxAscent + size.actualBoundingBoxDescent);

      var padding = 2;
      var x = size.actualBoundingBoxLeft + padding;
      var y = size.actualBoundingBoxAscent + padding;
      width += padding + padding;
      height += padding + padding;

      canvas = new OffscreenCanvas(width, height);
      ctx = canvas.getContext('2d');
      ctx.font = font;
      ctx.fillStyle = color;

      ctx.fillText(text, x, y);

      var scale = 1 / scalar;

      return {
        type: 'bitmap',
        bitmap: canvas.transferToImageBitmap(),
        matrix: [scale, 0, 0, scale, -width * scale / 2, -height * scale / 2]
      };
    }

    property var confetti: null
    QtQ.Component.onCompleted: {
        root.confetti = root.confettiCannon(root.canvas, {})
    }
}
