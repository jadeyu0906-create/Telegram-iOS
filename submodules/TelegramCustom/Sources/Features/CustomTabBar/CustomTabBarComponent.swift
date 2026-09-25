import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramPresentationData
import TelegramCustomCore

public final class CustomTabBarComponent: Component {
    public typealias EnvironmentType = Empty

    public final class Item: Equatable {
        public let id: AnyHashable
        public let title: String
        public let iconSystemName: String
        public let badge: String?
        public let action: (Bool) -> Void
        public let doubleTapAction: (() -> Void)?
        public let contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?

        public init(
            id: AnyHashable,
            title: String,
            iconSystemName: String,
            badge: String?,
            action: @escaping (Bool) -> Void,
            doubleTapAction: (() -> Void)?,
            contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?
        ) {
            self.id = id
            self.title = title
            self.iconSystemName = iconSystemName
            self.badge = badge
            self.action = action
            self.doubleTapAction = doubleTapAction
            self.contextAction = contextAction
        }

        public static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs === rhs {
                return true
            }
            if lhs.id != rhs.id {
                return false
            }
            if lhs.title != rhs.title {
                return false
            }
            if lhs.iconSystemName != rhs.iconSystemName {
                return false
            }
            if lhs.badge != rhs.badge {
                return false
            }
            if (lhs.doubleTapAction == nil) != (rhs.doubleTapAction == nil) {
                return false
            }
            if (lhs.contextAction == nil) != (rhs.contextAction == nil) {
                return false
            }
            return true
        }
    }

    public let theme: PresentationTheme
    public let strings: PresentationStrings
    public let items: [Item]
    public let selectedId: AnyHashable?
    public let outerInsets: UIEdgeInsets

    public init(
        theme: PresentationTheme,
        strings: PresentationStrings,
        items: [Item],
        selectedId: AnyHashable?,
        outerInsets: UIEdgeInsets
    ) {
        self.theme = theme
        self.strings = strings
        self.items = items
        self.selectedId = selectedId
        self.outerInsets = outerInsets
    }

    public static func ==(lhs: CustomTabBarComponent, rhs: CustomTabBarComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.selectedId != rhs.selectedId {
            return false
        }
        if lhs.outerInsets != rhs.outerInsets {
            return false
        }
        return true
    }

    public func makeView() -> View {
        return View(frame: CGRect())
    }

    public func makeState() -> EmptyComponentState {
        return EmptyComponentState()
    }

    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }

    public final class View: UIView {
    private let backgroundView: UIView
    private let separatorView: UIView
    private var itemViews: [AnyHashable: CustomTabBarItemView] = [:]

    private var component: CustomTabBarComponent?

    override init(frame: CGRect) {
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = .black

        self.separatorView = UIView()
        self.separatorView.backgroundColor = ColorPalette.borderClrUI

        super.init(frame: frame)

        self.addSubview(self.backgroundView)
        self.addSubview(self.separatorView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 只响应内容区（y < 49pt），底部安全区域（Home Indicator）不拦截触摸
        return point.y >= 0.0 && point.y < 49.0
    }

    func update(component: CustomTabBarComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        self.component = component

        // 计算 Tab Bar 高度（含底部安全区域，覆盖到屏幕底部）
        let itemHeight: CGFloat = 49.0
        let totalHeight = itemHeight + component.outerInsets.bottom

        // 更新背景（覆盖到屏幕底部，含安全区域）
        let backgroundFrame = CGRect(origin: .zero, size: CGSize(width: availableSize.width, height: totalHeight))
        transition.setFrame(view: self.backgroundView, frame: backgroundFrame)

        // 顶部分割线（1pt，颜色 #292929）
        let separatorFrame = CGRect(origin: .zero, size: CGSize(width: availableSize.width, height: 1.0))
        transition.setFrame(view: self.separatorView, frame: separatorFrame)

        // 计算每个 item 的宽度（首尾各缩进半个图标宽度 14pt，中间 4 个 tab 等距）
        let sideInset: CGFloat = 14.0
        let contentWidth = availableSize.width - sideInset * 2.0
        let itemWidth = contentWidth / CGFloat(component.items.count)

        // 更新或创建 item views
        var validIds = Set<AnyHashable>()

        for (index, item) in component.items.enumerated() {
            validIds.insert(item.id)

            let itemView: CustomTabBarItemView
            if let existing = self.itemViews[item.id] {
                itemView = existing
            } else {
                itemView = CustomTabBarItemView()
                self.itemViews[item.id] = itemView
                self.addSubview(itemView)

                // 添加点击手势
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                itemView.addGestureRecognizer(tapGesture)
                itemView.isUserInteractionEnabled = true
                itemView.tag = index
            }

            // 更新 item 内容
            let icon = UIImage(
                systemName: item.iconSystemName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
            )?.withRenderingMode(.alwaysTemplate)

            itemView.icon = icon
            itemView.title = item.title
            itemView.badgeText = item.badge
            itemView.isSelected = (item.id == component.selectedId)

            // 布局 item
            let itemFrame = CGRect(
                x: sideInset + CGFloat(index) * itemWidth,
                y: 0,
                width: itemWidth,
                height: itemHeight
            )
            transition.setFrame(view: itemView, frame: itemFrame)
        }

        // 移除不再需要的 views
        var toRemove: [AnyHashable] = []
        for (id, view) in self.itemViews {
            if !validIds.contains(id) {
                view.removeFromSuperview()
                toRemove.append(id)
            }
        }
        for id in toRemove {
            self.itemViews.removeValue(forKey: id)
        }

        return CGSize(width: availableSize.width, height: totalHeight)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view as? CustomTabBarItemView,
              let component = self.component,
              itemView.tag < component.items.count else {
            return
        }

        let item = component.items[itemView.tag]

        // 触发回调（变色由 isSelected 处理，无缩放动画）
        item.action(false)
    }
    }
}
