qt_add_library(confetti STATIC)
qt_add_qml_module(confetti
  URI "Confetti"
  VERSION 1.0
  QML_FILES
    ConfettiCavnas.qml
  RESOURCE_PREFIX /Confetti/
)

target_link_libraries(confetti
  PRIVATE Qt6::Quick
)
