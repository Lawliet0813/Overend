# Algorithm Version Implementation Plan

This plan details the transformation of OVEREND from an AI-dependent application to a pure, offline-first algorithm-driven application.

## Goal Description

Replace all generative AI features with deterministic, rule-based, and statistical algorithms to ensure offline capability, privacy, zero cost, and predictable performance.

## User Review Required

- **Terminology Dictionary**: Need a list of "Colloquial -> Academic" terms for the Writing Assistant.
- **Stopwords**: Confirm language support (English/Chinese).
- **CrossRef Usage**: Confirm if CrossRef metadata lookup is permitted (API, not AI) under "offline" constraints. (Assumed Permitted as hybrid/metadata).

## Proposed Changes

### Core NLP Services

Create a new `Services/Algorithm` directory.

#### [NEW] `NLPService.swift`

- Implement robust tokenization using `NaturalLanguage` framework (Standard on macOS).
- Implement TF-IDF calculation logic.
- Implement Cosine Similarity function.
- Implement Stopword removal (English + Chinese).

#### [NEW] `TextSummarizer.swift`

- Implement "Extractive Summarization".
- Score sentences based on: Position, Length, TF-IDF sum, Keyword presence.
- Return top N sentences.

#### [NEW] `KeywordExtractor.swift`

- Extract top N words/phrases with highest TF-IDF scores.

### PDF Metadata Extraction

Refactor `AIService` or create `PDFMetadataService`.

#### [NEW] `PDFMetadataExtractor.swift`

- Layer 1: Read `PDFDocument.documentAttributes`.
- Layer 2: Regex parsing of first page (Title, Author, Journal, Year, DOI).
- Layer 3: CrossRef API lookup (using DOI if found).

### Literature Agent Refactoring

Modify `LiteratureAgent.swift` to use `NLPService` and `AlgorithmService` instead of `UnifiedAIService`.

#### `LiteratureAgent.swift`

- **Summarization**: Call `TextSummarizer`.
- **Classification**: Call `NLPService` to match keywords against predefined category dictionaries.
- **Recommendation**: Call `NLPService` to compute Cosine Similarity between entries.

### Writing Assistant Refactoring

### Writing Assistant Refactoring

[COMPLETED] Modified `WritingAIDomain.swift` to include Algorithm Services.

#### [NEW] `ToneAdjuster.swift` (Merged into `WritingAIDomain.swift`)

- Rule-based string replacement using a dictionary of [Colloquial: Academic] pairs.
- Regex handling for sentence restructuring hints.

#### [NEW] `ContentExpander.swift` (Merged into `WritingAIDomain.swift`)

- Logic to insert starter phrases based on sentence type (Argument/Evidence).
- Append transition words.

#### [NEW] `ContentSimplifier.swift` (Merged into `WritingAIDomain.swift`)

- Removal of redundant words ("Redundant Words List").
- Simplification of complex phrases.

## Verification Plan

### Automated Tests

- [x] Create `NLPServiceTests.swift`: Verify TF-IDF and Tokenization.
- [x] Create `TextSummarizerTests.swift`: Verify summary ratio and deterministic output.
- [x] Create `AlgorithmBenchmarkTests.swift`: Measure performance (ensure < 100ms for typical tasks).

### Manual Verification

1. [x] **PDF Import**: Drag a PDF, verify metadata is extracted without internet (except CrossRef).
2. [x] **Summarization**: Select an entry, click "Summarize", verify output is instant and reasonable.
3. [x] **Writing Assistant**: Type colloquial text, verify suggestion to academicize.
