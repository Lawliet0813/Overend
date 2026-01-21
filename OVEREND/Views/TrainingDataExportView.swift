import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// 匯出訓練資料工具
class TrainingDataExporter {
    
    /// 從 Core Data 匯出文獻資料為 CSV
    static func exportToCSV(context: NSManagedObjectContext, outputURL: URL) throws {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let entries = try context.fetch(fetchRequest)
        
        var csvContent = "text,label\n" // CSV 標題
        
        for entry in entries {
            // 組合文獻描述文字
            let text = buildDescriptionText(from: entry)
            
            // 從 BibTeX 類型推斷標籤（需要手動校正）
            let label = inferLabelFromBibTeX(entry.bibtexRaw)
            
            // 轉義 CSV 特殊字元
            let escapedText = escapeCSV(text)
            
            csvContent += "\"\(escapedText)\",\"\(label)\"\n"
        }
        
        // 寫入檔案
        try csvContent.write(to: outputURL, atomically: true, encoding: .utf8)
        
        print("✅ 已匯出 \(entries.count) 筆資料至 \(outputURL.path)")
    }
    
    
    // MARK: - 輔助方法
    
    /// 建立文獻描述文字（用於訓練）
    private static func buildDescriptionText(from entry: Entry) -> String {
        var parts: [String] = []
        
        let title = entry.title
        if !title.isEmpty && title != "Untitled" {
            parts.append(title)
        }
        
        let author = entry.author
        if !author.isEmpty && author != "Unknown" {
            parts.append(author)
        }
        
        if let journal = entry.fields["journal"], !journal.isEmpty {
            parts.append("發表於《\(journal)》")
        }
        
        if let booktitle = entry.fields["booktitle"], !booktitle.isEmpty {
            parts.append("收錄於《\(booktitle)》")
        }
        
        if let y = Int(entry.year), y > 0 {
            parts.append("\(y)年")
        }
        
        return parts.joined(separator: "，")
    }
    
    
    /// 從 BibTeX 類型推斷標籤（粗略分類）
    private static func inferLabelFromBibTeX(_ bibtex: String) -> String {
        let lowercased = bibtex.lowercased()
        
        if lowercased.contains("@article") {
            return "Journal Article"
        } else if lowercased.contains("@inproceedings") || lowercased.contains("@conference") {
            return "Conference Paper"
        } else if lowercased.contains("@phdthesis") || lowercased.contains("@mastersthesis") {
            return "Thesis"
        } else if lowercased.contains("@incollection") || lowercased.contains("@inbook") {
            return "Book Chapter"
        } else {
            return "Unknown" // 需要手動標註
        }
    }
    
    
    /// 轉義 CSV 特殊字元
    private static func escapeCSV(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\"", with: "\"\"") // 雙引號轉義
            .replacingOccurrences(of: "\n", with: " ")    // 移除換行
            .replacingOccurrences(of: "\r", with: " ")    // 移除回車
    }
}


// MARK: - SwiftUI 測試介面

struct TrainingDataExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isExporting = false
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("匯出訓練資料")
                .font(.title)
                .fontWeight(.bold)
            
            Text("從現有文獻庫匯出 CSV 格式訓練資料")
                .foregroundColor(.secondary)
            
            Button(action: exportData) {
                Label(isExporting ? "匯出中..." : "開始匯出", 
                      systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isExporting)
            
            if !message.isEmpty {
                Text(message)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(30)
        .frame(width: 500, height: 300)
    }
    
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "training_data.csv"
        panel.message = "儲存訓練資料"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            isExporting = true
            message = ""
            
            do {
                try TrainingDataExporter.exportToCSV(
                    context: viewContext,
                    outputURL: url
                )
                message = "✅ 匯出成功！請手動校正標籤"
                
            } catch {
                message = "❌ 匯出失敗：\(error.localizedDescription)"
            }
            
            isExporting = false
        }
    }
}


#Preview {
    TrainingDataExportView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
