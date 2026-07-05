import XCTest
@testable import Logly

final class LogSinkTests: XCTestCase {
    struct SampleError: Error {}

    final class RecordingSink: LogSink, @unchecked Sendable {
        private(set) var events: [LogEvent] = []
        func emit(_ event: LogEvent) { events.append(event) }
    }

    func testLogEventStoresAllFields() {
        let error = SampleError()
        let event = LogEvent(
            level: .error,
            category: "Database",
            message: "boom",
            error: error,
            file: "/tmp/File.swift",
            line: 42,
            timestamp: Date()
        )
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.category, "Database")
        XCTAssertEqual(event.message, "boom")
        XCTAssertTrue(event.error is SampleError)
        XCTAssertEqual(event.line, 42)
    }

    func testSinkReceivesEmittedEvent() {
        let sink = RecordingSink()
        let event = LogEvent(
            level: .info, category: "App", message: "hi",
            error: nil, file: "f.swift", line: 1, timestamp: Date()
        )
        sink.emit(event)
        XCTAssertEqual(sink.events.count, 1)
        XCTAssertEqual(sink.events.first?.message, "hi")
        XCTAssertNil(sink.events.first?.error)
    }
}
