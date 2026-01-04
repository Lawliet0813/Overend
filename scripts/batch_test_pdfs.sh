#!/bin/bash
# 批次測試 PDF 匯入
# 自動匯入測試素材到 OVEREND 並檢查識別結果

TEST_DIR="/Volumes/TEAM PD20M/MEPA27課程資料/跨域治理"

echo "======================================"
echo "🧪 OVEREND PDF 匯入批次測試"
echo "======================================"
echo ""

# 測試案例 1: .indd 文件名
echo "📄 測試 1: 都市更新公私合夥（.indd 問題）"
PDF1="$TEST_DIR/Week03_公私部門差異/都市更新公私合夥開發模式與參與認知特性之研究.pdf"
echo "檔案: $(basename "$PDF1")"
echo "預期標題: 都市更新公私合夥開發模式與參與認知特性之研究"
echo "預期作者: 張學聖、黃惠愉"
echo "預期年份: 2005"
echo ""

# 測試案例 2: Hex 編碼標題
echo "📄 測試 2: 民主治理下的政務官（Hex 編碼問題）"
PDF2="$TEST_DIR/Week10_政務事務關係/民主治理下的政務官與事務官互動關係：以「是的，部長！」影集分析為例.pdf"
echo "檔案: $(basename "$PDF2")"
echo "預期標題: 民主治理下的政務官與事務官互動關係：以「是的，部長！」影集分析為例"
echo "預期作者: 呂季蓉、林俐君、陳敦源"
echo "預期年份: 2018"
echo ""

# 測試案例 3: 網絡治理（無 PDF 屬性）
echo "📄 測試 3: 網絡治理與民主課責（無 PDF 屬性）"
PDF3="$TEST_DIR/Week05_網絡治理/網絡治理與民主課責：監控民主下的理性選擇理論觀點.pdf"
echo "檔案: $(basename "$PDF3")"
echo "預期標題: 網絡治理與民主課責：監控民主下的理性選擇理論觀點"
echo "預期作者: 陳敦源、簡鈺珒"
echo "預期年份: 2019"
echo ""

# 測試案例 4: 從個人風險（單個英文單字作者）
echo "📄 測試 4: 從個人風險特質探討（yang 問題）"
PDF4="$TEST_DIR/Week04_組織間合作/從個人風險特質探討公務人員之創新行為—以計畫行為理論為分析架構.pdf"
if [ -f "$PDF4" ]; then
    echo "檔案: $(basename "$PDF4")"
    echo "預期標題: 從個人風險特質探討公務人員之創新行為"
    echo "預期作者: 楊庭安攝（研究生）"
    echo "預期年份: 2018（民國107年）"
else
    echo "⚠️  檔案不存在，跳過"
fi
echo ""

echo "======================================"
echo "💡 測試方式："
echo "1. 在 OVEREND 中匯入以上 PDF"
echo "2. 檢查標題、作者、年份是否正確"
echo "3. 記錄任何識別錯誤"
echo "======================================"
echo ""
echo "📋 快速測試指令："
echo "swift test_pdf_metadata.swift \"$PDF1\""
echo "swift test_pdf_metadata.swift \"$PDF2\""
echo "swift test_pdf_metadata.swift \"$PDF3\""
