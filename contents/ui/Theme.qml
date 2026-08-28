// Theme.qml

import QtQuick

// The original, fixed Ki Station palette.
Item {
    visible: false
    width: 0
    height: 0

    readonly property var active: ({
        // Entire widget and shared cards
        widgetBackgroundColor: "#470020",
        cardBackgroundColor: "#2E0015",
        insetBackgroundColor: "#1A0009",
        primaryTextColor: "#FFFFFF",
        secondaryTextColor: "#AAAAAA",

        // Top Panel — battery and quick-action icons
        topPanelBatteryIconColor: "#FFFFFF",
        topPanelSettingsIconColor: "#FFFFFF",
        topPanelWifiIconColor: "#8FA3FF",
        topPanelBluetoothIconColor: "#BCC7F5",
        topPanelKdeConnectIconColor: "#FFFFFF",
        topPanelPowerIconColor: "#ffffff",

        // Weather & Time card
        weatherTimeIconColor: "#FFFFFF",
        weatherTimePeriodTextColor: "#FFD93D",

        // Media Player card
        mediaControlIconColor: "#FFFFFF",
        mediaPlayerNameTextColor: "#69FF94",
        mediaProgressTrackColor: "#200011",
        mediaProgressFillColor: "#69FF94",

        // Volume & Brightness card
        volumeIconColor: "#FFFFFF",
        brightnessIconColor: "#FFFFFF",

        volumeBrightnessSliderTrackColor: "#200011",

        volumeBrightnessSliderFillColor: "#FF4081",
        volumeBrightnessHandleColor: "#670725",
        volumeBrightnessHandleBorderColor: "#FFFFFF",

        // Do Not Disturb card
        doNotDisturbOnIconColor: "#FF6B6B",
        doNotDisturbOffIconColor: "#ffffff",

        // Microphone card
        microphoneEnabledIconColor: "#69c1ff",
        microphoneMutedIconColor: "#FF6B6B",

        // System Information card
        cpuIconColor: "#FFFFFF",
        memoryIconColor: "#FFFFFF",
        ethernetIconColor: "#FFFFFF",
        networkStatisticsTextColor: "#5AC8FA",
        highCpuWarningTextColor: "#FF6B6B",

        // Wi-Fi popup
        wifiPopupBorderColor: "#26FFFFFF",
        wifiConnectedIndicatorColor: "#69FF94",

        // Terminal panel
        terminalHeaderTextColor: "#AAAAAA",
        terminalOutputTextColor: "#E0A458",
        terminalPromptTextColor: "#6AED0C",

        // Alarm card
        alarmHeaderTextColor: "#AAAAAA",
        alarmTimeTextColor: "#E0A458",
        alarmExpiredTextColor: "#FF6B6B",
        alarmResetIconColor: "#FF6B6B"
    })

    property color widgetBackgroundColor: active.widgetBackgroundColor
    property color cardBackgroundColor: active.cardBackgroundColor
    property color insetBackgroundColor: active.insetBackgroundColor
    property color primaryTextColor: active.primaryTextColor
    property color secondaryTextColor: active.secondaryTextColor
    property color topPanelBatteryIconColor: active.topPanelBatteryIconColor
    property color topPanelSettingsIconColor: active.topPanelSettingsIconColor
    property color topPanelWifiIconColor: active.topPanelWifiIconColor
    property color topPanelBluetoothIconColor: active.topPanelBluetoothIconColor
    property color topPanelKdeConnectIconColor: active.topPanelKdeConnectIconColor
    property color topPanelPowerIconColor: active.topPanelPowerIconColor
    property color weatherTimeIconColor: active.weatherTimeIconColor
    property color weatherTimePeriodTextColor: active.weatherTimePeriodTextColor
    property color mediaControlIconColor: active.mediaControlIconColor
    property color mediaPlayerNameTextColor: active.mediaPlayerNameTextColor
    property color mediaProgressTrackColor: active.mediaProgressTrackColor
    property color mediaProgressFillColor: active.mediaProgressFillColor
    property color volumeIconColor: active.volumeIconColor
    property color brightnessIconColor: active.brightnessIconColor
    property color volumeBrightnessSliderTrackColor: active.volumeBrightnessSliderTrackColor
    property color volumeBrightnessSliderFillColor: active.volumeBrightnessSliderFillColor
    property color volumeBrightnessHandleColor: active.volumeBrightnessHandleColor
    property color volumeBrightnessHandleBorderColor: active.volumeBrightnessHandleBorderColor
    property color doNotDisturbOnIconColor: active.doNotDisturbOnIconColor
    property color doNotDisturbOffIconColor: active.doNotDisturbOffIconColor
    property color microphoneEnabledIconColor: active.microphoneEnabledIconColor
    property color microphoneMutedIconColor: active.microphoneMutedIconColor
    property color cpuIconColor: active.cpuIconColor
    property color memoryIconColor: active.memoryIconColor
    property color ethernetIconColor: active.ethernetIconColor
    property color networkStatisticsTextColor: active.networkStatisticsTextColor
    property color highCpuWarningTextColor: active.highCpuWarningTextColor
    property color wifiPopupBorderColor: active.wifiPopupBorderColor
    property color wifiConnectedIndicatorColor: active.wifiConnectedIndicatorColor
    property color terminalHeaderTextColor: active.terminalHeaderTextColor
    property color terminalOutputTextColor: active.terminalOutputTextColor
    property color terminalPromptTextColor: active.terminalPromptTextColor
    property color alarmHeaderTextColor: active.alarmHeaderTextColor
    property color alarmTimeTextColor: active.alarmTimeTextColor
    property color alarmExpiredTextColor: active.alarmExpiredTextColor
    property color alarmResetIconColor: active.alarmResetIconColor

    // Semantic names consumed by the UI components.
    readonly property color surface: cardBackgroundColor
    readonly property color surfaceAlt: insetBackgroundColor
    readonly property color text: primaryTextColor
    readonly property color subtext: secondaryTextColor
    readonly property color iconAction: topPanelSettingsIconColor
    readonly property color batteryIconColor: topPanelBatteryIconColor
    readonly property color wifiIconColor: topPanelWifiIconColor
    readonly property color bluetoothIconColor: topPanelBluetoothIconColor
    readonly property color kdeConnectIconColor: topPanelKdeConnectIconColor
    readonly property color weatherIconColor: weatherTimeIconColor
    readonly property color iconMedia: mediaControlIconColor
    readonly property color positive: mediaProgressFillColor
    readonly property color negative: alarmExpiredTextColor
    readonly property color accent: volumeBrightnessSliderFillColor
    readonly property color onAccent: volumeBrightnessHandleBorderColor
    readonly property color info: networkStatisticsTextColor
    readonly property color neutral: weatherTimePeriodTextColor
    readonly property color border: wifiPopupBorderColor
    readonly property color terminalText: terminalOutputTextColor
    readonly property color terminalPrompt: terminalPromptTextColor
}
