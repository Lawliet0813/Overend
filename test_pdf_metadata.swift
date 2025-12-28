#!/usr/bin/env swift

import Foundation
import PDFKit

// 測試 PDF 元數據提取
// 使用方式：swift test_pdf_metadata.swift "/path/to/your.pdf"

guard CommandLine.arguments.count > 1 else {
    print("使用方式: swift test_pdf_metadata.swift <PDF檔案路徑>")
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let url = URL(fileURLWithPath: pdfPath)

guard let pdfDocument = PDFDocument(url: url) else {
    print("❌ 無法讀取 PDF: \(pdfPath)")
    exit(1)
}

let sep = String(repeating: "=", count: 80)
let div = String(repeating: "-", count: 80)

print(sep)
print("📄 PDF: \(url.lastPathComponent)")
print(sep)

// 1. PDF 內建屬性
print("\n📋 PDF 內建屬性:")
print(div)

if let attr = pdfDocument.documentAttributes {
    print("Title: \(attr[PDFDocumentAttribute.titleAttribute] as? String ?? "(無)")")
    print("Author: \(attr[PDFDocumentAttribute.authorAttribute] as? String ?? "(無)")")
    if let subject = attr[PDFDocumentAttribute.subjectAttribute] as? String {
        print("Subject: \(subject)")
    }
    if let creator = attr[PDFDocumentAttribute.creatorAttribute] as? String {
        print("Creator: \(creator)")
    }
    if let date = attr[PDFDocumentAttribute.creationDateAttribute] as? Date {
        print("Creation Date: \(date)")
    }
} else {
    print("(無任何 PDF 屬性)")
}

// 2. 前 3 頁文字
print("\n📄 前 3 頁文字內容:")
print(div)

for i in 0..<min(3, pdfDocument.pageCount) {
    if let page = pdfDocument.page(at: i), let text = page.string {
        print("\n--- 第 \(i + 1) 頁 (前 800 字元) ---")
        let preview = String(text.prefix(800))
        print(preview)
        if text.count > 800 {
            print("... (省略 \(text.count - 800) 字元)")
        }
    }
}

// 3. DOI
print("\n🔍 DOI 偵測:")
print(div)

let doiPattern = #"10\.\d{4,}/[^\s\]\"'>\)]+"#
if let regex = try? NSRegularExpression(pattern: doiPattern, options: [.caseInsensitive]) {
    var found = false
    for i in 0..<min(5, pdfDocument.pageCount) {
        if let page = pdfDocument.page(at: i), let text = page.string {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let swiftRange = Range(match.range, in: text) {
                print("✅ 第 \(i + 1) 頁找到 DOI: \(String(text[swiftRange]))")
                found = true
                break
            }
        }
    }
    if !found {
        print("❌ 未找到 DOI")
    }
}

print("\n" + sep)
print("✅ 測試完成")
print(sep)
