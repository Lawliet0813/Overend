//! OverendCore - Rust core library for OVEREND
//!
//! Provides high-performance document processing capabilities:
//! - Typst compilation to PDF
//! - BibTeX/CSL bibliography processing via Hayagriva

uniffi::setup_scaffolding!();

use std::sync::Arc;

// Internal modules
mod errors;
mod world;
mod bibliography;

// Re-exports for UniFFI
pub use errors::{TypstError, BibliographyError};
pub use bibliography::{BibEntry, CitationStyle};

/// Main engine for OVEREND document processing
#[derive(uniffi::Object)]
pub struct OverendEngine;

#[uniffi::export]
impl OverendEngine {
    /// Create a new OverendEngine instance
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }

    /// Hello world test function
    pub fn hello_world(&self) -> String {
        "Hello from Rust Core!".to_string()
    }

    /// Compile Typst source to PDF
    ///
    /// # Arguments
    /// * `source` - Typst markup source code
    /// * `font_data` - Optional font data (e.g., Noto Serif TC)
    /// * `aux_files` - Optional map of auxiliary files (filename -> content bytes) for images/bibliography
    ///
    /// # Returns
    /// PDF bytes on success, TypstError on failure
    pub fn compile_typst(
        &self,
        source: String,
        font_data: Option<Vec<u8>>,
        aux_files: Option<std::collections::HashMap<String, Vec<u8>>>,
    ) -> Result<Vec<u8>, TypstError> {
        world::compile_to_pdf(source, font_data, aux_files)
    }

    /// Parse BibTeX content into structured entries
    ///
    /// # Arguments
    /// * `content` - BibTeX file content
    ///
    /// # Returns
    /// List of BibEntry records
    pub fn parse_bibtex(&self, content: String) -> Result<Vec<BibEntry>, BibliographyError> {
        bibliography::parse_bibtex(&content)
    }

    /// Format citations using a specific style (simplified)
    ///
    /// For full CSL support, use Swift-side CitationService.
    ///
    /// # Arguments
    /// * `bibtex_content` - BibTeX source
    /// * `cite_keys` - List of citation keys to format
    /// * `style` - Citation style to use
    ///
    /// # Returns
    /// Formatted citation string
    pub fn format_citation(
        &self,
        bibtex_content: String,
        cite_keys: Vec<String>,
        style: CitationStyle,
    ) -> Result<String, BibliographyError> {
        bibliography::format_citation_simple(&bibtex_content, cite_keys, style)
    }

    /// Generate a formatted bibliography list (simplified)
    ///
    /// For full CSL support, use Swift-side CitationService.
    ///
    /// # Arguments
    /// * `bibtex_content` - BibTeX source
    /// * `style` - Citation style to use
    ///
    /// # Returns
    /// List of formatted bibliography entries
    pub fn generate_bibliography(
        &self,
        bibtex_content: String,
        style: CitationStyle,
    ) -> Result<Vec<String>, BibliographyError> {
        bibliography::generate_bibliography_simple(&bibtex_content, style)
    }

    // Legacy method for backwards compatibility
    pub fn render_pdf(&self, source: String) -> String {
        format!("Rendering PDF for source: {}", source)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_engine_creation() {
        let engine = OverendEngine::new();
        assert_eq!(engine.hello_world(), "Hello from Rust Core!");
    }

    #[test]
    fn test_typst_compilation() {
        let engine = OverendEngine::new();
        let result = engine.compile_typst("= Hello\n\nWorld".to_string(), None, None);
        assert!(result.is_ok());
        let pdf = result.unwrap();
        assert!(pdf.starts_with(b"%PDF"));
    }

    #[test]
    fn test_bibtex_parsing() {
        let engine = OverendEngine::new();
        let bibtex = r#"
@article{test2024,
    author = {Test, Author},
    title = {A Test Article},
    journal = {Test Journal},
    year = {2024}
}
"#;
        let result = engine.parse_bibtex(bibtex.to_string());
        assert!(result.is_ok());
        let entries = result.unwrap();
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].key, "test2024");
    }
}
