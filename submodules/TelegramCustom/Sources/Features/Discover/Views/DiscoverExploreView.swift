import SwiftUI
import TelegramCustomCore

@available(iOS 14.0, *)
struct DiscoverExploreView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    let onTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroBannerCarousel(banners: viewModel.banners)

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("discover.tools.section".localized)
                    ToolGridView(tools: viewModel.tools) { _ in onTap() }
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("discover.dapp.section".localized)
                    DAppListView(dApps: viewModel.dApps) { _ in onTap() }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(ColorPalette.backgroundBlack)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(ColorPalette.textSub)
            .kerning(1.0)
    }
}
