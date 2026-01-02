//
//  IconGeneratorTool.swift
//  OVEREND
//
//  命令行工具生成 App Icon
//

import Foundation
import AppKit
import SwiftUI

// @main
struct IconGeneratorTool {
    static func main() {
        print("🎨 OVEREND App Icon Generator")
        print("============================\n")

        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let outputFolder = desktop.appendingPathComponent("OVEREND_Icons")

        // 創建輸出資料夾
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        // 生成所有尺寸
        let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]

        for size in sizes {
            print("📐 生成 \(Int(size))x\(Int(size)) 圖標...")
            generateIconImage(size: size, outputFolder: outputFolder)
        }

        print("\n✅ 完成！")
        print("📁 圖標已保存到: \(outputFolder.path)")

        // 打開資料夾
        NSWorkspace.shared.open(outputFolder)
    }

    static func generateIconImage(size: CGFloat, outputFolder: URL) {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // 背景漸層
        let gradient = NSGradient(colors: [
            NSColor(red: 0/255, green: 217/255, blue: 126/255, alpha: 1.0),
            NSColor(red: 0/255, green: 179/255, blue: 104/255, alpha: 1.0)
        ])
        let path = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                                xRadius: size * 0.225,
                                yRadius: size * 0.225)
        gradient?.draw(in: path, angle: 135)

        // 繪製書籍圖案
        drawBooks(size: size)

        image.unlockFocus()

        // 保存
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            let filename = "icon_\(Int(size))x\(Int(size)).png"
            let fileURL = outputFolder.appendingPathComponent(filename)
            try? png.write(to: fileURL)
        }
    }

    static func drawBooks(size: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext

        // 書籍參數
        let bookWidth = size * 0.45
        let bookHeight = size * 0.1
        let centerX = size / 2
        let centerY = size / 2

        // 第三本書（最下層）
        context?.saveGState()
        context?.translateBy(x: centerX, y: centerY - bookHeight * 1.2)
        context?.rotate(by: 2 * .pi / 180)
        drawBook(width: bookWidth * 1.08, height: bookHeight, opacity: 0.7)
        context?.restoreGState()

        // 第二本書
        context?.saveGState()
        context?.translateBy(x: centerX, y: centerY)
        context?.rotate(by: -1 * .pi / 180)
        drawBook(width: bookWidth * 1.04, height: bookHeight, opacity: 0.8)
        context?.restoreGState()

        // 第一本書（最上層）
        context?.saveGState()
        context?.translateBy(x: centerX - bookWidth * 0.1, y: centerY + bookHeight * 1.2)
        context?.rotate(by: -6 * .pi / 180)
        drawBook(width: bookWidth, height: bookHeight, opacity: 0.95)
        context?.restoreGState()
    }

    static func drawBook(width: CGFloat, height: CGFloat, opacity: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext

        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        let path = NSBezierPath(roundedRect: rect, xRadius: height * 0.15, yRadius: height * 0.15)

        // 書籍填充
        NSColor.white.withAlphaComponent(opacity).setFill()
        path.fill()

        // 書脊線
        context?.setStrokeColor(NSColor.white.withAlphaComponent(opacity * 0.6).cgColor)
        context?.setLineWidth(height * 0.05)
        context?.move(to: CGPoint(x: -width/2 + width * 0.08, y: -height/2))
        context?.addLine(to: CGPoint(x: -width/2 + width * 0.08, y: height/2))
        context?.strokePath()
    }
}
