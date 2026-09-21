import Foundation

/// 多语言管理器 - 统一管理本地化字符串
public enum LocalizationManager {
    /// 获取本地化字符串
    public static func string(forKey key: String, comment: String = "") -> String {
        // Bazel 构建时，资源在主 Bundle 里
        return NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.main, comment: comment)
    }

    /// 获取带参数的本地化字符串
    public static func string(forKey key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.main, comment: comment)
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
