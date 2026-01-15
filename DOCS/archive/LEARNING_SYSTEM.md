# OVEREND 個人化學習系統架構文件

## 1. 系統概述

OVEREND 的個人化學習系統旨在透過分析使用者的行為模式（如標籤使用、分組習慣、文獻評分），提供客製化的建議，從而提升文獻管理效率。本系統強調「隱私優先」與「本機運算」，所有學習與預測過程皆在使用者裝置上完成。

## 2. 系統架構

系統分為三個主要階段：

* **Phase 1: 基礎學習框架 (Tag Learning)** - 專注於標籤預測。
* **Phase 2: 進階學習功能 (Group Recommendation)** - 專注於分組建議與準確度追蹤。
* **Phase 3: Core ML 整合 (Importance & Citation)** - 引入機器學習模型進行重要性評分與引用推薦。

### 2.1 數據流

1. **輸入 (Input)**: 使用者行為（新增標籤、移動群組、評分）。
2. **處理 (Processing)**: `LearningService` 提取特徵（關鍵字、TF-IDF 向量）。
3. **儲存 (Storage)**: 學習數據儲存於 `UserDefaults` (Phase 1) 或 Core Data (Phase 2+)。
4. **輸出 (Output)**: 預測結果（建議標籤、建議群組）顯示於 UI。
5. **反饋 (Feedback)**: 使用者接受或拒絕建議，回饋至系統以修正模型。

## 3. Phase 1: 標籤學習系統 (Tag Learning System)

### 3.1 核心算法：關鍵字頻率統計

不使用複雜的神經網絡，而是採用直觀且高效的詞頻統計法。

#### 訓練過程 (Training)

當使用者為一篇文獻 `E` 添加標籤 `T` 時：

1. 取得文獻標題 `Title`。
2. **關鍵字提取 (Keyword Extraction)**:
    * 將 `Title` 轉為小寫。
    * 移除標點符號。
    * 移除停用詞 (Stop Words)（如 "the", "and", "of", "in" 等）。
    * 移除長度 < 3 的短詞。
    * 結果為關鍵字列表 `[K1, K2, ...]`。
3. **權重更新 (Weight Update)**:
    * 對於每個關鍵字 `Ki`，在標籤 `T` 的模型中增加計數。
    * 記錄 `T` 的總使用次數。

#### 預測過程 (Prediction)

當需要為新文獻（標題 `NewTitle`）預測標籤時：

1. 提取 `NewTitle` 的關鍵字 `[NK1, NK2, ...]`。
2. 對於系統中已知的每個標籤 `T`，計算得分：
    * `Score(T) = Σ (Weight(NK_i, T))`
    * 其中 `Weight(NK_i, T)` 是關鍵字 `NK_i` 在標籤 `T` 中出現的頻率。
3. **排序與過濾**:
    * 按 `Score` 降序排列。
    * 過濾掉 `Score` 過低的標籤。
    * 取前 3 名作為建議。

### 3.2 數據結構 (Data Structures)

```swift
struct LearningData: Codable {
    // 標籤模型： [標籤名: [關鍵字: 出現次數]]
    var tagModels: [String: [String: Int]]
    
    // 標籤總使用次數： [標籤名: 次數]
    var tagUsageCounts: [String: Int]
    
    // 總互動次數（用於計算成熟度）
    var totalInteractions: Int
    
    // 預測統計
    var totalPredictions: Int
    var acceptedPredictions: Int
}
```

### 3.3 隱私與數據管理

* **儲存位置**: 本機 `UserDefaults` (Key: `OverendLearningData`)。
* **匯出**: 支援匯出為 JSON 格式供使用者檢視。
* **清除**: 使用者可隨時清除所有學習數據，系統將重置為初始狀態。
* **不收集**: 不會收集文獻的具體內容（PDF 內文），僅使用標題進行特徵提取。

## 4. 未來擴充 (Phase 2 & 3)

* **TF-IDF**: 用於計算文獻相似度，支援分組建議。
* **Core ML**: 訓練 Random Forest 或其他分類器，用於預測文獻重要性（星等）。
