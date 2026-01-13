#!/usr/bin/env python3
"""
OVEREND Adapter Training Script

使用 Apple Foundation Models Adapter Training Toolkit 訓練
專屬於學術文獻管理的 Custom Adapter。

需求:
- Apple Developer Program entitlement
- Python 3.10+
- PyTorch 2.0+
- Adapter Training Toolkit (從 Apple Developer 下載)

使用方式:
    python train_adapter.py --data ../data/training_data.jsonl
"""

import argparse
import json
from pathlib import Path

# 注意: 以下 import 需要安裝 Apple 的 Adapter Training Toolkit
# from adapter_toolkit import TrainingConfig, Trainer, DataLoader


def load_jsonl(path: str) -> list:
    """載入 JSONL 格式的訓練資料"""
    data = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                data.append(json.loads(line))
    return data


def validate_data(data: list) -> bool:
    """驗證資料格式是否正確"""
    for i, item in enumerate(data):
        if 'messages' not in item:
            print(f"錯誤: 第 {i+1} 筆資料缺少 'messages' 欄位")
            return False
        
        messages = item['messages']
        if len(messages) < 2:
            print(f"錯誤: 第 {i+1} 筆資料需要至少 2 則訊息 (user + assistant)")
            return False
        
        roles = [m.get('role') for m in messages]
        if 'user' not in roles or 'assistant' not in roles:
            print(f"錯誤: 第 {i+1} 筆資料需要包含 'user' 和 'assistant' 角色")
            return False
    
    return True


def main():
    parser = argparse.ArgumentParser(description='OVEREND Adapter Training')
    parser.add_argument('--data', type=str, default='../data/training_data.jsonl',
                        help='訓練資料路徑 (JSONL 格式)')
    parser.add_argument('--output', type=str, default='../adapters/overend_literature.fmadapter',
                        help='輸出 Adapter 路徑')
    parser.add_argument('--epochs', type=int, default=3,
                        help='訓練輪數')
    parser.add_argument('--lr', type=float, default=1e-4,
                        help='學習率')
    parser.add_argument('--batch-size', type=int, default=4,
                        help='批次大小')
    parser.add_argument('--lora-rank', type=int, default=32,
                        help='LoRA rank')
    args = parser.parse_args()
    
    # 載入並驗證資料
    print(f"📂 載入訓練資料: {args.data}")
    data = load_jsonl(args.data)
    print(f"   共 {len(data)} 筆訓練範例")
    
    if not validate_data(data):
        print("❌ 資料驗證失敗")
        return
    
    print("✅ 資料驗證通過")
    
    # 訓練配置
    print(f"\n📋 訓練配置:")
    print(f"   Epochs: {args.epochs}")
    print(f"   Learning Rate: {args.lr}")
    print(f"   Batch Size: {args.batch_size}")
    print(f"   LoRA Rank: {args.lora_rank}")
    print(f"   Output: {args.output}")
    
    # TODO: 實際訓練邏輯 (需要 Apple Adapter Training Toolkit)
    # config = TrainingConfig(
    #     dataset_path=args.data,
    #     output_path=args.output,
    #     epochs=args.epochs,
    #     learning_rate=args.lr,
    #     batch_size=args.batch_size,
    #     lora_rank=args.lora_rank
    # )
    # trainer = Trainer(config)
    # trainer.train()
    
    print("\n⚠️  注意: 實際訓練需要 Apple Adapter Training Toolkit")
    print("   請從 Apple Developer 下載並安裝 Toolkit 後再執行訓練")
    
    # 確保輸出目錄存在
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    print("\n🎉 準備工作完成！")


if __name__ == '__main__':
    main()
