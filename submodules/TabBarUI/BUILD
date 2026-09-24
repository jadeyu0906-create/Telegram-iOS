load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TabBarUI",
    module_name = "TabBarUI",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ] + select({
        # ==================== CUSTOM START ====================
        # 描述：为 Web3 自定义 Tab Bar 添加条件编译宏
        # 文件：TabBarUI/BUILD
        # 日期：2026-09-23
        # 注意：同步 upstream 时保留此块
        "//Telegram:enableWeb3SplashSetting": ["-DENABLE_WEB3_SPLASH"],
        # ==================== CUSTOM END ====================
        "//conditions:default": [],
    }),
    deps = [
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
    	"//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode",
        "//submodules/TelegramPresentationData",
        "//submodules/ComponentFlow",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/TelegramUI/Components/TabBarComponent",
        "//submodules/TelegramUI/Components/GlassControls",
    ] + select({
        # ==================== CUSTOM START ====================
        # 描述：Web3 自定义 Tab Bar 依赖 TelegramCustom 模块
        # 文件：TabBarUI/BUILD
        # 日期：2026-09-23
        # 注意：同步 upstream 时保留此块
        "//Telegram:enableWeb3SplashSetting": ["//submodules/TelegramCustom:TelegramCustom"],
        # ==================== CUSTOM END ====================
        "//conditions:default": [],
    }),
    visibility = [
        "//visibility:public",
    ],
)
