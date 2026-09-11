// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DepremOlduCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "DepremOlduDomain", targets: ["DepremOlduDomain"]),
        .library(name: "DepremOlduFaults", targets: ["DepremOlduFaults"]),
        .library(name: "DepremOlduNetworking", targets: ["DepremOlduNetworking"]),
        .library(name: "DepremOlduPersistence", targets: ["DepremOlduPersistence"]),
        .library(name: "DepremOlduRepository", targets: ["DepremOlduRepository"]),
        .library(name: "DepremOlduTestSupport", targets: ["DepremOlduTestSupport"]),
    ],
    targets: [
        .target(name: "DepremOlduDomain"),
        .target(
            name: "DepremOlduNetworking",
            dependencies: ["DepremOlduDomain"]
        ),
        .target(name: "DepremOlduPersistence"),
        .target(
            name: "DepremOlduFaults",
            dependencies: ["DepremOlduDomain"]
        ),
        .target(
            name: "DepremOlduRepository",
            dependencies: [
                "DepremOlduDomain",
                "DepremOlduNetworking",
                "DepremOlduPersistence",
            ]
        ),
        .target(
            name: "DepremOlduTestSupport",
            dependencies: [
                "DepremOlduDomain",
                "DepremOlduNetworking",
                "DepremOlduRepository",
            ]
        ),
        .testTarget(
            name: "DepremOlduDomainTests",
            dependencies: ["DepremOlduDomain"]
        ),
        .testTarget(
            name: "DepremOlduNetworkingTests",
            dependencies: [
                "DepremOlduDomain",
                "DepremOlduNetworking",
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "DepremOlduPersistenceTests",
            dependencies: ["DepremOlduPersistence"]
        ),
        .testTarget(
            name: "DepremOlduRepositoryTests",
            dependencies: [
                "DepremOlduDomain",
                "DepremOlduNetworking",
                "DepremOlduPersistence",
                "DepremOlduRepository",
                "DepremOlduTestSupport",
            ]
        ),
        .testTarget(
            name: "DepremOlduFaultsTests",
            dependencies: [
                "DepremOlduDomain",
                "DepremOlduFaults",
            ],
            resources: [.process("Fixtures")]
        ),
    ]
)
