// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextContract",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ContextContract", targets: ["ContextContract"])
    ],
    targets: [
        .target(name: "ContextContract"),
        .testTarget(name: "ContextContractTests", dependencies: ["ContextContract"])
    ]
)
