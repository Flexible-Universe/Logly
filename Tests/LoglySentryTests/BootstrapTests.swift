#if canImport(Sentry)
import XCTest
import Sentry
@testable import LoglySentry
import Logly

final class BootstrapTests: XCTestCase {
    override func tearDown() {
        LoggerConfiguration.shared.removeAllSinks()
        LoggerConfiguration.shared.sentryURL = nil
        super.tearDown()
    }

    func testShouldActivateOnlyWithNonEmptyURLAndNotAlreadyEnabled() {
        XCTAssertFalse(LoglySentry.shouldActivate(url: nil, alreadyEnabled: false))
        XCTAssertFalse(LoglySentry.shouldActivate(url: "", alreadyEnabled: false))
        XCTAssertTrue(LoglySentry.shouldActivate(url: "https://public@example.com/1", alreadyEnabled: false))
        XCTAssertFalse(LoglySentry.shouldActivate(url: "https://public@example.com/1", alreadyEnabled: true))
    }

    func testBootstrapWithoutURLIsNoOp() {
        LoggerConfiguration.shared.sentryURL = nil
        LoglySentry.bootstrap()
        XCTAssertFalse(SentrySDK.isEnabled)
        XCTAssertEqual(LoggerConfiguration.shared.sinks.count, 0)
    }
}
#endif
