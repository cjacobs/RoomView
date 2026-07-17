// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RoomViewKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "RoomViewKit",
            targets: ["RoomViewKit"]
        ),
    ],
    targets: [
        .target(
            name: "RoomViewKit"
        ),
        .testTarget(
            name: "RoomViewKitTests",
            dependencies: ["RoomViewKit"]
        ),
    ]
)
