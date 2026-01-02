//
//  PhysicalCanvasView.swift
//  OVEREND
//
//  物理 A4 畫布視圖 - 確保螢幕顯示與 PDF 輸出完全一致
//

import SwiftUI
import AppKit

/// 座標轉換工具 - 處理螢幕顯示與物理尺寸的轉換
struct CoordinateConverter {
    /// 當前螢幕的 DPI (每英寸點數)
    static var screenDPI: CGFloat {
        if let screen = NSScreen.main {
            let description = screen.deviceDescription
            if let resolution = description[.resolution] as? NSSize {
                return resolution.height
            }
        }
        return 72.0 // 預設 72 DPI
    }

    /// 縮放比例 - 用於在螢幕上以合適的大小顯示 A4 頁面
    var displayScale: CGFloat

    init(displayScale: CGFloat = 1.0) {
        self.displayScale = displayScale
    }

    /// 將物理尺寸（Points）轉換為螢幕顯示尺寸
    func toDisplaySize(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width * displayScale,
            height: size.height * displayScale
        )
    }

    /// 將螢幕顯示座標轉換回物理座標
    func toPhysicalPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x / displayScale,
            y: point.y / displayScale
        )
    }

    /// 將物理座標轉換為螢幕顯示座標
    func toDisplayPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x * displayScale,
            y: point.y * displayScale
        )
    }

    /// 計算適合視窗的縮放比例
    static func calculateFitScale(pageSize: CGSize, viewportSize: CGSize, padding: CGFloat = 40) -> CGFloat {
        let availableWidth = viewportSize.width - padding * 2
        let availableHeight = viewportSize.height - padding * 2

        let widthScale = availableWidth / pageSize.width
        let heightScale = availableHeight / pageSize.height

        return min(widthScale, heightScale, 1.5) // 最大不超過 150%
    }
}

/// 物理畫布視圖 - 包含標尺、邊距導引線與編輯區域
struct PhysicalCanvasView: View {
    @ObservedObject var page: PageModel
    @Binding var attributedString: NSAttributedString
    @State private var displayScale: CGFloat = 1.0
    @State private var viewportSize: CGSize = .zero

    var onTextChange: ((NSAttributedString) -> Void)?

    // MARK: - 計算屬性

    private var converter: CoordinateConverter {
        CoordinateConverter(displayScale: displayScale)
    }

    private var pageSize: CGSize {
        A4PageSize.sizeInPoints
    }

    private var displayPageSize: CGSize {
        converter.toDisplaySize(pageSize)
    }

    private var displayContentOrigin: CGPoint {
        converter.toDisplayPoint(page.contentOrigin)
    }

