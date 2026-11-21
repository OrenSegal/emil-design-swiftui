// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EmilMotion",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "EmilMotion", targets: ["EmilMotion"])],
    targets: [
        .target(name: "EmilMotion"),
        .testTarget(name: "EmilMotionTests", dependencies: ["EmilMotion"]),
    ]
)
