// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KittyPlayer",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "KittyPlayer",
            path: "Sources/KittyPlayer",
            resources: [
                .copy("../../Resources/overlay.html")
            ],
            linkerSettings: [
                .linkedFramework("WebKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("CryptoKit")
            ]
        )
    ]
)
