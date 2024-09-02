qt_add_library(confetti STATIC)
qt_add_qml_module(confetti
  URI "Confetti"
  VERSION 1.0
  QML_FILES
    ConfettiCavnas.qml
  RESOURCE_PREFIX /Confetti/

  # Compile qml files (listed in QML_FILES) to C++ using qmltc and add these
  # files to the application binary:
  ENABLE_TYPE_COMPILER
)

target_link_libraries(confetti
  PRIVATE
    Qt6::Quick
    Qt6::QuickPrivate # Required for "ENABLE_TYPE_COMPILER".
)
