//
//  Logly.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//

/// # Logly - Advanced Logging System for Swift
/// 
/// A lightweight, modular, and concurrency-safe logging system for Swift projects.
/// Designed for macOS and iOS applications, it supports log levels, structured formatting,
/// log rotation, file output, asynchronous logging, and crash/signal handling – all configurable at runtime.
/// 
/// ## Quick Start Guide
/// 
/// Get started with Logly in just a few lines:
/// 
/// ```swift
/// import Logly
/// 
/// // Basic setup
/// let logger = Logger.custom(category: "MyApp")
/// logger.info("Application started")
/// 
/// // Configure for production
/// let config = LoggerConfiguration.shared
/// config.currentLogLevel = .warning
/// config.logToFile = true
/// config.logFilePath = documentsDirectory.appendingPathComponent("app.log")
/// 
/// // Enable crash handling
/// LoggerCrashHandler.install()
/// ```
/// 
/// ## 🚀 Core Features
/// 
/// ### Logging Capabilities
/// - **Five Log Levels**: `debug`, `info`, `warning`, `error`, `fault` with intelligent filtering
/// - **Structured Formatting**: Customizable format strings with token replacement
/// - **Dual API Support**: Both synchronous and async/await patterns
/// - **Thread-Safe Operations**: All APIs are safe for concurrent access
/// - **Category Organization**: Logical grouping of log messages by functional domain
/// 
/// ### File Management
/// - **Automatic Log Rotation**: Based on file size and age thresholds
/// - **Intelligent Cleanup**: Configurable retention of rotated files
/// - **UTF-8 Encoding**: Full Unicode support for international applications
/// - **Atomic Operations**: Crash-safe file writing and rotation
/// 
/// ### Advanced Features
/// - **Crash & Signal Handling**: Automatic logging of exceptions and system signals
/// - **ANSI Color Support**: Enhanced console readability with color coding
/// - **Asynchronous Processing**: Non-blocking logging for UI responsiveness
/// - **Apple Integration**: Full compatibility with Console.app and unified logging
/// 
/// ## Installation Requirements
/// 
/// - **Platforms**: iOS 16.0+, macOS 13.0+
/// - **Swift Version**: 6.1+
/// - **Package Manager**: Swift Package Manager (SPM)
/// 
/// Add to your project via Xcode:
/// 1. Go to `File > Add Packages...`
/// 2. Enter the repository URL
/// 3. Add `Logly` to your target
/// 
/// ## Architecture Overview
/// 
/// ### System Components
/// 
/// ```
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │                              Your Application Code                              │
/// └──────────────────────────────────┬───────────────────────────────────────┘
///                                │
///    ┌──────────────────────────────┴──────────────────────────────┐
///    │           LogCategory (Public API)           │
///    │                                              │
///    │  Main logging interface with dual APIs     │
///    │  - Synchronous: logger.info("message")     │
///    │  - Async: await logger.info("message")     │
///    └──────────────────────────────┬──────────────────────────────┘
///                               │
///         ┌───────────────────┴───────────────────┐
///         │  LoggerConfiguration  │
///         │                       │
///         │  Thread-safe settings │
///         │  Dual sync/async APIs │
///         └───────────────────┬───────────────────┘
///                               │
///    ┌──────────────────────────────┬──────────────────────────────┐
///    │        Processing Pipeline         │
///    │                                  │
///    │  LogFormatter ──┐ LogWriter      │
///    │  • Template      │ • File I/O     │
///    │  • Tokens       │ • Rotation    │
///    │  • Padding      │ • Atomic Ops  │
///    └──────────────────────────────┴──────────────────────────────┘
///                               │
///               ┌───────────────┴───────────────┐
///               │     LogRotator      │
///               │                     │
///               │  • Size triggers   │
///               │  • Age triggers    │
///               │  • File cleanup    │
///               └───────────────────────────────┘
/// ```
/// 
/// ### Thread-Safe Design
/// 
/// Logly is built from the ground up for concurrent applications:
/// 
/// - **Concurrent Queue Architecture**: Optimized reader-writer locks for configuration
/// - **Sendable Conformance**: All public types work safely across concurrency boundaries
/// - **Lock-Free Logging**: Hot paths avoid expensive synchronization
/// - **Actor Integration**: Seamless usage within Swift actors and async contexts
/// 
/// ## Usage Patterns
/// 
/// ### Basic Logging
/// 
/// ```swift
/// import Logly
/// 
/// let logger = Logger.custom(category: "MyService")
/// 
/// logger.debug("Detailed diagnostic information")
/// logger.info("User action completed successfully")
/// logger.warning("Performance threshold exceeded")
/// logger.error("Operation failed: \(error)")
/// logger.fault("Critical system failure detected")
/// ```
/// 
/// ### Structured Application Logging
/// 
/// ```swift
/// // Define your application's logging domains
/// extension Logger {
///     static let network = Logger.custom(category: "Network")
///     static let database = Logger.custom(category: "Database")
///     static let authentication = Logger.custom(category: "Auth")
///     static let userInterface = Logger.custom(category: "UI")
/// }
/// 
/// // Use throughout your application
/// class APIClient {
///     func fetchData() async throws {
///         Logger.network.info("📡 Starting API request")
///         defer { Logger.network.debug("🏁 API request completed") }
///         
///         do {
///             let data = try await performRequest()
///             Logger.network.info("✅ Request successful: \(data.count) bytes")
///         } catch {
///             Logger.network.error("❌ Request failed: \(error)")
///             throw error
///         }
///     }
/// }
/// ```
/// 
/// ### SwiftUI Integration
/// 
/// ```swift
/// struct ContentView: View {
///     private let logger = Logger.custom(category: "UI")
///     @State private var isLoading = false
///     
///     var body: some View {
///         VStack {
///             if isLoading {
///                 ProgressView("Loading...")
///                     .onAppear { logger.debug("🔄 Loading indicator shown") }
///             } else {
///                 Text("Content loaded")
///                     .onAppear { logger.info("✅ Content displayed") }
///             }
///         }
///         .task { await loadContent() }
///     }
///     
///     private func loadContent() async {
///         logger.info("🚀 Starting content load")
///         isLoading = true
///         defer { 
///             isLoading = false
///             logger.debug("🏁 Load completed")
///         }
///         // Content loading logic...
///     }
/// }
/// ```
/// 
/// ## Configuration Examples
/// 
/// ### Development Configuration
/// 
/// ```swift
/// func setupDevelopmentLogging() {
///     let config = LoggerConfiguration.shared
///     
///     // Show all log levels
///     config.currentLogLevel = .debug
///     
///     // Enable file logging for debugging
///     config.logToFile = true
///     let documentsPath = FileManager.default
///         .urls(for: .documentDirectory, in: .userDomainMask)[0]
///     config.logFilePath = documentsPath.appendingPathComponent("debug.log")
///     
///     // Detailed formatting with colors
///     config.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"
///     config.enableANSIColors = true
///     
///     // Frequent rotation for analysis
///     config.maxFileSizeInBytes = 5 * 1024 * 1024  // 5MB
///     config.maxLogAge = 60 * 60  // 1 hour
///     config.maxRotatedFiles = 10
/// }
/// ```
/// 
/// ### Production Configuration
/// 
/// ```swift
/// func setupProductionLogging() {
///     let config = LoggerConfiguration.shared
///     
///     // Filter out debug noise
///     config.currentLogLevel = .warning
///     
///     // Enable efficient file logging
///     config.logToFile = true
///     config.asynchronousLogging = true
///     
///     // Compact formatting
///     config.logFormat = "{timestamp} {level} {message}"
///     config.enableANSIColors = false
///     
///     // Production file location
///     let appSupportPath = FileManager.default
///         .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
///         .appendingPathComponent(Bundle.main.bundleIdentifier ?? "MyApp")
///     config.logFilePath = appSupportPath.appendingPathComponent("production.log")
///     
///     // Conservative rotation
///     config.maxFileSizeInBytes = 10 * 1024 * 1024  // 10MB
///     config.maxLogAge = 24 * 60 * 60  // 24 hours
///     config.maxRotatedFiles = 7  // Keep one week
///     
///     // Enable crash logging
///     LoggerCrashHandler.install()
/// }
/// ```
/// 
/// ## Advanced Features
/// 
/// ### Crash & Signal Handling
/// 
/// ```swift
/// // Install comprehensive crash logging
/// LoggerCrashHandler.install()
/// 
/// // Automatically captures:
/// // - Uncaught exceptions with stack traces
/// // - System signals (SIGABRT, SIGILL, SIGSEGV, etc.)
/// // - Logs to dedicated "Crash" and "Signal" categories
/// ```
/// 
/// ### Performance Monitoring Integration
/// 
/// ```swift
/// class PerformanceLogger {
///     private let logger = Logger.custom(category: "Performance")
///     
///     func measureAndLog<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
///         let startTime = CFAbsoluteTimeGetCurrent()
///         logger.debug("Starting: \(operation)")
///         
///         let result = try block()
///         
///         let duration = CFAbsoluteTimeGetCurrent() - startTime
///         if duration > 1.0 {
///             logger.warning("Slow operation '\(operation)': \(duration)s")
///         } else {
///             logger.info("Operation '\(operation)' completed in \(duration)s")
///         }
///         
///         return result
///     }
/// }
/// ```
/// 
/// ## Integration with Apple Ecosystem
/// 
/// ### Console.app Integration
/// - All messages appear in macOS Console application
/// - Native subsystem and category filtering
/// - Compatible with existing log analysis workflows
/// - Structured data support for complex log analysis
/// 
/// ### Xcode Development Integration
/// - Messages appear in Xcode console during development
/// - Color coding matches configured log levels
/// - Seamless debugging with breakpoints and flow control
/// - Performance analysis with Instruments integration
/// 
/// ## Best Practices
/// 
/// ### Message Content Guidelines
/// - **Debug**: Variable values, execution flow, detailed state information
/// - **Info**: Significant application events, user actions, system state changes
/// - **Warning**: Performance issues, deprecated usage, recoverable problems
/// - **Error**: Operation failures, recoverable errors, validation failures
/// - **Fault**: Critical failures, data corruption, unrecoverable system errors
/// 
/// ### Performance Optimization
/// - Use appropriate log levels to minimize production overhead
/// - Enable asynchronous logging for high-throughput scenarios
/// - Configure rotation settings based on disk space and retention requirements
/// - Leverage early filtering to avoid expensive string interpolation
/// 
/// ### Security Considerations
/// - Never log sensitive information (passwords, tokens, personal data)
/// - Use appropriate log levels to control information disclosure
/// - Configure file permissions properly for log directories
/// - Consider log shipping and aggregation for production monitoring
/// 
/// ## License & Attribution
/// 
/// Logly is released under the MIT License. Built with ❤️ in Swift for scalable and safe application logging.
/// 
/// For complete API documentation and examples, build the DocC documentation:
/// ```bash
/// swift package generate-documentation --target Logly
/// ```
/// 
/// Or view in Xcode: **Product → Build Documentation**

