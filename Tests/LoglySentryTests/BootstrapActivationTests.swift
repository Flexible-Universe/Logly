#if canImport(Sentry)
import XCTest
import Sentry
@testable import LoglySentry
import Logly

final class BootstrapActivationTests: XCTestCase {
    override func tearDown() {
        LoggerConfiguration.shared.removeAllSinks()
        LoggerConfiguration.shared.sentryURL = nil
        super.tearDown()
    }

    func testActivationStartsSDKWithWiredOptionsAndRegistersSink() {
        LoggerConfiguration.shared.sentryURL = "https://public@example.com/1"
        let spy = SpyReporter(enabled: false)

        final class Box: @unchecked Sendable { var called = false }
        let box = Box()
        let scrub: @Sendable (Event) -> Event? = { event in box.called = true; return event }

        LoglySentry.bootstrap(scrub: scrub, reporter: spy)

        XCTAssertTrue(spy.startCalled)
        XCTAssertEqual(spy.startedOptions?.dsn, "https://public@example.com/1")
        XCTAssertEqual(spy.startedOptions?.enableCrashHandler, true)
        XCTAssertEqual(spy.startedOptions?.sendDefaultPii, false)
        XCTAssertEqual(spy.startedOptions?.tracesSampleRate, 0.0)
        _ = spy.startedOptions?.beforeSend?(Event())
        XCTAssertTrue(box.called, "scrub must be wired to options.beforeSend")
        XCTAssertEqual(LoggerConfiguration.shared.sinks.count, 1)
    }

    func testNoURLIsNoOp() {
        LoggerConfiguration.shared.sentryURL = nil
        let spy = SpyReporter(enabled: false)
        LoglySentry.bootstrap(scrub: nil, reporter: spy)
        XCTAssertFalse(spy.startCalled)
        XCTAssertEqual(LoggerConfiguration.shared.sinks.count, 0)
    }

    func testAlreadyEnabledIsNoOp() {
        LoggerConfiguration.shared.sentryURL = "https://public@example.com/1"
        let spy = SpyReporter(enabled: true)
        LoglySentry.bootstrap(scrub: nil, reporter: spy)
        XCTAssertFalse(spy.startCalled)
        XCTAssertEqual(LoggerConfiguration.shared.sinks.count, 0)
    }
}
#endif
