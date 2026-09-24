import Foundation
import SwiftUI
import TelegramCustomCore

public final class DiscoverViewModel: ObservableObject {
    @Published public var banners: [DiscoverBanner] = []
    @Published public var tools: [DiscoverTool] = []
    @Published public var dApps: [DiscoverDApp] = []

    public init() {
        self.loadMockData()
    }

    private func loadMockData() {
        let banner = DiscoverBanner(
            id: "banner-1",
            tag: "discover.banner.tag".localized,
            title: "discover.banner.title".localized,
            subtitle: "discover.banner.subtitle".localized,
            actionTitle: "discover.banner.action".localized
        )
        self.banners = [banner, banner, banner]

        self.tools = [
            DiscoverTool(
                id: "meeting",
                iconSystemName: "video.fill",
                title: "discover.tool.meeting".localized,
                subtitle: "discover.tool.meeting.desc".localized
            ),
            DiscoverTool(
                id: "vpn",
                iconSystemName: "shield.lefthalf.filled",
                title: "discover.tool.vpn".localized,
                subtitle: "discover.tool.vpn.desc".localized,
                subtitleIsAccent: true
            ),
            DiscoverTool(
                id: "escrow",
                iconSystemName: "checkmark.shield.fill",
                title: "discover.tool.escrow".localized,
                subtitle: "discover.tool.escrow.desc".localized
            )
        ]

        self.dApps = [
            DiscoverDApp(
                id: "uniswap",
                logoText: "UNI",
                logoColorHex: "EC4899",
                title: "Uniswap V3",
                subtitle: "discover.dapp.uniswap.desc".localized,
                actionTitle: "discover.dapp.action".localized
            ),
            DiscoverDApp(
                id: "opensea",
                logoText: "OS",
                logoColorHex: "3B82F6",
                title: "OpenSea NFT Hub",
                subtitle: "discover.dapp.opensea.desc".localized,
                actionTitle: "discover.dapp.action".localized
            )
        ]
    }
}
