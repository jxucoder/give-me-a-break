import XCTest
@testable import Give_Me_A_Break

final class ReminderTypeTests: XCTestCase {
    func testFallbackMessagesAreNeverEmpty() {
        for type in ReminderType.allCases {
            XCTAssertFalse(type.fallbackMessages.isEmpty)
            XCTAssertFalse(type.randomFallbackMessage.isEmpty)
            XCTAssertFalse(type.fallbackMessage(isStanding: false).isEmpty)
            XCTAssertFalse(type.fallbackMessage(isStanding: true).isEmpty)
        }
    }

    func testStandSitMessageDependsOnCurrentPosition() {
        let standing = ReminderType.standSit.fallbackMessage(isStanding: true)
        let sitting = ReminderType.standSit.fallbackMessage(isStanding: false)
        XCTAssertTrue(standing.localizedCaseInsensitiveContains("sit"))
        XCTAssertTrue(sitting.localizedCaseInsensitiveContains("stand"))
    }

    func testSparkleBuildNumberMustOutrankLegacyMarketingVersion() {
        XCTAssertEqual("12".compare("11", options: .numeric), .orderedDescending)
        XCTAssertEqual("11".compare("1.6.3", options: .numeric), .orderedDescending)
        XCTAssertEqual("1.6.4".compare("11", options: .numeric), .orderedAscending)
    }
}
