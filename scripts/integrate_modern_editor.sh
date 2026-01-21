#!/bin/bash

# OVEREND 現代化編輯器整合腳本
# 自動將 ModernEditorToolbar 和 AITextAnalysisPanel 整合到專案中

echo "🚀 OVEREND 現代化編輯器整合"
echo "================================"
echo ""

PROJECT_ROOT="/Users/lawliet/OVEREND"
XCODE_PROJECT="$PROJECT_ROOT/OVEREND.xcodeproj"

# 檢查專案是否存在
if [ ! -d "$XCODE_PROJECT" ]; then
    echo "❌ 找不到 Xcode 專案"
    exit 1
fi

echo "✅ 找到專案：$XCODE_PROJECT"
echo ""

# 1. 檢查新文件是否已創建
echo "📋 檢查新文件..."

files=(
    "$PROJECT_ROOT/OVEREND/Views/Editor/ModernEditorToolbar.swift"
    "$PROJECT_ROOT/OVEREND/Views/Editor/AITextAnalysisPanel.swift"
)

all_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $(basename $file)"
    else
        echo "  ❌ $(basename $file) - 不存在"
        all_exist=false
    fi
done

if [ "$all_exist" = false ]; then
    echo ""
    echo "❌ 部分文件缺失，請先運行 Desktop Commander 創建文件"
    exit 1
fi

echo ""
echo "✅ 所有必要文件已就緒"
echo ""

# 2. 編譯測試
echo "🔨 編譯測試..."
echo ""

cd "$PROJECT_ROOT"

# 清理舊的建置
echo "  清理建置快取..."
xcodebuild clean -scheme OVEREND -quiet 2>/dev/null

# 嘗試編譯
echo "  開始編譯..."
if xcodebuild -scheme OVEREND -destination 'platform=macOS' build -quiet 2>&1 | grep -i "error:"; then
    echo ""
    echo "❌ 編譯失敗，請檢查錯誤訊息："
    echo ""
    xcodebuild -scheme OVEREND -destination 'platform=macOS' build 2>&1 | grep -A 5 "error:"
    exit 1
fi

echo ""
echo "✅ 編譯成功！"
echo ""

# 3. 創建備份
echo "💾 創建備份..."

BACKUP_DIR="$PROJECT_ROOT/.backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 備份原始編輯器文件
cp "$PROJECT_ROOT/OVEREND/Views/Editor/DocumentEditorView.swift" "$BACKUP_DIR/"
cp "$PROJECT_ROOT/OVEREND/Views/Editor/EditorToolbar.swift" "$BACKUP_DIR/"

echo "  ✅ 備份已保存至：$BACKUP_DIR"
echo ""

# 4. 功能總結
echo "🎉 整合準備完成！"
echo ""
echo "新增功能："
echo "  ✨ ModernEditorToolbar - 現代化工具列設計"
echo "  🤖 AITextAnalysisPanel - AI 文本分析面板"
echo ""
echo "下一步："
echo "  1. 在 Xcode 中打開專案"
echo "  2. 找到 DocumentEditorView.swift"
echo "  3. 將 EditorToolbar 替換為 ModernEditorToolbar"
echo "  4. 添加 AI 分析面板到視圖"
echo ""
echo "詳細整合步驟請參考："
echo "  📖 $PROJECT_ROOT/DOCS/development/ModernEditorToolbar_Integration.md"
echo ""

# 5. 自動打開相關文件
echo "📂 是否在 Xcode 中打開專案？(y/n)"
read -r response

if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo ""
    echo "正在打開 Xcode..."
    open "$XCODE_PROJECT"
    
    # 等待 Xcode 啟動
    sleep 2
    
    # 打開關鍵文件
    echo "正在打開關鍵文件..."
    open -a Xcode "$PROJECT_ROOT/OVEREND/Views/Editor/DocumentEditorView.swift"
    open -a Xcode "$PROJECT_ROOT/OVEREND/Views/Editor/ModernEditorToolbar.swift"
    open -a Xcode "$PROJECT_ROOT/OVEREND/Views/Editor/AITextAnalysisPanel.swift"
fi

echo ""
echo "✅ 完成！"
echo ""
echo "提示："
echo "  • 確保所有元件都注入 @EnvironmentObject var theme: AppTheme"
echo "  • 測試字數統計功能是否正常"
echo "  • 檢查 AI 分析面板的模擬數據"
echo ""
echo "需要幫助？查看整合文檔或聯繫開發團隊"
echo ""