    private var displayContentSize: CGSize {
        converter.toDisplaySize(page.contentSize)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.windowBackgroundColor)

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // 頁面背景（白色紙張）
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: displayPageSize.width, height: displayPageSize.height)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                        // 邊距導引線
                        if page.showMarginGuides {
                            marginGuidesView
                        }

                        // 標尺
                        if page.showRulers {
                            rulersView
                        }

                        // 頁首
                        if let headerText = page.headerText {
                            headerView(text: headerText)
                        }

                        // 主要內容區域
                        PhysicalTextEditorView(
                            attributedString: $attributedString,
                            page: page,
                            displayScale: displayScale,
                            onTextChange: onTextChange
                        )
                        .frame(width: displayContentSize.width, height: displayContentSize.height)
                        .position(
                            x: displayContentOrigin.x + displayContentSize.width / 2,
                            y: displayContentOrigin.y + displayContentSize.height / 2
                        )

                        // 頁尾與頁碼
                        footerView
                    }
                    .frame(width: displayPageSize.width, height: displayPageSize.height)
                    .padding(40) // 頁面周圍留白
                }
            }
            .onAppear {
                updateScale(for: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                updateScale(for: newSize)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                scaleControls
            }
        }
    }

    // MARK: - 子視圖

    /// 邊距導引線
    private var marginGuidesView: some View {
        let margins = page.margins

        return ZStack {
            // 上邊距線
            Rectangle()
                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .frame(width: displayPageSize.width, height: 1)
                .position(x: displayPageSize.width / 2, y: converter.toDisplayPoint(CGPoint(x: 0, y: margins.top.toPoints)).y)

            // 下邊距線
            Rectangle()
                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .frame(width: displayPageSize.width, height: 1)
                .position(
                    x: displayPageSize.width / 2,
                    y: displayPageSize.height - converter.toDisplayPoint(CGPoint(x: 0, y: margins.bottom.toPoints)).y
                )

            // 左邊距線
            Rectangle()
                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .frame(width: 1, height: displayPageSize.height)
                .position(x: converter.toDisplayPoint(CGPoint(x: margins.left.toPoints, y: 0)).x, y: displayPageSize.height / 2)

            // 右邊距線
            Rectangle()
                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .frame(width: 1, height: displayPageSize.height)
                .position(
                    x: displayPageSize.width - converter.toDisplayPoint(CGPoint(x: margins.right.toPoints, y: 0)).x,
                    y: displayPageSize.height / 2
                )
        }
    }

    /// 標尺視圖
    private var rulersView: some View {
        ZStack(alignment: .topLeading) {
            // 水平標尺（頂部）
            HorizontalRulerView(
                width: displayPageSize.width,
                scale: displayScale,
                unit: .centimeter
            )
            .frame(height: 20)
            .position(x: displayPageSize.width / 2, y: 10)

            // 垂直標尺（左側）
            VerticalRulerView(
                height: displayPageSize.height,
                scale: displayScale,
                unit: .centimeter
            )
            .frame(width: 20)
            .position(x: 10, y: displayPageSize.height / 2)
        }
    }

    /// 頁首視圖
    private func headerView(text: String) -> some View {
        Text(text)
            .font(.system(size: 10 * displayScale))
            .foregroundColor(.secondary)
            .frame(width: displayContentSize.width, alignment: .leading)
            .position(
                x: displayContentOrigin.x + displayContentSize.width / 2,
                y: displayContentOrigin.y - 10 * displayScale
            )
    }

    /// 頁尾與頁碼視圖
    private var footerView: some View {
        HStack {
            if let footerText = page.footerText {
                Text(footerText)
                    .font(.system(size: 10 * displayScale))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if page.pageNumberStyle != .none {
                Text(page.formattedPageNumber)
                    .font(.system(size: 10 * displayScale))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: displayContentSize.width)
        .position(
            x: displayContentOrigin.x + displayContentSize.width / 2,
            y: displayPageSize.height - displayContentOrigin.y + 10 * displayScale
        )
    }

    /// 縮放控制按鈕
    private var scaleControls: some View {
        HStack(spacing: 8) {
            Button(action: { displayScale = max(0.5, displayScale - 0.1) }) {
                Image(systemName: "minus.magnifyingglass")
            }

            Text("\(Int(displayScale * 100))%")
                .frame(minWidth: 50)
                .font(.system(size: 12, weight: .medium))

            Button(action: { displayScale = min(2.0, displayScale + 0.1) }) {
                Image(systemName: "plus.magnifyingglass")
            }

            Button(action: { updateScale(for: viewportSize) }) {
                Text("適合頁面")
                    .font(.system(size: 12))
            }
        }
    }

    // MARK: - 輔助方法

    private func updateScale(for size: CGSize) {
        viewportSize = size
        displayScale = CoordinateConverter.calculateFitScale(
            pageSize: pageSize,
            viewportSize: size
        )
    }
}

// MARK: - 預覽

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var page = PageModel.preview
        @State private var text = NSAttributedString(string: "這是測試內容\n\n第一段落。\n\n第二段落。")

        var body: some View {
            PhysicalCanvasView(page: page, attributedString: $text)
                .frame(width: 900, height: 700)
        }
    }

    return PreviewWrapper()
}
