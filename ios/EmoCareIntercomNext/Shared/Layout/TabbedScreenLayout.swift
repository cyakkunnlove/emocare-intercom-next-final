import SwiftUI

// MARK: - TabbedScreenLayout
// 全タブ画面（Channels / CallHistory / Settings）で共通のレイアウト定数。
// タブバー高さを動的に計算し、ハードコードされた固定値を排除する。
enum TabbedScreenLayout {
    static let tabBarBaseHeight: CGFloat = 49
    static let bottomContentSpacing: CGFloat = 12
    static let floatingButtonSize: CGFloat = 56
    static let floatingButtonTrailingInset: CGFloat = 20
    static let floatingButtonBottomSpacing: CGFloat = 16
    static let headerHorizontalPadding: CGFloat = 16
    static let headerTopPadding: CGFloat = 8
    static let headerBottomPadding: CGFloat = 8
    static let sectionTopSpacing: CGFloat = 8

    /// safeAreaBottom を考慮した実際のタブバー高さを返す
    static func resolvedTabBarHeight(safeAreaBottom: CGFloat) -> CGFloat {
        safeAreaBottom >= tabBarBaseHeight ? safeAreaBottom : safeAreaBottom + tabBarBaseHeight
    }

    /// リストコンテンツの下部インセット（タブバー + 余白）
    static func contentBottomInset(safeAreaBottom: CGFloat) -> CGFloat {
        resolvedTabBarHeight(safeAreaBottom: safeAreaBottom) + bottomContentSpacing
    }

    /// フローティングボタンの下部インセット
    static func floatingButtonBottomInset(safeAreaBottom: CGFloat) -> CGFloat {
        resolvedTabBarHeight(safeAreaBottom: safeAreaBottom) + floatingButtonBottomSpacing
    }

    /// フローティングボタンが占める高さ（リスト末尾のクリアランス用）
    static var floatingButtonListClearance: CGFloat {
        floatingButtonSize + floatingButtonBottomSpacing
    }
}
