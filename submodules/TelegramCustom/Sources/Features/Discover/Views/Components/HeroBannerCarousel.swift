import SwiftUI
import TelegramCustomCore

@available(iOS 14.0, *)
struct HeroBannerCarousel: View {
    let banners: [DiscoverBanner]
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentIndex) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    bannerCard(banner)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 144)

            HStack(spacing: 4) {
                ForEach(0..<banners.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? ColorPalette.brandNeon : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % banners.count
            }
        }
    }

    private func bannerCard(_ banner: DiscoverBanner) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(banner.tag)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ColorPalette.brandNeon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(ColorPalette.brandNeon.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(ColorPalette.brandNeon.opacity(0.4), lineWidth: 1)
                    )
                Spacer()
            }
            Spacer()
            Text(banner.title)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
            Text(banner.subtitle)
                .font(.system(size: 12))
                .foregroundColor(ColorPalette.textSub)
            Spacer()
            HStack {
                Text(banner.actionTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorPalette.brandNeon)
                    .cornerRadius(12)
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "022C22"),
                    ColorPalette.surface2,
                    ColorPalette.backgroundBlack
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorPalette.brandNeon.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