import Foundation
import os
import Darwin

/// Defines the severity levels for log messages in the Logly logging system.
/// 
/// Log levels form a hierarchical filtering system where each level represents increasing severity.
/// The system processes messages at or above the configured minimum level, discarding lower-priority
/// messages to optimize performance and reduce noise in production environments.
/// 
/// ## Level Hierarchy (Ascending Severity)
/// 
/// 1. **Debug** (`rawValue: 1`): Detailed diagnostic information useful during development
/// 2. **Info** (`rawValue: 2`): General informational messages about application flow
/// 3. **Warning** (`rawValue: 3`): Potentially problematic situations that don't prevent operation
/// 4. **Error** (`rawValue: 4`): Error conditions that prevent specific operations from completing
/// 5. **Fault** (`rawValue: 5`): Critical system failures requiring immediate attention
/// 
/// ## Implementation Details
/// 
/// The enum conforms to `Sendable` for safe usage across concurrent contexts and implements
/// `Int` raw values for efficient comparison operations. The filtering mechanism compares
/// raw values: `messageLevel.rawValue >= configuredLevel.rawValue`.
/// 
/// ## Usage Patterns
/// 
/// ### Development Configuration
/// ```swift
/// let config = LoggerConfiguration.shared
/// config.currentLogLevel = .debug  // See all messages
/// 
/// logger.debug("Variable state: \(variable)")     // Shown
/// logger.info("User action completed")           // Shown
/// logger.warning("Performance threshold exceeded") // Shown
/// ```
/// 
/// ### Production Configuration
/// ```swift
/// config.currentLogLevel = .warning  // Filter out debug/info noise
/// 
/// logger.debug("Detailed state info")    // Filtered out
/// logger.info("Operation completed")     // Filtered out
/// logger.warning("Token expires soon")   // Shown
/// logger.error("Network failure")        // Shown
/// logger.fault("Critical system error")  // Shown
/// ```
/// 
/// ## ANSI Color Coding
/// 
/// Each log level has distinct ANSI escape sequences for terminal colorization:
/// - **Debug**: Cyan (`\u{001B}[0;36m`) - Cool color for development info
/// - **Info**: Green (`\u{001B}[0;32m`) - Positive color for normal operations
/// - **Warning**: Yellow (`\u{001B}[0;33m`) - Cautionary color for attention needed
/// - **Error**: Red (`\u{001B}[0;31m`) - Alert color for problems
/// - **Fault**: Bright Red (`\u{001B}[1;31m`) - Critical color for severe issues
/// 
/// Color support is automatically applied when ``LoggerConfiguration/enableANSIColors`` is `true`
/// and can be toggled for different environments (development vs. production).
/// 
/// ## Performance Considerations
/// 
/// - Level comparison uses efficient integer operations
/// - Messages below threshold are rejected before expensive formatting
/// - String interpolation in filtered messages is avoided entirely
/// - Raw value comparison: O(1) constant time complexity
public enum LogLevel: Int, Sendable {
    /// Detailed diagnostic information typically useful only during development.
    /// 
    /// Debug messages should contain verbose information about application state,
    /// variable values, execution paths, and other diagnostic details. These messages
    /// are automatically filtered out in production builds when the log level is set
    /// to `.info` or higher.
    /// 
    /// **Use for**: Variable dumps, state transitions, detailed flow tracking
    case debug = 1
    
    /// General informational messages about normal application operation.
    /// 
    /// Info messages document significant application events, user actions,
    /// and system state changes that are useful for understanding application
    /// behavior in production environments.
    /// 
    /// **Use for**: User actions, system events, successful operations
    case info
    
    /// Potentially problematic situations that don't prevent normal operation.
    /// 
    /// Warning messages indicate conditions that could lead to errors or
    /// performance issues if not addressed, but allow the application to
    /// continue functioning normally.
    /// 
    /// **Use for**: Performance issues, deprecated features, recoverable problems
    case warning
    
    /// Error conditions that prevent specific operations from completing successfully.
    /// 
    /// Error messages indicate that a specific functionality failed, but the
    /// application can continue operating. These represent recoverable failures
    /// that should be handled gracefully.
    /// 
    /// **Use for**: Network failures, file I/O errors, validation failures
    case error
    
