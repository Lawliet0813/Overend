#!/usr/bin/swift
import Foundation
import PDFKit

let pdfPath = "/Users/lawliet/Library/Mobile Documents/com~apple~CloudDocs/MEPA27/學位論文/參考文獻/民營化面臨之困境與挑戰：以臺鐵組織效能為例.pdf"
let url = URL(fileURLWithPath: pdfPath)
let fileName = url.deletingPathExtension().lastPathComponent

// 模擬 extractEnhancedMetadata
guard let pdfDocument = PDFDocument(url: url) else {
    print("❌ 無法打開 PDF")
    exit(1)
}

// 提取前 3 頁文字
var fullText = ""
for i in 0..<min(3, pdfDocument.pageCount) {
    if let page = pdfDocument.page(at: i),
       let text = page.string {
        fullText += text + "\n"
    }
}

print("📄 提取的文字（前 1000 字元）:")
print(String(fullText.prefix(1000)))
print("")

// 測試標題提取
let lines = fullText.components(separatedBy: .newlines)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

print("📋 前 20 行內容:")
for (index, line) in lines.prefix(20).enumerated() {
    print("\(index): [\(line.count)字] \(line)")
}
