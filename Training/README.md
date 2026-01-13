# OVEREND Adapter Training

本目錄用於訓練 Apple Foundation Models 的 Custom Adapter。

## 目錄結構

```
Training/
├── data/                    # 訓練資料
│   ├── training_data.jsonl  # 主訓練資料
│   └── validation.jsonl     # 驗證資料
├── scripts/                 # 訓練腳本
│   └── train_adapter.py
├── adapters/               # 輸出的 Adapter 檔案
│   └── overend_literature.fmadapter
└── README.md
```

## 訓練資料格式

```jsonl
{"messages": [{"role": "user", "content": "任務描述..."}, {"role": "assistant", "content": "期望輸出..."}]}
```

## 使用方式

1. 準備訓練資料至 `data/training_data.jsonl`
2. 執行 `python scripts/train_adapter.py`
3. 產出的 Adapter 會在 `adapters/` 目錄
