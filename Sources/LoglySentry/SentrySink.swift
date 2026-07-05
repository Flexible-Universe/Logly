//
//  SentrySink.swift
//  LoglySentry
//
//  Copyright © 2026 Flexible-Universe. All rights reserved.
//

#if canImport(Sentry)
import Foundation
import Logly
import Sentry

/// The Sentry action a ``LogEvent`` maps to. Pure and `Equatable` so the
/// level mapping can be unit-tested without touching the SDK.
public enum SentryEmission: Equatable {
    case captureError(category: String)
    case captureMessage(level: SentryLevel, category: String, message: String)
    case breadcrumb(level: SentryLevel, category: String, message: String)
}

/// A ``LogSink`` that forwards events to Sentry: errors/faults become captured
/// exceptions (or message events when no `Error` is attached), warnings and
/// below become breadcrumbs for context.
public struct SentrySink: LogSink {
    let reporter: SentryReporting

    public init() { self.init(reporter: SentrySDKReporter()) }
    init(reporter: SentryReporting) { self.reporter = reporter }

    /// Pure mapping from a log event to its intended Sentry action.
    public static func plan(for event: LogEvent) -> SentryEmission {
        switch event.level {
        case .fault:
            return event.error != nil
                ? .captureError(category: event.category)
                : .captureMessage(level: .fatal, category: event.category, message: event.message)
        case .error:
            return event.error != nil
                ? .captureError(category: event.category)
                : .captureMessage(level: .error, category: event.category, message: event.message)
        case .warning:
            return .breadcrumb(level: .warning, category: event.category, message: event.message)
        case .info, .debug:
            return .breadcrumb(level: .info, category: event.category, message: event.message)
        }
    }

    public func emit(_ event: LogEvent) {
        switch Self.plan(for: event) {
        case .captureError(let category):
            if let error = event.error {
                reporter.captureError(error, category: category)
            }
        case let .captureMessage(level, category, message):
            reporter.captureMessage(level: level, category: category, message: message)
        case let .breadcrumb(level, category, message):
            reporter.addBreadcrumb(level: level, category: category, message: message)
        }
    }
}
#endif
