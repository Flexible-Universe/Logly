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

/// Defines the severity levels for log messages in the Logly logging system.
/// 
/// Log levels are ordered by severity, with higher raw values indicating more severe messages.
/// The logging system can be configured to filter out messages below a certain level.
/// 
/// ## Usage
/// 
/// ```swift
/// let config = LoggerConfiguration.shared
/// config.currentLogLevel = .warning // Only show warnings and above
/// 
/// logger.debug("This won't be shown")    // Below threshold
/// logger.warning("This will be shown")   // At or above threshold
/// logger.error("This will be shown")     // Above threshold
/// ```
/// 
/// ## ANSI Color Support
/// 
/// Each log level has an associated ANSI color code for enhanced console readability:
/// - Debug: Cyan
/// - Info: Green
/// - Warning: Yellow
/// - Error: Red
/// - Fault: Bright Red
/// 
/// Colors can be disabled via ``LoggerConfiguration/enableANSIColors``.
public enum LogLevel: Int, Sendable {
    case debug = 1, info, warning, error, fault

    /// Returns a human-readable string representation of the log level.
    /// 
    /// The description is used in formatted log messages and can be padded to a consistent width
    /// using ``LoggerConfiguration/logLevelWidth``.
    /// 
    /// - Returns: A string representation of the log level (e.g., "DEBUG", "INFO", "WARNING").
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        }
    }

    /// Returns the ANSI escape code for colorizing console output.
    /// 
    /// Each log level has a distinct color to improve readability in terminal environments:
    /// - Debug: Cyan (`\u{001B}[0;36m`)
    /// - Info: Green (`\u{001B}[0;32m`)
    /// - Warning: Yellow (`\u{001B}[0;33m`)
    /// - Error: Red (`\u{001B}[0;31m`)
    /// - Fault: Bright Red (`\u{001B}[1;31m`)
    /// 
    /// Colors are automatically applied when ``LoggerConfiguration/enableANSIColors`` is `true`.
    /// 
    /// - Returns: The ANSI color escape sequence for this log level.
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

/// Provides automatic crash and signal handling capabilities for the Logly logging system.
/// 
/// The crash handler can be installed to automatically capture and log uncaught exceptions
/// and system signals, providing valuable debugging information when applications crash.
/// 
/// ## Installation
/// 
/// Install the crash handler early in your application lifecycle, typically in `main()` or
/// during app startup:
/// 
/// ```swift
/// import Logly
/// 
/// @main
/// struct MyApp: App {
///     init() {
///         LoggerCrashHandler.install()
///     }
/// 
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
/// 
/// ## Captured Events
/// 
/// The handler automatically captures:
/// - **Uncaught Exceptions**: Full exception reason and stack trace
/// - **System Signals**: SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE
/// 
/// All crash information is logged to the "Crash" and "Signal" categories and written
/// to the configured log file for later analysis.
/// 
/// > Important: Install the crash handler only once per application lifecycle.
/// > Multiple installations may lead to undefined behavior.
public enum LoggerCrashHandler {
    /// Installs global crash and signal handlers for automatic logging.
    /// 
    /// This method sets up handlers for uncaught exceptions and critical system signals.
    /// When a crash occurs, detailed information including stack traces and signal information
    /// is automatically logged using the Logly system.
    /// 
    /// The following signals are monitored:
    /// - `SIGABRT`: Abnormal termination
    /// - `SIGILL`: Illegal instruction
    /// - `SIGSEGV`: Segmentation violation
    /// - `SIGFPE`: Floating-point exception
    /// - `SIGBUS`: Bus error
    /// - `SIGPIPE`: Broken pipe
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// // Install at application startup
    /// LoggerCrashHandler.install()
    /// 
    /// // Configure logging
    /// let config = LoggerConfiguration.shared
    /// config.logToFile = true
    /// config.logFilePath = logsDirectory.appendingPathComponent("crashes.log")
    /// ```
    /// 
    /// > Warning: This should be called only once during application startup.
    /// > Multiple calls may interfere with each other.
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

/// The central configuration manager for the Logly logging system.
/// 
/// `LoggerConfiguration` provides thread-safe access to all logging settings through
/// a singleton instance. It uses a concurrent queue with barrier writes to ensure
/// thread safety while allowing multiple concurrent reads.
/// 
/// ## Thread Safety
/// 
/// All configuration properties are thread-safe and can be accessed from any queue:
/// 
/// ```swift
/// // Safe from any thread
/// DispatchQueue.global().async {
///     config.currentLogLevel = .error
/// }
/// 
/// DispatchQueue.main.async {
///     let level = config.currentLogLevel
/// }
/// ```
/// 
/// ## Dual API Support
/// 
/// The configuration supports both synchronous and asynchronous APIs:
/// 
/// ```swift
/// // Synchronous API
/// config.currentLogLevel = .warning
/// let level = config.currentLogLevel
/// 
/// // Asynchronous API
/// await config.setCurrentLogLevel(.warning)
/// let level = await config.getCurrentLogLevel()
/// ```
/// 
/// ## Configuration Categories
/// 
/// - **Log Levels**: Control which messages are processed
/// - **Output Settings**: Configure console and file output
/// - **Formatting**: Customize log message appearance
/// - **File Management**: Control log file rotation and cleanup
/// - **Performance**: Configure asynchronous processing
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

