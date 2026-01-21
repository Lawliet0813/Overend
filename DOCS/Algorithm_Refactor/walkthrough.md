# Walkthrough - Fixing Test Failures & Core Data Crash

We successfully resolved a series of blocking test failures and a critical Core Data crash that was preventing the test suite from execution.

## Key Issues Resolved

### 1. Core Data Crash (`A fetch request must have an entity`)

**Symptoms**: `DocumentDomainTests` and `LearningServiceTests` crashed with `NSInvalidArgumentException`.
**Root Cause**: The singleton `AgentAutoTrigger` was automatically initializing `PersistenceController.shared` (using the main app's Core Data stack) during tests. This conflicted with the test environment, especially when tests were using an in-memory store or mocking.
**Fix**:

- Modified `AgentAutoTrigger.init` to detect `XCTestConfigurationFilePath` and disable automatic analysis during tests.
- Modified `LiteratureAgent` to support Dependency Injection for `EntryRepository`, allowing tests to inject a repository connected to the in-memory `CoreDataTestHelper` instead of the main app's context.

### PDF Metadata Consolidation & Advanced Algorithms

- **Enhancement**: Ported advanced extraction logic from legacy `External/DOIService` to the unified `PDFMetadataExtractor`.
  - Added **ROC Year (民國年)** support.
  - Added **Chinese Author Name** formatting.
  - Upgraded **DOI Regex** patterns.
  - Upgraded **CrossRef Parser** with detailed field mapping (Volume, Issue, etc.).
- **New Feature: Advanced Rule-Based Extraction**:
  - Implemented **Strategy 2: Weighted Scoring System**: Analyzes font size, position (Golden Zone), and keywords to identify titles with high precision.
  - Implemented **Strategy 3: Relative Position Anchoring**: Specifically targets Thesis formats by detecting "Graduate Student" / "Advisor" anchors to infer Title and Author locations.
- **Cleanup**: Deleted `Services/External/DOIService.swift` to eliminate duplicate logic.
- **Normalization**: `PDFService` now focuses on file management, while `LiteratureAgent` (via `PDFMetadataExtractor`) handles all metadata intelligence.

### 2. BibTeX Parser Failure (`testParseWithNestedBraces`)

**Symptoms**: `BibTeXParserTests` failed to correctly parse fields with nested curly braces (e.g., `{LaTeX}`).
**Root Cause**: The regex pattern used for parsing BibTeX entries only supported one level of non-nested braces.
**Fix**: Updated the regex in `BibTeXParser.swift` to support up to 3 levels of nested braces, correctly handling complex BibTeX values.

### 3. Citation Service Failure (`CitationServiceTests`)

**Symptoms**: `CitationServiceTests` failed assertions for APA author formatting.
**Root Cause**: The `formatSingleAuthorAPA` function did not correctly handle "Last, First" format when a comma was present.
**Fix**: Added logic to detect commas and correctly parse "Last, First" names, ensuring correct APA output (e.g., "Doe, J.").

### 4. Learning Service Concurrency

**Symptoms**: Potential race conditions in `LearningServiceTests`.
**Fix**: Marked `LearningServiceTests` with `@MainActor` to ensure thread-safe access to the `@Published` properties of `LearningService` which are updated on the Main Actor.

## Verification Results

All tests passed successfully using `xcodebuild test -scheme OVEREND`.

| Test Suite | Status | Notes |
|------------|--------|-------|
| `CitationServiceTests` | ✅ PASS | APA formatting verified |
| `BibTeXParserTests` | ✅ PASS | Nested braces handled |
| `LearningServiceTests` | ✅ PASS | Core Data crash resolved |
| `LiteratureAgentTests` | ✅ PASS | Duplicate finding logic verified with mock data |
| `DocumentDomainTests` | ✅ PASS | No longer blocked by Core Data crash |

## Code Changes

### `AgentAutoTrigger.swift`

Disabling auto-trigger in tests:

```swift
    private init() {
        // Detect if running in Unit Tests
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        if isTesting {
            isAutoAnalysisEnabled = false
            return
        }
        ...
```

### `LiteratureAgent.swift`

Added Dependency Injection:

```swift
    init(..., entryRepository: EntryRepositoryProtocol = EntryRepository()) {
        self.entryRepository = entryRepository
        ...
    }
```

### `BibTeXParser.swift`

Improved Regex:

```swift
let pattern = #"@(\w+)\s*\{\s*([^,\s]+)\s*,\s*((?:[^{}]|\{(?:[^{}]|\{(?:[^{}]|\{[^}]*\})*\})*\})*)\s*\}"#
```
