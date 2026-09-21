import Foundation

/// 多语言管理器 - 统一管理本地化字符串
public enum LocalizationManager {
    /// 获取资源bundle - 直接使用主bundle，资源文件会被打包进去
    private static var resourceBundle: Bundle = Bundle.main

    /// 获取本地化字符串
    public static func string(forKey key: String, comment: String = "") -> String {
        return NSLocalizedString(key, tableName: "Localizable", bundle: resourceBundle, comment: comment)
    }

    /// 获取带参数的本地化字符串
    public static func string(forKey key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, tableName: "Localizable", bundle: resourceBundle, comment: comment)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - String Extension

extension String {
    /// 快捷本地化方法
    public var localized: String {
        return LocalizationManager.string(forKey: self)
    }

    /// 带参数的本地化
    public func localized(with arguments: CVarArg...) -> String {
        return LocalizationManager.string(forKey: self, arguments: arguments)
    }
}
