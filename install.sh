#!/bin/bash
# OVEREND 快速編譯安裝腳本

echo "🔨 編譯 OVEREND (Release)..."
cd /Users/lawliet/OVEREND
xcodebuild -project OVEREND.xcodeproj -scheme OVEREND -configuration Release clean build CONFIGURATION_BUILD_DIR="$PWD/build" 2>&1 | grep -E "(BUILD|error|warning)" | tail -10

if [ $? -eq 0 ]; then
    echo ""
    echo "📦 安裝到 /Applications..."
    cp -R build/OVEREND.app /Applications/
    
    echo ""
    echo "✅ 完成！啟動 OVEREND..."
    open /Applications/OVEREND.app
    
    echo ""
    echo "💡 提示："
    echo "  - OVEREND 已安裝到 /Applications/OVEREND.app"
    echo "  - 以後可以直接從 Launchpad 或 Spotlight 啟動"
    echo "  - 數據位置：~/Library/Containers/com.lawliet.OVEREND/"
else
    echo "❌ 編譯失敗"
    exit 1
fi
