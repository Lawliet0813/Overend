#!/bin/bash

echo "=========================================="
echo "驗證 AI 測試框架修復"
echo "=========================================="
echo ""

# 檢查 AITestRunner 的 @MainActor
echo "1. 檢查 AITestRunner 類別..."
MAINACTOR_COUNT=$(grep -A 1 "/// AI 測試執行器" OVERENDTests/AI/AITestFramework.swift | grep -c "@MainActor")
if [ "$MAINACTOR_COUNT" -eq 1 ]; then
    echo "   ✅ AITestRunner 只有一個 @MainActor"
else
    echo "   ❌ AITestRunner 有 $MAINACTOR_COUNT 個 @MainActor (應該只有 1 個)"
fi

# 檢查 AIDomainTestable 協議
echo "2. 檢查 AIDomainTestable 協議..."
PROTOCOL_MAINACTOR=$(grep -B 1 "protocol AIDomainTestable" OVERENDTests/AI/AITestFramework.swift | grep -c "@MainActor")
if [ "$PROTOCOL_MAINACTOR" -eq 1 ]; then
    echo "   ✅ AIDomainTestable 協議有 @MainActor"
else
    echo "   ❌ AIDomainTestable 協議缺少 @MainActor"
fi

# 檢查 CitationDomainTests
echo "3. 檢查 CitationDomainTests..."
if grep -q "nonisolated func testAllFeatures" OVERENDTests/AI/CitationDomainTests.swift; then
    echo "   ❌ CitationDomainTests 仍有 nonisolated 標記"
else
    echo "   ✅ CitationDomainTests 已移除 nonisolated"
fi

# 檢查 DocumentDomainTests
echo "4. 檢查 DocumentDomainTests..."
if grep -q "nonisolated func testAllFeatures" OVERENDTests/AI/DocumentDomainTests.swift; then
    echo "   ❌ DocumentDomainTests 仍有 nonisolated 標記"
else
    echo "   ✅ DocumentDomainTests 已移除 nonisolated"
fi

# 檢查 WritingDomainTests
echo "5. 檢查 WritingDomainTests..."
if grep -q "nonisolated func testAllFeatures" OVERENDTests/AI/WritingDomainTests.swift; then
    echo "   ❌ WritingDomainTests 仍有 nonisolated 標記"
else
    echo "   ✅ WritingDomainTests 已移除 nonisolated"
fi

echo ""
echo "=========================================="
echo "建議的清理步驟："
echo "=========================================="
echo "1. 在 Xcode 中執行: Product > Clean Build Folder (Cmd+Option+Shift+K)"
echo "2. 刪除 DerivedData:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/OVEREND-*"
echo "3. 退出並重新開啟 Xcode"
echo "4. 重新構建專案"
echo ""
