//
//  MaterialIcon.swift
//  OVEREND
//
//  臨時修復：MaterialIcon 組件遺失
//

import SwiftUI

/// Material Design 風格圖示組件（簡化版）
struct MaterialIcon: View {
    let name: String
    let size: CGFloat
    let color: Color

    init(name: String, size: CGFloat = 24, color: Color = .primary) {
        self.name = name
        self.size = size
        self.color = color
    }

    var body: some View {
        // 使用 SF Symbols 作為降級方案
        Image(systemName: symbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(color)
    }

    /// 將 Material Icon 名稱映射到 SF Symbols
    private var symbolName: String {
        switch name.lowercased() {
        case "add": return "plus"
        case "search": return "magnifyingglass"
        case "close": return "xmark"
        case "menu": return "line.3.horizontal"
        case "arrow_back": return "chevron.left"
        case "arrow_forward": return "chevron.right"
        case "arrow_drop_down": return "chevron.down"
        case "arrow_drop_up": return "chevron.up"
        case "check": return "checkmark"
        case "edit": return "pencil"
        case "delete": return "trash"
        case "star": return "star"
        case "star_border": return "star"
        case "favorite": return "heart"
        case "favorite_border": return "heart"
        case "settings": return "gear"
        case "home": return "house"
        case "person": return "person"
        case "info": return "info.circle"
        case "warning": return "exclamationmark.triangle"
        case "error": return "exclamationmark.circle"
        case "help": return "questionmark.circle"
        case "download": return "arrow.down.circle"
        case "upload": return "arrow.up.circle"
        case "share": return "square.and.arrow.up"
        case "more_vert": return "ellipsis"
        case "more_horiz": return "ellipsis"
        case "refresh": return "arrow.clockwise"
        case "visibility": return "eye"
        case "visibility_off": return "eye.slash"
        case "lock": return "lock"
        case "lock_open": return "lock.open"
        case "folder": return "folder"
        case "folder_open": return "folder.badge.plus"
        case "file": return "doc"
        case "attach_file": return "paperclip"
        case "link": return "link"
        case "code": return "chevron.left.forwardslash.chevron.right"
        case "copy": return "doc.on.doc"
        case "paste": return "doc.on.clipboard"
        case "cut": return "scissors"
        case "save": return "square.and.arrow.down"
        case "print": return "printer"
        case "email": return "envelope"
        case "phone": return "phone"
        case "calendar": return "calendar"
        case "clock": return "clock"
        case "tag": return "tag"
        case "bookmark": return "bookmark"
        case "filter": return "line.3.horizontal.decrease.circle"
        case "sort": return "arrow.up.arrow.down"
        case "expand_more": return "chevron.down"
        case "expand_less": return "chevron.up"
        case "play_arrow": return "play"
        case "pause": return "pause"
        case "stop": return "stop"
        case "volume_up": return "speaker.wave.3"
        case "volume_off": return "speaker.slash"
        default: return "questionmark.square.dashed"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MaterialIcon(name: "add", size: 24, color: .blue)
        MaterialIcon(name: "search", size: 24, color: .green)
        MaterialIcon(name: "settings", size: 24, color: .orange)
    }
    .padding()
}
