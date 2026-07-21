// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BirdHiDPI",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BirdHiDPI", targets: ["HiDPI"])
    ],
    targets: [
        .target(
            name: "VirtualDisplayBridge",
            publicHeadersPath: "include",
            linkerSettings: [.linkedFramework("CoreGraphics")]
        ),
        .executableTarget(name: "HiDPI", dependencies: ["VirtualDisplayBridge"]),
        .testTarget(
            name: "HiDPITests",
            dependencies: ["HiDPI", "VirtualDisplayBridge"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
