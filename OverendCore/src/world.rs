//! MemoryWorld - In-memory virtual file system for Typst
//!
//! This module implements the `typst::World` trait using an in-memory file system,
//! making it compatible with iOS sandbox restrictions.

use std::collections::HashMap;
use chrono::{Datelike, Timelike, Utc};
use comemo::Prehashed;
use typst::diag::{FileError, FileResult};
use typst::foundations::{Bytes, Datetime, Smart};
use typst::syntax::{FileId, Source, VirtualPath};
use typst::text::{Font, FontBook};
use typst::Library;

use crate::errors::TypstError;

/// In-memory virtual file system for Typst compilation
pub struct MemoryWorld {
    /// The main source file being compiled
    main: Source,
    /// Virtual files in memory
    files: HashMap<FileId, Bytes>,
    /// Font book for available fonts
    book: Prehashed<FontBook>,
    /// Loaded fonts
    fonts: Vec<Font>,
    /// Standard library
    library: Prehashed<Library>,
}

impl MemoryWorld {
    /// Create a new MemoryWorld with the given source content
    pub fn new(source: String, font_data: Option<Vec<u8>>) -> Result<Self, TypstError> {
        let main = Source::detached(source);
        
        // Create font book and load fonts
        let mut book = FontBook::new();
        let mut fonts = Vec::new();
        
        // Load embedded fonts if provided
        if let Some(data) = font_data {
            let font_bytes = Bytes::from(data);
            for font in Font::iter(font_bytes) {
                book.push(font.info().clone());
                fonts.push(font);
            }
        }
        
        Ok(Self {
            main,
            files: HashMap::new(),
            book: Prehashed::new(book),
            fonts,
            library: Prehashed::new(Library::default()),
        })
    }
    
    /// Add a virtual file to the world
    #[allow(dead_code)]
    pub fn add_file(&mut self, path: &str, content: Vec<u8>) {
        let vpath = VirtualPath::new(path);
        let id = FileId::new(None, vpath);
        self.files.insert(id, Bytes::from(content));
    }
    
    /// Get the current datetime for PDF metadata
    fn current_datetime() -> Option<Datetime> {
        let now = Utc::now();
        Datetime::from_ymd_hms(
            now.year(),
            now.month().try_into().ok()?,
            now.day().try_into().ok()?,
            now.hour().try_into().ok()?,
            now.minute().try_into().ok()?,
            now.second().try_into().ok()?,
        )
    }
}

impl typst::World for MemoryWorld {
    fn library(&self) -> &Prehashed<Library> {
        &self.library
    }

    fn book(&self) -> &Prehashed<FontBook> {
        &self.book
    }

    fn main(&self) -> Source {
        self.main.clone()
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.main.id() {
            Ok(self.main.clone())
        } else {
            Err(FileError::NotFound(id.vpath().as_rooted_path().into()))
        }
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        self.files
            .get(&id)
            .cloned()
            .ok_or_else(|| FileError::NotFound(id.vpath().as_rooted_path().into()))
    }

    fn font(&self, index: usize) -> Option<Font> {
        self.fonts.get(index).cloned()
    }

    fn today(&self, offset: Option<i64>) -> Option<Datetime> {
        let now = Utc::now();
        let offset = offset.unwrap_or(0);
        let hours = chrono::Duration::hours(offset);
        let adjusted = now + hours;
        
        Datetime::from_ymd_hms(
            adjusted.year(),
            adjusted.month().try_into().ok()?,
            adjusted.day().try_into().ok()?,
            adjusted.hour().try_into().ok()?,
            adjusted.minute().try_into().ok()?,
            adjusted.second().try_into().ok()?,
        )
    }
}

/// Compile Typst source to PDF bytes
pub fn compile_to_pdf(source: String, font_data: Option<Vec<u8>>) -> Result<Vec<u8>, TypstError> {
    let world = MemoryWorld::new(source, font_data)?;
    
    // Compile the document
    let mut tracer = typst::eval::Tracer::new();
    let document = typst::compile(&world, &mut tracer)
        .map_err(|errors| {
            let messages: Vec<String> = errors
                .iter()
                .map(|e| e.message.to_string())
                .collect();
            TypstError::CompilationFailed {
                message: messages.join("\n"),
            }
        })?;
    
    // Generate PDF - typst_pdf::pdf uses Smart<&str> for ident, use Smart::Auto
    let timestamp = MemoryWorld::current_datetime();
    let pdf_bytes = typst_pdf::pdf(&document, Smart::Auto, timestamp);
    
    Ok(pdf_bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_compilation() {
        let source = "= Hello World\n\nThis is a test.".to_string();
        let result = compile_to_pdf(source, None);
        assert!(result.is_ok());
        let pdf = result.unwrap();
        assert!(!pdf.is_empty());
        // PDF should start with %PDF
        assert!(pdf.starts_with(b"%PDF"));
    }

    #[test]
    fn test_memory_world_creation() {
        let world = MemoryWorld::new("= Test".to_string(), None);
        assert!(world.is_ok());
    }
}
