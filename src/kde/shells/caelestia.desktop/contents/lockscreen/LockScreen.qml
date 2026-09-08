/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later

    Caelestia lock screen entry point.
    This is the root Item that kscreenlocker expects.
*/

import QtQuick
import Caelestia.Services
import M3Shapes

Item {
    id: root

    // kscreenlocker sets and reads this property to track the lock state
    property bool locked: true
    property bool viewVisible: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        anchors.fill: parent
    }
}
