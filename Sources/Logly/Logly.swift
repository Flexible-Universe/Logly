//
//  Logly.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation
import os
import Darwin

public enum LogLevel: Int, Sendable {
    case debug = 1, info, warning, error, fault

    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        }
    }

    public var ansiColorCode: String {
        switch self {
        case .debug: return "\u{001B}[0;36m" // Cyan
        case .info: return "\u{001B}[0;32m"  // Green
        case .warning: return "\u{001B}[0;33m" // Yellow
        case .error: return "\u{001B}[0;31m" // Red
        case .fault: return "\u{001B}[1;31m" // Bright Red
        }
    }
}

// MARK: - Crash & Signal Handler Setup

public enum LoggerCrashHandler {
    public static func install() {
        NSSetUncaughtExceptionHandler { exception in
            let reason = exception.reason ?? "No reason"
            let stack = exception.callStackSymbols.joined(separator: "\n")
            let message = """
            💥 Uncaught Exception: \(reason)
            Stack trace:
            \(stack)
            """
            Logger.custom(category: "Crash").fault(message)
        }

        // Register signal handlers using static C-compatible functions
        signal(SIGABRT, signalHandler)
        signal(SIGILL,  signalHandler)
        signal(SIGSEGV, signalHandler)
        signal(SIGFPE,  signalHandler)
        signal(SIGBUS,  signalHandler)
        signal(SIGPIPE, signalHandler)
    }
}

// MARK: - C-compatible Signal Handler

@_cdecl("signalHandler")
private func signalHandler(signalValue: Int32) {
    let signalName: String
    switch signalValue {
    case SIGABRT: signalName = "SIGABRT"
    case SIGILL:  signalName = "SIGILL"
    case SIGSEGV: signalName = "SIGSEGV"
    case SIGFPE:  signalName = "SIGFPE"
    case SIGBUS:  signalName = "SIGBUS"
    case SIGPIPE: signalName = "SIGPIPE"
    default:      signalName = "Unknown"
    }

    let message = "💥 Caught signal: \(signalName) (\(signalValue))"
    Logger.custom(category: "Signal").fault(message)

    signal(signalValue, SIG_DFL)
    raise(signalValue)
}

// Configuration Module
public actor LoggerConfiguration {
    public static var currentLogLevel: LogLevel = .debug
    public static var logToFile: Bool = true
    public static var logFilePath: URL = FileManager.default.temporaryDirectory.appendingPathComponent("app_log.txt")
    public static var logLevelWidth: Int = 7
    public static var categoryWidth: Int = 12
    public static var logFormat: String = "{timestamp} - {level} - {category} - {file}:{line} - {message}"
    public static var asynchronousLogging: Bool = true

    // Rotation
    public static var maxFileSizeInBytes: Int64 = 5 * 1024 * 1024 // 5 MB
    public static var maxLogAge: TimeInterval = 60 * 60 * 24 // 1 day
    public static var maxRotatedFiles: Int = 5
    public static var enableANSIColors: Bool = true
}

// Logger Category (Main API)
public struct LogCategory: Sendable {
    private let logger: Logger
    private let categoryName: String
    private static let logQueue = DispatchQueue(label: "LoggingQueue", qos: .utility)

    public init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.categoryName = category
    }

    private func formattedLog(level: LogLevel, message: String, file: String, line: Int) -> String {
        return LogFormatter.format(
            level: level,
            category: categoryName,
            message: message,
            file: file,
            line: line
        )
    }

    private func printFormatted(_ level: LogLevel, _ formattedMessage: String) {
        if LoggerConfiguration.enableANSIColors {
            print("\(level.ansiColorCode)\(formattedMessage)\u{001B}[0m")
        } else {
            print(formattedMessage)
        }
    }

    private func log(level: LogLevel, message: String, file: String, line: Int) {
        guard level.rawValue >= LoggerConfiguration.currentLogLevel.rawValue else { return }

        if LoggerConfiguration.asynchronousLogging {
            LogCategory.logQueue.async {
                let formattedMessage = self.formattedLog(level: level, message: message, file: file, line: line)
                self.printFormatted(level, formattedMessage)
                if LoggerConfiguration.logToFile {
                    LogWriter.write(formattedMessage)
                }
            }
        } else {
            let formattedMessage = formattedLog(level: level, message: message, file: file, line: line)
            printFormatted(level, formattedMessage)
            if LoggerConfiguration.logToFile {
                LogWriter.write(formattedMessage)
            }
        }
    }

    public func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }

    public func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }

    public func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }

    public func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }

    public func fault(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .fault, message: message, file: file, line: line)
    }

    // MARK: - Async versions

    public func debugAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await asyncLog(level: .debug, message: message, file: file, line: line)
    }

    public func infoAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await asyncLog(level: .info, message: message, file: file, line: line)
    }

    public func warningAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await asyncLog(level: .warning, message: message, file: file, line: line)
    }

    public func errorAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await asyncLog(level: .error, message: message, file: file, line: line)
    }

    public func faultAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await asyncLog(level: .fault, message: message, file: file, line: line)
    }

    private func asyncLog(level: LogLevel, message: String, file: String, line: Int) async {
        guard level.rawValue >= LoggerConfiguration.currentLogLevel.rawValue else { return }
        let formattedMessage = formattedLog(level: level, message: message, file: file, line: line)
        printFormatted(level, formattedMessage)
        if LoggerConfiguration.logToFile {
            LogWriter.write(formattedMessage)
        }
    }
}

public extension Logger {
    static func custom(subsystem: String = Bundle.main.bundleIdentifier ?? "DefaultSubsystem", category: String) -> LogCategory {
        return LogCategory(subsystem: subsystem, category: category)
    }
}
