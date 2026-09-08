import QtQuick
import Quickshell
import Caelestia.Models

// Loads every font found under assets/fonts - both the bundled ones
// (google-sans-flex) and anything the user drops in (e.g. SF-Pro/, SF-Mono/,
// or their own folders) - recursively. Adding a font never requires touching
// this file.
Item {
    FileSystemModel {
        id: fontsModel

        recursive: true
        path: Quickshell.shellPath("assets/fonts")
        filter: FileSystemModel.Files
        nameFilters: ["*.ttf", "*.otf"]
    }

    Repeater {
        model: fontsModel

        delegate: Item {
            FontLoader {
                source: "file://" + modelData.path
            }
        }
    }
}
