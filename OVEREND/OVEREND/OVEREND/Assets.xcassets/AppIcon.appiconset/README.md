# OVEREND App Icon 設置指南

## 🎨 圖標設計

OVEREND 的 App Icon 設計理念：
- **主題**：學術文獻管理
- **元素**：堆疊的書籍 + 引用符號
- **顏色**：品牌綠色漸層 (#00D97E → #00B368)
- **風格**：現代、簡潔、專業

## 📝 使用 Xcode Preview 導出圖標

### 方法一：使用 AppIconPreview.swift

1. 在 Xcode 中打開 `Views/Utils/AppIconPreview.swift`
2. 點擊 Preview 按鈕（或按 ⌥⌘↩）
3. 選擇 "1024x1024 Icon Only" 預覽
4. 使用 macOS 截圖工具：
   - 按 `⌘⇧4`
   - 再按**空格鍵**（切換到視窗截圖模式）
   - 點擊 Preview 視窗
5. 截圖會自動保存到桌面

### 方法二：使用 All Sizes Preview

1. 打開 `AppIconPreview.swift` 的 "All Sizes" 預覽
2. 右鍵點擊各個尺寸的圖標
3. 選擇「拷貝圖像」
4. 在 Finder 中貼上，保存為對應的檔名

## 📁 需要的圖標尺寸

| 文件名 | 尺寸 | 用途 |
|--------|------|------|
| icon_16x16.png | 16x16 | Finder 小圖標 |
| icon_32x32.png | 32x32 | @2x 小圖標 / @1x 標準圖標 |
| icon_32x32-1.png | 32x32 | @1x 標準圖標 |
| icon_64x64.png | 64x64 | @2x 標準圖標 |
| icon_128x128.png | 128x128 | @1x 大圖標 |
| icon_256x256.png | 256x256 | @2x 大圖標 / @1x 超大圖標 |
| icon_256x256-1.png | 256x256 | @1x 超大圖標 |
| icon_512x512.png | 512x512 | @2x 超大圖標 / @1x App Store |
| icon_512x512-1.png | 512x512 | @1x App Store |
| icon_1024x1024.png | 1024x1024 | @2x App Store |

## 🚀 快速設置步驟

1. **生成 1024x1024 主圖標**
   ```
   打開 AppIconPreview.swift → "1024x1024 Icon Only" 預覽 → 截圖
   ```

2. **批量生成其他尺寸**
   - 使用圖像編輯工具（如 Preview.app）打開 1024x1024 圖標
   - 調整大小到需要的尺寸並導出

3. **將圖標放入 AppIcon.appiconset**
   ```
   將所有生成的 .png 文件拖入此資料夾
   ```

4. **驗證**
   - 在 Xcode 中打開 Assets.xcassets
   - 點擊 AppIcon
   - 確認所有尺寸都已填入

## 💡 提示

- **高品質導出**：確保截圖時 Retina 顯示器分辨率正確
- **透明背景**：Icon 已包含圓角，無需額外處理
- **顏色一致性**：所有尺寸使用相同的漸層色
- **測試**：在 Finder、Dock 和 App Switcher 中測試圖標效果

## 🛠 進階：命令行批量生成

如果需要命令行批量生成，可以運行：

```bash
# 安裝 imagemagick
brew install imagemagick

# 批量生成
for size in 16 32 64 128 256 512 1024; do
  convert icon_1024x1024.png -resize ${size}x${size} icon_${size}x${size}.png
done
```

---

✅ 設置完成後，重新編譯項目即可看到新圖標！
