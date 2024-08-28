import QtQuick

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Confetti")

    color: "grey"

    Confetti {
        id: confetti
        canvas: canvas
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        MouseArea {
            anchors.fill: canvas

            onPressed: event => {
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
