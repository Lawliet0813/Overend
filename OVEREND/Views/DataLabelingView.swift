import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// 訓練資料標註工具
struct DataLabelingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    @State private var currentIndex = 0
    @State private var labeledData: [(text: String, label: String)] = []
    @State private var showExport = false
    
    var currentEntry: Entry? {
        guard currentIndex < entries.count else { return nil }
        return entries[currentIndex]
    }
    
    var progress: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(currentIndex) / Double(entries.count)
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // 進度條
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            // 標題列
            HStack {
                Text("標註訓練資料")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(currentIndex + 1) / \(entries.count)")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // 文獻資訊顯示
            if let entry = currentEntry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        LabelingInfoRow(label: "標題", value: entry.title)
                        LabelingInfoRow(label: "作者", value: entry.author)
                        LabelingInfoRow(label: "期刊", value: entry.fields["journal"] ?? "無")
                        LabelingInfoRow(label: "會議", value: entry.fields["booktitle"] ?? "無")
                        LabelingInfoRow(label: "年份", value: entry.year)
                        
                        let bibtex = entry.bibtexRaw
                        if !bibtex.isEmpty {
                            VStack(alignment: .leading) {
                                Text("BibTeX 類型：")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(extractBibTeXType(bibtex))
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding()
                
                // 標籤按鈕
                VStack(spacing: 12) {
                    Text("請選擇文獻類型：")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        LabelButton(title: "期刊論文", icon: "doc.text", color: .blue) {
                            labelCurrent("Journal Article")
                        }
                        
                        LabelButton(title: "會議論文", icon: "person.3", color: .green) {
                            labelCurrent("Conference Paper")
                        }
                    }
                    
                    HStack(spacing: 12) {
                        LabelButton(title: "學位論文", icon: "graduationcap", color: .orange) {
                            labelCurrent("Thesis")
                        }
                        
                        LabelButton(title: "書籍章節", icon: "book.closed", color: .purple) {
                            labelCurrent("Book Chapter")
                        }
                    }
                    
                    Button(action: skipCurrent) {
                        Label("跳過", systemImage: "forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                }
                .padding()
                
            } else {
                // 完成標註
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("標註完成！")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("已標註 \(labeledData.count) 筆資料")
                        .foregroundColor(.secondary)
                    
                    Button(action: { showExport = true }) {
                        Label("匯出 CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $showExport) {
            ExportSheet(data: labeledData)
        }
    }
    
    
    // MARK: - 方法
    
    private func labelCurrent(_ label: String) {
        guard let entry = currentEntry else { return }
        
        let text = buildTrainingText(from: entry)
        labeledData.append((text: text, label: label))
        
        currentIndex += 1
    }
    
    private func skipCurrent() {
        currentIndex += 1
    }
    
    private func buildTrainingText(from entry: Entry) -> String {
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
    
    private func extractBibTeXType(_ bibtex: String) -> String {
        if let match = bibtex.range(of: "@\\w+", options: .regularExpression) {
            return String(bibtex[match])
        }
        return "未知"
    }
}


// MARK: - 子元件

struct LabelingInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

struct LabelButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct ExportSheet: View {
    let data: [(text: String, label: String)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("匯出訓練資料")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("儲存為 CSV") {
                exportCSV()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("取消") { dismiss() }
        }
        .padding(30)
        .frame(width: 400, height: 200)
    }
    
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "labeled_training_data.csv"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            var csv = "text,label\n"
            for item in data {
                let escapedText = item.text
                    .replacingOccurrences(of: "\"", with: "\"\"")
                    .replacingOccurrences(of: "\n", with: " ")
                csv += "\"\(escapedText)\",\"\(item.label)\"\n"
            }
            
            try? csv.write(to: url, atomically: true, encoding: .utf8)
            dismiss()
        }
    }
}


#Preview {
    DataLabelingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
