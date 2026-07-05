//
//  LoglySentry.swift
//  LoglySentry
//
//  Copyright © 2026 Flexible-Universe. All rights reserved.
//

#if canImport(Sentry)
import Foundation
import Logly
import Sentry

/// Entry point that activates the Sentry transport for Logly.
///
/// Activation is driven entirely by ``LoggerConfiguration/sentryURL``:
/// set the URL before calling ``bootstrap(scrub:)`` and Sentry starts;
/// leave it `nil`/empty and the call is a complete no-op.
public enum LoglySentry {
    /// Pure activation predicate: activate only for a non-empty URL that isn't
    /// already running.
    public static func shouldActivate(url: String?, alreadyEnabled: Bool) -> Bool {
        guard let url, !url.isEmpty else { return false }
        return !alreadyEnabled
    }

    /// Starts the Sentry SDK (crash handler on) and registers a ``SentrySink``
    /// when a Sentry URL is configured. No-op otherwise. Idempotent.
    ///
    /// - Parameter scrub: Optional PII-scrubbing hook wired to
    ///   `options.beforeSend`. Supply an app-specific redaction for GDPR.
    ///
    /// - Important: When this activates Sentry, do **not** also call
    ///   `LoggerCrashHandler.install()` — Sentry owns crash handling and two
    ///   handlers would fight over the same POSIX signals.
    public static func bootstrap(scrub: (@Sendable (Event) -> Event?)? = nil) {
        bootstrap(scrub: scrub, reporter: SentrySDKReporter())
    }

    static func bootstrap(scrub: (@Sendable (Event) -> Event?)?, reporter: SentryReporting) {
        let url = LoggerConfiguration.shared.sentryURL
        guard shouldActivate(url: url, alreadyEnabled: reporter.isEnabled) else { return }
        reporter.start { options in
            options.dsn = url
            options.enableCrashHandler = true
            options.sendDefaultPii = false
            options.tracesSampleRate = 0.0
            if let scrub {
                options.beforeSend = { event in scrub(event) }
            }
        }
        LoggerConfiguration.shared.addSink(SentrySink(reporter: reporter))
    }
}
#endif
