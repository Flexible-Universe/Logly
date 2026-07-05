#if canImport(Sentry)
import Foundation
import Sentry
@testable import LoglySentry

/// Test double for `SentryReporting`: records every effect instead of hitting
/// the process-global `SentrySDK`. `start` runs the configure closure against a
/// fresh `Options()` so tests can assert the actual option wiring.
final class SpyReporter: SentryReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var _enabled: Bool
    init(enabled: Bool = false) { self._enabled = enabled }

    var isEnabled: Bool { lock.lock(); defer { lock.unlock() }; return _enabled }

    private(set) var startCalled = false
    private(set) var startedOptions: Options?
    private(set) var capturedErrors: [(error: Error, category: String)] = []
    private(set) var capturedMessages: [(level: SentryLevel, category: String, message: String)] = []
    private(set) var breadcrumbs: [(level: SentryLevel, category: String, message: String)] = []

    func start(_ configure: @escaping (Options) -> Void) {
        lock.lock(); defer { lock.unlock() }
        startCalled = true
        let options = Options()
        configure(options)
        startedOptions = options
    }

    func captureError(_ error: Error, category: String) {
        lock.lock(); defer { lock.unlock() }
        capturedErrors.append((error, category))
    }

    func captureMessage(level: SentryLevel, category: String, message: String) {
        lock.lock(); defer { lock.unlock() }
        capturedMessages.append((level, category, message))
    }

    func addBreadcrumb(level: SentryLevel, category: String, message: String) {
        lock.lock(); defer { lock.unlock() }
        breadcrumbs.append((level, category, message))
    }
}
#endif
