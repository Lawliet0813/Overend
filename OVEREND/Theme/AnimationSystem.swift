//
//  AnimationSystem.swift
//  OVEREND
//
//  動畫系統 - 統一定義所有動畫標準和過渡效果
//

import SwiftUI
import Combine

/// 動畫系統
/// 提供統一的動畫時長、緩動函數、過渡動畫標準
struct AnimationSystem {

    // MARK: - 動畫時長

    /// 動畫時長標準
    enum Duration {
        /// 即時反饋 - 100ms
        /// 用於：按鈕按壓反饋
        static let instant: Double = 0.1

        /// 快速過渡 - 200ms
        /// 用於：懸停效果、簡單過渡
        static let fast: Double = 0.2

        /// 標準動畫 - 300ms
        /// 用於：大多數 UI 動畫
        static let normal: Double = 0.3

        /// 慢速強調 - 500ms
        /// 用於：強調動畫、複雜過渡
        static let slow: Double = 0.5
    }

    // MARK: - 緩動函數

    /// 緩動函數標準
    enum Easing {
        /// 標準緩動 - easeInOut
        /// 用於：一般 UI 過渡
        static let standard = Animation.easeInOut(duration: Duration.normal)

        /// 快速緩動 - easeInOut
        /// 用於：懸停效果、快速反饋
        static let quick = Animation.easeInOut(duration: Duration.fast)

        /// 彈性動畫 - spring
        /// 用於：重要操作、強調效果
        static let spring = Animation.spring(
            response: 0.3,
            dampingFraction: 0.7,
            blendDuration: 0
        )

        /// 柔和彈性 - spring
        /// 用於：優雅的過渡、淡入淡出
        static let softSpring = Animation.spring(
            response: 0.4,
            dampingFraction: 0.8,
            blendDuration: 0
        )

        /// 強調彈性 - spring
        /// 用於：重要操作回饋、成功提示
        static let emphasizedSpring = Animation.spring(
            response: 0.5,
            dampingFraction: 0.6,
            blendDuration: 0
        )

        /// 即時反饋 - linear
        /// 用於：按壓效果
        static let instant = Animation.linear(duration: Duration.instant)
    }

    // MARK: - 常用過渡動畫

    /// 預定義過渡動畫
    enum Transition {
        /// 淡入淡出
        /// 用於：一般元素顯示/隱藏
        static let fade: AnyTransition = .opacity

        /// 滑入（從右側）
        /// 用於：側邊面板、詳情頁
        static let slideIn: AnyTransition = .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )

        /// 滑入（從左側）
        /// 用於：返回動畫
        static let slideInLeading: AnyTransition = .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )

        /// 滑入（從上方）
        /// 用於：下拉刷新、通知
        static let slideInTop: AnyTransition = .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )

        /// 滑入（從下方）
        /// 用於：Sheet、底部面板
        static let slideInBottom: AnyTransition = .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )

        /// 彈出（縮放+淡入）
        /// 用於：對話框、Modal
        static let popup: AnyTransition = .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )

        /// 消失（縮放+淡出）
        /// 用於：刪除動畫
        static let dismiss: AnyTransition = .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )

        /// 展開（高度變化）
        /// 用於：摺疊面板
        static let expand: AnyTransition = .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    // MARK: - 列表動畫

    /// 計算交錯動畫延遲
    /// - Parameters:
    ///   - index: 元素索引
    ///   - baseDelay: 基礎延遲（預設 0.05 秒）
    /// - Returns: 計算後的延遲時間
    static func staggerDelay(index: Int, baseDelay: Double = 0.05) -> Double {
        return Double(index) * baseDelay
    }

    /// 列表項最大交錯動畫數量
    /// 避免列表過長時動畫延遲過久
    static let maxStaggeredItems: Int = 20
    
    // MARK: - P2 擴充動畫
    
    /// 面板動畫
    enum Panel {
        /// 面板滑入
        static let slideIn: Animation = .spring(response: 0.3, dampingFraction: 0.85)
        
        /// 面板滑出
        static let slideOut: Animation = .easeIn(duration: 0.2)
        
        /// 面板淡入
        static let fadeIn: Animation = .easeIn(duration: 0.15)
        
        /// 面板淡出
        static let fadeOut: Animation = .easeOut(duration: 0.12)
    }
    
    /// 按鈕動畫
    enum Button {
        /// 按鈕點擊
        static let press: Animation = .easeInOut(duration: 0.1)
        
        /// 按鈕懸停
        static let hover: Animation = .easeOut(duration: 0.12)
        
        /// 按鈕縮放值
        static let pressScale: CGFloat = 0.95
        
        /// 按鈕懸停縮放值
        static let hoverScale: CGFloat = 1.02
    }
    
    /// 卡片動畫
    enum Card {
        /// 卡片懸停浮起
        static let lift: Animation = .spring(response: 0.2, dampingFraction: 0.8)
        
        /// 卡片選取
        static let select: Animation = .easeOut(duration: 0.15)
        
        /// 卡片出現
        static let appear: Animation = .spring(response: 0.4, dampingFraction: 0.7)
    }
    
    /// 內容動畫
    enum Content {
        /// 內容載入
        static let load: Animation = .easeOut(duration: 0.3)
        
        /// 內容刷新
        static let refresh: Animation = .easeInOut(duration: 0.25)
        
        /// 列表項目出現（staggered）
        static func staggered(index: Int) -> Animation {
            .spring(response: 0.35, dampingFraction: 0.8)
            .delay(Double(index) * 0.05)
        }
    }
    
    /// Modal 動畫
    enum Modal {
        /// Modal 彈出
        static let present: Animation = .spring(response: 0.35, dampingFraction: 0.85)
        
        /// Modal 關閉
        static let dismiss: Animation = .easeIn(duration: 0.2)
        
        /// 背景淡入
        static let backdropFade: Animation = .easeOut(duration: 0.2)
    }
    
    /// Toast 動畫
    enum Toast {
        /// Toast 滑入
        static let slideIn: Animation = .spring(response: 0.3, dampingFraction: 0.7)
        
        /// Toast 滑出
        static let slideOut: Animation = .easeIn(duration: 0.15)
    }
    
    /// 載入動畫
    enum Loading {
        /// 脈動動畫
        static let pulse: Animation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        
        /// 旋轉動畫
        static let spin: Animation = .linear(duration: 1.0).repeatForever(autoreverses: false)
        
        /// 骨架屏閃爍
        static let shimmer: Animation = .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
    }
}

