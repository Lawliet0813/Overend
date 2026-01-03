//
//  CitationSearchPanel.swift
//  OVEREND
//
//  引用搜尋面板 - 類似 Spotlight 的浮動搜尋框
//

import SwiftUI
import CoreData

struct CitationSearchPanel: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var isPresented: Bool
    var onSelectEntry: (Entry) -> Void
    
    @State private var searchText = ""
    @State private var searchResults: [Entry] = []
    @State private var selectedIndex = 0
    
    // 模擬數據
    private var mockEntries: [Entry] {
        let context = PersistenceController.preview.container.viewContext
        
        let entry1 = Entry(context: context)
        entry1.entryType = "article"
        entry1.fields = ["title": "Deep Learning", "author": "LeCun, Yann and Bengio, Yoshua and Hinton, Geoffrey", "year": "2015"]
        entry1.citationKey = "LeCun2015"
        
        let entry2 = Entry(context: context)
        entry2.entryType = "book"
        entry2.fields = ["title": "Artificial Intelligence: A Modern Approach", "author": "Russell, Stuart and Norvig, Peter", "year": "2020"]
        entry2.citationKey = "Russell2020"
        
        let entry3 = Entry(context: context)
        entry3.entryType = "inproceedings"
        entry3.fields = ["title": "Attention Is All You Need", "author": "Vaswani, Ashish et al.", "year": "2017"]
        entry3.citationKey = "Vaswani2017"
        
        return [entry1, entry2, entry3]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜尋框
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(theme.textMuted)
                
                TextField("搜尋文獻 (作者, 標題, 年份)...", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in performSearch() }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(theme.card)
            
            Divider()
            
            // 結果列表
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, entry in
                            CitationResultRow(
                                entry: entry,
                                isSelected: index == selectedIndex,
                                theme: theme
                            )
                            .onTapGesture {
                                selectEntry(entry)
                            }
                            .onHover { isHovering in
                                if isHovering { selectedIndex = index }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            } else if !searchText.isEmpty {
                Text("無搜尋結果")
                    .foregroundColor(theme.textMuted)
                    .padding(20)
            }
        }
        .frame(width: 500)
        .background(theme.card)
        .cornerRadius(12)
        .shadow(radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        )
        .onAppear {
            performSearch()
        }
    }
    
    private func performSearch() {
        if searchText.isEmpty {
            searchResults = mockEntries
        } else {
            searchResults = mockEntries.filter { entry in
                let title = entry.fields["title"]?.lowercased() ?? ""
                let author = entry.fields["author"]?.lowercased() ?? ""
                let year = entry.fields["year"] ?? ""
                let query = searchText.lowercased()
                
                return title.contains(query) || author.contains(query) || year.contains(query)
            }
        }
        selectedIndex = 0
    }
    
    private func selectEntry(_ entry: Entry) {
        onSelectEntry(entry)
        isPresented = false
    }
}

struct CitationResultRow: View {
    let entry: Entry
    let isSelected: Bool
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            // 圖標
            Image(systemName: iconForType(entry.entryType))
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : theme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fields["title"] ?? "Untitled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
                    .lineLimit(1)
                
                Text(formatAuthorYear(entry))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : theme.textMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "return")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? theme.accent : Color.clear)
        .contentShape(Rectangle())
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "article": return "doc.text"
        case "book": return "book.closed"
        case "inproceedings": return "person.3"
        case "phdthesis", "mastersthesis": return "graduationcap"
        default: return "doc"
        }
    }
    
    private func formatAuthorYear(_ entry: Entry) -> String {
        let author = entry.fields["author"] ?? "Unknown"
        let year = entry.fields["year"] ?? "n.d."
        return "\(author) (\(year))"
    }
}
