load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")

# 核心工具库
swift_library(
    name = "TelegramCustomCore",
    srcs = glob(["Sources/Core/**/*.swift"]),
    module_name = "TelegramCustomCore",
    data = glob(["Resources/Localizations/**/*.strings"]),
    visibility = ["//visibility:public"],
)

# 开屏页模块
swift_library(
    name = "SplashScreenModule",
    srcs = glob(["Sources/Features/SplashScreen/**/*.swift"]),
    module_name = "SplashScreen",
    deps = [":TelegramCustomCore"],
    data = glob(["Resources/Localizations/**/*.strings"]),
    visibility = ["//visibility:public"],
)

# 登录页模块
swift_library(
    name = "LoginScreenModule",
    srcs = glob(["Sources/Features/LoginScreen/**/*.swift"]),
    module_name = "LoginScreen",
    deps = [":TelegramCustomCore"],
    data = glob(["Resources/Localizations/**/*.strings"]),
    visibility = ["//visibility:public"],
)

# ==================== CUSTOM START ====================
# 描述：添加 CustomTabBar 和 DiscoverPlaceholder 模块
# 文件：TelegramCustom/BUILD
# 日期：2026-09-23

swift_library(
    name = "CustomTabBarModule",
    module_name = "CustomTabBar",
    srcs = glob([
        "Sources/Features/CustomTabBar/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "DiscoverPlaceholderModule",
    module_name = "DiscoverPlaceholder",
    srcs = glob([
        "Sources/Features/DiscoverPlaceholder/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "DiscoverModule",
    module_name = "Discover",
    srcs = glob([
        "Sources/Features/Discover/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
    ],
    visibility = ["//visibility:public"],
)
# ==================== CUSTOM END ====================

# 多语言资源
apple_resource_bundle(
    name = "LocalizationResources",
    resources = glob(["Resources/Localizations/**/*.strings"]),
    visibility = ["//visibility:public"],
)

# 统一导出（未来可扩展更多模块）
swift_library(
    name = "TelegramCustom",
    module_name = "TelegramCustom",
    srcs = ["Sources/TelegramCustom.swift"],
    deps = [
        ":TelegramCustomCore",
        ":SplashScreenModule",
        ":LoginScreenModule",
        ":CustomTabBarModule",
        ":DiscoverPlaceholderModule",
        ":DiscoverModule",
    ],
    visibility = ["//visibility:public"],
)