// MARK: - View 擴展

extension View {
    /// 應用標準懸停縮放效果
    /// - Parameter isHovered: 是否懸停
    func hoverScale(isHovered: Bool) -> some View {
        self.scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(AnimationSystem.Easing.quick, value: isHovered)
    }

    /// 應用標準按壓縮放效果
    /// - Parameter isPressed: 是否按壓
    func pressScale(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AnimationSystem.Easing.instant, value: isPressed)
    }

    /// 應用懸停與按壓組合效果
    /// - Parameters:
    ///   - isHovered: 是否懸停
    ///   - isPressed: 是否按壓
    func interactiveScale(isHovered: Bool, isPressed: Bool) -> some View {
        let scale: CGFloat = isPressed ? 0.96 : (isHovered ? 1.02 : 1.0)
        return self.scaleEffect(scale)
            .animation(AnimationSystem.Easing.quick, value: isHovered)
            .animation(AnimationSystem.Easing.instant, value: isPressed)
    }

    /// 應用漸進式顯示（交錯動畫）
    /// - Parameter index: 元素索引
    func staggeredAppearance(index: Int) -> some View {
        let limitedIndex = min(index, AnimationSystem.maxStaggeredItems - 1)
        return self
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(
                AnimationSystem.Easing.spring.delay(
                    AnimationSystem.staggerDelay(index: limitedIndex)
                ),
                value: true
            )
    }

    /// 應用淡入動畫
    /// - Parameter delay: 延遲時間（秒）
    func fadeIn(delay: Double = 0) -> some View {
        self.transition(.opacity)
            .animation(
                AnimationSystem.Easing.standard.delay(delay),
                value: true
            )
    }

    /// 應用彈跳效果
    /// - Parameter trigger: 觸發值
    func bounce<V: Equatable>(trigger: V) -> some View {
        self.animation(AnimationSystem.Easing.spring, value: trigger)
    }

    /// 應用呼吸效果（脈衝動畫）
    /// - Parameter isAnimating: 是否正在動畫
    func breathingEffect(isAnimating: Bool) -> some View {
        self.scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }

    /// 應用抖動效果（錯誤提示）
    /// - Parameter trigger: 觸發值
    func shake<V: Hashable>(trigger: V) -> some View {
        self.modifier(ShakeEffect(animatableData: trigger.hashValue))
    }
}

// MARK: - 抖動效果修飾器

/// 抖動效果（用於錯誤提示）
struct ShakeEffect: GeometryEffect {
    var animatableData: Int

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(CGFloat(animatableData) * .pi * 2) * 5
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - 可訪問性支援

/// 動畫可訪問性管理器
@MainActor
class AnimationAccessibility: ObservableObject {
    /// 是否減少動態效果（遵循系統設定）
    @Published var reduceMotion: Bool = false

    init() {
        // 監聽系統「減少動態效果」設定
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// 根據可訪問性設定返回動畫
    /// - Parameter animation: 原始動畫
    /// - Returns: 考慮可訪問性後的動畫
    func animation(_ animation: Animation) -> Animation? {
        return reduceMotion ? nil : animation
    }
}

// MARK: - 使用範例

/*

 使用範例：

 // 1. 使用標準緩動
 Text("Hello")
    .animation(AnimationSystem.Easing.standard, value: isVisible)

 // 2. 懸停效果
 .hoverScale(isHovered: isHovered)

 // 3. 按壓效果
 .pressScale(isPressed: isPressed)

 // 4. 交錯動畫
 ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
     ItemView(item: item)
         .staggeredAppearance(index: index)
 }

 // 5. 過渡動畫
 if showDetail {
     DetailView()
         .transition(AnimationSystem.Transition.slideIn)
         .animation(AnimationSystem.Easing.spring, value: showDetail)
 }

 // 6. 可訪問性支援
 @StateObject private var animationAccessibility = AnimationAccessibility()

 .animation(animationAccessibility.animation(.spring()), value: someValue)

 */
