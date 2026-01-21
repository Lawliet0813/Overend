# Task List (Algorithm Version)

- [/] Plan and Architecture Design <!-- id: 0 -->
  - [ ] Design `LocalAlgorithmService` architecture <!-- id: 10 -->
  - [ ] Create `AlgorithmService` protocol reflecting new requirements <!-- id: 11 -->

- [x] Phase 1: Core NLP & Algorithms <!-- id: 1 -->
  - [x] Implement `NLPService` (Tokenization, TF-IDF, Cosine Similarity) <!-- id: 12 -->
  - [x] Implement `TextSummarizer` (Extractive method) <!-- id: 13 -->
  - [x] Implement `KeywordExtractor` (TF-IDF based) <!-- id: 14 -->

- [x] Phase 2: PDF Metadata Extraction <!-- id: 2 -->
  - [x] Implement PDF Attribute Reader (PDFKit) <!-- id: 20 -->
  - [x] Implement Regex-based Metadata Extraction (Title, Author, DOI) <!-- id: 21 -->
  - [x] Implement CrossRef Lookup (Optional/Hybrid) <!-- id: 22 -->
  - [x] Integrate into `PDFMetadataService` <!-- id: 23 -->

- [x] Phase 3: Literature Agent Refactoring <!-- id: 3 -->
  - [x] Refactor `LiteratureAgent` to use `NLPService` <!-- id: 30 -->
  - [x] Implement Rule-based Classification <!-- id: 31 -->
  - [x] Implement Similarity-based Recommendation <!-- id: 32 -->

- [x] Phase 4: Writing Assistant Refactoring <!-- id: 4 -->
  - [x] Implement Rule-based Tone Adjustment (`ToneAdjuster`) <!-- id: 40 -->
  - [x] Implement Template-based Expansion (`ContentExpander`) <!-- id: 41 -->
  - [x] Implement Rule-based Simplification (`ContentSimplifier`) <!-- id: 42 -->

- [x] Phase 5: Cleanup & Verification <!-- id: 5 -->
  - [x] Remove dependencies on remote AI services <!-- id: 50 -->
  - [x] Verify offline capability <!-- id: 51 -->
  - [x] Verify performance (latency checks) <!-- id: 52 -->

## Completed Fixes (Migrated)

- [x] Fix `CitationServiceTests` failures (APA formatting) <!-- id: 5 -->
- [x] Fix `BibTeXParserTests` failure (Nested braces) <!-- id: 6 -->
- [x] Resolve Core Data `NSInvalidArgumentException` crash <!-- id: 7 -->
- [x] Fix `LiteratureAgentTests` failure (Duplicates) <!-- id: 8 -->
- [x] Verify all tests pass <!-- id: 9 -->