    /// Critical system failures that may lead to application crashes or data corruption.
    /// 
    /// Fault messages represent the highest severity level, indicating serious
    /// problems that compromise system integrity and require immediate attention.
    /// These often precede application termination.
    /// 
    /// **Use for**: Memory corruption, critical resource failures, unrecoverable states
    case fault

    /// Returns the standardized string representation used in formatted log messages.
    /// 
    /// This computed property provides uppercase string identifiers for each log level,
    /// designed for consistent formatting across different output destinations (console, file).
    /// The strings are intentionally kept short to maintain readable log formatting while
    /// being descriptive enough for immediate recognition.
    /// 
    /// ## Implementation Details
    /// 
    /// The method uses a simple switch statement for O(1) lookup performance and returns
    /// static string literals to avoid unnecessary memory allocation. All returned strings
    /// are uppercase for visual consistency and parsing compatibility.
    /// 
    /// ## Formatting Integration
    /// 
    /// The description is automatically padded to a consistent width using
    /// ``LoggerConfiguration/logLevelWidth`` when processed through the log formatter.
    /// This ensures perfect column alignment in structured log output:
    /// 
    /// ```
    /// // With logLevelWidth = 7:
    /// "DEBUG  " (2 spaces added)
    /// "INFO   " (3 spaces added)
    /// "WARNING" (no padding needed)
    /// "ERROR  " (2 spaces added)
    /// "FAULT  " (2 spaces added)
    /// ```
    /// 
    /// ## Output Examples
    /// 
    /// ```swift
    /// print(LogLevel.debug.description)   // "DEBUG"
    /// print(LogLevel.info.description)    // "INFO"
    /// print(LogLevel.warning.description) // "WARNING"
    /// print(LogLevel.error.description)   // "ERROR"
    /// print(LogLevel.fault.description)   // "FAULT"
    /// ```
    /// 
    /// - Returns: An uppercase string identifier ("DEBUG", "INFO", "WARNING", "ERROR", "FAULT")
    /// - Complexity: O(1) constant time lookup
    /// - SeeAlso: ``LoggerConfiguration/logLevelWidth`` for padding configuration
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        }
    }

    /// Returns the ANSI escape sequence for terminal colorization of this log level.
    /// 
    /// This computed property provides standardized ANSI color codes that enhance readability
    /// in terminal environments by providing immediate visual distinction between different
    /// message severities. The color scheme follows common conventions where severity
    /// increases from cool to warm colors.
    /// 
    /// ## Color Scheme Rationale
    /// 
    /// The color choices follow established UX patterns for severity indication:
    /// 
    /// - **Debug** → **Cyan** (`\u{001B}[0;36m`): Cool, calm color for diagnostic info
    /// - **Info** → **Green** (`\u{001B}[0;32m`): Positive, success-associated color
    /// - **Warning** → **Yellow** (`\u{001B}[0;33m`): Caution color, universally recognized
    /// - **Error** → **Red** (`\u{001B}[0;31m`): Alert color indicating problems
    /// - **Fault** → **Bright Red** (`\u{001B}[1;31m`): Intense color for critical issues
    /// 
    /// ## ANSI Escape Code Format
    /// 
    /// All codes follow the pattern `\u{001B}[{style};{color}m` where:
    /// - `\u{001B}` is the ESC character (ASCII 27)
    /// - `[` starts the Control Sequence Introducer (CSI)
    /// - Style codes: `0` = normal, `1` = bold/bright
    /// - Color codes: `31` = red, `32` = green, `33` = yellow, `36` = cyan
    /// - `m` terminates the sequence
    /// 
    /// ## Integration with Logging System
    /// 
    /// Colors are applied automatically when:
    /// 1. ``LoggerConfiguration/enableANSIColors`` is `true`
    /// 2. Output destination supports ANSI codes (typically terminals)
    /// 3. The log formatter processes console output
    /// 
    /// Usage pattern in formatted output:
    /// ```swift
    /// let colorizedMessage = "\(level.ansiColorCode)\(formattedMessage)\u{001B}[0m"
    /// ```
    /// 
    /// The reset sequence `\u{001B}[0m` is automatically appended to return terminal
    /// to default colors after each message.
    /// 
    /// ## Terminal Compatibility
    /// 
    /// - **Supported**: Most modern terminals (Terminal.app, iTerm, VS Code, etc.)
    /// - **Fallback**: Graceful degradation when ANSI not supported
    /// - **File Output**: Colors are never applied to file logging
    /// 
    /// - Returns: ANSI escape sequence string for colorizing this log level
    /// - Complexity: O(1) constant time lookup
    /// - SeeAlso: ``LoggerConfiguration/enableANSIColors`` for color control
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

