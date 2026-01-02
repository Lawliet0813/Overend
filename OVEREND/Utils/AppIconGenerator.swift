//
//  AppIconGenerator.swift
//  OVEREND
//
//  App Icon 生成器 - 生成符合 macOS 規範的應用圖標
//

import SwiftUI
import AppKit

/// App Icon 設計視圖
struct AppIconDesign: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [
                    Color(hex: "#00D97E"),  // 品牌綠色
                    Color(hex: "#00B368")   // 深綠色
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 主圖案 - 書籍堆疊
            VStack(spacing: size * 0.03) {
                // 第一本書（最上層）
                BookShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.12)
                    .shadow(color: .black.opacity(0.15), radius: size * 0.01, x: 0, y: size * 0.01)
                    .offset(x: -size * 0.05, y: 0)
                    .rotationEffect(.degrees(-8))

                // 第二本書
                BookShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.52, height: size * 0.12)
                    .shadow(color: .black.opacity(0.12), radius: size * 0.01, x: 0, y: size * 0.01)
                    .rotationEffect(.degrees(-3))

                // 第三本書（最下層）
                BookShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.75),
                                Color.white.opacity(0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.54, height: size * 0.12)
                    .shadow(color: .black.opacity(0.1), radius: size * 0.01, x: 0, y: size * 0.01)
                    .offset(x: size * 0.03, y: 0)
                    .rotationEffect(.degrees(2))
            }
            .offset(y: -size * 0.05)

            // 學術帽裝飾（可選，讓圖標更具學術氣息）
            Image(systemName: "graduationcap.fill")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.2), radius: size * 0.02, x: 0, y: size * 0.02)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225)) // macOS 圓角比例
    }
}

/// 書籍形狀
struct BookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let spineWidth = width * 0.08

        // 書脊
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: spineWidth, y: height * 0.1))
        path.addLine(to: CGPoint(x: spineWidth, y: height * 0.9))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        // 書頁
        path.move(to: CGPoint(x: spineWidth, y: height * 0.1))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: spineWidth, y: height * 0.9))
        path.closeSubpath()

        return path
    }
}

/// App Icon 生成器
class AppIconGenerator {

    /// 生成所有需要的 App Icon 尺寸
    static func generateAllIcons(saveTo outputURL: URL) {
        let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]

        for size in sizes {
            if let image = generateIcon(size: size) {
                let filename = "icon_\(Int(size))x\(Int(size)).png"
                let fileURL = outputURL.appendingPathComponent(filename)

                if let pngData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: pngData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: fileURL)
                    print("✅ 生成圖標: \(filename)")
                }
            }
        }

        print("🎉 所有圖標生成完成！")
        print("📁 保存位置: \(outputURL.path)")
    }

    /// 生成單個尺寸的圖標
    static func generateIcon(size: CGFloat) -> NSImage? {
        let view = AppIconDesign(size: size)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: size, height: size)

        guard let bitmapRep = hostingController.view.bitmapImageRepForCachingDisplay(in: hostingController.view.bounds) else {
            return nil
        }

        hostingController.view.cacheDisplay(in: hostingController.view.bounds, to: bitmapRep)

        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(bitmapRep)

        return image
    }
}

// MARK: - 預覽和生成助手

#Preview("App Icon Preview") {
    VStack(spacing: 32) {
        Text("OVEREND App Icon")
            .font(.system(size: 24, weight: .bold))

        // 不同尺寸預覽
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                AppIconDesign(size: 64)
                Text("64x64")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 8) {
                AppIconDesign(size: 128)
                Text("128x128")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 8) {
                AppIconDesign(size: 256)
                Text("256x256")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }

        // 生成按鈕
        Button("生成所有圖標") {
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let outputFolder = desktop.appendingPathComponent("OVEREND_Icons")

            try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

            AppIconGenerator.generateAllIcons(saveTo: outputFolder)

            // 打開資料夾
            NSWorkspace.shared.open(outputFolder)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    .padding(40)
    .frame(width: 800, height: 600)
}
