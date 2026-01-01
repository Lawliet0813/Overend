//
//  LaTeXRenderer.swift
//  OVEREND
//
//  LaTeX 公式渲染服務 - 將 LaTeX 公式轉換為圖片
//

import Foundation
import AppKit

/// LaTeX 公式渲染器
class LaTeXRenderer {

    /// 渲染結果
    enum RenderResult {
        case success(NSImage)
        case error(String)
    }

    /// 檢查系統是否安裝 LaTeX
    static func isLaTeXInstalled() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["pdflatex"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return !data.isEmpty && task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// 將 LaTeX 公式渲染為圖片
    /// - Parameters:
    ///   - formula: LaTeX 公式（不含 $ 符號）
    ///   - fontSize: 字體大小（用於調整圖片尺寸）
    /// - Returns: 渲染結果
    static func render(formula: String, fontSize: CGFloat = 16) -> RenderResult {
        // 檢查 LaTeX 是否安裝
        guard isLaTeXInstalled() else {
            return .error("系統未安裝 LaTeX。請安裝 MacTeX 或 BasicTeX。\n下載：https://www.tug.org/mactex/")
        }

        // 建立臨時目錄
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            return .error("無法建立臨時目錄：\(error.localizedDescription)")
        }

        // 清理公式（移除可能存在的 $ 符號）
        let cleanFormula = formula
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")

        // 計算 LaTeX 文檔的字體大小（根據 NSTextView 字體大小調整）
        let latexFontSize = Int(fontSize * 1.2) // LaTeX pt 稍大

        // 建立 LaTeX 文檔
        let latexDocument = """
        \\documentclass[\(latexFontSize)pt]{article}
        \\usepackage{amsmath}
        \\usepackage{amssymb}
        \\usepackage[active,tightpage]{preview}
        \\PreviewEnvironment{math}
        \\setlength\\PreviewBorder{2pt}
        \\begin{document}
        \\begin{math}
        \(cleanFormula)
        \\end{math}
        \\end{document}
        """

        let texFile = tempDir.appendingPathComponent("formula.tex")

        do {
            try latexDocument.write(to: texFile, atomically: true, encoding: .utf8)
        } catch {
            cleanup(tempDir)
            return .error("無法寫入 LaTeX 文件：\(error.localizedDescription)")
        }

        // 執行 pdflatex
        let task = Process()
        task.currentDirectoryURL = tempDir
        task.launchPath = "/usr/bin/env"
        task.arguments = [
            "pdflatex",
            "-interaction=nonstopmode",
            "-halt-on-error",
            "formula.tex"
        ]

        let errorPipe = Pipe()
        task.standardError = errorPipe
        task.standardOutput = Pipe() // 忽略標準輸出

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "未知錯誤"
                cleanup(tempDir)
                return .error("LaTeX 編譯失敗：\n\(errorMessage)")
            }
        } catch {
            cleanup(tempDir)
            return .error("無法執行 pdflatex：\(error.localizedDescription)")
        }

        // 讀取生成的 PDF
        let pdfFile = tempDir.appendingPathComponent("formula.pdf")

        guard FileManager.default.fileExists(atPath: pdfFile.path) else {
            cleanup(tempDir)
            return .error("PDF 文件未生成")
        }

        guard let pdfData = try? Data(contentsOf: pdfFile),
              let pdfRep = NSPDFImageRep(data: pdfData) else {
            cleanup(tempDir)
            return .error("無法讀取 PDF 文件")
        }

        // 轉換為高解析度圖片
        let image = NSImage(size: pdfRep.size)
        image.addRepresentation(pdfRep)

        // 清理臨時文件
        cleanup(tempDir)

        return .success(image)
    }

    /// 清理臨時目錄
    private static func cleanup(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}
