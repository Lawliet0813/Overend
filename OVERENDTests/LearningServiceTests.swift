import XCTest
@testable import OVEREND

@MainActor
class LearningServiceTests: XCTestCase {
    
    var service: LearningService!
    var mockDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test run to ensure isolation
        mockDefaults = UserDefaults(suiteName: "LearningServiceTests_\(UUID().uuidString)")
        mockDefaults.removePersistentDomain(forName: "LearningServiceTests")
        service = LearningService(defaults: mockDefaults)
    }
    
    override func tearDown() {
        mockDefaults.removePersistentDomain(forName: "LearningServiceTests")
        service = nil
        mockDefaults = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(service.learningData.totalInteractions, 0)
        XCTAssertEqual(service.maturityLevel, 0.0)
        XCTAssertTrue(service.learningData.tagModels.isEmpty)
    }
    
    func testLearnTagging() async {
        let title = "Deep Learning for Image Classification"
        let tags = ["AI", "Computer Vision"]
        
        let expectation = XCTestExpectation(description: "Learning task completed")
        
        // Since learnTagging runs in a detached task, we need to wait a bit or inspect internal state if possible.
        // However, we can't easily await the detached task.
        // We will loop and check for updates or use a small delay.
        
        service.learnTagging(title: title, tags: tags)
        
        // Wait for async update
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second
        
        XCTAssertEqual(service.learningData.totalInteractions, 1)
        XCTAssertNotNil(service.learningData.tagModels["AI"])
        XCTAssertNotNil(service.learningData.tagModels["Computer Vision"])
        
        // Check keyword association
        let aiModel = service.learningData.tagModels["AI"]
        XCTAssertEqual(aiModel?["deep"], 1)
        XCTAssertEqual(aiModel?["image"], 1)
        XCTAssertEqual(aiModel?["classification"], 1)
    }
    
    func testPredictTags() async {
        // Train the model first
        // We need at least 5 interactions to get predictions
        let trainingData = [
            ("Deep Learning Applications", ["AI"]),
            ("Machine Learning Basics", ["AI"]),
            ("Neural Networks Intro", ["AI"]),
            ("Artificial Intelligence Overview", ["AI"]),
            ("Deep Neural Networks", ["AI"])
        ]
        
        for (title, tags) in trainingData {
            service.learnTagging(title: title, tags: tags)
        }
        
        // Wait for training to complete
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        XCTAssertGreaterThanOrEqual(service.learningData.totalInteractions, 5)
        
        // Test Prediction
        let predictions = service.predictTags(for: "Deep Learning")
        
        XCTAssertFalse(predictions.isEmpty)
        XCTAssertEqual(predictions.first?.tag, "AI")
        XCTAssertGreaterThan(predictions.first?.confidence ?? 0, 0)
    }
    
    func testPersistence() async {
        let title = "Test Persistence"
        let tags = ["TestTag"]
        
        service.learnTagging(title: title, tags: tags)
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // Create a new service instance with the same defaults
        let newService = LearningService(defaults: mockDefaults)
        
        XCTAssertEqual(newService.learningData.totalInteractions, 1)
        XCTAssertNotNil(newService.learningData.tagModels["TestTag"])
    }
}
