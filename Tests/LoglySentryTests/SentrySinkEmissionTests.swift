#if canImport(Sentry)
import XCTest
import Sentry
@testable import LoglySentry
import Logly

final class SentrySinkEmissionTests: XCTestCase {
    struct SampleError: Error {}

    private func event(_ level: LogLevel, error: (any Error)? = nil) -> LogEvent {
        LogEvent(level: level, category: "Cloud", message: "msg",
                 error: error, file: "f.swift", line: 1, timestamp: Date())
    }

    func testErrorWithErrorDispatchesCaptureError() {
        let spy = SpyReporter()
        SentrySink(reporter: spy).emit(event(.error, error: SampleError()))
        XCTAssertEqual(spy.capturedErrors.count, 1)
        XCTAssertEqual(spy.capturedErrors.first?.category, "Cloud")
        XCTAssertTrue(spy.capturedErrors.first?.error is SampleError)
        XCTAssertEqual(spy.capturedMessages.count, 0)
        XCTAssertEqual(spy.breadcrumbs.count, 0)
    }

    func testErrorWithoutErrorDispatchesErrorMessage() {
        let spy = SpyReporter()
        SentrySink(reporter: spy).emit(event(.error))
        XCTAssertEqual(spy.capturedMessages.count, 1)
        XCTAssertEqual(spy.capturedMessages.first?.level, .error)
        XCTAssertEqual(spy.capturedMessages.first?.category, "Cloud")
        XCTAssertEqual(spy.capturedMessages.first?.message, "msg")
        XCTAssertEqual(spy.capturedErrors.count, 0)
    }

    func testFaultWithoutErrorDispatchesFatalMessage() {
        let spy = SpyReporter()
        SentrySink(reporter: spy).emit(event(.fault))
        XCTAssertEqual(spy.capturedMessages.first?.level, .fatal)
    }

    func testWarningDispatchesWarningBreadcrumb() {
        let spy = SpyReporter()
        SentrySink(reporter: spy).emit(event(.warning))
        XCTAssertEqual(spy.breadcrumbs.count, 1)
        XCTAssertEqual(spy.breadcrumbs.first?.level, .warning)
    }

    func testInfoAndDebugDispatchInfoBreadcrumb() {
        let spy = SpyReporter()
        SentrySink(reporter: spy).emit(event(.info))
        SentrySink(reporter: spy).emit(event(.debug))
        XCTAssertEqual(spy.breadcrumbs.count, 2)
        XCTAssertTrue(spy.breadcrumbs.allSatisfy { $0.level == .info })
    }
}
#endif
