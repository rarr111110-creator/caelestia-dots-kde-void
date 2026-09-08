/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import ".."
import QtQuick.Layouts

Rectangle {
    id: root

    property var weatherInfo: null
    property real centerScale: 1.0

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer
    clip: true

    readonly property var _cc: weatherInfo && weatherInfo.current_condition && weatherInfo.current_condition.length > 0
                               ? weatherInfo.current_condition[0] : null
    readonly property var _wd: _cc && _cc.weatherDesc && _cc.weatherDesc.length > 0
                               ? _cc.weatherDesc[0] : null
    readonly property var _day: weatherInfo && weatherInfo.weather && weatherInfo.weather.length > 0
                                ? weatherInfo.weather[0] : null
    readonly property bool isHorizontalLayout: root.width >= 300 && root.height >= 80

    // Natural height = content + vertical padding so the card shrinks-to-fit
    // when Layout.fillHeight is not set (matches Quickshell Content.qml behaviour)
    implicitHeight: isHorizontalLayout
                    ? (horizontalContent.implicitHeight + Math.max(16, 24 * centerScale))
                    : (compactContent.implicitHeight + Math.max(12, 20 * centerScale))

    function getWeatherSymbol(desc, code) {
        var d = (desc || "").toLowerCase();
        if (d.indexOf("sunny") !== -1 || d.indexOf("clear") !== -1) return "clear_day";
        if (d.indexOf("partly") !== -1) return "partly_cloudy_day";
        if (d.indexOf("cloud") !== -1 || d.indexOf("overcast") !== -1) return "cloud";
        if (d.indexOf("rain") !== -1 || d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "rainy";
        if (d.indexOf("thunder") !== -1 || d.indexOf("storm") !== -1) return "thunderstorm";
        if (d.indexOf("snow") !== -1 || d.indexOf("blizzard") !== -1 || d.indexOf("ice") !== -1) return "weather_snowy";
        if (d.indexOf("fog") !== -1 || d.indexOf("mist") !== -1 || d.indexOf("haze") !== -1) return "foggy";
        if (d.indexOf("wind") !== -1) return "air";
        return "cloud";
    }

    // ── High-DPI / Wide Horizontal Layout ──
    RowLayout {
        id: horizontalContent
        anchors.centerIn: parent
        spacing: Math.max(12, Math.round(18 * root.centerScale))
        visible: root.isHorizontalLayout
        opacity: root._cc ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 400 } }

        // Left Section: Big Hero Temperature & Weather Icon
        RowLayout {
            id: heroSection
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.max(6, Math.round(10 * root.centerScale))

            Text {
                id: heroTemp
                text: root._cc ? root._cc.temp_C + "°C" : "--°C"
                font {
                    pixelSize: Math.max(28, Math.round(38 * root.centerScale))
                    family: LockScreenConfig.fontMetrics
                    weight: Font.DemiBold
                }
                color: root.clPrimary
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: heroIcon
                text: root._wd
                      ? root.getWeatherSymbol(root._wd.value, root._cc.weatherCode)
                      : "cloud"
                font.family: LockScreenConfig.fontIcon
                font.pixelSize: Math.max(28, Math.round(38 * root.centerScale))
                color: root.clPrimary
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Vertical Divider Separator
        Rectangle {
            id: divider
            Layout.preferredWidth: 1
            Layout.preferredHeight: Math.min(root.height - Math.round(16 * root.centerScale), Math.max(34, Math.round(46 * root.centerScale)))
            Layout.alignment: Qt.AlignVCenter
            color: Qt.rgba(root.clSurfaceVariantFg.r, root.clSurfaceVariantFg.g, root.clSurfaceVariantFg.b, 0.18)
        }

        // Right Section: Condition, Feels Like, High / Low Range
        ColumnLayout {
            id: detailsSection
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: Math.max(80, root.width - heroSection.implicitWidth - divider.width - (horizontalContent.spacing * 2) - Math.round(32 * root.centerScale))
            spacing: Math.max(1, Math.round(2 * root.centerScale))

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: detailsSection.Layout.maximumWidth
                text: root._wd ? root._wd.value : "No weather"
                font {
                    pixelSize: Math.max(12, Math.round(14 * root.centerScale))
                    family: LockScreenConfig.fontHeading
                    weight: Font.Medium
                }
                color: root.clSurfaceFg
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: detailsSection.Layout.maximumWidth
                text: root._cc ? "Feels like " + root._cc.FeelsLikeC + "°C" : "Feels like --°C"
                font {
                    pixelSize: Math.max(10, Math.round(12 * root.centerScale))
                    family: LockScreenConfig.fontBody
                }
                color: root.clSurfaceVariantFg
                elide: Text.ElideRight
            }

            Text {
                visible: Boolean(root._day)
                Layout.fillWidth: true
                Layout.maximumWidth: detailsSection.Layout.maximumWidth
                text: root._day
                      ? "High " + root._day.maxtempC + "°C • Low " + root._day.mintempC + "°C"
                      : ""
                font {
                    pixelSize: Math.max(10, Math.round(11 * root.centerScale))
                    family: LockScreenConfig.fontMetrics
                }
                color: root.clSurfaceVariantFg
                elide: Text.ElideRight
            }
        }
    }

    // ── Low-DPI / Compact Layout ──
    RowLayout {
        id: compactContent
        anchors.centerIn: parent
        spacing: Math.max(6, 10 * root.centerScale)
        visible: !root.isHorizontalLayout
        opacity: root._cc ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Text {
            text: root._cc ? root._cc.temp_C + "°C" : "--°C"
            font {
                pixelSize: LockScreenConfig.sizeLarge
                family: LockScreenConfig.fontMetrics
                weight: Font.Medium
            }
            color: root.clPrimary
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root._wd
                  ? root.getWeatherSymbol(root._wd.value, root._cc.weatherCode)
                  : "cloud"
            font.family: LockScreenConfig.fontIcon
            font.pixelSize: LockScreenConfig.sizeLarge
            color: root.clPrimary
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
