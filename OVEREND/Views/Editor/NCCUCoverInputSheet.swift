//
//  NCCUCoverInputSheet.swift
//  OVEREND
//
//  政大論文封面資訊輸入表單
//

import SwiftUI

struct NCCUCoverInfo {
    var thesisTitleCH: String = ""
    var thesisTitleEN: String = ""
    var studentName: String = ""
    var advisorName: String = ""
    var department: String = ""
    var degree: String = "碩士"
    var year: String = ""
    var month: String = ""
}

struct NCCUCoverInputSheet: View {
    @Binding var isPresented: Bool
    var onInsert: (NCCUCoverInfo) -> Void
    
    @State private var info = NCCUCoverInfo()
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("插入政大論文封面")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.elevated)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 系所資訊
                    SectionView(title: "系所資訊") {
                        TextField("系所名稱 (例如：資訊科學系)", text: $info.department)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("學位別", selection: $info.degree) {
                            Text("碩士").tag("碩士")
                            Text("博士").tag("博士")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 論文題目
                    SectionView(title: "論文題目") {
                        TextField("中文題目", text: $info.thesisTitleCH)
                            .textFieldStyle(.roundedBorder)
                        TextField("英文題目", text: $info.thesisTitleEN)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 人員資訊
                    SectionView(title: "人員資訊") {
                        TextField("研究生姓名", text: $info.studentName)
                            .textFieldStyle(.roundedBorder)
                        TextField("指導教授姓名 (例如：王大明 博士)", text: $info.advisorName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 日期
                    SectionView(title: "口試通過日期") {
                        HStack {
                            TextField("中華民國年份", text: $info.year)
                                .textFieldStyle(.roundedBorder)
                            Text("年")
                            TextField("月份", text: $info.month)
                                .textFieldStyle(.roundedBorder)
                            Text("月")
                        }
                    }
                }
                .padding()
            }
            
            // Footer
            HStack {
                Spacer()
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("插入封面") {
                    onInsert(info)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(info.thesisTitleCH.isEmpty || info.studentName.isEmpty)
            }
            .padding()
            .background(theme.elevated)
        }
        .frame(width: 500, height: 600)
        .background(theme.background)
        .onAppear {
            // Set default date
            let calendar = Calendar.current
            let date = Date()
            let year = calendar.component(.year, from: date) - 1911
            let month = calendar.component(.month, from: date)
            info.year = "\(year)"
            info.month = "\(month)"
        }
    }
}

private struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    @EnvironmentObject var theme: AppTheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)
            
            content
        }
        .padding()
        .background(theme.elevated.opacity(0.3))
        .cornerRadius(8)
    }
}
