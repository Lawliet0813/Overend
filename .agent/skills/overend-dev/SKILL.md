# OVEREND Development Skill

**Version:** 1.0.0  
**Last Updated:** 2026-01-19  
**Purpose:** Comprehensive development guide for the OVEREND macOS academic writing and reference management application

---

## 📋 Project Overview

**OVEREND** is a native macOS application for academic writing and reference management, built with:
- **SwiftUI + AppKit** for the UI layer
- **Rust + UniFFI** for high-performance core functionality
- **Core Data** for local persistence
- **MVVM architecture** for clean separation of concerns

### Key Features
- ✅ BibTeX library management (import/export/edit)
- ✅ Rich text document editor (Word-like experience)
- ✅ PDF/DOCX export with Typst rendering
- ✅ PDF attachment management
- ✅ Full-text search and filtering
- ✅ Hierarchical group organization
- ✅ Citation formatting (APA, MLA, Chicago, IEEE)
- ✅ No login required - fully local application

---

## 🏗️ Architecture

### Technology Stack

```
┌─────────────────────────────────────────────┐
│         OVEREND (Swift/SwiftUI/AppKit)      │
│                                             │
│  Views → ViewModels → Services → Models    │
│                                             │
│  ├─ SwiftUI (macOS 13.0+)                  │
│  ├─ Core Data (persistence)                │
│  ├─ PDFKit (PDF viewing/management)        │
│  └─ NSTextView/AppKit (rich text editing)  │
└──────────────┬──────────────────────────────┘
               │
               │ UniFFI Bridge
               ▼
┌─────────────────────────────────────────────┐
│      OverendCore (Rust Native Library)      │
│                                             │
│  ├─ Typst 0.11 (document compilation)      │
│  ├─ Hayagriva 0.6 (BibTeX/citations)       │
│  └─ UniFFI 0.28 (FFI bindings)             │
└─────────────────────────────────────────────┘
```

### Project Structure

```
OVEREND/
├── OVEREND.xcodeproj/           # Xcode project
├── OVEREND/                     # Main Swift app
│   ├── App/
│   │   └── OVERENDApp.swift    # App entry point
│   ├── Core/
│   │   ├── AppError.swift       # Error types
│   │   ├── AppService.swift     # Core app service
│   │   └── OverendCoreBridge.swift  # Rust bridge
│   ├── Models/                  # Core Data models
│   │   ├── Library.swift
│   │   ├── Entry.swift
│   │   ├── Group.swift
│   │   ├── Attachment.swift
│   │   └── Document.swift
│   ├── ViewModels/              # MVVM view models
│   │   ├── LibraryViewModel.swift
│   │   ├── EntryViewModel.swift
│   │   ├── GroupViewModel.swift
│   │   └── DocumentViewModel.swift
│   ├── Views/                   # SwiftUI views
│   │   ├── Sidebar/
│   │   ├── EntryList/
│   │   ├── EntryDetail/
│   │   └── Editor/
│   ├── Services/                # Business logic
│   │   ├── External/
│   │   │   ├── TypstService.swift      # Typst compilation
│   │   │   └── HayagrivaService.swift  # BibTeX/citations
│   │   ├── BibTeXParser.swift
│   │   ├── ExportService.swift
│   │   └── SearchService.swift
│   ├── Utilities/
│   └── Theme/
│       └── Color+Brand.swift    # Brand colors
├── OverendCore/                 # Rust core library
│   ├── Cargo.toml               # Rust dependencies
│   ├── src/
│   │   ├── lib.rs               # Main API
│   │   ├── world.rs             # Typst compilation
│   │   ├── bibliography.rs      # BibTeX/Hayagriva
│   │   └── errors.rs            # Error types
│   ├── overend_core.udl         # UniFFI interface
│   └── build_xcframework.sh     # Build script
└── OVEREND_WEB/                 # Future web version
```

---

## 🎨 Brand Identity

