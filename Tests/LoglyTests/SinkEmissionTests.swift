import XCTest
import os
@testable import Logly

final class SinkEmissionTests: XCTestCase {
    struct SampleError: Error {}

    final class RecordingSink: LogSink, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []
        var events: [LogEvent] { lock.lock(); defer { lock.unlock() }; return _events }
        func emit(_ event: LogEvent) { lock.lock(); _events.append(event); lock.unlock() }
    }

    private var sink: RecordingSink!

    override func setUp() {
        super.setUp()
        sink = RecordingSink()
        let config = LoggerConfiguration.shared
        config.removeAllSinks()
        config.addSink(sink)
        config.currentLogLevel = .debug
        config.asynchronousLogging = false   // deterministic, synchronous emission
        config.logToFile = false
    }

    override func tearDown() {
        let config = LoggerConfiguration.shared
        config.removeAllSinks()
        config.asynchronousLogging = true
        config.currentLogLevel = .debug
        config.logToFile = true
        super.tearDown()
    }

    func testErrorWithErrorIsForwarded() {
        let logger = Logger.custom(category: "Database")
        logger.error("save failed", error: SampleError())
        XCTAssertEqual(sink.events.count, 1)
        let event = sink.events[0]
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.category, "Database")
        XCTAssertEqual(event.message, "save failed")
        XCTAssertTrue(event.error is SampleError)
    }

    func testErrorWithoutErrorHasNilError() {
        let logger = Logger.custom(category: "App")
        logger.error("plain")
        XCTAssertEqual(sink.events.count, 1)
        XCTAssertNil(sink.events[0].error)
    }

    func testLevelFilterAlsoSuppressesSinkEmission() {
        LoggerConfiguration.shared.currentLogLevel = .fault
        let logger = Logger.custom(category: "App")
        logger.error("below threshold")
        XCTAssertEqual(sink.events.count, 0)
    }
}
