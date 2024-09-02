import QtQuick

Window {
  id: root;

  width: 640;
  height: 480;
  visible: true;
  title: qsTr("Confetti");

  color: "#131313";

  function snow() {
    var duration = 15 * 1000;
    var animationEnd = Date.now() + duration;
    var skew = 1;

    function randomInRange(min, max) {
      return Math.random() * (max - min) + min;
    }

    function frame() {
      var timeLeft = animationEnd - Date.now();
      var ticks = Math.max(200, 500 * (timeLeft / duration));
      skew = Math.max(0.8, skew - 0.001);

      confetti.fire({
        particleCount: 1,
        startVelocity: 0,
        ticks: ticks,
        origin: {
          x: Math.random(),
          // since particles fall down, skew start toward the top
          y: (Math.random() * skew) - 0.2
        },
        colors: [
          Qt.color('#FB923C'), // orange_300
          Qt.color('#E51A9B'), // meld_rhodamine_red
          Qt.color('#8E51ED'), // meld_indigo
          Qt.color('#0083CB'), // meld_process_blue
          Qt.color('#017AFF'), // meld_blue
          Qt.color('#52FFC0'), // meld_teal
        ],
        shapes: ['square'],
        gravity: randomInRange(0.4, 0.6),
        scalar: randomInRange(0.4, 1),
        drift: randomInRange(-0.4, 0.4)
      });
      confetti.requestPaint();

      if (timeLeft <= 0) {
        confetti.painted.disconnect(frame);
      }
    }

    confetti.painted.connect(frame);
    frame();
  }

  ////////////////////////////////////////////////////////////////////////////
  // Example method for how to "confetti" emoji icons.
  // Right click canvas to trigger.
  ////////////////////////////////////////////////////////////////////////////

  // Step 1: Create a text item displaying the required emoji.
  Text {
    id: textShapeSource;

    // Make invisible this item does not show normally.
    visible: false;
    color: "#000000";
    font.family: "Segoe UI Emoji";
    font.pixelSize: 32;
    text: "🦄";
  }

  function emoji() : void {
    // Step 2: Use QML's Item.grabToImage method to get the item as a image.
    textShapeSource.grabToImage(function(itemGrabResult) {

    function onLoadedCallback(itemGrabResultShape) {
      // Step 5: Optionally unload the image if it is no longer
      // required. You must unload any images you load as otherwise
      // confetti will retain a reference to them internally.
      function unloadImageGrabResultShape() {
        confetti.unloadItemGrabResultShape(itemGrabResultShape);
      }

      // Step 4: Create teh confetti effect using the provided
      // "itemGrabResultShape" as the shape.
      confetti.fire({
        spread: 360,
        ticks: 60,
        gravity: 0,
        origin: Qt.point(0.5, 0.5),
        decay: 0.96,
        startVelocity: 20,
        shapes: [itemGrabResultShape],
      }).then(unloadImageGrabResultShape, unloadImageGrabResultShape);
    }

    function onLoadFailedCallback(itemGrabResult) {
      console.warn("Confetti failed to load ItemGrabResult as shape.");
    }

    // Step 3: Use "loadItemGrabResultAsShape" to asynchronously load
    // the image into the canvas so that it can rendered.
    const itemSize = Qt.size(textShapeSource.width, textShapeSource.height);
    confetti.loadItemGrabResultAsShape(itemGrabResult,
                                       itemSize,
                                       onLoadedCallback,
                                       onLoadFailedCallback);
    })
  }
  ////////////////////////////////////////////////////////////////////////////

  Confetti {
    id: confetti;

    anchors.fill: root.contentItem;
    contextType: "2d";
    renderStrategy: Canvas.Threaded;

    Column {
      anchors.top: parent.top;
      anchors.left: parent.left;
      anchors.margins: 10;
      Text {
        text: "Current FPS: " + confetti.currentFPS.toFixed(2);
        font.pixelSize: 20;
        color: "white";
      }
      Text {
        text: "Average FPS: " + confetti.averageFPS.toFixed(2);
        font.pixelSize: 20;
        color: "white";
      }
    }

    MouseArea {
      anchors.fill: confetti;
      acceptedButtons: Qt.AllButtons;

      onPressed: event => {
        if (event.button === Qt.RightButton) {
          root.snow();
          return;
        }

        if (event.button === Qt.MiddleButton) {
          root.emoji();
          return;
        }

        const count = 200;
        const defaults = {
          "origin": Qt.point(event.x / confetti.width, event.y / confetti.height)
        }

        function fire(particleRatio, opts) {
          const params = Object.assign({"particleCount": Math.floor(count * particleRatio)}, defaults, opts);
          confetti.fire(params);
        }

        fire(0.25, {
          "spread": 26,
          "startVelocity": 55
        })
        fire(0.2, {
          "spread": 60,
        })
        fire(0.35, {
          "spread": 100,
          "decay": 0.91,
          "scalar": 0.8
        })
        fire(0.1, {
          "spread": 120,
          "startVelocity": 25,
          "decay": 0.92,
          "scalar": 1.2
        })
        fire(0.1, {
          "spread": 120,
          "startVelocity": 45
        })
      }
    }
  }
}
