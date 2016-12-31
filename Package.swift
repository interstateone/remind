import PackageDescription

let package = Package(
    name: "remind",
    dependencies: [
        .Package(url: "https://github.com/interstateone/argue.git", majorVersion: 2)
    ]
)
