#!/usr/bin/env swift

import Foundation

let testLine = "董祥開*、楊庭安**"

print("測試行：\(testLine)")
print("長度：\(testLine.count)")
print("")

// 檢查 1：太短？
if testLine.count < 2 || testLine.count > 100 {
    print("❌ 長度檢查失敗（需要 2-100）")
} else {
    print("✅ 長度檢查通過：\(testLine.count)")
}

// 檢查 2：不應該包含句子結束符號
if testLine.contains("。") || testLine.contains("！") || testLine.contains("？") {
    print("❌ 包含句子結束符號")
} else {
    print("✅ 無句子結束符號")
}

// 檢查 3：數字比例
let digitCount = testLine.filter { $0.isNumber }.count
let digitRatio = Double(digitCount) / Double(testLine.count)
print("數字比例：\(digitRatio * 100)% (\(digitCount)/\(testLine.count))")
if digitRatio > 0.3 {
    print("❌ 數字比例過高（>30%）")
} else {
    print("✅ 數字比例合理")
}

// 檢查 4：電子郵件
if testLine.contains("@") {
    print("✅ 包含 email")
} else {
    print("⚪ 無 email")
}

// 檢查 5：機構關鍵字
let institutionKeywords = ["university", "college", "institute", "大學", "學院", "研究所", "中心"]
let hasInstitution = institutionKeywords.contains(where: { testLine.lowercased().contains($0.lowercased()) })
if hasInstitution {
    print("✅ 包含機構關鍵字")
} else {
    print("⚪ 無機構關鍵字")
}

// 檢查 6：姓名模式（用頓號分隔）
let nameParts = testLine.components(separatedBy: CharacterSet(charactersIn: ",、；"))
print("分隔後的部分：\(nameParts)")
print("部分數量：\(nameParts.count)")

if nameParts.count >= 2 {
    print("✅ 有多個部分（可能是多位作者）")
} else {
    print("❌ 只有一個部分")
}

print("")
print("🔍 結論：")
if digitRatio <= 0.3 && nameParts.count >= 2 {
    print("✅ 應該被識別為作者行")
} else {
    print("❌ 可能不會被識別為作者行")
}
