import Foundation
import UIKit
import SwiftUI
import Display
import AsyncDisplayKit

@available(iOS 14.0, *)
public final class DiscoverViewController: ViewController {
    private var hostingController: UIHostingController<DiscoverScreenView>?

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

        let hostingController = UIHostingController(rootView: DiscoverScreenView())
        hostingController.view.backgroundColor = .black
        self.hostingController = hostingController

        self.addChild(hostingController)
        self.displayNode.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.hostingController?.view.frame = CGRect(origin: .zero, size: layout.size)

        // 桥接 Display 的安全区域到 SwiftUI，让内容避开状态栏和底部 Tab Bar
        var safeAreaInsets = UIEdgeInsets.zero
        if let statusBarHeight = layout.statusBarHeight {
            safeAreaInsets.top = statusBarHeight
        }
        safeAreaInsets.bottom = layout.intrinsicInsets.bottom
        self.hostingController?.additionalSafeAreaInsets = safeAreaInsets
    }
}
