import XCTest
@testable import Linley

final class LinleyTests: XCTestCase {
    func testBrandCopyIsReadyForPrototype() {
        XCTAssertEqual(LinleyCopy.appName, "Linley")
        XCTAssertEqual(LinleyCopy.version, "Prototype 0.3")
        XCTAssertFalse(LinleyCopy.tagline.isEmpty)
    }

    func testSuggestionShareTextRequiresDadReview() {
        let suggestion = LinleySuggestion(
            title: "New idea",
            category: "Design change",
            details: "Make the button coral."
        )

        XCTAssertTrue(suggestion.shareText.contains("Dad to review"))
        XCTAssertTrue(suggestion.shareText.contains("does not change the app automatically"))
    }
}
