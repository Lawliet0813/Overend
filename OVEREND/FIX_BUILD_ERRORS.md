# 解決構建錯誤：完整步驟

## 問題診斷

錯誤訊息：
```
Multiple commands produce '.../CitationPicker.stringsdata'
Multiple commands produce '.../WordStyleEditorView.stringsdata'
```

這表示 **文件在構建階段被重複添加**。

## 解決方案（按順序執行）

### 步驟 1：清理構建緩存

1. 在 Xcode 中，按 **⇧⌘K**（Shift + Command + K）清理構建文件夾
2. 關閉 Xcode
3. 打開終端機，執行：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/OVEREND-*
   ```
4. 重新打開 Xcode

### 步驟 2：檢查 Build Phases 中的重複項

1. 在 Xcode 中，點擊左側的藍色項目圖標
2. 選擇 **OVEREND** target（不是項目本身）
3. 點擊 **Build Phases** 標籤
4. 展開 **Compile Sources** 區域
5. 查找以下文件是否出現多次：
   - `CitationPicker.swift`
   - `WordStyleEditorView.swift`
6. 如果有重複，**選擇重複的項目並按刪除鍵（－按鈕）**
7. 只保留一個

### 步驟 3：搜尋重複文件

1. 在 Xcode 的項目導航器（左側欄）中
2. 點擊搜尋框（頂部）
3. 搜尋 `CitationPicker.swift`
4. 如果看到多個結果：
   - 右鍵點擊其中一個
   - 選擇 **Show in Finder**
   - 檢查是否真的有多個文件
   - 如果有，刪除重複的（保留在正確位置的那個）

5. 對 `WordStyleEditorView.swift` 重複同樣的步驟

### 步驟 4：使用 File Inspector 檢查 Target Membership

1. 在項目導航器中選擇 `CitationPicker.swift`
2. 打開右側的 **File Inspector**（最右邊的面板，或按 ⌥⌘1）
3. 查看 **Target Membership** 區域
4. **確保只勾選了一個 OVEREND target**（不要重複勾選）
5. 對 `WordStyleEditorView.swift` 重複同樣的步驟

### 步驟 5：修改構建設置（如果上述步驟無效）

1. 選擇項目（藍色圖標）
2. 選擇 **OVEREND** target
3. 點擊 **Build Settings** 標籤
4. 在搜尋框中輸入 `ENABLE_PREVIEWS`
5. 如果找到，設為 **NO**（臨時禁用預覽）
6. 嘗試構建

### 步驟 6：終極方案 - 手動移除並重新添加文件

如果以上都無效：

1. 在項目導航器中，右鍵點擊 `CitationPicker.swift`
2. 選擇 **Delete**
3. 選擇 **Remove Reference**（不要選 Move to Trash）
4. 在 Finder 中找到該文件（它還在那裡）
5. 將文件拖回 Xcode 項目導航器
6. 確保勾選正確的 target
7. 對 `WordStyleEditorView.swift` 重複同樣的步驟

### 步驟 7：構建項目

按 **⌘B** 構建項目

## 預覽已暫時禁用

為了解決這個問題，我已經**註解掉了兩個文件中的 `#Preview` 代碼**：
- `CitationPicker.swift` 
- `WordStyleEditorView.swift`

這不會影響應用程式的功能，只是在 Xcode 中無法使用預覽功能。

## 如果仍然失敗

請在終端機執行以下命令，並將輸出發給我：

```bash
cd /path/to/OVEREND
find . -name "CitationPicker.swift" -o -name "WordStyleEditorView.swift"
```

這會顯示所有同名文件的位置。

## 常見原因

這個錯誤通常由以下原因引起：

1. ✅ **文件被意外複製** - 在 Finder 中複製文件而非 Xcode
2. ✅ **Git 合併衝突** - 合併時產生重複文件
3. ✅ **多次添加到 target** - 文件在 Build Phases 中被列出多次
4. ✅ **Xcode 索引損壞** - DerivedData 緩存問題

## 預防措施

1. 永遠在 Xcode 內複製文件（Edit → Duplicate）
2. 添加文件時確保只勾選需要的 target
3. 定期清理 DerivedData
4. 使用有意義的 Preview 名稱

---

## 快速檢查清單

- [ ] 清理構建文件夾（⇧⌘K）
- [ ] 刪除 DerivedData
- [ ] 檢查 Build Phases → Compile Sources
- [ ] 搜尋重複文件
- [ ] 檢查 Target Membership
- [ ] 重新構建（⌘B）

構建成功後請回報！🎉