    // MARK: - Synchronous Configuration Properties
    
    /// Thread-safe properties with concurrent queue and barrier writes.
    /// 
    /// All properties use a concurrent queue for reads and barrier writes for modifications,
    /// ensuring thread safety while maintaining performance for concurrent read access.
    
    /// The minimum log level that will be processed by the logging system.
    /// 
    /// Messages with a log level below this threshold are discarded, improving performance
    /// by avoiding unnecessary processing of debug information in production builds.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// let config = LoggerConfiguration.shared
    /// config.currentLogLevel = .warning // Only warnings, errors, and faults
    /// 
    /// logger.debug("Debug info")     // Ignored
    /// logger.info("General info")    // Ignored  
    /// logger.warning("Warning!")     // Processed
    /// logger.error("Error occurred") // Processed
    /// ```
    /// 
    /// - Default: `.debug` (all messages processed)
    public var currentLogLevel: LogLevel {
        get { queue.sync { _currentLogLevel } }
        set { queue.async(flags: .barrier) { self._currentLogLevel = newValue } }
    }
    
    /// Controls whether log messages are written to a file.
    /// 
    /// When enabled, all log messages (subject to level filtering) are written to the file
    /// specified by ``logFilePath``. File logging includes automatic rotation based on
    /// size and age limits.
    /// 
    /// ## File Creation
    /// 
    /// The log file and its parent directories are created automatically when needed.
    /// If file creation fails, an error message is printed to the console.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// let config = LoggerConfiguration.shared
    /// config.logToFile = true
    /// config.logFilePath = documentsDirectory.appendingPathComponent("app.log")
    /// ```
    /// 
    /// - Default: `true`
    /// - SeeAlso: ``logFilePath``, ``maxFileSizeInBytes``, ``maxLogAge``
    public var logToFile: Bool {
        get { queue.sync { _logToFile } }
        set { queue.async(flags: .barrier) { self._logToFile = newValue } }
    }
    
    /// The file system location where log messages are written.
    /// 
    /// This URL specifies the complete path to the active log file. The file and any
    /// necessary parent directories are created automatically when logging begins.
    /// 
    /// ## Rotation Behavior
    /// 
    /// When log rotation occurs, the current file is renamed with a timestamp and
    /// a new file is created at this location.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// let config = LoggerConfiguration.shared
    /// 
    /// // Custom log location
    /// let logsDirectory = FileManager.default
    ///     .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    ///     .appendingPathComponent("MyApp/Logs")
    /// 
    /// config.logFilePath = logsDirectory.appendingPathComponent("application.log")
    /// ```
    /// 
    /// - Default: Temporary directory with name "app_log.txt"
    /// - SeeAlso: ``logToFile``, ``maxRotatedFiles``
    public var logFilePath: URL {
        get { queue.sync { _logFilePath } }
        set { queue.async(flags: .barrier) { self._logFilePath = newValue } }
    }
    