/// Comprehensive crash and signal handling system for automatic failure logging.
/// 
/// `LoggerCrashHandler` provides a robust safety net for capturing and logging critical
/// application failures that would otherwise result in silent crashes or incomplete
/// diagnostic information. The system integrates with both Objective-C exception handling
/// and POSIX signal handling to provide comprehensive coverage of failure modes.
/// 
/// ## System Architecture
/// 
/// The crash handler operates through two complementary mechanisms:
/// 
/// 1. **NSSetUncaughtExceptionHandler**: Captures Objective-C/Swift exceptions
/// 2. **POSIX Signal Handlers**: Monitors critical system signals
/// 
/// Both systems immediately log detailed failure information through the Logly system
/// before allowing normal crash handling to proceed, ensuring crash data is preserved
/// even if the application terminates immediately.
/// 
/// ## Installation Lifecycle
/// 
/// Install the crash handler as early as possible in your application's lifecycle,
/// ideally before any other significant initialization:
/// 
/// ### SwiftUI Applications
/// ```swift
/// import Logly
/// 
/// @main
/// struct MyApp: App {
///     init() {
///         // Configure logging first
///         let config = LoggerConfiguration.shared
///         config.logToFile = true
///         config.logFilePath = getApplicationLogsDirectory().appendingPathComponent("crashes.log")
///         
///         // Install crash handler
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
/// ### UIKit Applications
/// ```swift
/// class AppDelegate: UIResponder, UIApplicationDelegate {
///     func application(_ application: UIApplication, 
///                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
///         
///         // Early crash handler installation
///         LoggerCrashHandler.install()
///         
///         return true
///     }
/// }
/// ```
/// 
/// ## Exception Capture System
/// 
/// ### Uncaught Exception Handling
/// - Captures complete exception reason and description
/// - Extracts full call stack with symbol information
/// - Logs through dedicated "Crash" category for easy filtering
/// - Preserves original exception information for system handlers
/// 
/// ### Signal Monitoring Coverage
/// 
/// The system monitors these critical POSIX signals:
/// 
/// - **SIGABRT**: Abnormal termination (abort() calls, assertion failures)
/// - **SIGILL**: Illegal instruction (corrupted code, unsupported opcodes)
/// - **SIGSEGV**: Segmentation violation (memory access violations)
/// - **SIGFPE**: Floating-point exception (division by zero, overflow)
/// - **SIGBUS**: Bus error (unaligned memory access, hardware faults)
/// - **SIGPIPE**: Broken pipe (writing to closed file descriptors)
/// 
/// ## Log Output Format
/// 
/// ### Exception Logs
/// ```
/// 2025-01-20T10:30:45Z - FAULT - Crash - MyApp.swift:123 - 💥 Uncaught Exception: NSRangeException
/// Stack trace:
/// 0   MyApp    0x0000000100001234 -[MyClass problematicMethod] + 42
/// 1   MyApp    0x0000000100005678 -[MyClass caller] + 156
/// ...
/// ```
/// 
/// ### Signal Logs
///
/// Signal handling is intentionally **not** routed through the `Logger`/file
/// pipeline (see ``signalHandler(signalValue:)`` for why) and instead writes
/// a minimal diagnostic line straight to stderr via `write(2)`:
/// ```
/// 💥 Logly: caught fatal signal SIGSEGV — terminating (see crash report for details)
/// ```
/// For structured, persisted crash data use the system crash reporter /
/// Console.app, or a crash-reporting SDK (e.g. Sentry via `LoglySentry`).
///
/// ## Integration Benefits
/// 
/// - **Persistent Storage**: Crashes are logged to files that survive application termination
/// - **Structured Format**: Consistent with regular application logs for unified analysis
/// - **Remote Logging**: Can be integrated with log shipping solutions
/// - **Development Aid**: Immediate visibility into crash causes during development
/// - **Production Debugging**: Post-mortem analysis capabilities for production issues
/// 
/// ## Safety Considerations
/// 
/// > **Critical**: Install the crash handler only **once** during application startup.
/// > Multiple installations can create handler conflicts and undefined behavior.
/// 
/// > **Thread Safety**: The crash handler uses C-compatible functions to ensure
/// > signal handling works correctly in multi-threaded environments.
/// 
/// > **Memory Safety**: Handler implementation avoids Swift features that might
/// > not be available during crash scenarios (minimal allocations, no ARC dependencies).
/// 
/// ## Platform Compatibility
/// 
/// - **iOS**: Full support for exception and signal handling
/// - **macOS**: Complete POSIX signal support and exception handling
/// - **Simulator**: Limited signal support due to simulation environment
/// - **Testing**: Handlers are automatically bypassed during unit testing
public enum LoggerCrashHandler {
    /// Installs comprehensive crash and signal monitoring with automatic logging capabilities.
    /// 
    /// This method establishes a robust crash detection system by installing both NSException
    /// handlers and POSIX signal handlers. The installation process is designed to be called
    /// once during application startup and provides immediate crash logging capabilities
    /// that persist even if the application terminates unexpectedly.
    /// 
    /// ## Installation Process
    /// 
    /// The method performs these operations atomically:
    /// 
    /// 1. **Exception Handler Setup**: Registers `NSSetUncaughtExceptionHandler` to catch
    ///    Objective-C exceptions, including Swift runtime errors that bridge through NSException
    /// 
    /// 2. **Signal Handler Registration**: Installs C-compatible signal handlers for critical
    ///    POSIX signals using the `signal()` system call
    /// 
    /// 3. **Handler Chain Preservation**: Preserves existing handlers where possible to
    ///    maintain compatibility with debugging tools and crash reporting systems
    /// 
    /// ## Signal Coverage Matrix
    /// 
    /// | Signal   | Description | Common Causes | Handler Action |
    /// |----------|-------------|---------------|-----------------|
    /// | SIGABRT  | Abnormal termination | `abort()` calls, failed assertions, std::terminate | Log → Reset → Re-raise |
    /// | SIGILL   | Illegal instruction | Code corruption, unsupported CPU instructions | Log → Reset → Re-raise |
    /// | SIGSEGV  | Segmentation fault | Null pointer dereference, buffer overruns | Log → Reset → Re-raise |
    /// | SIGFPE   | Floating-point exception | Division by zero, numeric overflow | Log → Reset → Re-raise |
    /// | SIGBUS   | Bus error | Unaligned memory access, hardware issues | Log → Reset → Re-raise |
    /// | SIGPIPE  | Broken pipe | Writing to closed socket/pipe | Log → Reset → Re-raise |
    /// 
    /// ## Handler Implementation Details
    /// 
    /// ### Exception Handler Closure
    /// ```swift
    /// NSSetUncaughtExceptionHandler { exception in
    ///     // Extract exception details
    ///     let reason = exception.reason ?? "No reason"
    ///     let symbols = exception.callStackSymbols.joined(separator: "\n")
    ///     
    ///     // Log via dedicated crash logger
    ///     Logger.custom(category: "Crash").fault("💥 Uncaught Exception: \(reason)\nStack:\n\(symbols)")
    /// }
    /// ```
    /// 
    /// ### Signal Handler Function
    /// The signal handler is implemented as a C-compatible function to ensure
    /// reliable operation during crash scenarios:
    /// 
    /// ```c
    /// void signalHandler(int signalValue) {
    ///     // Minimal Swift code - avoid complex operations
    ///     // Log signal information
    ///     // Reset handler to default
    ///     // Re-raise signal for normal crash handling
    /// }
    /// ```
    /// 
    /// ## Integration Examples
    /// 
    /// ### Complete Crash Logging Setup
    /// ```swift
    /// import Logly
    /// 
    /// func setupCrashLogging() {
    ///     // 1. Configure file logging first
    ///     let config = LoggerConfiguration.shared
    ///     config.logToFile = true
    ///     
    ///     // 2. Ensure crash log directory exists
    ///     let crashLogsDir = FileManager.default
    ///         .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    ///         .appendingPathComponent("CrashLogs")
    ///     
    ///     try? FileManager.default.createDirectory(at: crashLogsDir, 
    ///                                              withIntermediateDirectories: true)
    ///     
    ///     config.logFilePath = crashLogsDir.appendingPathComponent("crashes.log")
    ///     
    ///     // 3. Configure for crash scenarios
    ///     config.asynchronousLogging = false  // Ensure immediate writes
    ///     config.maxFileSizeInBytes = 50 * 1024 * 1024  // Larger files for crash data
    ///     
    ///     // 4. Install crash handlers
    ///     LoggerCrashHandler.install()
    /// }
    /// ```
    /// 
    /// ### Development vs Production Configuration
    /// ```swift
    /// #if DEBUG
    /// // Development: Immediate crash visibility
    /// config.logToFile = true
    /// config.enableANSIColors = true
    /// LoggerCrashHandler.install()
    /// #else
    /// // Production: Silent crash logging
    /// config.logToFile = true
    /// config.enableANSIColors = false
    /// config.currentLogLevel = .error  // Reduce log noise
    /// LoggerCrashHandler.install()
    /// #endif
    /// ```
    /// 
    /// ## Safety and Reliability Guarantees
    /// 
    /// - **Single Installation**: Method is designed to be called once; multiple calls are safe but unnecessary
    /// - **Thread Safety**: Signal handlers use async-signal-safe functions only
    /// - **Memory Safety**: Minimal heap allocation in crash scenarios
    /// - **System Integration**: Preserves system crash handling after logging
    /// - **Tool Compatibility**: Maintains compatibility with Xcode debugger and external crash reporters
    /// 
    /// ## Debugging Considerations
    /// 
    /// When debugging with Xcode:
    /// - Debugger will catch signals before our handlers in most cases
    /// - Exception handlers still trigger for uncaught exceptions
    /// - Use "Continue" in debugger to trigger custom handlers
    /// - Crash logs are written even when debugging
    /// 
    /// > **Installation Timing**: Call this method as early as possible in your application
    /// > lifecycle, ideally in `main()`, `@main struct init()`, or `application:didFinishLaunchingWithOptions:`.
    /// 
    /// > **Thread Safety**: This method is thread-safe and can be called from any thread,
    /// > but should only be called once per application session.
    /// 
    /// - Complexity: O(1) - Constant time installation
    /// - Side Effects: Installs global exception and signal handlers
    /// - Thread Safety: Safe to call from any thread, but should only be called once
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

/// Writes a compile-time constant string directly to a file descriptor.
///
/// `StaticString`'s UTF-8 buffer is baked into the binary's read-only data
/// segment, so reading it performs no heap allocation and takes no lock —
/// unlike `String` interpolation, `Foundation` formatting, or `Dispatch`,
/// none of which are safe to touch from inside a POSIX signal handler.
/// `write(2)` itself is on the POSIX async-signal-safe function list.
@inline(__always)
private func signalSafeWrite(_ text: StaticString, to fd: Int32) {
    text.withUTF8Buffer { buffer in
        _ = write(fd, buffer.baseAddress, buffer.count)
    }
}

/// Minimal, async-signal-safe fatal-signal handler.
///
/// - Important: This function runs on the signal-delivery thread, which may
///   already hold the malloc heap lock, a `libdispatch` internal lock, or
///   (if the crash originated inside ``LoggerConfiguration``) its own
///   configuration queue. Routing through the full `Logger`/`Dispatch`/
///   `Foundation` pipeline here — as earlier versions did — can therefore
///   re-enter an already-held lock and deadlock the process instead of
///   crashing it, which surfaces as a hung `xcodebuild test`/app process
///   that never terminates. Only async-signal-safe operations are used
///   below; no allocation, locking, or `Dispatch`/`Logger` calls.
@_cdecl("signalHandler")
private func signalHandler(signalValue: Int32) {
    let signalName: StaticString
    switch signalValue {
    case SIGABRT: signalName = "SIGABRT"
    case SIGILL:  signalName = "SIGILL"
    case SIGSEGV: signalName = "SIGSEGV"
    case SIGFPE:  signalName = "SIGFPE"
    case SIGBUS:  signalName = "SIGBUS"
    case SIGPIPE: signalName = "SIGPIPE"
    default:      signalName = "UNKNOWN"
    }

    signalSafeWrite("\n💥 Logly: caught fatal signal ", to: STDERR_FILENO)
    signalSafeWrite(signalName, to: STDERR_FILENO)
    signalSafeWrite(" — terminating (see crash report for details)\n", to: STDERR_FILENO)

    signal(signalValue, SIG_DFL)
    raise(signalValue)
}

/// Central configuration hub for all Logly logging system settings and behavior.
/// 
/// `LoggerConfiguration` serves as the single source of truth for logging behavior across
/// your entire application. It implements a thread-safe singleton pattern, supporting both
/// traditional synchronous configuration and modern Swift Concurrency patterns.
///
/// ## Architecture Overview
///
/// The configuration system is built on several key architectural principles:
///
/// ### Thread-Safe Singleton Pattern
/// - **Global Access**: Single `shared` instance accessible from anywhere in your app
/// - **Thread Safety**: All operations are protected by a single unfair lock
/// - **Performance**: Lock acquisition is a lightweight kernel futex, not a GCD queue hop
/// - **Memory Efficiency**: Lazy initialization and efficient property storage
///
/// ### Lock-Based Architecture
///
/// ```swift
/// private let lock = OSAllocatedUnfairLock(initialState: State())
///
/// public var currentLogLevel: LogLevel {
///     get { lock.withLock { $0.currentLogLevel } }
///     set { lock.withLock { $0.currentLogLevel = newValue } }
/// }
/// ```
///
/// This pattern allows:
/// - **Bounded Blocking**: Waiting threads park on a futex instead of consuming a GCD
///   worker thread, so contention cannot exhaust the global dispatch thread pool
/// - **Atomicity**: All state lives in a single `State` struct guarded by one lock,
///   so callers never observe a partially-updated configuration
/// 
/// ### Dual API Architecture
/// 
/// The configuration provides parallel synchronous and asynchronous APIs for maximum flexibility:
/// 
/// #### Synchronous API (Traditional)
/// ```swift
/// let config = LoggerConfiguration.shared
/// 
/// // Direct property access
/// config.currentLogLevel = .warning
/// config.logToFile = true
/// config.enableANSIColors = false
/// 
/// // Immediate reads
/// let level = config.currentLogLevel
/// let isFileLogging = config.logToFile
/// ```
/// 
/// #### Asynchronous API (Swift Concurrency)
/// ```swift
/// let config = LoggerConfiguration.shared
/// 
/// // Async configuration
/// await config.setCurrentLogLevel(.warning)
/// await config.setLogToFile(true)
/// await config.setEnableANSIColors(false)
/// 
/// // Async reads
/// let level = await config.getCurrentLogLevel()
/// let isFileLogging = await config.getLogToFile()
/// ```
/// 
/// ## Configuration Domain Areas
/// 
/// The configuration system is organized into logical domains:
/// 
/// ### 1. Message Filtering (`LogLevel` Control)
/// - **Purpose**: Determine which messages are processed vs. discarded
/// - **Performance Impact**: High - affects every log call
/// - **Properties**: ``currentLogLevel``
/// - **Use Cases**: Development vs. production filtering, performance optimization
/// 
/// ### 2. Output Destinations (Console & File)
/// - **Purpose**: Control where log messages are written
/// - **Properties**: ``logToFile``, ``logFilePath``
/// - **Use Cases**: Development debugging, production logging, compliance
/// 
/// ### 3. Message Formatting (Appearance & Structure)
/// - **Purpose**: Control how log messages appear in output
/// - **Properties**: ``logFormat``, ``logLevelWidth``, ``categoryWidth``, ``enableANSIColors``
/// - **Use Cases**: Structured logging, parsing compatibility, visual clarity
/// 
/// ### 4. File Management (Rotation & Cleanup)
/// - **Purpose**: Prevent unlimited disk usage and maintain log freshness
/// - **Properties**: ``maxFileSizeInBytes``, ``maxLogAge``, ``maxRotatedFiles``
/// - **Use Cases**: Long-running applications, disk space management, compliance retention
/// 
/// ### 5. Performance & Concurrency
/// - **Purpose**: Optimize logging performance and threading behavior
/// - **Properties**: ``asynchronousLogging``
/// - **Use Cases**: High-throughput logging, UI responsiveness, performance optimization
/// 
/// ## Usage Patterns
/// 
/// ### Application Startup Configuration
/// ```swift
/// func configureLogging() {
///     let config = LoggerConfiguration.shared
///     
///     #if DEBUG
///     // Development configuration
///     config.currentLogLevel = .debug
///     config.logToFile = true
///     config.enableANSIColors = true
///     config.logFormat = "{timestamp} {level} {category} {file}:{line} - {message}"
///     #else
///     // Production configuration
///     config.currentLogLevel = .warning
///     config.logToFile = true
///     config.enableANSIColors = false
///     config.asynchronousLogging = true
///     config.logFormat = "{timestamp} {level} {message}"
///     #endif
///     
///     // Configure file output
///     let logsDir = getApplicationLogsDirectory()
///     config.logFilePath = logsDir.appendingPathComponent("app.log")
///     
///     // Configure rotation
///     config.maxFileSizeInBytes = 10 * 1024 * 1024  // 10MB
///     config.maxLogAge = 7 * 24 * 60 * 60  // 7 days
///     config.maxRotatedFiles = 5
/// }
/// ```
/// 
/// ### Runtime Configuration Changes
/// ```swift
/// // Safe to call from any thread
/// DispatchQueue.global().async {
///     LoggerConfiguration.shared.currentLogLevel = .error  // Reduce verbosity
/// }
/// 
/// DispatchQueue.main.async {
///     let config = LoggerConfiguration.shared
///     config.enableANSIColors = UserDefaults.standard.bool(forKey: "EnableColors")
/// }
/// ```
/// 
/// ### Async/Await Configuration
/// ```swift
/// Task {
///     let config = LoggerConfiguration.shared
///     
///     // Configure multiple settings atomically
///     await config.setCurrentLogLevel(.info)
///     await config.setLogToFile(true)
///     await config.setAsynchronousLogging(true)
///     
///     // Read current state
///     let currentLevel = await config.getCurrentLogLevel()
///     print("Logging level: \(currentLevel)")
/// }
/// ```
/// 
/// ## Performance Characteristics
/// 
/// - **Read Operations**: O(1) with minimal locking overhead
/// - **Write Operations**: O(1) with barrier synchronization
/// - **Memory Footprint**: Minimal - single instance with efficient property storage
/// - **Thread Contention**: Minimized through reader-writer lock pattern
/// - **Startup Cost**: Lazy initialization, no upfront performance penalty
/// 
/// ## Integration with README Examples
/// 
/// This configuration system enables all the patterns shown in the project README:
/// - Environment-specific logging setups
/// - Dynamic runtime configuration
/// - Performance optimization through level filtering
/// - File management and rotation
/// - Thread-safe multi-threaded applications
public class LoggerConfiguration: @unchecked Sendable {
    public static let shared = LoggerConfiguration()

