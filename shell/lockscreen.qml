pragma ComponentBehavior: Bound

import "modules"
import "modules/lock"
import QtQml
import Quickshell
import Caelestia
import Caelestia.Config

ShellRoot {
    Component.onCompleted: {
        Qt.application.name = "caelestia-lockscreen";
    }

    Fonts {}
    GSFLoader {}

    // Match the shell's language (see shell/translations)
    Binding {
        target: Translations
        property: "extraSearchPaths"
        value: [Qt.resolvedUrl("translations")]
    }

    Binding {
        target: Translations
        property: "language"
        value: GlobalConfig.general.language
    }

    Variants {
        model: Quickshell.screens
        
        LockBackgroundWindow {
            required property var modelData

            targetScreen: modelData
        }
    }
}
