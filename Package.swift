// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "QRCodeApp",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // Generatore di QR-Code
        .package(url: "https://github.com/fwcd/swift-qrcode-generator.git", branch: "main"),
        .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.5.0")

    ],
    targets: [
        .executableTarget(
            name: "QRCodeApp",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "QRCodeGenerator", package: "swift-qrcode-generator"),
                .product(name: "SwiftGD", package: "SwiftGD")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "QRCodeAppTests",
            dependencies: [
                .target(name: "QRCodeApp"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            path: "Tests/QRCodeAppTests",
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