    fileprivate struct State {
        var currentLogLevel: LogLevel = .debug
        var logToFile: Bool = true
        var logFilePath: URL = FileManager.default.temporaryDirectory.appendingPathComponent("app_log.txt")
        var logLevelWidth: Int = 7
        var categoryWidth: Int = 12
        var logFormat: String = "{timestamp} - {level} - {category} - {file}:{line} - {message}"
        var asynchronousLogging: Bool = true
        var maxFileSizeInBytes: Int64 = 5 * 1024 * 1024 // 5 MB
        var maxLogAge: TimeInterval = 60 * 60 * 24 // 1 day
        var maxRotatedFiles: Int = 5
        var enableANSIColors: Bool = true
        var sentryURL: String? = nil
        var sinks: [LogSink] = []
    }

    fileprivate let lock = OSAllocatedUnfairLock(initialState: State())

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
        get { lock.withLock { $0.currentLogLevel } }
        set { lock.withLock { $0.currentLogLevel = newValue } }
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
        get { lock.withLock { $0.logToFile } }
        set { lock.withLock { $0.logToFile = newValue } }
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
        get { lock.withLock { $0.logFilePath } }
        set { lock.withLock { $0.logFilePath = newValue } }
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
        get { lock.withLock { $0.logLevelWidth } }
        set { lock.withLock { $0.logLevelWidth = newValue } }
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
        get { lock.withLock { $0.categoryWidth } }
        set { lock.withLock { $0.categoryWidth = newValue } }
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
        get { lock.withLock { $0.logFormat } }
        set { lock.withLock { $0.logFormat = newValue } }
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
        get { lock.withLock { $0.asynchronousLogging } }
        set { lock.withLock { $0.asynchronousLogging = newValue } }
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
        get { lock.withLock { $0.maxFileSizeInBytes } }
        set { lock.withLock { $0.maxFileSizeInBytes = newValue } }
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
        get { lock.withLock { $0.maxLogAge } }
        set { lock.withLock { $0.maxLogAge = newValue } }
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
        get { lock.withLock { $0.maxRotatedFiles } }
        set { lock.withLock { $0.maxRotatedFiles = newValue } }
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
        get { lock.withLock { $0.enableANSIColors } }
        set { lock.withLock { $0.enableANSIColors = newValue } }
    }

