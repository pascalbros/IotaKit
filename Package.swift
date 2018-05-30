// IotaKit Package.swift

import PackageDescription

let package = Package(
    name: "IotaKit",
    products: [
        .library(
            name: "IotaKit",
            targets: ["IotaKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
		.target(name: "sha3", dependencies: []),
        .target(name: "cpow", dependencies: []),
        .target(
            name: "IotaKit",
            dependencies: ["sha3", "cpow"]),
        .testTarget(
            name: "IotaKitTests",
            dependencies: ["IotaKit"]),
    ]
)
