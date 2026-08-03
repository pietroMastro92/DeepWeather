import ProjectDescription

let project = Project(
    name: "DeepWeather-iOS",
    targets: [
        .target(
            name: "DeepWeather-iOS",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.pietromastro.deepweather",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "LaunchBackground",
                    "UIImageName": "LaunchLogo"
                ],
                "NSLocationWhenInUseUsageDescription": "DeepWeather uses your location to show local weather when no city is selected.",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight"
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationPortraitUpsideDown",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight"
                ]
            ]),
            entitlements: .file(path: "DeepWeather-iOS.entitlements"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                "PRODUCT_NAME": "DeepWeather",
                "MARKETING_VERSION": "1.0",
                "CURRENT_PROJECT_VERSION": "1"
            ]),
            dependencies: [
                .target(name: "DeepWeatherWidget")
            ]
        ),
        .target(
            name: "DeepWeatherWidget",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.pietromastro.deepweather.widget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ],
                "GeneratedExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).DeepWeatherWidgetBundle"
            ]),
            entitlements: .file(path: "DeepWeatherWidget.entitlements"),
            sources: [
                "Widget/**",
                "Sources/Shared/AppGroup.swift",
                "Sources/Shared/WeatherSnapshot.swift",
                "Sources/Shared/WeatherModel.swift",
                "Sources/Shared/WeatherClient.swift",
                "Sources/Shared/WeatherIconMapper.swift",
                "Sources/Shared/SavedLocation.swift"
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                "PRODUCT_NAME": "DeepWeatherWidget",
                "MARKETING_VERSION": "1.0",
                "CURRENT_PROJECT_VERSION": "1",
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "SKIP_INSTALL": "YES"
            ])
        )
    ]
)
