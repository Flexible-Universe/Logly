import XCTest
@testable import Logly

final class SinkRegistryTests: XCTestCase {
    final class DummySink: LogSink, @unchecked Sendable {
        func emit(_ event: LogEvent) {}
    }

    override func tearDown() {
        LoggerConfiguration.shared.removeAllSinks()
        LoggerConfiguration.shared.sentryURL = nil
        super.tearDown()
    }

    func testAddAndRemoveSinks() {
        let config = LoggerConfiguration.shared
        config.removeAllSinks()
        XCTAssertEqual(config.sinks.count, 0)

        config.addSink(DummySink())
        config.addSink(DummySink())
        XCTAssertEqual(config.sinks.count, 2)

        config.removeAllSinks()
        XCTAssertEqual(config.sinks.count, 0)
    }

    func testSentryURLSyncAndAsync() async {
        let config = LoggerConfiguration.shared
        XCTAssertNil(config.sentryURL)

        config.sentryURL = "https://public@example.com/1"
        XCTAssertEqual(config.sentryURL, "https://public@example.com/1")

        await config.setSentryURL(nil)
        let value = await config.getSentryURL()
        XCTAssertNil(value)
    }
}
