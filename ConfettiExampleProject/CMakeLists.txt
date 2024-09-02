cmake_minimum_required(VERSION 3.20)

project(ConfettiExampleProject VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.7 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.7)

add_subdirectory(Confetti)

qt_add_executable(appConfetti
  main.cpp
)

qt_add_qml_module(appConfetti
  URI ConfettiExampleProject
  VERSION 1.0
  QML_FILES
    Main.qml
)

target_link_libraries(appConfetti PRIVATE confettiplugin)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appConfetti PROPERTIES
#  MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appConfetti
  MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
  MACOSX_BUNDLE TRUE
  WIN32_EXECUTABLE TRUE
)

target_link_libraries(appConfetti
  PRIVATE Qt6::Quick
)
