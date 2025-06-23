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
            Task {
                await Logger.custom(category: "Crash").faultAsync(message)
            }
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
    Task {
        await Logger.custom(category: "Signal").faultAsync(message)
    }

    signal(signalValue, SIG_DFL)
    raise(signalValue)
}

// Configuration Module
public actor LoggerConfiguration {
    public static let shared = LoggerConfiguration()
    private var currentLogLevel: LogLevel = .debug
    private var logToFile: Bool = true
    private var logFilePath: URL = FileManager.default.temporaryDirectory.appendingPathComponent("app_log.txt")
    private var logLevelWidth: Int = 7
    private var categoryWidth: Int = 12
    private var logFormat: String = "{timestamp} - {level} - {category} - {file}:{line} - {message}"
    private var asynchronousLogging: Bool = true

    // Rotation
    private var maxFileSizeInBytes: Int64 = 5 * 1024 * 1024 // 5 MB
    private var maxLogAge: TimeInterval = 60 * 60 * 24 // 1 day
    private var maxRotatedFiles: Int = 5
    private var enableANSIColors: Bool = true

    // Async getters and setters for each property

    public func setCurrentLogLevel(_ value: LogLevel) async { self.currentLogLevel = value }
    public func getCurrentLogLevel() async -> LogLevel { self.currentLogLevel }

    public func setLogToFile(_ value: Bool) async { self.logToFile = value }
    public func getLogToFile() async -> Bool { self.logToFile }

    public func setLogFilePath(_ value: URL) async { self.logFilePath = value }
    public func getLogFilePath() async -> URL { self.logFilePath }

    public func setLogLevelWidth(_ value: Int) async { self.logLevelWidth = value }
    public func getLogLevelWidth() async -> Int { self.logLevelWidth }

    public func setCategoryWidth(_ value: Int) async { self.categoryWidth = value }
    public func getCategoryWidth() async -> Int { self.categoryWidth }

    public func setLogFormat(_ value: String) async { self.logFormat = value }
    public func getLogFormat() async -> String { self.logFormat }

    public func setAsynchronousLogging(_ value: Bool) async { self.asynchronousLogging = value }
    public func getAsynchronousLogging() async -> Bool { self.asynchronousLogging }

    public func setMaxFileSizeInBytes(_ value: Int64) async { self.maxFileSizeInBytes = value }
    public func getMaxFileSizeInBytes() async -> Int64 { self.maxFileSizeInBytes }

    public func setMaxLogAge(_ value: TimeInterval) async { self.maxLogAge = value }
    public func getMaxLogAge() async -> TimeInterval { self.maxLogAge }

    public func setMaxRotatedFiles(_ value: Int) async { self.maxRotatedFiles = value }
    public func getMaxRotatedFiles() async -> Int { self.maxRotatedFiles }

    public func setEnableANSIColors(_ value: Bool) async { self.enableANSIColors = value }
    public func getEnableANSIColors() async -> Bool { self.enableANSIColors }
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

    private func formattedLog(level: LogLevel, message: String, file: String, line: Int) async -> String {
        let logFormat = await LoggerConfiguration.shared.getLogFormat()
        let logLevelWidth = await LoggerConfiguration.shared.getLogLevelWidth()
        let categoryWidth = await LoggerConfiguration.shared.getCategoryWidth()

        // Prepare formatted strings with widths if needed
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let levelString = level.description.padding(toLength: logLevelWidth, withPad: " ", startingAt: 0)
        let categoryString = categoryName.padding(toLength: categoryWidth, withPad: " ", startingAt: 0)
        let fileName = (file as NSString).lastPathComponent

        // Replace tokens in format string
        var formatted = logFormat
        formatted = formatted.replacingOccurrences(of: "{timestamp}", with: timestamp)
        formatted = formatted.replacingOccurrences(of: "{level}", with: levelString)
        formatted = formatted.replacingOccurrences(of: "{category}", with: categoryString)
        formatted = formatted.replacingOccurrences(of: "{file}", with: fileName)
        formatted = formatted.replacingOccurrences(of: "{line}", with: "\(line)")
        formatted = formatted.replacingOccurrences(of: "{message}", with: message)
        return formatted
    }

    private func printFormatted(_ level: LogLevel, _ formattedMessage: String) async {
        let enableColors = await LoggerConfiguration.shared.getEnableANSIColors()
        if enableColors {
            print("\(level.ansiColorCode)\(formattedMessage)\u{001B}[0m")
        } else {
            print(formattedMessage)
        }
    }

    private func log(level: LogLevel, message: String, file: String, line: Int) async {
        let currentLevel = await LoggerConfiguration.shared.getCurrentLogLevel()
        guard level.rawValue >= currentLevel.rawValue else { return }
        let asyncLogging = await LoggerConfiguration.shared.getAsynchronousLogging()
        if asyncLogging {
            LogCategory.logQueue.async {
                Task {
                    let formattedMessage = await self.formattedLog(level: level, message: message, file: file, line: line)
                    await self.printFormatted(level, formattedMessage)
                    if await LoggerConfiguration.shared.getLogToFile() {
                        await LogWriter.write(formattedMessage)
                    }
                }
            }
        } else {
            let formattedMessage = await formattedLog(level: level, message: message, file: file, line: line)
            await printFormatted(level, formattedMessage)
            if await LoggerConfiguration.shared.getLogToFile() {
                await LogWriter.write(formattedMessage)
            }
        }
    }

    public func debug(_ message: String, file: String = #file, line: Int = #line) async {
        await log(level: .debug, message: message, file: file, line: line)
    }

    public func info(_ message: String, file: String = #file, line: Int = #line) async {
        await log(level: .info, message: message, file: file, line: line)
    }

    public func warning(_ message: String, file: String = #file, line: Int = #line) async {
        await log(level: .warning, message: message, file: file, line: line)
    }

    public func error(_ message: String, file: String = #file, line: Int = #line) async {
        await log(level: .error, message: message, file: file, line: line)
    }

    public func fault(_ message: String, file: String = #file, line: Int = #line) async {
        await log(level: .fault, message: message, file: file, line: line)
    }

    // MARK: - Async versions (just call the async functions directly)

    public func debugAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await debug(message, file: file, line: line)
    }

    public func infoAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await info(message, file: file, line: line)
    }

    public func warningAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await warning(message, file: file, line: line)
    }

    public func errorAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await error(message, file: file, line: line)
    }

    public func faultAsync(_ message: String, file: String = #file, line: Int = #line) async {
        await fault(message, file: file, line: line)
    }
}

public extension Logger {
    static func custom(subsystem: String = Bundle.main.bundleIdentifier ?? "DefaultSubsystem", category: String) -> LogCategory {
        return LogCategory(subsystem: subsystem, category: category)
    }
}
