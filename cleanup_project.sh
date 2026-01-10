#!/bin/bash

echo "🧹 OVEREND 專案瘦身開始..."

# 1. 建立備份目錄
BACKUP_DIR="_Archived_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📂 備份目錄已建立: $BACKUP_DIR"

# 2. 定義要移除的檔案清單
FILES_TO_REMOVE=(
    # 舊版 HTML 輸出引擎
    "OVEREND/Services/PDFExporter.swift"
    "OVEREND/Services/DocumentFormatter.swift"
    "OVEREND/Services/CoverPageGenerator.swift"
    "OVEREND/Services/AILayoutFormatter.swift"
    
    # 舊版編輯器
    "OVEREND/Views/Writer/RichTextEditor.swift"
    "OVEREND/Views/Writer/LaTeXSupportedTextView.swift"
    "OVEREND/Views/Writer/FocusWritingView.swift"
    
    # 重複的 UI 元件
    "OVEREND/Views/Writer/WriterToolbar.swift"
    "OVEREND/Views/Common/DynamicToolbar.swift"
    "OVEREND/Views/Writer/CitationPicker.swift"
    "OVEREND/Views/Writer/CitationSearchPanel.swift"
    "OVEREND/Views/Writer/TemplatePickerView.swift"
    
    # 垃圾與備份
    "OVEREND/Views/NewContentView.swift.bak"
    "OVEREND/FIX_BUILD_ERRORS.md"
    "OVEREND/Views/_experimental"
)

# 3. 移動檔案
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -e "$file" ]; then
        # 建立目標資料夾結構
        target_dir="$BACKUP_DIR/$(dirname "$file")"
        mkdir -p "$target_dir"
        mv "$file" "$target_dir/"
        echo "✅ 已移除並備份: $file"
    else
        echo "⚠️  找不到 (可能已刪除): $file"
    fi
done

echo "🎉 瘦身完成！"
echo "👉 接下來請打開 Xcode，編譯專案。"
echo "👉 如果 'ProfessionalEditorView.swift' 報錯，請刪除對 RichTextEditor 的引用，改用 MultiPageDocumentView。"