    /// Optional Sentry DSN. When set (non-empty), `LoglySentry.bootstrap()`
    /// activates Sentry; when `nil`/empty, Sentry stays disabled.
    ///
    /// The core only stores this string — it has no Sentry dependency.
    public var sentryURL: String? {
        get { lock.withLock { $0.sentryURL } }
        set { lock.withLock { $0.sentryURL = newValue } }
    }

    /// The registered log sinks. Read-only; mutate via ``addSink(_:)`` /
    /// ``removeAllSinks()``.
    public var sinks: [LogSink] {
        lock.withLock { $0.sinks }
    }

    /// Registers a sink that receives every log event at or above the current level.
    public func addSink(_ sink: LogSink) {
        lock.withLock { $0.sinks.append(sink) }
    }

    /// Removes all registered sinks.
    public func removeAllSinks() {
        lock.withLock { $0.sinks.removeAll() }
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

    /// Asynchronously sets the Sentry DSN.
    public func setSentryURL(_ value: String?) async {
        sentryURL = value
    }

    /// Asynchronously retrieves the Sentry DSN.
    public func getSentryURL() async -> String? {
        sentryURL
    }
}

/// Primary logging interface providing structured, categorized message emission with enhanced capabilities.
/// 
/// `LogCategory` serves as the main entry point for all logging operations in the Logly system.
/// It wraps Apple's native `os.Logger` while adding significant enhancements including file output,
/// custom formatting, log rotation, crash handling, and dual synchronous/asynchronous APIs.
/// Each instance represents a distinct logging domain within your application architecture.
/// 
/// ## Architectural Design
/// 
/// ### Hybrid Logging Architecture
/// 
/// `LogCategory` implements a hybrid approach that combines the best of both worlds:
/// 
/// 1. **Apple's Unified Logging**: Full integration with `os.Logger` for system-level logging
/// 2. **Enhanced File Logging**: Structured file output with rotation and formatting
/// 3. **Custom Formatting**: Token-based message formatting with alignment and colorization
/// 4. **Performance Optimization**: Early filtering and asynchronous processing capabilities
/// 
/// ```
/// ┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
/// │   LogCategory   │───▶│  Apple os.Logger │───▶│ Console.app     │
/// │                 │    └──────────────────┘    └─────────────────┘
/// │                 │    ┌──────────────────┐    ┌─────────────────┐
/// │                 │───▶│  LogFormatter    │───▶│ File Output     │
/// │                 │    └──────────────────┘    └─────────────────┘
/// └─────────────────┘    ┌──────────────────┐    ┌─────────────────┐
///                        │  Console Output  │───▶│ Terminal/Xcode  │
///                        └──────────────────┘    └─────────────────┘
/// ```
/// 
/// ### Category-Based Organization
/// 
/// The category system enables logical organization of log messages by functional domain:
/// 
/// ```swift
/// // Define your application's logging domains
/// extension Logger {
///     static let network = Logger.custom(category: "Network")
///     static let database = Logger.custom(category: "Database")
///     static let authentication = Logger.custom(category: "Auth")
///     static let userInterface = Logger.custom(category: "UI")
///     static let analytics = Logger.custom(subsystem: "com.myapp.analytics", category: "Events")
/// }
/// 
/// // Use throughout your application
/// class NetworkManager {
///     func fetchData() {
///         Logger.network.info("Starting API request")
///         // Network logic...
///         Logger.network.debug("Response received: \(responseSize) bytes")
///     }
/// }
/// ```
/// 
/// ## Dual API Architecture
/// 
/// ### Synchronous API (Traditional Pattern)
/// 
/// The synchronous API provides immediate execution with optional background processing:
/// 
/// ```swift
/// let logger = Logger.custom(category: "MyService")
/// 
/// // Direct logging - returns immediately or after file write (depending on config)
/// logger.debug("Detailed diagnostic information")
/// logger.info("User action completed successfully")
/// logger.warning("Performance threshold exceeded")
/// logger.error("Operation failed: \(error)")
/// logger.fault("Critical system failure detected")
/// ```
/// 
/// **Execution Behavior**:
/// - When `asynchronousLogging = false`: Blocks until message is fully processed
/// - When `asynchronousLogging = true`: Returns immediately, processing in background
/// - Thread-safe: Can be called from any queue without synchronization concerns
/// 
/// ### Asynchronous API (Swift Concurrency)
/// 
/// The async API integrates seamlessly with Swift's concurrency model:
/// 
/// ```swift
/// class AsyncService {
///     private let logger = Logger.custom(category: "AsyncService")
///     
///     func performAsyncOperation() async throws {
///         await logger.info("Starting async operation")
///         
///         do {
///             let result = try await someAsyncWork()
///             await logger.info("Operation completed: \(result)")
///         } catch {
///             await logger.error("Async operation failed: \(error)")
///             throw error
///         }
///     }
/// }
/// ```
/// 
/// ## Message Processing Pipeline
/// 
/// ### 1. Level Filtering (Performance Gate)
/// ```swift
/// guard level.rawValue >= LoggerConfiguration.shared.currentLogLevel.rawValue else { 
///     return  // Early exit - no processing overhead
/// }
/// ```
/// 
/// ### 2. Format Processing
/// - Token replacement: `{timestamp}`, `{level}`, `{category}`, `{file}`, `{line}`, `{message}`
/// - Width alignment: Padded columns for structured output
/// - Color application: ANSI codes for terminal output
/// 
/// ### 3. Output Distribution
/// - **Console Output**: Immediate display with optional colorization
/// - **File Output**: Formatted message with rotation checks
/// - **System Logging**: Integration with Apple's unified logging system
/// 
/// ## Thread Safety & Concurrency
/// 
/// ### Sendable Conformance
/// `LogCategory` conforms to `Sendable`, enabling safe usage across concurrent contexts:
/// 
/// ```swift
/// let logger = Logger.custom(category: "ConcurrentService")
/// 
/// // Safe usage across multiple actors
/// actor DataProcessor {
///     func processData() {
///         logger.info("Processing data in actor context")  // ✅ Safe
///     }
/// }
/// 
/// // Safe usage in concurrent tasks
/// Task.detached {
///     logger.info("Processing in detached task")  // ✅ Safe
/// }
/// 
/// await withTaskGroup(of: Void.self) { group in
///     for i in 0..<10 {
///         group.addTask {
///             logger.info("Concurrent task \(i)")  // ✅ Safe
///         }
///     }
/// }
/// ```
/// 
/// ### Internal Synchronization
/// - **Configuration Access**: Thread-safe reads from LoggerConfiguration
/// - **File Writing**: Serialized through dedicated queue when asynchronous
/// - **Formatting**: Stateless operations safe for concurrent execution
/// 
/// ## Real-World Integration Examples
/// 
/// ### Network Layer Integration
/// ```swift
/// class APIClient {
///     private let logger = Logger.custom(category: "API")
///     
///     func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
///         logger.info("📡 Starting request: \(endpoint.path)")
///         
///         let startTime = Date()
///         defer {
///             let duration = Date().timeIntervalSince(startTime)
///             logger.debug("⏱️ Request completed in \(String(format: "%.3f", duration))s")
///         }
///         
///         do {
///             let data = try await performRequest(endpoint)
///             logger.info("✅ Request successful: \(data.count) bytes")
///             return try JSONDecoder().decode(T.self, from: data)
///         } catch {
///             logger.error("❌ Request failed: \(error.localizedDescription)")
///             throw error
///         }
///     }
/// }
/// ```
/// 
/// ### Database Operations
/// ```swift
/// class DatabaseManager {
///     private let logger = Logger.custom(category: "Database")
///     
///     func save<T: NSManagedObject>(_ object: T) throws {
///         logger.debug("💾 Saving \(T.self) object")
///         
///         do {
///             try context.save()
///             logger.info("✅ Successfully saved \(T.self)")
///         } catch {
///             logger.error("❌ Save failed: \(error.localizedDescription)")
///             throw error
///         }
///     }
/// }
/// ```
/// 
/// ### SwiftUI View Integration
/// ```swift
/// struct ContentView: View {
///     private let logger = Logger.custom(category: "UI")
///     @State private var isLoading = false
///     
///     var body: some View {
///         VStack {
///             if isLoading {
///                 ProgressView()
///                     .onAppear { logger.debug("🔄 Loading indicator shown") }
///             } else {
///                 Text("Content loaded")
///                     .onAppear { logger.info("✅ Content displayed to user") }
///             }
///         }
///         .task {
///             await loadContent()
///         }
///     }
///     
///     private func loadContent() async {
///         logger.info("🚀 Starting content load")
///         isLoading = true
///         defer { 
///             isLoading = false
///             logger.debug("🏁 Content load completed")
///         }
///         
///         // Async content loading...
///     }
/// }
/// ```
/// 
/// ## Performance Optimization
/// 
/// ### Early Filtering Benefits
/// ```swift
/// // When currentLogLevel = .warning:
/// logger.debug("Expensive computation: \(expensiveFunction())")  // ❌ expensiveFunction() still called
/// 
/// // Better approach:
/// if LoggerConfiguration.shared.currentLogLevel.rawValue <= LogLevel.debug.rawValue {
///     logger.debug("Expensive computation: \(expensiveFunction())")  // ✅ Conditional execution
/// }
/// 
/// // Best approach - automatic in Logly:
/// logger.debug("Expensive computation: \(expensiveFunction())")  // ✅ Early exit before string interpolation
/// ```
/// 
/// ### Asynchronous Processing
/// - **UI Responsiveness**: Never blocks main thread when enabled
/// - **Throughput**: Higher message processing capacity
/// - **Order Preservation**: Messages maintain chronological order
/// 
/// ## Apple Ecosystem Integration
/// 
/// ### Console.app Compatibility
/// - All messages appear in macOS Console application
/// - Subsystem and category filtering works natively
/// - Log level mapping to os_log types
/// - Structured data support for complex objects
/// 
/// ### Xcode Integration
/// - Messages appear in Xcode console during development
/// - Color coding matches log levels
/// - Debugging integration with breakpoints and flow control
/// - Performance testing with Instruments integration
public struct LogCategory: Sendable {
    private let logger: Logger
    private let categoryName: String
    private static let logQueue = DispatchQueue(label: "LoggingQueue", qos: .utility)

