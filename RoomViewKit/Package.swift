// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RoomViewKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
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
