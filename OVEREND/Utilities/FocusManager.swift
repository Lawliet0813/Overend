//
//  FocusManager.swift
//  OVEREND
//
//  全局焦點管理
//

import SwiftUI
import Combine

enum FocusLocation {
    case none
    case newLibraryInput
    case searchField
}

class FocusManager: ObservableObject {
    @Published var currentFocus: FocusLocation = .none

    static let shared = FocusManager()

    private init() {}

    func setFocus(to location: FocusLocation) {
        currentFocus = location
    }

    func clearFocus() {
        currentFocus = .none
    }
}