    /// The fixed width for log level strings in formatted output.
    /// 
    /// Log level names are padded with spaces to this width to ensure consistent
    /// column alignment in log files and console output.
    /// 
    /// ## Formatting Effect
    /// 
    /// ```swift
    /// config.logLevelWidth = 8
    /// 
    /// // Results in:
    /// // "DEBUG   " (padded to 8 characters)
    /// // "INFO    " (padded to 8 characters)
    /// // "WARNING " (padded to 8 characters)
    /// ```
    /// 
    /// - Default: `7`
    /// - SeeAlso: ``categoryWidth``, ``logFormat``
    public var logLevelWidth: Int {
        get { queue.sync { _logLevelWidth } }
        set { queue.async(flags: .barrier) { self._logLevelWidth = newValue } }
    }
    
    /// The fixed width for category names in formatted output.
    /// 
    /// Category names are padded with spaces to this width to ensure consistent
    /// column alignment in log files and console output.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// config.categoryWidth = 15
    /// 
    /// let networkLogger = Logger.custom(category: "Network")
    /// let dbLogger = Logger.custom(category: "Database")
    /// 
    /// // Results in aligned columns:
    /// // "Network        " (padded to 15 characters)
    /// // "Database       " (padded to 15 characters)
    /// ```
    /// 
    /// - Default: `12`
    /// - SeeAlso: ``logLevelWidth``, ``logFormat``
    public var categoryWidth: Int {
        get { queue.sync { _categoryWidth } }
        set { queue.async(flags: .barrier) { self._categoryWidth = newValue } }
    }
    
    /// The template string used to format log messages.
    /// 
    /// The format string supports token replacement for dynamic content:
    /// 
    /// ## Available Tokens
    /// 
    /// - `{timestamp}`: ISO8601 formatted current time
    /// - `{level}`: Log level name (padded to ``logLevelWidth``)
    /// - `{category}`: Logger category name (padded to ``categoryWidth``)
    /// - `{file}`: Source file name (without path)
    /// - `{line}`: Source line number
    /// - `{message}`: The actual log message content
    /// 
    /// ## Examples
    /// 
    /// ```swift
    /// // Detailed format
    /// config.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"
    /// 
    /// // Minimal format
    /// config.logFormat = "{level}: {message}"
    /// 
    /// // Custom format
    /// config.logFormat = "{timestamp} | {category} | {message}"
    /// ```
    /// 
    /// - Default: `"{timestamp} - {level} - {category} - {file}:{line} - {message}"`
    public var logFormat: String {
        get { queue.sync { _logFormat } }
        set { queue.async(flags: .barrier) { self._logFormat = newValue } }
    }
    
    /// Controls whether log operations are performed asynchronously.
    /// 
    /// When enabled, log messages are processed on a dedicated background queue,
    /// preventing blocking of the calling thread. This is particularly important
    /// for UI responsiveness when logging from the main thread.
    /// 
    /// ## Performance Impact
    /// 
    /// - **Enabled**: Log calls return immediately, processing happens in background
    /// - **Disabled**: Log calls block until file I/O and formatting are complete
    /// 
    /// ## Thread Safety
    /// 
    /// Both modes are thread-safe. Asynchronous mode adds a serialization queue
    /// to ensure log messages are written in the correct order.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// config.asynchronousLogging = true
    /// 
    /// // This returns immediately, even with file logging enabled
    /// logger.info("Processing user request")
    /// ```
    /// 
    /// - Default: `true`
    public var asynchronousLogging: Bool {
        get { queue.sync { _asynchronousLogging } }
        set { queue.async(flags: .barrier) { self._asynchronousLogging = newValue } }
    }
    
    /// The maximum size in bytes before a log file is rotated.
    /// 
    /// When the current log file reaches this size, it is automatically rotated
    /// (renamed with a timestamp) and a new file is created. This prevents log
    /// files from growing indefinitely.
    /// 
    /// ## Size Checking
    /// 
    /// File size is checked before each write operation. Once the threshold is
    /// exceeded, rotation occurs immediately before writing the new message.
    /// 
    /// ## Example Values
    /// 
    /// ```swift
    /// config.maxFileSizeInBytes = 1024 * 1024        // 1 MB
    /// config.maxFileSizeInBytes = 5 * 1024 * 1024    // 5 MB
    /// config.maxFileSizeInBytes = 10 * 1024 * 1024   // 10 MB
    /// ```
    /// 
    /// - Default: `5242880` (5 MB)
    /// - SeeAlso: ``maxLogAge``, ``maxRotatedFiles``
    public var maxFileSizeInBytes: Int64 {
        get { queue.sync { _maxFileSizeInBytes } }
        set { queue.async(flags: .barrier) { self._maxFileSizeInBytes = newValue } }
    }
    
