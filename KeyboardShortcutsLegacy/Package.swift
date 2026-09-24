// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardShortcutsLegacy",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "KeyboardShortcutsLegacy",
            targets: ["KeyboardShortcutsLegacy"]
        ),
    ],
    targets: [
        .target(
            name: "KeyboardShortcutsLegacy",
            path: "Sources/KeyboardShortcutsLegacy"
        ),
    ]
)
