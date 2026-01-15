//! Bibliography processing using Hayagriva
//!
//! This module provides BibTeX parsing functionality.
//! Full CSL citation formatting requires loading CSL style files.

use hayagriva::io::from_biblatex_str;
use serde::{Deserialize, Serialize};

use crate::errors::BibliographyError;

/// A bibliography entry exported to Swift
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct BibEntry {
    pub key: String,
    pub title: Option<String>,
    pub authors: Vec<String>,
    pub year: Option<String>,
    pub entry_type: String,
    pub journal: Option<String>,
    pub volume: Option<String>,
    pub pages: Option<String>,
    pub doi: Option<String>,
    pub url: Option<String>,
}

/// Supported citation styles
#[derive(Debug, Clone, Copy, uniffi::Enum)]
pub enum CitationStyle {
    Apa,
    ChicagoAuthorDate,
    Ieee,
    Mla,
}

/// Parse BibTeX content and return structured entries
pub fn parse_bibtex(content: &str) -> Result<Vec<BibEntry>, BibliographyError> {
    let bibliography = from_biblatex_str(content)
        .map_err(|e| BibliographyError::ParseError {
            message: format!("Failed to parse BibTeX: {:?}", e),
        })?;
    
    let entries: Vec<BibEntry> = bibliography
        .iter()
        .map(|entry| {
            let authors: Vec<String> = entry
                .authors()
                .map(|persons| {
                    persons
                        .iter()
                        .map(|p| {
                            // Person.name is String, given_name is Option<String>
                            let name: &str = &p.name;
                            let given = p.given_name.as_deref().unwrap_or("");
                            if given.is_empty() {
                                name.to_string()
                            } else {
                                format!("{}, {}", name, given)
                            }
                        })
                        .collect()
                })
                .unwrap_or_default();
            
            // Journal extraction simplified - can be enhanced later
            let journal: Option<String> = None;
            
            BibEntry {
                key: entry.key().to_string(),
                title: entry.title().map(|t| t.value.to_str().to_string()),
                authors,
                year: entry.date().map(|d| d.year.to_string()),
                entry_type: format!("{:?}", entry.entry_type()),
                journal,
                volume: entry.volume().map(|v| format!("{}", v)),
                pages: entry.page_range().map(|p| format!("{}", p)),
                doi: entry.doi().map(|d| d.to_string()),
                url: entry.url().map(|u| u.value.to_string()),
            }
        })
        .collect();
    
    Ok(entries)
}

/// Format a basic citation string (simplified, without full CSL processing)
/// 
/// For full CSL formatting, use Swift-side CitationService which can load CSL files.
pub fn format_citation_simple(
    bibtex_content: &str,
    cite_keys: Vec<String>,
    _style: CitationStyle,
) -> Result<String, BibliographyError> {
    let entries = parse_bibtex(bibtex_content)?;
    
    let citations: Vec<String> = cite_keys
        .iter()
        .filter_map(|key| {
            entries.iter().find(|e| e.key == *key).map(|entry| {
                // Simple APA-like formatting
                let author = entry.authors.first()
                    .map(|a| {
                        // Get last name only
                        a.split(',').next().unwrap_or(a).trim().to_string()
                    })
                    .unwrap_or_else(|| "Unknown".to_string());
                
                let year = entry.year.clone().unwrap_or_else(|| "n.d.".to_string());
                format!("({}, {})", author, year)
            })
        })
        .collect();
    
    if citations.is_empty() {
        return Err(BibliographyError::EntryNotFound { 
            key: cite_keys.first().cloned().unwrap_or_default() 
        });
    }
    
    Ok(citations.join("; "))
}

/// Generate a simple bibliography list (without full CSL processing)
pub fn generate_bibliography_simple(
    bibtex_content: &str,
    _style: CitationStyle,
) -> Result<Vec<String>, BibliographyError> {
    let entries = parse_bibtex(bibtex_content)?;
    
    let bib_entries: Vec<String> = entries
        .iter()
        .map(|entry| {
            let authors = if entry.authors.is_empty() {
                "Unknown".to_string()
            } else {
                entry.authors.join(", ")
            };
            
            let year = entry.year.clone().unwrap_or_else(|| "n.d.".to_string());
            let title = entry.title.clone().unwrap_or_else(|| "Untitled".to_string());
            
            format!("{} ({}). {}.", authors, year, title)
        })
        .collect();
    
    Ok(bib_entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_BIBTEX: &str = r#"
@article{smith2020,
    author = {Smith, John and Doe, Jane},
    title = {A Sample Article},
    journal = {Journal of Examples},
    year = {2020},
    volume = {10},
    pages = {1-20},
    doi = {10.1234/example}
}

@book{johnson2019,
    author = {Johnson, Robert},
    title = {A Sample Book},
    publisher = {Example Press},
    year = {2019}
}
"#;

    #[test]
    fn test_parse_bibtex() {
        let result = parse_bibtex(SAMPLE_BIBTEX);
        assert!(result.is_ok());
        let entries = result.unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].key, "smith2020");
        assert_eq!(entries[1].key, "johnson2019");
    }

    #[test]
    fn test_format_citation_simple() {
        let result = format_citation_simple(
            SAMPLE_BIBTEX,
            vec!["smith2020".to_string()],
            CitationStyle::Apa,
        );
        assert!(result.is_ok());
        let citation = result.unwrap();
        assert!(citation.contains("Smith"));
        assert!(citation.contains("2020"));
    }

    #[test]
    fn test_generate_bibliography_simple() {
        let result = generate_bibliography_simple(SAMPLE_BIBTEX, CitationStyle::Apa);
        assert!(result.is_ok());
        let bib = result.unwrap();
        assert!(!bib.is_empty());
    }
}
