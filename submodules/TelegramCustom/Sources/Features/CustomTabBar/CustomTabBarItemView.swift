import Foundation
import UIKit
import Display
import TelegramCustomCore

final class CustomTabBarItemView: UIView {
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let badgeView: CustomTabBarBadgeView

    private var isSelectedState: Bool = false

    var icon: UIImage? {
        didSet {
            self.iconImageView.image = icon
        }
    }

    var title: String? {
        didSet {
            self.titleLabel.text = title
            self.setNeedsLayout()
        }
    }

    var badgeText: String? {
        didSet {
            self.badgeView.badgeText = badgeText
            self.setNeedsLayout()
        }
    }

    var isSelected: Bool {
        get {
            return self.isSelectedState
        }
        set {
            if self.isSelectedState != newValue {
                self.isSelectedState = newValue
                self.updateAppearance(animated: true)
            }
        }
    }

    override init(frame: CGRect) {
        self.iconImageView = UIImageView()
        self.iconImageView.contentMode = .scaleAspectFit

        self.titleLabel = UILabel()
        self.titleLabel.textAlignment = .center
        self.titleLabel.numberOfLines = 1

        self.badgeView = CustomTabBarBadgeView()

        super.init(frame: frame)

        self.addSubview(self.iconImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.badgeView)

        self.updateAppearance(animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance(animated: Bool) {
        let duration: TimeInterval = animated ? 0.15 : 0

        UIView.animate(withDuration: duration) {
            if self.isSelectedState {
                // 选中状态：荧光绿
                self.iconImageView.tintColor = ColorPalette.brandNeonUI
                self.titleLabel.textColor = ColorPalette.brandNeonUI
                self.titleLabel.font = .systemFont(ofSize: 10, weight: .bold)
            } else {
                // 未选中状态：灰色
                self.iconImageView.tintColor = UIColor.white.withAlphaComponent(0.6)
                self.titleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
                self.titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds
        let iconSize: CGFloat = 28.0
        let spacing: CGFloat = 4.0

        // 图标居中，距离顶部一定距离
        let iconY: CGFloat = 3.0
        let iconFrame = CGRect(
            x: (bounds.width - iconSize) / 2.0,
            y: iconY,
            width: iconSize,
            height: iconSize
        )
        self.iconImageView.frame = iconFrame

        // 文字在图标下方
        let titleY = iconFrame.maxY + spacing
        let titleHeight: CGFloat = 12.0
        let titleFrame = CGRect(
            x: 0,
            y: titleY,
            width: bounds.width,
            height: titleHeight
        )
        self.titleLabel.frame = titleFrame

        // 徽章在图标右上角
        if !self.badgeView.isHidden {
            let badgeSize = self.badgeView.sizeThatFits(bounds.size)
            let badgeFrame = CGRect(
                x: iconFrame.maxX - 4.0,
                y: iconFrame.minY - 4.0,
                width: badgeSize.width,
                height: badgeSize.height
            )
            self.badgeView.frame = badgeFrame
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let iconSize: CGFloat = 28.0
        let spacing: CGFloat = 4.0
        let titleHeight: CGFloat = 12.0
        let topPadding: CGFloat = 3.0
        let bottomPadding: CGFloat = 3.0

        let totalHeight = topPadding + iconSize + spacing + titleHeight + bottomPadding

        return CGSize(width: size.width, height: totalHeight)
    }
}