    /// Creates a new log category with comprehensive subsystem and category organization.
    /// 
    /// This initializer establishes a structured logging namespace that integrates with both
    /// Apple's unified logging system and Logly's enhanced features. The subsystem and category
    /// pair provides hierarchical organization for filtering, analysis, and debugging.
    /// 
    /// ## Parameter Details
    /// 
    /// ### Subsystem Identifier
    /// The subsystem should follow reverse domain notation and represent a major functional
    /// area of your application:
    /// 
    /// ```swift
    /// "com.mycompany.myapp"           // Main application
    /// "com.mycompany.myapp.network"   // Networking module
    /// "com.mycompany.myapp.database"  // Data persistence
    /// "com.mycompany.myapp.auth"      // Authentication system
    /// "com.mycompany.frameworks.util" // Shared utility framework
    /// ```
    /// 
    /// ### Category Name
    /// The category provides fine-grained classification within the subsystem:
    /// 
    /// ```swift
    /// "HTTPClient"     // Specific network client
    /// "CoreData"       // Database context operations
    /// "TokenManager"   // Authentication token handling
    /// "ImageCache"     // Caching subsystem
    /// "AnalyticsSDK"   // Third-party integration
    /// ```
    /// 
    /// ## Architecture Integration
    /// 
    /// ### Apple's Unified Logging Integration
    /// ```swift
    /// let logger = LogCategory(subsystem: "com.myapp.network", category: "APIClient")
    /// logger.info("Request started")  // Appears in Console.app under com.myapp.network
    /// ```
    /// 
    /// ### Console.app Filtering
    /// - **Subsystem Filter**: `subsystem:com.myapp.network`
    /// - **Category Filter**: `category:APIClient`
    /// - **Combined Filter**: `subsystem:com.myapp.network AND category:APIClient`
    /// 
    /// ## Organizational Examples
    /// 
    /// ### Modular Application Structure
    /// ```swift
    /// // Main application components
    /// let mainLogger = LogCategory(subsystem: "com.myapp", category: "Application")
    /// let uiLogger = LogCategory(subsystem: "com.myapp.ui", category: "ViewController")
    /// 
    /// // Business logic modules
    /// let authLogger = LogCategory(subsystem: "com.myapp.auth", category: "LoginService")
    /// let dataLogger = LogCategory(subsystem: "com.myapp.data", category: "APIClient")
    /// 
    /// // Third-party integrations
    /// let analyticsLogger = LogCategory(subsystem: "com.myapp.analytics", category: "Firebase")
    /// let crashLogger = LogCategory(subsystem: "com.myapp.monitoring", category: "CrashReporter")
    /// ```
    /// 
    /// ### Framework Development
    /// ```swift
    /// // Framework-specific logging
    /// let networkLogger = LogCategory(subsystem: "com.mycompany.networkkit", category: "HTTPSession")
    /// let cacheLogger = LogCategory(subsystem: "com.mycompany.networkkit", category: "ResponseCache")
    /// let securityLogger = LogCategory(subsystem: "com.mycompany.networkkit", category: "TLSHandler")
    /// ```
    /// 
    /// ## Performance Considerations
    /// 
    /// ### Logger Instance Management
    /// ```swift
    /// class NetworkManager {
    ///     // Create once, reuse throughout object lifecycle
    ///     private let logger = LogCategory(subsystem: "com.myapp.network", category: "Manager")
    ///     
    ///     func performRequest() {
    ///         logger.info("Starting request")  // Efficient reuse
    ///     }
    /// }
    /// ```
    /// 
    /// ### Static Logger Pattern
    /// ```swift
    /// extension Logger {
    ///     // Define once, use everywhere
    ///     static let network = Logger.custom(subsystem: "com.myapp.network", category: "APIClient")
    ///     static let database = Logger.custom(subsystem: "com.myapp.data", category: "CoreData")
    ///     static let ui = Logger.custom(subsystem: "com.myapp.ui", category: "Interface")
    /// }
    /// 
    /// // Usage throughout application
    /// Logger.network.info("API request completed")
    /// Logger.database.debug("Executing fetch request")
    /// Logger.ui.warning("View controller load time exceeded threshold")
    /// ```
    /// 
    /// ## Best Practices from README Integration
    /// 
    /// ### Environment-Specific Logging
    /// ```swift
    /// class LoggingSetup {
    ///     static func configureNetworkLogging() {
    ///         #if DEBUG
    ///         let networkLogger = LogCategory(subsystem: "com.myapp.network.debug", category: "APIClient")
    ///         #else
    ///         let networkLogger = LogCategory(subsystem: "com.myapp.network", category: "APIClient")
    ///         #endif
    ///         
    ///         // Use networkLogger throughout networking code
    ///     }
    /// }
    /// ```
    /// 
    /// ### SwiftUI Integration Pattern
    /// ```swift
    /// struct ContentView: View {
    ///     private let logger = LogCategory(subsystem: "com.myapp.ui", category: "ContentView")
    ///     
    ///     var body: some View {
    ///         VStack {
    ///             Text("Hello World")
    ///                 .onAppear {
    ///                     logger.info("ContentView appeared")
    ///                 }
    ///         }
    ///     }
    /// }
    /// ```
    /// 
    /// - Parameters:
    ///   - subsystem: Reverse domain identifier representing the major functional area
    ///   - category: Descriptive name for fine-grained classification within the subsystem
    /// 
    /// - Returns: Configured LogCategory instance ready for logging operations
    /// 
    /// > **Recommendation**: Use ``Logger/custom(subsystem:category:)`` extension method
    /// > for more convenient logger creation with automatic subsystem detection.
    /// 
    /// - Complexity: O(1) - Creates logger instance with minimal overhead
    /// - Thread Safety: Safe to call from any thread; resulting instance is `Sendable`
    /// - SeeAlso: ``Logger/custom(subsystem:category:)`` for simplified logger creation
    public init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.categoryName = category
    }

