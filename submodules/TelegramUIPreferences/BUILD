load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TelegramUIPreferences",
    module_name = "TelegramUIPreferences",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ] + select({
        # ==================== CUSTOM START ====================
        # 描述：为 Web3 默认黑色主题添加条件编译宏
        # 文件：TelegramUIPreferences/BUILD
        # 日期：2026-09-23
        # 注意：同步 upstream 时保留此块
        "//Telegram:enableWeb3SplashSetting": ["-DENABLE_WEB3_SPLASH"],
        # ==================== CUSTOM END ====================
        "//conditions:default": [],
    }),
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/Postbox:Postbox",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
