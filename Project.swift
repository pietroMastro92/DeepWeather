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
                "LSUIElement": true
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                "PRODUCT_NAME": "DeepWeather",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"
            ])
        )
    ]
)
