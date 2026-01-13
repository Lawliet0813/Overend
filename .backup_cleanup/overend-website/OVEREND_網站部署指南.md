# OVEREND Beta 網站部署指南

## ✅ 網站已完成！

所有檔案已準備完成，位於 `/mnt/user-data/outputs/overend-website/`

### 📁 檔案清單
- `index.html` - 主頁面 (13KB)
- `style.css` - 樣式表 (11KB)
- `script.js` - JavaScript 功能 (3KB)
- `vercel.json` - Vercel 設定
- `package.json` - 專案設定
- `README.md` - 說明文件

---

## 🚀 方法一：Vercel CLI 部署（最快）

### 步驟：

1. **安裝 Vercel CLI**（如果尚未安裝）
```bash
npm install -g vercel
```

2. **進入網站目錄**
```bash
cd /mnt/user-data/outputs/overend-website
```

3. **登入 Vercel**
```bash
vercel login
```

4. **部署**
```bash
vercel --prod
```

5. **完成！**
系統會自動部署並提供網址，類似：
- `https://overend-beta.vercel.app`

---

## 🌐 方法二：Vercel Dashboard 部署

### 步驟：

1. **下載網站檔案**
   - 從 Claude 下載整個 `overend-website` 資料夾

2. **上傳到 GitHub**（選擇性，但推薦）
   ```bash
   cd overend-website
   git init
   git add .
   git commit -m "Initial commit: OVEREND Beta Website"
   git remote add origin https://github.com/你的帳號/overend-beta.git
   git push -u origin main
   ```

3. **前往 Vercel Dashboard**
   - 訪問 https://vercel.com/dashboard
   - 點擊 "Add New Project"

4. **選擇部署方式**
   
   **方式 A：從 GitHub 部署（推薦）**
   - 選擇你的 GitHub repository
   - Vercel 會自動偵測設定
   - 點擊 "Deploy"

   **方式 B：直接上傳檔案**
   - 選擇 "Import from file system"
   - 上傳整個 overend-website 資料夾
   - 點擊 "Deploy"

5. **設定專案**
   - Project Name: `overend-beta`
   - Framework Preset: Other
   - Root Directory: `./`
   - Build Command: 留空
   - Output Directory: `./`

6. **完成！**
   網站會自動部署並取得網址

---

## 🎨 網站特色

### 設計元素
- ✨ Liquid Glass 視覺風格
- 🌓 深色主題（符合 OVEREND 品牌）
- 📱 完整響應式設計
- 🎬 流暢動畫效果

### 區塊內容
1. **Hero 區塊** - 品牌宣言與 CTA
2. **為什麼選擇** - EndNote vs OVEREND 比較
3. **核心功能** - 6 大功能卡片
4. **開發路線圖** - 時間軸展示進度
5. **Beta 測試** - 申請表單與權益說明
6. **頁尾** - 聯絡資訊與連結

### 技術亮點
- 純 HTML/CSS/JavaScript（無框架依賴）
- SEO 友善的語意化標籤
- 平滑滾動與進入動畫
- 性能優化（<30KB 總大小）

---

## 📧 自訂設定

### 修改聯絡 Email
在 `index.html` 中搜尋 `contact@overend.tw` 並替換為你的 Email。

### 調整品牌色
在 `style.css` 開頭的 `:root` 變數中修改：
```css
--primary-color: #00D97E;  /* 主色調 */
--secondary-color: #667eea; /* 次要色 */
```

### 更新內容
直接編輯 `index.html` 中的文字內容。

---

## 🔧 本地測試

部署前可以先在本地測試：

```bash
cd /mnt/user-data/outputs/overend-website
python3 -m http.server 8000
```

然後在瀏覽器開啟 http://localhost:8000

---

## 📊 部署後檢查清單

- [ ] 網站可正常訪問
- [ ] 所有區塊正常顯示
- [ ] 導航連結正常運作
- [ ] 手機版顯示正常
- [ ] Email 連結測試
- [ ] 動畫效果流暢

---

## 🎯 下一步建議

1. **自訂網域**
   - 在 Vercel Dashboard 中設定自訂網域
   - 建議使用：`beta.overend.tw` 或 `www.overend.tw`

2. **Google Analytics**
   - 加入追蹤碼監控流量

3. **SEO 優化**
   - 提交 sitemap 到 Google Search Console
   - 設定 Open Graph 標籤

4. **未來功能**
   - Beta 測試申請表單（可使用 Google Forms 或 Typeform）
   - 加入產品截圖或展示影片
   - 整合 Newsletter 訂閱

---

## ❓ 常見問題

### Q: 部署後顯示 404？
A: 確認 `vercel.json` 檔案存在且內容正確。

### Q: CSS 樣式沒套用？
A: 檢查 `index.html` 中 `<link rel="stylesheet" href="style.css">` 路徑是否正確。

### Q: 如何更新網站？
A: 修改檔案後重新執行 `vercel --prod` 即可。

---

## 📞 需要協助？

如有問題，可以：
1. 查看 Vercel 官方文件：https://vercel.com/docs
2. 聯絡我繼續協助調整

---

**祝部署順利！🎉**
