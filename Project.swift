import ProjectDescription

let project = Project(
    name: "DeepWeather",
    targets: [
        .target(
            name: "DeepWeather",
            destinations: [.mac],
            product: .app,
            bundleId: "com.pietromastro.deepweather",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "LSUIElement": true,
                "CFBundleShortVersionString": "1.5.2"
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                "PRODUCT_NAME": "DeepWeather",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ARCHS": "arm64 x86_64",
                "ONLY_ACTIVE_ARCH": "NO"
            ])
        )
    ]
)
