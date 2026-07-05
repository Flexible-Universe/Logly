//
//  LogSink.swift
//  Logly
//
//  Copyright © 2026 Flexible-Universe. All rights reserved.
//

import Foundation

/// A destination that receives structured log events from Logly.
///
/// Sinks let backends (e.g. Sentry) observe the full, structured event —
/// level, category, message and the original `Error` — instead of a
/// pre-formatted string. Implementations must be safe to call from any thread.
public protocol LogSink: Sendable {
    /// Called for every log message at or above the configured level.
    func emit(_ event: LogEvent)
}

/// A structured log event carrying the original `Error` and category through
/// to a ``LogSink``.
///
/// Marked `@unchecked Sendable`: every stored property is a `let` and the
/// optional `Error` is only ever read by sinks, never mutated. This lets a
/// `catch`-bound `any Error` be forwarded without a `Sendable` constraint at
/// the call site.
public struct LogEvent: @unchecked Sendable {
    public let level: LogLevel
    public let category: String
    public let message: String
    public let error: (any Error)?
    public let file: String
    public let line: Int
    public let timestamp: Date

    public init(
        level: LogLevel,
        category: String,
        message: String,
        error: (any Error)?,
        file: String,
        line: Int,
        timestamp: Date
    ) {
        self.level = level
        self.category = category
        self.message = message
        self.error = error
        self.file = file
        self.line = line
        self.timestamp = timestamp
    }
}
