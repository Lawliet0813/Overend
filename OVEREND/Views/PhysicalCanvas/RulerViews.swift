//
//  RulerViews.swift
//  OVEREND
//
//  標尺視圖 - 顯示物理尺寸刻度
//

import SwiftUI

/// 標尺單位
enum RulerUnit {
    case millimeter
    case centimeter
    case inch

    var tickInterval: Double {
        switch self {
        case .millimeter: return 1.0
        case .centimeter: return 1.0
        case .inch: return 0.125 // 1/8 英寸
        }
    }

    var majorTickInterval: Double {
        switch self {
        case .millimeter: return 10.0
        case .centimeter: return 1.0
        case .inch: return 1.0
        }
    }

    var label: String {
        switch self {
        case .millimeter: return "mm"
        case .centimeter: return "cm"
        case .inch: return "in"
        }
    }

    func toPoints(_ value: Double) -> CGFloat {
        switch self {
        case .millimeter:
            return UnitLength.millimeter(value).toPoints
        case .centimeter:
            return UnitLength.centimeter(value).toPoints
        case .inch:
            return UnitLength.inch(value).toPoints
        }
    }
}

/// 水平標尺視圖
struct HorizontalRulerView: View {
    let width: CGFloat
    let scale: CGFloat
    let unit: RulerUnit

    var body: some View {
        Canvas { context, size in
            drawRuler(context: context, size: size, isHorizontal: true)
        }
        .frame(width: width, height: 20)
        .background(Color(.controlBackgroundColor).opacity(0.9))
    }

    private func drawRuler(context: GraphicsContext, size: CGSize, isHorizontal: Bool) {
        let physicalLength = size.width / scale

        // 根據單位計算刻度數量
        var position = 0.0
        var tickNumber = 0

        while position * scale < size.width {
            let x = position * scale

            // 判斷刻度類型
            let isMajorTick = tickNumber % Int(unit.majorTickInterval / unit.tickInterval) == 0
            let tickHeight: CGFloat = isMajorTick ? 12 : 6

            // 繪製刻度線
            let startPoint = CGPoint(x: x, y: size.height - tickHeight)
            let endPoint = CGPoint(x: x, y: size.height)

            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)

            context.stroke(
                path,
                with: .color(.secondary),
                lineWidth: isMajorTick ? 1.0 : 0.5
            )

            // 繪製數字標籤（僅主刻度）
            if isMajorTick && tickNumber > 0 {
                let labelValue = position / unit.majorTickInterval
                let labelText = String(format: "%.0f", labelValue)

                let textPosition = CGPoint(x: x - 10, y: 2)

                context.draw(
                    Text(labelText)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary),
                    at: textPosition
                )
            }

            position += unit.toPoints(unit.tickInterval) / 72.0 * 25.4 // 轉換回物理單位
            tickNumber += 1
        }
    }
}

/// 垂直標尺視圖
struct VerticalRulerView: View {
    let height: CGFloat
    let scale: CGFloat
    let unit: RulerUnit

    var body: some View {
        Canvas { context, size in
            drawRuler(context: context, size: size)
        }
        .frame(width: 20, height: height)
        .background(Color(.controlBackgroundColor).opacity(0.9))
    }

    private func drawRuler(context: GraphicsContext, size: CGSize) {
        var position = 0.0
        var tickNumber = 0

        while position * scale < size.height {
            let y = position * scale

            let isMajorTick = tickNumber % Int(unit.majorTickInterval / unit.tickInterval) == 0
            let tickWidth: CGFloat = isMajorTick ? 12 : 6

            // 繪製刻度線
            let startPoint = CGPoint(x: size.width - tickWidth, y: y)
            let endPoint = CGPoint(x: size.width, y: y)

            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)

            context.stroke(
                path,
                with: .color(.secondary),
                lineWidth: isMajorTick ? 1.0 : 0.5
            )

            // 繪製數字標籤（僅主刻度）
            if isMajorTick && tickNumber > 0 {
                let labelValue = position / unit.majorTickInterval
                let labelText = String(format: "%.0f", labelValue)

                let textPosition = CGPoint(x: 2, y: y - 8)

                context.draw(
                    Text(labelText)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary),
                    at: textPosition
                )
            }

            position += unit.toPoints(unit.tickInterval) / 72.0 * 25.4
            tickNumber += 1
        }
    }
}

// MARK: - 預覽

#Preview("水平標尺") {
    HorizontalRulerView(width: 595, scale: 1.0, unit: .centimeter)
        .frame(height: 20)
}

#Preview("垂直標尺") {
    VerticalRulerView(height: 842, scale: 1.0, unit: .centimeter)
        .frame(width: 20)
}
