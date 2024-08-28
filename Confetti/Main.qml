import QtQuick

Window {
    id: root

    width: 640
    height: 480
    visible: true
    title: qsTr("Confetti")

    color: "grey"

    Confetti {
        id: confetti
        canvas: canvas
    }

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

          confetti.confetti({
            particleCount: 1,
            startVelocity: 0,
            ticks: ticks,
            origin: {
              x: Math.random(),
              // since particles fall down, skew start toward the top
              y: (Math.random() * skew) - 0.2
            },
            colors: ['#ffffff'],
            shapes: ['circle'],
            gravity: randomInRange(0.4, 0.6),
            scalar: randomInRange(0.4, 1),
            drift: randomInRange(-0.4, 0.4)
          });
          canvas.requestPaint()

          if (timeLeft <= 0) {
            canvas.painted.disconnect(frame)
          }
        }

        canvas.painted.connect(frame)
        frame()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        contextType: "2d"
        renderStrategy: Canvas.Threaded

        property int frameCount: 0
        property real lastTime: 0
        property real fps: 0
        onPainted: {
            const frameCount = ++this.frameCount;
            var currentTime = Date.now();
            if (this.lastTime === 0) {
                this.lastTime = currentTime;
            } else {
                // time in seconds
                var deltaTime = (currentTime - this.lastTime) / 1000.0;

                if (deltaTime >= 0.2) {
                    this.fps = frameCount / deltaTime;
                    this.frameCount = 0;
                    this.lastTime = currentTime;
                }

            }
        }

        Text {
            id: fpsText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            text: "FPS: " + canvas.fps.toFixed(2)
            font.pixelSize: 20
            color: "white"
        }

        MouseArea {
            anchors.fill: canvas
            acceptedButtons: Qt.AllButtons

            onPressed: event => {

                if (event.button === Qt.RightButton) {
                    root.snow()
                    return
                }
                var count = 200
                var defaults = {
                    "origin": {
                        "y": 0.7
                    }
                }

                function fire(particleRatio, opts) {
                    const params = Object.assign({"particleCount": Math.floor(count * particleRatio)}, defaults, opts)
                    confetti.confetti(params)
                }

                fire(0.25, {
                    "spread": 26,
                    "startVelocity": 55
                })
                fire(0.2, {
                    "spread": 60
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

    Column {
        Text {
            text: "canUsePaths: " + confetti.canUsePaths
        }
    }
}
