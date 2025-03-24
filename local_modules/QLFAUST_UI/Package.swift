// swift-tools-version:5.5

//  Package.swift
//  QLFAUST
//
//  Created by alex on 24/03/2025.
//

import PackageDescription

let package = Package(
    name: "QLFAUST_UI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "QLFAUST_UI",
            targets: ["QLFAUST_UI"]
        )
         
    ],
    dependencies: [
        .package(url: "https://github.com/njazz/FaustSwiftUI", .branch("dev")),
        .package(url: "https://github.com/exyte/SVGView", .branch("main")),
        .package(url: "https://github.com/danielsaidi/RichTextKit.git", .branch("main"))
    ],
    targets: [
        .target(
            name: "QLFAUST_UI",
            dependencies: [.byName(name: "FaustSwiftUI"), .byName(name: "SVGView"), .byName(name: "RichTextKit")],
            path: "Sources/",
            resources: []
        )
    ]
)