### Colors
- **Primary (Steel Pen Blue):** `#1A2B3C` - Professional, reliable, depth of knowledge
- **Accent (Inspiring Green):** `#00F5A0` - Innovation, inspiration, vitality
- **Background (Paper Gray):** `#F4F4F9` - Soft paper-like texture

### Design Philosophy
- Clean, minimal, focused on content
- Three-column layout: Sidebar → List → Detail
- macOS-native feel with AppKit integration
- Keyboard-first navigation

---

## 🔧 Development Workflow

### Prerequisites
- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0** or later
- **Swift 5.9** or later
- **Rust 1.70+** (for OverendCore development)
- **Cargo** (Rust package manager)

### Building the App

#### Option 1: Xcode (Recommended)
```bash
# Open project in Xcode
open OVEREND.xcodeproj

# Or via command line
xed OVEREND.xcodeproj

# Build and run: ⌘R
```

#### Option 2: Command Line
```bash
# Build
xcodebuild -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -configuration Debug \
  build

# Run
open build/Debug/OVEREND.app
```

### Building Rust Core

```bash
cd OverendCore

# Build for current architecture
cargo build --release

# Build universal XCFramework (Apple Silicon + Intel)
./build_xcframework.sh

# Run Rust tests
cargo test

# Run Rust benchmarks
cargo bench
```

### Testing

```bash
# Run Swift tests
xcodebuild test -project OVEREND.xcodeproj -scheme OVEREND

# Run specific test
xcodebuild test -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -only-testing:OVERENDTests/LibraryViewModelTests

# Run Rust tests
cd OverendCore && cargo test
```

### Creating DMG Installer

```bash
# Build release version
xcodebuild -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -configuration Release \
  build

# Create DMG
./create_dmg.sh
```

---

## 🔌 Rust Core Integration

### What Rust Handles

1. **Typst Compilation** - Convert Typst markup to PDF
2. **BibTeX Parsing** - Parse .bib files with Hayagriva
3. **Citation Formatting** - Format citations (APA, MLA, Chicago, IEEE)
4. **Bibliography Generation** - Generate reference lists

### Using Rust from Swift

#### Example: Compile Typst to PDF
```swift
import OverendCore

// Via TypstService wrapper
let pdfData = try await TypstService.shared.compile(
    source: """
    = Academic Paper Title
    
    #set text(font: "Noto Serif TC", lang: "zh")
    
    == Abstract
    This is an academic paper written in Typst...
    """,
    fontData: chineseFontData
)

// Direct bridge access
let bridge = OverendCoreBridge.shared
let pdfBytes = try bridge.engine.compileTypst(
    source: typstSource,
    fontData: fontData
)
```

#### Example: Parse BibTeX
```swift
// Via HayagrivaService wrapper
let entries = try HayagrivaService.shared.parseBibtex(bibtexContent)

for entry in entries {
    print("\(entry.key): \(entry.title)")
}
```

#### Example: Format Citations
```swift
let citation = try HayagrivaService.shared.formatCitation(
    bibtexContent: bibtexData,
    citeKeys: ["einstein1905", "newton1687"],
    style: "apa"
)
// Returns: "(Einstein, 1905; Newton, 1687)"
```

### Adding New Rust Functionality

1. **Update Rust code**
   ```rust
   // OverendCore/src/lib.rs
   #[uniffi::export]
   impl OverendEngine {
       pub fn new_function(&self, param: String) -> Result<String, Error> {
           // Implementation
           Ok(result)
       }
   }
   ```

2. **Rebuild XCFramework**
   ```bash
   cd OverendCore
   ./build_xcframework.sh
   ```

3. **Use in Swift** (UniFFI auto-generates bindings)
   ```swift
   let result = try bridge.engine.newFunction(param: "value")
   ```

---

## 📦 Core Data Models

### Entity Relationships

```
Library (1) ──< Entry (*)
Entry (1) ──< Attachment (*)
Entry (1) ──< Document (*)
Library (1) ──< Group (*)
Group (1) ──< Entry (*) [many-to-many]
```

### Key Entities

