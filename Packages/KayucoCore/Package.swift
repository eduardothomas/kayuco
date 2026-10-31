// swift-tools-version: 6.1
// KayucoCore: protocolo host↔clientes y política de ruteo (ADR 0004, 0006, 0007).
// Sin dependencias y sin APIs exclusivas de Apple: el CI lo compila en Linux (regla 23).
import PackageDescription

let package = Package(
    name: "KayucoCore",
    platforms: [
        // Con tools-version 6.1 aún no existe `.v26`; se usa la forma de texto.
        .macOS("26.0"),
        .iOS("26.0"),
    ],
    products: [
        .library(name: "KayucoCore", targets: ["KayucoCore"]),
    ],
    targets: [
        .target(name: "KayucoCore"),
        .testTarget(
            name: "KayucoCoreTests",
            dependencies: ["KayucoCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