    /// The maximum age in seconds before a log file is rotated.
    /// 
    /// Log files older than this duration are automatically rotated, regardless
    /// of their size. This ensures that log files don't become stale and helps
    /// maintain a regular rotation schedule.
    /// 
    /// ## Age Calculation
    /// 
    /// File age is calculated from the creation date and checked before each
    /// write operation.
    /// 
    /// ## Example Values
    /// 
    /// ```swift
    /// config.maxLogAge = 60 * 60          // 1 hour
    /// config.maxLogAge = 60 * 60 * 24     // 1 day
    /// config.maxLogAge = 60 * 60 * 24 * 7 // 1 week
    /// ```
    /// 
    /// - Default: `86400` (24 hours)
    /// - SeeAlso: ``maxFileSizeInBytes``, ``maxRotatedFiles``
    public var maxLogAge: TimeInterval {
        get { queue.sync { _maxLogAge } }
        set { queue.async(flags: .barrier) { self._maxLogAge = newValue } }
    }
    
    /// The maximum number of rotated log files to retain.
    /// 
    /// When log rotation occurs, old rotated files beyond this limit are automatically
    /// deleted to prevent unlimited disk usage. Files are deleted in order of creation,
    /// with the oldest files removed first.
    /// 
    /// ## Cleanup Behavior
    /// 
    /// - Active log file does not count toward this limit
    /// - Only files matching the rotated naming pattern are considered
    /// - Cleanup occurs immediately after each rotation
    /// 
    /// ## Storage Planning
    /// 
    /// ```swift
    /// config.maxFileSizeInBytes = 5 * 1024 * 1024  // 5 MB per file
    /// config.maxRotatedFiles = 10                   // Keep 10 old files
    /// // Maximum disk usage: ~55 MB (10 old + 1 active)
    /// ```
    /// 
    /// - Default: `5`
    /// - SeeAlso: ``maxFileSizeInBytes``, ``maxLogAge``
    public var maxRotatedFiles: Int {
        get { queue.sync { _maxRotatedFiles } }
        set { queue.async(flags: .barrier) { self._maxRotatedFiles = newValue } }
    }
    
    /// Controls whether ANSI color codes are used in console output.
    /// 
    /// When enabled, log messages printed to the console include ANSI escape sequences
    /// that colorize the output based on log level. This improves readability in
    /// terminal environments that support color.
    /// 
    /// ## Color Scheme
    /// 
    /// - Debug: Cyan
    /// - Info: Green
    /// - Warning: Yellow
    /// - Error: Red
    /// - Fault: Bright Red
    /// 
    /// ## Terminal Compatibility
    /// 
    /// Most modern terminals and IDEs support ANSI colors, but you may want to
    /// disable colors for:
    /// - Log file output (colors don't apply to files)
    /// - Older terminal environments
    /// - Automated parsing of log output
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// // Enable colors for development
    /// #if DEBUG
    /// config.enableANSIColors = true
    /// #else
    /// config.enableANSIColors = false
    /// #endif
    /// ```
    /// 
    /// - Default: `true`
    /// - Note: Colors only affect console output, not file output
    public var enableANSIColors: Bool {
        get { queue.sync { _enableANSIColors } }
        set { queue.async(flags: .barrier) { self._enableANSIColors = newValue } }
    }
    
    // MARK: - Asynchronous Configuration API
    
    /// Asynchronous variants of all configuration properties for use in async contexts.
    /// 
    /// These methods provide the same functionality as their synchronous counterparts
    /// but are designed for use within async functions and Task contexts.
    
    /// Asynchronously sets the minimum log level for message processing.
    /// 
    /// This is the async variant of ``currentLogLevel``. Use this method when
    /// configuring logging from within async contexts.
    /// 
    /// - Parameter value: The new minimum log level to apply.
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// Task {
    ///     await config.setCurrentLogLevel(.warning)
    /// }
    /// ```
    public func setCurrentLogLevel(_ value: LogLevel) async { 
        currentLogLevel = value 
    }
    
