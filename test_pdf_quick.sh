#!/bin/bash
# 快速測試 PDF 標題提取
# 使用方式: ./test_pdf_quick.sh "/path/to/pdf"

PDF_PATH="$1"

if [ -z "$PDF_PATH" ]; then
    echo "使用方式: $0 <PDF檔案路徑>"
    exit 1
fi

echo "======================================"
echo "測試 PDF: $(basename "$PDF_PATH")"
echo "======================================"

# 使用 mdls 快速查看 PDF 屬性（macOS 內建工具）
echo ""
echo "📋 PDF 內建屬性:"
echo "--------------------------------------"
mdls -name kMDItemTitle -name kMDItemAuthors -name kMDItemContentCreationDate "$PDF_PATH"

echo ""
echo "📄 PDF 前 50 行文字:"
echo "--------------------------------------"

# 使用 pdftotext 提取文字（如果有安裝）
if command -v pdftotext &> /dev/null; then
    pdftotext -l 3 "$PDF_PATH" - | head -50
else
    echo "⚠️  未安裝 pdftotext，請執行: brew install poppler"
fi

echo ""
echo "======================================"
