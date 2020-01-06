// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Avenue",
    products: [
        .library(name: "Avenue", targets: ["Avenue"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        // 🔵 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Avenue", dependencies: ["FluentPostgreSQL", "Vapor"]),
        .testTarget(name: "AvenueTests", dependencies: ["Avenue"]),
    ]
)
