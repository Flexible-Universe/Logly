#if canImport(Sentry)
import XCTest
import Sentry
@testable import LoglySentry
import Logly

final class SentrySinkMappingTests: XCTestCase {
    struct SampleError: Error {}

    private func event(_ level: LogLevel, error: (any Error)? = nil) -> LogEvent {
        LogEvent(level: level, category: "Cloud", message: "msg",
                 error: error, file: "f.swift", line: 1, timestamp: Date())
    }

    func testErrorWithErrorMapsToCaptureError() {
        XCTAssertEqual(SentrySink.plan(for: event(.error, error: SampleError())),
                       .captureError(category: "Cloud"))
    }

    func testFaultWithErrorMapsToCaptureError() {
        XCTAssertEqual(SentrySink.plan(for: event(.fault, error: SampleError())),
                       .captureError(category: "Cloud"))
    }

    func testErrorWithoutErrorMapsToErrorMessage() {
        XCTAssertEqual(SentrySink.plan(for: event(.error)),
                       .captureMessage(level: .error, category: "Cloud", message: "msg"))
    }

    func testFaultWithoutErrorMapsToFatalMessage() {
        XCTAssertEqual(SentrySink.plan(for: event(.fault)),
                       .captureMessage(level: .fatal, category: "Cloud", message: "msg"))
    }

    func testWarningMapsToWarningBreadcrumb() {
        XCTAssertEqual(SentrySink.plan(for: event(.warning)),
                       .breadcrumb(level: .warning, category: "Cloud", message: "msg"))
    }

    func testInfoAndDebugMapToInfoBreadcrumb() {
        XCTAssertEqual(SentrySink.plan(for: event(.info)),
                       .breadcrumb(level: .info, category: "Cloud", message: "msg"))
        XCTAssertEqual(SentrySink.plan(for: event(.debug)),
                       .breadcrumb(level: .info, category: "Cloud", message: "msg"))
    }
}
#endif
