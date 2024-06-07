// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "image-source",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "image-source",
            targets: [
                "image-source"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", exact: "4.2.0")
    ],
    targets: [
        .target(
            name: "image-source",
            dependencies: ["AlamofireImage"],
            path: "ImageSource"
        )
    ]
)
