// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpirtoAPI",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git",
                 .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git",
                 .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git",
                 .upToNextMajor(from: "3.0.0")),    
        .package(url: "https://github.com/IBM-Swift/Kitura-OpenAPI.git",
                .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "SpirtoAPI",
            dependencies: ["Kitura" , "HeliumLogger", "CouchDB", "KituraOpenAPI"]),
        .testTarget(
            name: "SpirtoAPITests",
            dependencies: ["Kitura" , "HeliumLogger", "CouchDB", "KituraOpenAPI"]),
    ]
)
