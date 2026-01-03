//
//  OnlineSearchView.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import SwiftUI

struct OnlineSearchView: View {
    @StateObject private var viewModel = OnlineSearchViewModel()
    @EnvironmentObject var entryViewModel: EntryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Picker("資料庫", selection: $viewModel.selectedDatabase) {
                    Text("華藝線上圖書館 (Airiti)").tag("Airiti")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
                
                TextField("搜尋論文...", text: $viewModel.query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                
                Button(action: {
                    Task {
                        await viewModel.search()
                    }
                }) {
                    Label("搜尋", systemImage: "magnifyingglass")
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            
            // Results
            if viewModel.isLoading {
                ProgressView("搜尋中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.results) { result in
                    SearchResultRow(result: result) {
                        Task {
                            await viewModel.importResult(result, to: entryViewModel)
                        }
                        // Optional: Show feedback
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("線上搜尋")
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let onImport: () -> Void
    @State private var isImported = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                Text(result.formattedAuthors)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text(result.year)
                    Text("•")
                    Text(result.publication)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                onImport()
                isImported = true
            }) {
                if isImported {
                    Label("已匯入", systemImage: "checkmark")
                } else {
                    Label("匯入", systemImage: "square.and.arrow.down")
                }
            }
            .disabled(isImported)
        }
        .padding(.vertical, 4)
    }
}
