//
//  RepositoryTests.swift
//  OVERENDTests
//
//  Repository 層單元測試
//

import XCTest
import CoreData
@testable import OVEREND

@MainActor
final class RepositoryTests: XCTestCase {

    var testHelper: CoreDataTestHelper!
    var testContext: NSManagedObjectContext!
    var libraryRepository: LibraryRepository!
    var entryRepository: EntryRepository!
    var documentRepository: DocumentRepository!
    var groupRepository: GroupRepository!

    override func setUp() async throws {
        // 使用 CoreDataTestHelper 創建測試環境
        await MainActor.run {
            testHelper = CoreDataTestHelper(inMemory: true)
            testContext = testHelper.viewContext
            
            // 初始化 Repositories
            libraryRepository = LibraryRepository(context: testContext)
            entryRepository = EntryRepository(context: testContext)
            documentRepository = DocumentRepository(context: testContext)
            groupRepository = GroupRepository(context: testContext)
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            testHelper?.reset()
            testHelper = nil
            testContext = nil
            libraryRepository = nil
            entryRepository = nil
            documentRepository = nil
            groupRepository = nil
        }
    }

    // MARK: - Library Repository Tests

    func testCreateLibrary() async throws {
        // When
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)

        // Then
        XCTAssertEqual(library.name, "測試庫")
        XCTAssertFalse(library.isDefault)
        XCTAssertNotNil(library.id)
    }

    func testFetchAllLibraries() async throws {
        // Given
        _ = try await libraryRepository.create(name: "庫1", isDefault: false)
        _ = try await libraryRepository.create(name: "庫2", isDefault: false)

        // When
        let libraries = try await libraryRepository.fetchAll()

        // Then
        XCTAssertEqual(libraries.count, 2)
    }

    func testFetchDefaultLibrary() async throws {
        // Given
        _ = try await libraryRepository.create(name: "普通庫", isDefault: false)
        let defaultLibrary = try await libraryRepository.create(name: "默認庫", isDefault: true)

        // When
        let fetched = try await libraryRepository.fetchDefault()

        // Then
        XCTAssertEqual(fetched?.id, defaultLibrary.id)
        XCTAssertEqual(fetched?.name, "默認庫")
    }

    func testUpdateLibrary() async throws {
        // Given
        let library = try await libraryRepository.create(name: "原始名稱", isDefault: false)

        // When
        try libraryRepository.update(library, name: "新名稱", colorHex: "#FF0000")

        // Then
        XCTAssertEqual(library.name, "新名稱")
        XCTAssertEqual(library.colorHex, "#FF0000")
    }

    func testDeleteLibrary() async throws {
        // Given
        let library = try await libraryRepository.create(name: "待刪除庫", isDefault: false)
        let librariesBefore = try await libraryRepository.fetchAll()

        // When
        try libraryRepository.delete(library)
        let librariesAfter = try await libraryRepository.fetchAll()

        // Then
        XCTAssertEqual(librariesBefore.count, 1)
        XCTAssertEqual(librariesAfter.count, 0)
    }

    // MARK: - Entry Repository Tests

    func testCreateEntry() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)

        // When
        let entry = try await entryRepository.create(
            citationKey: "Smith2023",
            entryType: "article",
            fields: ["title": "Test Article", "author": "John Smith"],
            library: library
        )

        // Then
        XCTAssertEqual(entry.citationKey, "Smith2023")
        XCTAssertEqual(entry.entryType, "article")
        XCTAssertEqual(entry.fields["title"], "Test Article")
        XCTAssertEqual(entry.library?.id, library.id)
    }

    func testFetchEntriesInLibrary() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        _ = try await entryRepository.create(
            citationKey: "Entry1",
            entryType: "article",
            fields: [:],
            library: library
        )
        _ = try await entryRepository.create(
            citationKey: "Entry2",
            entryType: "book",
            fields: [:],
            library: library
        )

        // When
        let entries = try await entryRepository.fetchAll(in: library, sortBy: .updated)

        // Then
        XCTAssertEqual(entries.count, 2)
    }

    func testSearchEntries() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        _ = try await entryRepository.create(
            citationKey: "Smith2023",
            entryType: "article",
            fields: ["title": "Machine Learning"],
            library: library
        )
        _ = try await entryRepository.create(
            citationKey: "Jones2022",
            entryType: "article",
            fields: ["title": "Deep Learning"],
            library: library
        )

        // When
        let results = try await entryRepository.search(query: "Learning", in: library)

        // Then
        XCTAssertEqual(results.count, 2)
    }

    func testUpdateEntryFields() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        let entry = try await entryRepository.create(
            citationKey: "Test2023",
            entryType: "article",
            fields: ["title": "Original Title"],
            library: library
        )

        // When
        try entryRepository.updateFields(entry, fields: ["title": "Updated Title", "year": "2023"])

        // Then
        XCTAssertEqual(entry.fields["title"], "Updated Title")
        XCTAssertEqual(entry.fields["year"], "2023")
    }

    // MARK: - Document Repository Tests

    func testCreateDocument() async throws {
        // When
        let document = try await documentRepository.create(title: "測試文檔")

        // Then
        XCTAssertEqual(document.title, "測試文檔")
        XCTAssertNotNil(document.id)
    }

    func testUpdateDocumentTitle() async throws {
        // Given
        let document = try await documentRepository.create(title: "原始標題")

        // When
        try documentRepository.updateTitle(document, title: "新標題")

        // Then
        XCTAssertEqual(document.title, "新標題")
    }

    func testAddCitation() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        let document = try await documentRepository.create(title: "測試文檔")
        let entry = try await entryRepository.create(
            citationKey: "Test2023",
            entryType: "article",
            fields: [:],
            library: library
        )

        // When
        try documentRepository.addCitation(document, entry: entry)

        // Then
        XCTAssertTrue(document.citations?.contains(entry) ?? false)
    }

    // MARK: - Group Repository Tests

    func testCreateGroup() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)

        // When
        let group = try await groupRepository.create(name: "測試組", library: library, parent: nil)

        // Then
        XCTAssertEqual(group.name, "測試組")
        XCTAssertEqual(group.library?.id, library.id)
        XCTAssertNil(group.parent)
    }

    func testFetchRootGroups() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        _ = try await groupRepository.create(name: "根組1", library: library, parent: nil)
        _ = try await groupRepository.create(name: "根組2", library: library, parent: nil)

        // When
        let rootGroups = try await groupRepository.fetchRootGroups(in: library)

        // Then
        XCTAssertEqual(rootGroups.count, 2)
    }

    func testCreateNestedGroup() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        let parentGroup = try await groupRepository.create(name: "父組", library: library, parent: nil)

        // When
        let childGroup = try await groupRepository.create(name: "子組", library: library, parent: parentGroup)

        // Then
        XCTAssertEqual(childGroup.parent?.id, parentGroup.id)
        XCTAssertTrue(parentGroup.children?.contains(childGroup) ?? false)
    }

    func testMoveGroup() async throws {
        // Given
        let library = try await libraryRepository.create(name: "測試庫", isDefault: false)
        let group1 = try await groupRepository.create(name: "組1", library: library, parent: nil)
        let group2 = try await groupRepository.create(name: "組2", library: library, parent: nil)

        // When
        try groupRepository.move(group2, to: group1)

        // Then
        XCTAssertEqual(group2.parent?.id, group1.id)
    }
}