    /// Asynchronously retrieves the current minimum log level.
    /// 
    /// - Returns: The currently configured minimum log level.
    public func getCurrentLogLevel() async -> LogLevel { 
        currentLogLevel 
    }
    
    /// Asynchronously enables or disables file logging.
    /// 
    /// - Parameter value: `true` to enable file logging, `false` to disable it.
    public func setLogToFile(_ value: Bool) async { 
        logToFile = value 
    }
    
    /// Asynchronously checks whether file logging is enabled.
    /// 
    /// - Returns: `true` if file logging is enabled, `false` otherwise.
    public func getLogToFile() async -> Bool { 
        logToFile 
    }
    
    /// Asynchronously sets the file system path for log file output.
    /// 
    /// - Parameter value: The URL where log files should be written.
    public func setLogFilePath(_ value: URL) async { 
        logFilePath = value 
    }
    
    /// Asynchronously retrieves the current log file path.
    /// 
    /// - Returns: The URL where log files are currently being written.
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

/// The main logging interface for the Logly system.
/// 
/// `LogCategory` provides the primary API for emitting log messages at different severity levels.
/// Each instance represents a logging category (such as "Network", "Database", "UI") and
/// wraps Apple's native `os.Logger` with additional formatting and file output capabilities.
/// 
/// ## Creating Loggers
/// 
/// Create logger instances using the `Logger.custom()` extension:
/// 
/// ```swift
/// // Basic category with default subsystem
/// let networkLogger = Logger.custom(category: "Network")
/// 
/// // Custom subsystem and category  
/// let dbLogger = Logger.custom(subsystem: "com.myapp.database", category: "Database")
/// ```
/// 
/// ## Logging Methods
/// 
/// All logging methods support both synchronous and asynchronous variants:
/// 
/// ```swift
/// // Synchronous logging
/// logger.info("Processing request")
/// logger.error("Failed to connect")
/// 
/// // Asynchronous logging (for use in async contexts)
/// await logger.info("Processing request")
/// await logger.error("Failed to connect")
/// ```
/// 
/// ## Thread Safety
/// 
/// `LogCategory` is fully thread-safe and conforms to `Sendable`. All methods can be called
/// safely from any queue or async context.
/// 
/// ## Performance Considerations
/// 
/// - Messages below ``LoggerConfiguration/currentLogLevel`` are filtered out early
/// - File I/O can be performed asynchronously via ``LoggerConfiguration/asynchronousLogging``
/// - Log formatting is optimized and cached where possible
/// 
/// ## Integration with Apple's Logging
/// 
/// While `LogCategory` adds file output and custom formatting, it maintains full compatibility
/// with Apple's unified logging system. Messages appear in Console.app and can be viewed
/// using standard logging tools.
public struct LogCategory: Sendable {
    private let logger: Logger
    private let categoryName: String
    private static let logQueue = DispatchQueue(label: "LoggingQueue", qos: .utility)

    /// Creates a new log category with the specified subsystem and category name.
    /// 
    /// - Parameters:
    ///   - subsystem: The subsystem identifier, typically a reverse domain name like "com.myapp.module"
    ///   - category: A descriptive name for this logging category (e.g., "Network", "Database")
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// let logger = LogCategory(subsystem: "com.myapp.networking", category: "HTTPClient")
    /// ```
    /// 
    /// > Note: Most users should create loggers via ``Logger/custom(subsystem:category:)`` 
    /// > rather than instantiating `LogCategory` directly.
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

    /// Logs a debug message.
    /// 
    /// Debug messages are intended for detailed diagnostic information that is typically
    /// only of interest when diagnosing problems. These messages are often filtered out
    /// in production builds.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// logger.debug("Processing user request with ID: \(requestID)")
    /// logger.debug("Cache hit rate: \(hitRate)%")
    /// ```
    public func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }

