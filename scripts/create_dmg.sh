#!/bin/bash

# OVEREND DMG 打包腳本
# 版本：1.0.1

set -e

echo "📦 開始打包 OVEREND v1.0.1 DMG..."

# 設定變數
APP_NAME="OVEREND"
VERSION="1.0.1"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/OVEREND-cndwckokhthjmcbkmovocplyeztc/Build/Products/Release"
SOURCE_APP="${BUILD_DIR}/${APP_NAME}.app"
DMG_DIR="$(pwd)/dmg_build"
FINAL_DMG="$(pwd)/${DMG_NAME}.dmg"

# 檢查 app 是否存在
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ 錯誤：找不到 ${APP_NAME}.app"
    echo "   位置：$SOURCE_APP"
    exit 1
fi

echo "✅ 找到應用程式：$SOURCE_APP"

# 檢查版本
APP_VERSION=$(defaults read "$SOURCE_APP/Contents/Info.plist" CFBundleShortVersionString)
echo "📌 應用程式版本：$APP_VERSION"

# 清理舊的 DMG
if [ -f "$FINAL_DMG" ]; then
    echo "🗑️  刪除舊的 DMG..."
    rm -f "$FINAL_DMG"
fi

# 清理並建立臨時目錄
if [ -d "$DMG_DIR" ]; then
    rm -rf "$DMG_DIR"
fi
mkdir -p "$DMG_DIR"

echo "📋 複製應用程式到臨時目錄..."
cp -R "$SOURCE_APP" "$DMG_DIR/"

# 建立 Applications 符號連結
echo "🔗 建立 Applications 符號連結..."
ln -s /Applications "$DMG_DIR/Applications"

# 建立 README
echo "📝 建立 README..."
cat > "$DMG_DIR/README.txt" << 'EOF'
OVEREND v1.0.1
===============

安裝說明：
1. 將 OVEREND.app 拖曳到 Applications 資料夾
2. 首次開啟時，請在「系統偏好設定」→「隱私與安全性」中允許執行

功能特色：
- 智慧文獻管理
- AI 驅動的論文寫作輔助
- BibTeX 匯入與管理
- PDF 文獻自動提取
- 學術翻譯與潤色
- 引用推薦系統

系統需求：
- macOS 15.0 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel 處理器

更新日誌（v1.0.1）：
- ✅ 文獻庫支援多個並可切換
- ✅ 文稿與文獻選取批次刪除功能
- ✅ AI智慧中心學術翻譯匯入文稿功能
- ✅ 設定中加入清空所有資料功能

© 2026 OVEREND Team
EOF

# 建立 DMG
echo "💿 建立 DMG 映像檔..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    -fs HFS+ \
    "$FINAL_DMG"

# 清理臨時目錄
echo "🧹 清理臨時檔案..."
rm -rf "$DMG_DIR"

# 檢查結果
if [ -f "$FINAL_DMG" ]; then
    DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
    echo ""
    echo "✅ DMG 打包成功！"
    echo "📦 檔案：$FINAL_DMG"
    echo "📏 大小：$DMG_SIZE"
    echo ""
    echo "🎉 完成！可以分發 ${DMG_NAME}.dmg 了"
else
    echo "❌ 錯誤：DMG 建立失敗"
    exit 1
fi
