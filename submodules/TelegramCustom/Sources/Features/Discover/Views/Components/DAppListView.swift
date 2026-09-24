import SwiftUI
import TelegramCustomCore

struct DAppListView: View {
    let dApps: [DiscoverDApp]
    let onTap: (DiscoverDApp) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(dApps) { dApp in
                Button(action: { onTap(dApp) }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: dApp.logoColorHex).opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: dApp.logoColorHex).opacity(0.3), lineWidth: 1)
                                )
                            Text(dApp.logoText)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(Color(hex: dApp.logoColorHex))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dApp.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text(dApp.subtitle)
                                .font(.system(size: 10))
                                .foregroundColor(ColorPalette.textSub)
                        }
                        Spacer()
                        Text(dApp.actionTitle)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ColorPalette.textSub)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(ColorPalette.surface2)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ColorPalette.borderClr, lineWidth: 1)
                            )
                    }
                    .padding(12)
                    .background(ColorPalette.surface1)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorPalette.borderClr, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