#### Library
- `id: UUID`
- `name: String`
- `createdAt: Date`
- `bibtexContent: String?` - Cached .bib content

#### Entry (BibTeX Entry)
- `id: UUID`
- `citationKey: String` - e.g., "einstein1905"
- `entryType: String` - e.g., "article", "book"
- `title: String?`
- `author: String?`
- `year: Int?`
- `journal: String?`
- `volume: String?`
- `pages: String?`
- Additional BibTeX fields as JSON

#### Group
- `id: UUID`
- `name: String`
- `parentGroup: Group?` - For hierarchical structure
- `entries: Set<Entry>` - Many-to-many

#### Attachment
- `id: UUID`
- `filename: String`
- `fileURL: URL` - Local file path
- `mimeType: String`
- `fileSize: Int64`

#### Document
- `id: UUID`
- `title: String`
- `content: Data` - NSAttributedString archived
- `exportFormat: String` - "typst", "markdown", etc.

---

## 🎯 Common Development Tasks

### Adding a New View

1. **Create SwiftUI view**
   ```swift
   // OVEREND/Views/MyNewView.swift
   import SwiftUI
   
   struct MyNewView: View {
       @StateObject private var viewModel = MyViewModel()
       
       var body: some View {
           VStack {
               Text("My New View")
           }
           .navigationTitle("My View")
       }
   }
   ```

2. **Add navigation**
   ```swift
   // In parent view
   NavigationLink(destination: MyNewView()) {
       Label("My View", systemImage: "doc")
   }
   ```

### Adding a New Service

1. **Create service class**
   ```swift
   // OVEREND/Services/MyService.swift
   import Foundation
   
   class MyService {
       static let shared = MyService()
       private init() {}
       
       func performTask() async throws -> Result {
           // Implementation
       }
   }
   ```

2. **Use in ViewModel**
   ```swift
   @MainActor
   class MyViewModel: ObservableObject {
       @Published var result: Result?
       
       func loadData() async {
           do {
               result = try await MyService.shared.performTask()
           } catch {
               print("Error: \(error)")
           }
       }
   }
   ```

### Adding a BibTeX Field

1. **Update Entry model**
   ```swift
   // OVEREND/Models/Entry.swift
   extension Entry {
       var doi: String? {
           get { customFields?["doi"] as? String }
           set { 
               if customFields == nil { customFields = [:] }
               customFields?["doi"] = newValue
           }
       }
   }
   ```

2. **Update UI**
   ```swift
   // In EntryDetailView
   TextField("DOI", text: Binding(
       get: { entry.doi ?? "" },
       set: { entry.doi = $0 }
   ))
   ```

### Exporting to PDF

```swift
// Use TypstService
let typstSource = """
= \(document.title)

\(document.content)

== References
\(bibliography.joined(separator: "\n"))
"""

let pdfData = try await TypstService.shared.compile(
    source: typstSource,
    fontData: nil
)

try pdfData.write(to: outputURL)
```

### Exporting to DOCX

```swift
// Use ExportService
let docxData = try await ExportService.shared.exportToDocx(
    document: document,
    bibliography: bibliography
)

try docxData.write(to: outputURL)
```

---

## 🐛 Debugging Tips

### Common Issues

#### Build Failures
```bash
# Clean build folder
rm -rf build/
xcodebuild clean

# Reset package cache
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### Rust Core Not Found
```bash
# Rebuild XCFramework
cd OverendCore
./build_xcframework.sh

# Verify it exists
ls -la OVEREND/Frameworks/OverendCore.xcframework
```

#### Core Data Migration Issues
```swift
// In PersistenceController.swift
// Add for development (destroys data!)
let container = NSPersistentContainer(name: "OVEREND")
container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
```

### Logging

```swift
// Use OSLog for structured logging
import OSLog

let logger = Logger(subsystem: "com.overend.app", category: "Library")

logger.info("Library loaded: \(library.name)")
logger.error("Failed to parse BibTeX: \(error.localizedDescription)")
```

### Performance Profiling

```bash
# Profile with Instruments
xcodebuild -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -configuration Release \
  build

