import Foundation
import UIKit
import Display

final class CustomTabBarBadgeView: UIView {
    private let backgroundView: UIView
    private let textLabel: UILabel

    var badgeText: String? {
        didSet {
            updateContent()
        }
    }

    override init(frame: CGRect) {
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = UIColor(rgb: 0xEF4444)
        self.backgroundView.layer.cornerRadius = 8.0

        self.textLabel = UILabel()
        self.textLabel.font = .systemFont(ofSize: 9, weight: .bold)
        self.textLabel.textColor = .white
        self.textLabel.textAlignment = .center

        super.init(frame: frame)

        self.addSubview(self.backgroundView)
        self.addSubview(self.textLabel)

        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateContent() {
        guard let text = badgeText, !text.isEmpty else {
            self.isHidden = true
            return
        }

        self.isHidden = false

        // 超过 99 显示 "99+"
        let displayText: String
        if let number = Int(text), number > 99 {
            displayText = "99+"
        } else {
            displayText = text
        }

        self.textLabel.text = displayText
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let text = self.textLabel.text, !text.isEmpty else {
            return
        }

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 100, height: 16),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.textLabel.font!],
            context: nil
        ).size

        // 最小宽度 16pt，如果文字更宽则自适应
        let minWidth: CGFloat = 16.0
        let width = max(minWidth, ceil(textSize.width) + 8.0)
        let height: CGFloat = 16.0

        let badgeSize = CGSize(width: width, height: height)
        self.bounds = CGRect(origin: .zero, size: badgeSize)

        self.backgroundView.frame = self.bounds
        self.backgroundView.layer.cornerRadius = height / 2.0

        self.textLabel.frame = self.bounds
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = self.textLabel.text, !text.isEmpty else {
            return .zero
        }

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 100, height: 16),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.textLabel.font!],
            context: nil
        ).size

        let minWidth: CGFloat = 16.0
        let width = max(minWidth, ceil(textSize.width) + 8.0)
        let height: CGFloat = 16.0

        return CGSize(width: width, height: height)
    }
}
