// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwAuth",
    products: [
        .library(name: "SwAuth", targets: ["SwAuth"])
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/EFPrefix/EFQRCode.git", .upToNextMinor(from: "6.1.0")),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "SwAuth", dependencies: [
            "KeychainAccess",
            "EFQRCode",
            .product(name: "AsyncHTTPClient", package: "async-http-client")
        ]),
        .testTarget(name: "SwAuthTests", dependencies: ["SwAuth"])
    ]
)