# Open in Instruments (Time Profiler)
instruments -t "Time Profiler" build/Release/OVEREND.app
```

---

## 📚 Key Dependencies

### Swift Packages
- **ZIPFoundation** - For DOCX zip/unzip

### Rust Crates
```toml
[dependencies]
typst = "0.11"              # Typst compiler
typst-pdf = "0.11"          # PDF generation
hayagriva = "0.6"           # BibTeX/bibliography
uniffi = "0.28"             # FFI bindings
serde = { version = "1.0", features = ["derive"] }
thiserror = "1.0"           # Error handling
```

---

## 🚀 Deployment

### Version Bumping

1. Update version in `Info.plist`
2. Update version in `Cargo.toml` (OverendCore)
3. Update `SKILL.md` version header
4. Tag release: `git tag v1.0.1`

### Release Checklist

- [ ] Run all tests (Swift + Rust)
- [ ] Build Release configuration
- [ ] Test on clean macOS installation
- [ ] Verify code signing
- [ ] Create DMG installer
- [ ] Notarize with Apple
- [ ] Update documentation
- [ ] Create release notes

### Code Signing

```bash
# Sign app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  build/Release/OVEREND.app

# Verify signature
codesign -vvv --deep --strict build/Release/OVEREND.app
spctl -a -vvv build/Release/OVEREND.app
```

---

## 📖 Best Practices

### Swift Code Style
- Use Swift naming conventions (lowerCamelCase)
- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI-bound ViewModels
- Avoid force unwrapping - use `if let` or `guard`
- Document public APIs with `///` comments

### Rust Code Style
- Follow Rust naming conventions (snake_case)
- Use `Result<T, E>` for error handling
- Document public APIs with `///` comments
- Run `cargo fmt` before committing
- Run `cargo clippy` to catch issues

### Git Workflow
```bash
# Feature branch
git checkout -b feature/new-citation-style

# Commit with descriptive messages
git commit -m "feat: Add IEEE citation style support"

# Before merging
git rebase main
cargo test && xcodebuild test
```

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## 🔗 Resources

### Official Documentation
- [Typst Documentation](https://typst.app/docs)
- [Hayagriva GitHub](https://github.com/typst/hayagriva)
- [UniFFI Book](https://mozilla.github.io/uniffi-rs/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)

### Learning Resources
- [Rust Book](https://doc.rust-lang.org/book/)
- [Swift.org Guides](https://swift.org/documentation/)

### Internal Documentation
- `README.md` - Project overview
- `Rust核心功能說明.md` - Rust core detailed explanation
- `BUILD_STATUS.md` - Build configuration status
- `UI_FIX_REPORT.md` - UI improvement reports

---

## 🤝 Contributing Guidelines

1. **Read the documentation** - Understand architecture first
2. **Small, focused PRs** - One feature/fix per PR
3. **Write tests** - Unit tests for logic, UI tests for views
4. **Follow style guides** - Use `swiftformat` and `cargo fmt`
5. **Update documentation** - Keep SKILL.md and READMEs current
6. **Performance matters** - Profile before optimizing
7. **Accessibility** - Support VoiceOver and keyboard navigation

---

## 📝 Notes

### Current Development Phase
**Phase 1 - Core Features Complete**
- ✅ BibTeX management (import/export/edit)
- ✅ Three-column UI layout
- ✅ Group management with hierarchy
- ✅ PDF attachment handling
- ✅ Document editor (basic)
- ✅ Typst compilation
- ✅ Citation formatting

**Phase 2 - In Progress**
- 🚧 Advanced rich text editing (styles, formatting)
- 🚧 DOCX export improvements
- 🚧 Full-text search optimization
- 🚧 Online bibliography search integration

### Known Limitations
- DOCX export: Limited formatting support
- Editor: No real-time collaboration
- Search: Basic string matching (no fuzzy search yet)
- Platform: macOS only (iOS/Windows planned)

---

**Last Reviewed:** 2026-01-19  
**Maintainer:** OVEREND Development Team
