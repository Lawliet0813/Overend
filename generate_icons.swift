#!/usr/bin/swift

import Foundation
import AppKit
import CoreGraphics

// OVEREND App Icon 生成器
class IconGenerator {

    static func generateAllIcons() {
        print("🎨 OVEREND App Icon Generator")
        print("=============================\n")

        let outputPath = FileManager.default.currentDirectoryPath + "/OVEREND/Assets.xcassets/AppIcon.appiconset"
        let outputURL = URL(fileURLWithPath: outputPath)

        // 確保目錄存在
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let sizes: [(size: Int, name: String)] = [
            (16, "icon_16x16.png"),
            (32, "icon_32x32.png"),
            (32, "icon_32x32-1.png"),
            (64, "icon_64x64.png"),
            (128, "icon_128x128.png"),
            (256, "icon_256x256.png"),
            (256, "icon_256x256-1.png"),
            (512, "icon_512x512.png"),
            (512, "icon_512x512-1.png"),
            (1024, "icon_1024x1024.png")
        ]

        for (size, filename) in sizes {
            print("📐 生成 \(size)x\(size) - \(filename)")
            if let image = drawIcon(size: CGFloat(size)) {
                let fileURL = outputURL.appendingPathComponent(filename)
                saveImage(image, to: fileURL)
            }
        }

        print("\n✅ 完成！所有圖標已生成")
        print("📁 位置: \(outputPath)")
    }

    static func drawIcon(size: CGFloat) -> NSImage? {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        // 1. 繪製背景漸層
        drawBackground(context: context, size: size)

        // 2. 繪製書籍堆疊
        drawBooks(context: context, size: size)

        // 3. 繪製引用符號
        drawQuotationMarks(context: context, size: size)

        image.unlockFocus()

        return image
    }

    static func drawBackground(context: CGContext, size: CGFloat) {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.225  // macOS 標準圓角

        // 創建圓角矩形路徑
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(path)
        context.clip()

        // 繪製漸層
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0/255, green: 217/255, blue: 126/255, alpha: 1.0),  // #00D97E
            CGColor(red: 0/255, green: 179/255, blue: 104/255, alpha: 1.0)   // #00B368
        ] as CFArray

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: 0, y: size),
                                     end: CGPoint(x: size, y: 0),
                                     options: [])
        }
    }

    static func drawBooks(context: CGContext, size: CGFloat) {
        let bookWidth = size * 0.45
        let bookHeight = size * 0.1
        let centerX = size / 2
        let centerY = size / 2 - size * 0.08

        // 第三本書（最下層）
        context.saveGState()
        context.translateBy(x: centerX, y: centerY - bookHeight * 1.2)
        context.rotate(by: 3 * .pi / 180)
        drawSingleBook(context: context, width: bookWidth * 1.08, height: bookHeight, opacity: 0.65)
        context.restoreGState()

        // 第二本書（中層）
        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: 0)
        drawSingleBook(context: context, width: bookWidth * 1.04, height: bookHeight, opacity: 0.78)
        context.restoreGState()

        // 第一本書（最上層）
        context.saveGState()
        context.translateBy(x: centerX - bookWidth * 0.1, y: centerY + bookHeight * 1.3)
        context.rotate(by: -6 * .pi / 180)
        drawSingleBook(context: context, width: bookWidth, height: bookHeight, opacity: 0.92)
        context.restoreGState()
    }

    static func drawSingleBook(context: CGContext, width: CGFloat, height: CGFloat, opacity: CGFloat) {
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        let cornerRadius = height * 0.15

        // 書籍主體
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(path)
        context.setFillColor(CGColor(gray: 1.0, alpha: opacity))
        context.fillPath()

        // 書脊線
        context.setStrokeColor(CGColor(gray: 1.0, alpha: opacity * 0.5))
        context.setLineWidth(height * 0.04)
        context.move(to: CGPoint(x: -width/2 + width * 0.08, y: -height/2))
        context.addLine(to: CGPoint(x: -width/2 + width * 0.08, y: height/2))
        context.strokePath()

        // 陰影效果（通過稍暗的邊緣）
        context.setStrokeColor(CGColor(gray: 0.0, alpha: opacity * 0.15))
        context.setLineWidth(1)
        context.addPath(path)
        context.strokePath()
    }

    static func drawQuotationMarks(context: CGContext, size: CGFloat) {
        let fontSize = size * 0.32
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .black),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.88)
        ]

        let text = "\" \"" as NSString
        let textSize = text.size(withAttributes: attributes)
        let x = (size - textSize.width) / 2
        let y = size * 0.55

        // 繪製陰影
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -size * 0.015),
                         blur: size * 0.02,
                         color: CGColor(gray: 0, alpha: 0.3))
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        context.restoreGState()
    }

    static func saveImage(_ image: NSImage, to url: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("❌ 保存失敗: \(url.lastPathComponent)")
            return
        }

        do {
            try pngData.write(to: url)
            print("   ✓ 已保存")
        } catch {
            print("   ✗ 錯誤: \(error)")
        }
    }
}

// 執行生成
IconGenerator.generateAllIcons()
