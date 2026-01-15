//! Error types for OverendCore
//!
//! Provides unified error handling for Typst compilation and bibliography processing.

use thiserror::Error;

/// Errors that can occur during Typst compilation
#[derive(Debug, Error, uniffi::Error)]
pub enum TypstError {
    #[error("Compilation failed: {message}")]
    CompilationFailed { message: String },

    #[error("Source file error: {message}")]
    SourceError { message: String },

    #[error("Font loading failed: {message}")]
    FontError { message: String },

    #[error("PDF generation failed: {message}")]
    PdfError { message: String },
}

/// Errors that can occur during bibliography processing
#[derive(Debug, Error, uniffi::Error)]
pub enum BibliographyError {
    #[error("Failed to parse BibTeX: {message}")]
    ParseError { message: String },

    #[error("Invalid CSL style: {message}")]
    StyleError { message: String },

    #[error("Citation formatting failed: {message}")]
    FormatError { message: String },

    #[error("Entry not found: {key}")]
    EntryNotFound { key: String },
}
