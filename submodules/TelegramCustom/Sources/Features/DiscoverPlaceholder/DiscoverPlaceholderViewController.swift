import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCustomCore

public final class DiscoverPlaceholderViewController: ViewController {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    public override init(navigationBarPresentationData: NavigationBarPresentationData?) {
        super.init(navigationBarPresentationData: navigationBarPresentationData)
        self.statusBar.statusBarStyle = .White
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = .black
        self.displayNodeDidLoad()
    }

    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()

        // 图标
        self.iconImageView.contentMode = .scaleAspectFit
        if let icon = UIImage(
            systemName: "safari",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        )?.withRenderingMode(.alwaysTemplate) {
            self.iconImageView.image = icon
            self.iconImageView.tintColor = UIColor(red: 207.0 / 255.0, green: 255.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
        }

        // 标题
        self.titleLabel.text = "discover.placeholder.title".localized
        self.titleLabel.textColor = .white
        self.titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        self.titleLabel.textAlignment = .center

        // 副标题
        self.subtitleLabel.text = "discover.placeholder.subtitle".localized
        self.subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        self.subtitleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.numberOfLines = 0

        self.displayNode.view.addSubview(self.iconImageView)
        self.displayNode.view.addSubview(self.titleLabel)
        self.displayNode.view.addSubview(self.subtitleLabel)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        let bounds = CGRect(origin: .zero, size: layout.size)

        let iconSize: CGFloat = 80.0
        let spacing: CGFloat = 20.0

        let titleSize = self.titleLabel.sizeThatFits(CGSize(width: bounds.width - 80.0, height: 100.0))
        let subtitleSize = self.subtitleLabel.sizeThatFits(CGSize(width: bounds.width - 80.0, height: 100.0))

        let totalHeight = iconSize + spacing + titleSize.height + 12.0 + subtitleSize.height
        let startY = (bounds.height - totalHeight) / 2.0

        let iconFrame = CGRect(
            x: (bounds.width - iconSize) / 2.0,
            y: startY,
            width: iconSize,
            height: iconSize
        )

        let titleFrame = CGRect(
            x: 40.0,
            y: iconFrame.maxY + spacing,
            width: bounds.width - 80.0,
            height: titleSize.height
        )

        let subtitleFrame = CGRect(
            x: 40.0,
            y: titleFrame.maxY + 12.0,
            width: bounds.width - 80.0,
            height: subtitleSize.height
        )

        transition.updateFrame(view: self.iconImageView, frame: iconFrame)
        transition.updateFrame(view: self.titleLabel, frame: titleFrame)
        transition.updateFrame(view: self.subtitleLabel, frame: subtitleFrame)
    }
}
