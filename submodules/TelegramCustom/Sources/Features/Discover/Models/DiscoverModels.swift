import Foundation

/// Banner 轮播项
public struct DiscoverBanner: Identifiable, Codable {
    public let id: String
    public let tag: String
    public let title: String
    public let subtitle: String
    public let actionTitle: String

    public init(id: String, tag: String, title: String, subtitle: String, actionTitle: String) {
        self.id = id
        self.tag = tag
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
    }
}

/// 核心工具
public struct DiscoverTool: Identifiable, Codable {
    public let id: String
    public let iconSystemName: String
    public let title: String
    public let subtitle: String
    public let subtitleIsAccent: Bool

    public init(id: String, iconSystemName: String, title: String, subtitle: String, subtitleIsAccent: Bool = false) {
        self.id = id
        self.iconSystemName = iconSystemName
        self.title = title
        self.subtitle = subtitle
        self.subtitleIsAccent = subtitleIsAccent
    }
}

/// DApp
public struct DiscoverDApp: Identifiable, Codable {
    public let id: String
    public let logoText: String
    public let logoColorHex: String
    public let title: String
    public let subtitle: String
    public let actionTitle: String

    public init(id: String, logoText: String, logoColorHex: String, title: String, subtitle: String, actionTitle: String) {
        self.id = id
        self.logoText = logoText
        self.logoColorHex = logoColorHex
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
    }
}
