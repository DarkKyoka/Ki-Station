cmake_minimum_required(VERSION 3.16)
project(Ki_Station VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

set(APP_RESOURCES
    Main.qml
        icons/Images/Makima.jpg
    icons/Weathers/sun.svg
    icons/battery-full.svg
    icons/power.svg

    # Media Control Icons
        icons/MediaPlayer/pause.svg
        icons/MediaPlayer/skip-forward.svg
        icons/MediaPlayer/skip-back.svg

    # Settings gear
        icons/settings.svg

    # Wifi
        icons/Wifi/wifi.svg
        icons/Wifi/wifi-high.svg
        icons/Wifi/wifi-low.svg
        icons/Wifi/wifi-zero.svg


    # Bluetooth
        icons/Bluetooth/bluetooth_static.svg

    # KDE
        icons/monitor-smartphone.svg

    # DnD
        icons/DnD/bell-off.svg

    # Mic
        icons/Mic/mic-on.svg
        icons/Mic/mic-off.svg

    # Volume
        icons/volume-2.svg
)

# Prefer Qt6, fall back to Qt5
find_package(Qt6 COMPONENTS Quick QUIET)
if (Qt6_FOUND)
  message(STATUS "Using Qt6")
  set(QT_QUICK_LIB Qt6::Quick)
else()
  find_package(Qt5 COMPONENTS Quick REQUIRED)
  message(STATUS "Using Qt5")
  set(QT_QUICK_LIB Qt5::Quick)
endif()

add_executable(${PROJECT_NAME}
    main.cpp
)

qt_add_resources(${PROJECT_NAME} "resources"
    PREFIX "/"
    FILES ${APP_RESOURCES}
)
set_source_files_properties(appConstants.qml
        PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)
qt_add_qml_module(ki_Station
        URI ki_Station
        VERSION 1.0
        QML_FILES
          Main.qml
          appConstants.qml

)


target_link_libraries(${PROJECT_NAME} PRIVATE ${QT_QUICK_LIB})
