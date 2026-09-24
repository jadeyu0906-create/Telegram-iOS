import SwiftUI
import TelegramCustomCore

@available(iOS 14.0, *)
public enum DiscoverTab: Int {
    case wallet = 0
    case explore = 1
}

@available(iOS 14.0, *)
public struct DiscoverScreenView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .explore
    @State private var showToast = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            segmentedControl
            if selectedTab == .explore {
                DiscoverExploreView(
                    viewModel: viewModel,
                    onTap: { showToast = true }
                )
            } else {
                DiscoverWalletPlaceholderView()
            }
        }
        .background(ColorPalette.backgroundBlack)
        .overlay(toastOverlay)
    }

    private var segmentedControl: some View {
        HStack {
            HStack(spacing: 0) {
                segmentButton(tab: .wallet, icon: "wallet", title: "discover.tab.wallet".localized)
                segmentButton(tab: .explore, icon: "compass", title: "discover.tab.explore".localized)
            }
            .padding(4)
            .background(ColorPalette.surface2)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorPalette.borderClr, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ColorPalette.backgroundBlack)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.borderClr),
            alignment: .bottom
        )
    }

    private func segmentButton(tab: DiscoverTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(isSelected ? .black : ColorPalette.textSub)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? ColorPalette.brandNeon : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var toastOverlay: some View {
        Group {
            if showToast {
                Text("discover.comingSoon".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorPalette.surface2)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorPalette.brandNeon.opacity(0.4), lineWidth: 1)
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showToast = false
                        }
                    }
            }
        }
    }
}
