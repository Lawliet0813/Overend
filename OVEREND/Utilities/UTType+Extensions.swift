//
//  UTType+Extensions.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import UniformTypeIdentifiers

extension UTType {
    static var bibtex: UTType {
        UTType(filenameExtension: "bib") ?? UTType(importedAs: "org.bibtex.file")
    }
}