    /// Logs an informational message.
    /// 
    /// Info messages are used for general information about application flow and state.
    /// These messages are typically useful for understanding application behavior in
    /// production environments.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// logger.info("User \(username) logged in successfully")
    /// logger.info("Started background sync process")
    /// ```
    public func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }

    /// Logs a warning message.
    /// 
    /// Warning messages indicate potentially problematic situations that don't prevent
    /// the application from continuing but may lead to errors or unexpected behavior
    /// if not addressed.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// logger.warning("API response took \(duration)s, exceeding recommended threshold")
    /// logger.warning("Deprecated configuration option 'legacy_mode' is being used")
    /// ```
    public func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }

    /// Logs an error message.
    /// 
    /// Error messages indicate serious problems that prevented a specific operation
    /// from completing successfully. The application can typically continue running,
    /// but the failed operation needs attention.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// logger.error("Failed to save user preferences: \(error.localizedDescription)")
    /// logger.error("Network request failed with status code \(statusCode)")
    /// ```
    public func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }

    /// Logs a fault message.
    /// 
    /// Fault messages indicate critical system errors that represent serious bugs
    /// or system failures. These are the highest severity messages and typically
    /// indicate conditions that may lead to application crashes or data corruption.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// logger.fault("Critical database corruption detected")
    /// logger.fault("Unrecoverable memory allocation failure")
    /// ```
    public func fault(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .fault, message: message, file: file, line: line)
    }
    
    // MARK: - Asynchronous Logging Methods
    
    /// Asynchronous variants of all logging methods for use in async contexts.
    /// 
    /// These methods provide identical functionality to their synchronous counterparts
    /// but are designed for use within async functions, Tasks, and other Swift Concurrency contexts.
    
    /// Asynchronously logs a debug message.
    /// 
    /// This is the async variant of ``debug(_:file:line:)``. Use this method when
    /// logging from within async contexts.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    public func debug(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .debug, message: message, file: file, line: line)
    }

    /// Asynchronously logs an informational message.
    /// 
    /// This is the async variant of ``info(_:file:line:)``. Use this method when
    /// logging from within async contexts.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    public func info(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .info, message: message, file: file, line: line)
    }

    /// Asynchronously logs a warning message.
    /// 
    /// This is the async variant of ``warning(_:file:line:)``. Use this method when
    /// logging from within async contexts.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    public func warning(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .warning, message: message, file: file, line: line)
    }

    /// Asynchronously logs an error message.
    /// 
    /// This is the async variant of ``error(_:file:line:)``. Use this method when
    /// logging from within async contexts.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    public func error(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .error, message: message, file: file, line: line)
    }

    /// Asynchronously logs a fault message.
    /// 
    /// This is the async variant of ``fault(_:file:line:)``. Use this method when
    /// logging from within async contexts.
    /// 
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The source file name (automatically captured)
    ///   - line: The source line number (automatically captured)
    public func fault(_ message: String, file: String = #file, line: Int = #line) async {
        log(level: .fault, message: message, file: file, line: line)
    }
}

/// Extension to Apple's `Logger` that provides convenient access to Logly's enhanced logging capabilities.
public extension Logger {
    /// Creates a custom `LogCategory` instance with enhanced logging features.
    /// 
    /// This is the recommended way to create loggers in the Logly system. It provides
    /// a familiar interface while adding file output, custom formatting, and other
    /// enhanced features on top of Apple's native logging.
    /// 
    /// - Parameters:
    ///   - subsystem: The subsystem identifier. Defaults to the main bundle identifier
    ///   - category: A descriptive name for this logging category
    /// 
    /// - Returns: A configured `LogCategory` instance
    /// 
    /// ## Example
    /// 
    /// ```swift
    /// // Create loggers for different parts of your app
    /// extension Logger {
    ///     static let network = Logger.custom(category: "Network")
    ///     static let database = Logger.custom(category: "Database") 
    ///     static let ui = Logger.custom(category: "UI")
    /// }
    /// 
    /// // Use throughout your application
    /// Logger.network.info("Starting API request")
    /// Logger.database.error("Failed to save user data")
    /// ```
    /// 
    /// ## Subsystem Handling
    /// 
    /// If no subsystem is provided, the method attempts to use `Bundle.main.bundleIdentifier`.
    /// If that's unavailable, it falls back to "DefaultSubsystem".
    static func custom(subsystem: String = Bundle.main.bundleIdentifier ?? "DefaultSubsystem", category: String) -> LogCategory {
        return LogCategory(subsystem: subsystem, category: category)
    }
}