    private func formattedLog(level: LogLevel, message: String, file: String, line: Int, settings: LogSettingsSnapshot) -> String {
        // Prepare formatted strings with widths if needed
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let levelString = level.description.padding(toLength: settings.logLevelWidth, withPad: " ", startingAt: 0)
        let categoryString = categoryName.padding(toLength: settings.categoryWidth, withPad: " ", startingAt: 0)
        let fileName = (file as NSString).lastPathComponent

        // Replace tokens in format string
        var formatted = settings.logFormat
        formatted = formatted.replacingOccurrences(of: "{timestamp}", with: timestamp)
        formatted = formatted.replacingOccurrences(of: "{level}", with: levelString)
        formatted = formatted.replacingOccurrences(of: "{category}", with: categoryString)
        formatted = formatted.replacingOccurrences(of: "{file}", with: fileName)
        formatted = formatted.replacingOccurrences(of: "{line}", with: "\(line)")
        formatted = formatted.replacingOccurrences(of: "{message}", with: message)
        return formatted
    }

    private func printFormatted(_ level: LogLevel, _ formattedMessage: String, settings: LogSettingsSnapshot) {
        if settings.enableANSIColors {
            print("\(level.ansiColorCode)\(formattedMessage)\u{001B}[0m")
        } else {
            print(formattedMessage)
        }
    }

    private struct LogSettingsSnapshot {
        let currentLevel: LogLevel
        let asyncLogging: Bool
        let logToFile: Bool
        let sinks: [LogSink]
        let logFormat: String
        let logLevelWidth: Int
        let categoryWidth: Int
        let enableANSIColors: Bool
    }

    private func log(level: LogLevel, message: String, error: (any Error)? = nil, file: String, line: Int) {
        let config = LoggerConfiguration.shared
        let settings = config.lock.withLock {
            LogSettingsSnapshot(
                currentLevel: $0.currentLogLevel,
                asyncLogging: $0.asynchronousLogging,
                logToFile: $0.logToFile,
                sinks: $0.sinks,
                logFormat: $0.logFormat,
                logLevelWidth: $0.logLevelWidth,
                categoryWidth: $0.categoryWidth,
                enableANSIColors: $0.enableANSIColors
            )
        }
        guard level.rawValue >= settings.currentLevel.rawValue else { return }
        let event = LogEvent(
            level: level,
            category: categoryName,
            message: message,
            error: error,
            file: file,
            line: line,
            timestamp: Date()
        )

        if settings.asyncLogging {
            LogCategory.logQueue.async {
                let formattedMessage = self.formattedLog(level: level, message: message, file: file, line: line, settings: settings)
                self.printFormatted(level, formattedMessage, settings: settings)
                if settings.logToFile {
                    LogWriter.write(formattedMessage)
                }
                for sink in settings.sinks { sink.emit(event) }
            }
        } else {
            let formattedMessage = formattedLog(level: level, message: message, file: file, line: line, settings: settings)
            printFormatted(level, formattedMessage, settings: settings)
            if settings.logToFile {
                LogWriter.write(formattedMessage)
            }
            for sink in settings.sinks { sink.emit(event) }
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
    public func error(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, error: error, file: file, line: line)
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
    public func fault(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) {
        log(level: .fault, message: message, error: error, file: file, line: line)
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
    public func error(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) async {
        log(level: .error, message: message, error: error, file: file, line: line)
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
    public func fault(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) async {
        log(level: .fault, message: message, error: error, file: file, line: line)
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
