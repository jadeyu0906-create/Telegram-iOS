import SwiftUI
import TelegramCustomCore

@available(iOS 14.0, *)
struct ToolGridView: View {
    let tools: [DiscoverTool]
    let onTap: (DiscoverTool) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(tools) { tool in
                Button(action: { onTap(tool) }) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorPalette.surface2)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ColorPalette.borderClr, lineWidth: 1)
                                )
                            Image(systemName: tool.iconSystemName)
                                .font(.system(size: 18))
                                .foregroundColor(ColorPalette.brandNeon)
                        }
                        Text(tool.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text(tool.subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(tool.subtitleIsAccent ? ColorPalette.brandNeon : ColorPalette.txtMuted)
                    }
                    .frame(maxWidth: .infinity)
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
