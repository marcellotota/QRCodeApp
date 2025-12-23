// swift-tools-version:6.0
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
    name: "QRCodeApp",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        .package(url: "https://github.com/EFPrefix/EFQRCode.git", from: "6.1.0")
    ],
    targets: [
        .executableTarget(
            name: "QRCodeApp",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "EFQRCode", package: "EFQRCode")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "QRCodeAppTests",
            dependencies: [
                .target(name: "QRCodeApp"),
                .product(name: "VaporTesting", package: "vapor")
            ],
            swiftSettings: swiftSettings
        )
    ]
)
