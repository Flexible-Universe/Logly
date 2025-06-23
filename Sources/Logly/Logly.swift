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
public class LoggerConfiguration {
    nonisolated(unsafe) public static let shared = LoggerConfiguration()
    private let queue = DispatchQueue(label: "LoggerConfiguration", attributes: .concurrent)
    
    private var _currentLogLevel: LogLevel = .debug
    private var _logToFile: Bool = true
    private var _logFilePath: URL = FileManager.default.temporaryDirectory.appendingPathComponent("app_log.txt")
    private var _logLevelWidth: Int = 7
    private var _categoryWidth: Int = 12
    private var _logFormat: String = "{timestamp} - {level} - {category} - {file}:{line} - {message}"
    private var _asynchronousLogging: Bool = true
    private var _maxFileSizeInBytes: Int64 = 5 * 1024 * 1024 // 5 MB
    private var _maxLogAge: TimeInterval = 60 * 60 * 24 // 1 day
    private var _maxRotatedFiles: Int = 5
    private var _enableANSIColors: Bool = true

    // Thread-safe properties with concurrent queue and barrier writes
    
    public var currentLogLevel: LogLevel {
        get { queue.sync { _currentLogLevel } }
        set { queue.async(flags: .barrier) { self._currentLogLevel = newValue } }
    }
    
    public var logToFile: Bool {
        get { queue.sync { _logToFile } }
        set { queue.async(flags: .barrier) { self._logToFile = newValue } }
    }
    
    public var logFilePath: URL {
        get { queue.sync { _logFilePath } }
        set { queue.async(flags: .barrier) { self._logFilePath = newValue } }
    }
    
    public var logLevelWidth: Int {
        get { queue.sync { _logLevelWidth } }
        set { queue.async(flags: .barrier) { self._logLevelWidth = newValue } }
    }
    
    public var categoryWidth: Int {
        get { queue.sync { _categoryWidth } }
        set { queue.async(flags: .barrier) { self._categoryWidth = newValue } }
    }
    
    public var logFormat: String {
        get { queue.sync { _logFormat } }
        set { queue.async(flags: .barrier) { self._logFormat = newValue } }
    }
    
    public var asynchronousLogging: Bool {
        get { queue.sync { _asynchronousLogging } }
        set { queue.async(flags: .barrier) { self._asynchronousLogging = newValue } }
    }
    
    public var maxFileSizeInBytes: Int64 {
        get { queue.sync { _maxFileSizeInBytes } }
        set { queue.async(flags: .barrier) { self._maxFileSizeInBytes = newValue } }
    }
    
    public var maxLogAge: TimeInterval {
        get { queue.sync { _maxLogAge } }
        set { queue.async(flags: .barrier) { self._maxLogAge = newValue } }
    }
    
    public var maxRotatedFiles: Int {
        get { queue.sync { _maxRotatedFiles } }
        set { queue.async(flags: .barrier) { self._maxRotatedFiles = newValue } }
    }
    
    public var enableANSIColors: Bool {
        get { queue.sync { _enableANSIColors } }
        set { queue.async(flags: .barrier) { self._enableANSIColors = newValue } }
    }
    
    // MARK: - Async API for Swift Concurrency support
    
    public func setCurrentLogLevel(_ value: LogLevel) async { 
        currentLogLevel = value 
    }
    
    public func getCurrentLogLevel() async -> LogLevel { 
        currentLogLevel 
    }
    
    public func setLogToFile(_ value: Bool) async { 
        logToFile = value 
    }
    
    public func getLogToFile() async -> Bool { 
        logToFile 
    }
    
    public func setLogFilePath(_ value: URL) async { 
        logFilePath = value 
    }
    
    public func getLogFilePath() async -> URL { 
        logFilePath 
    }
    
    public func setLogLevelWidth(_ value: Int) async { 
        logLevelWidth = value 
    }
    
    public func getLogLevelWidth() async -> Int { 
        logLevelWidth 
    }
    
    public func setCategoryWidth(_ value: Int) async { 
        categoryWidth = value 
    }
    
    public func getCategoryWidth() async -> Int { 
        categoryWidth 
    }
    
    public func setLogFormat(_ value: String) async { 
        logFormat = value 
    }
    
    public func getLogFormat() async -> String { 
        logFormat 
    }
    
    public func setAsynchronousLogging(_ value: Bool) async { 
        asynchronousLogging = value 
    }
    
    public func getAsynchronousLogging() async -> Bool { 
        asynchronousLogging 
    }
    
    public func setMaxFileSizeInBytes(_ value: Int64) async { 
        maxFileSizeInBytes = value 
    }
    
    public func getMaxFileSizeInBytes() async -> Int64 { 
        maxFileSizeInBytes 
    }
    
    public func setMaxLogAge(_ value: TimeInterval) async { 
        maxLogAge = value 
    }
    
    public func getMaxLogAge() async -> TimeInterval { 
        maxLogAge 
    }
    
    public func setMaxRotatedFiles(_ value: Int) async { 
        maxRotatedFiles = value 
    }
    
    public func getMaxRotatedFiles() async -> Int { 
        maxRotatedFiles 
    }
    
    public func setEnableANSIColors(_ value: Bool) async { 
        enableANSIColors = value 
    }
    
    public func getEnableANSIColors() async -> Bool { 
        enableANSIColors 
    }
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
        let logFormat = LoggerConfiguration.shared.logFormat
        let logLevelWidth = LoggerConfiguration.shared.logLevelWidth
        let categoryWidth = LoggerConfiguration.shared.categoryWidth

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

    private func printFormatted(_ level: LogLevel, _ formattedMessage: String) {
        let enableColors = LoggerConfiguration.shared.enableANSIColors
        if enableColors {
            print("\(level.ansiColorCode)\(formattedMessage)\u{001B}[0m")
        } else {
            print(formattedMessage)
        }
    }

    private func log(level: LogLevel, message: String, file: String, line: Int) {
        let currentLevel = LoggerConfiguration.shared.currentLogLevel
        guard level.rawValue >= currentLevel.rawValue else { return }
        let asyncLogging = LoggerConfiguration.shared.asynchronousLogging
        
        if asyncLogging {
            LogCategory.logQueue.async {
                let formattedMessage = self.formattedLog(level: level, message: message, file: file, line: line)
                self.printFormatted(level, formattedMessage)
                if LoggerConfiguration.shared.logToFile {
                    LogWriter.write(formattedMessage)
                }
            }
        } else {
            let formattedMessage = formattedLog(level: level, message: message, file: file, line: line)
            printFormatted(level, formattedMessage)
            if LoggerConfiguration.shared.logToFile {
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
    
    // MARK: - Async versions for Swift Concurrency support
    
    public func debug(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .debug, message: message, file: file, line: line)
    }

    public func info(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .info, message: message, file: file, line: line)
    }

    public func warning(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .warning, message: message, file: file, line: line)
    }

    public func error(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .error, message: message, file: file, line: line)
    }

    public func fault(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .fault, message: message, file: file, line: line)
    }
}

public extension Logger {
    static func custom(subsystem: String = Bundle.main.bundleIdentifier ?? "DefaultSubsystem", category: String) -> LogCategory {
        return LogCategory(subsystem: subsystem, category: category)
    }
}
