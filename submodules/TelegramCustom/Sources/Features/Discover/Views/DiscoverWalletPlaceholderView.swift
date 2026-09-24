import SwiftUI
import TelegramCustomCore

struct DiscoverWalletPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet")
                .font(.system(size: 64))
                .foregroundColor(ColorPalette.brandNeon)
            Text("discover.comingSoon".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.backgroundBlack)
    }
}
