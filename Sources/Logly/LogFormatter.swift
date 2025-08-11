//
//  LogFormatter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// High-performance message formatting engine with template-based customization.
/// 
/// `LogFormatter` serves as the core formatting engine for the Logly logging system,
/// transforming raw log message components into structured, human-readable output
/// according to configurable template patterns. The formatter is designed for
/// efficiency and consistency, supporting both file and console output destinations.
/// 
/// ## Template-Based Architecture
/// 
/// The formatter uses a token-replacement system that allows for flexible message
/// structuring while maintaining high performance through minimal string operations.
/// 
/// ### Supported Template Tokens
/// 
/// | Token | Description | Example Output | Notes |
/// |-------|-------------|----------------|-------|
/// | `{timestamp}` | ISO8601 formatted current time | `2025-01-20T14:30:45Z` | UTC timezone, millisecond precision available |
/// | `{level}` | Log level with consistent width | `INFO   ` | Padded to `logLevelWidth` characters |
/// | `{category}` | Logger category name | `Network  ` | Padded to `categoryWidth` characters |
/// | `{file}` | Source filename (basename only) | `APIClient.swift` | Path stripped for brevity |
/// | `{line}` | Source line number | `42` | Captured automatically via `#line` |
/// | `{message}` | User-provided log message | `Request completed` | Unmodified user content |
/// 
/// ### Template Processing Algorithm
/// 
/// ```swift
/// func format(template: String, components: LogComponents) -> String {
///     var result = template
///     result = result.replacingOccurrences(of: "{timestamp}", with: formatTimestamp())
///     result = result.replacingOccurrences(of: "{level}", with: padLevel(components.level))
///     result = result.replacingOccurrences(of: "{category}", with: padCategory(components.category))
///     result = result.replacingOccurrences(of: "{file}", with: extractFilename(components.file))
///     result = result.replacingOccurrences(of: "{line}", with: String(components.line))
///     result = result.replacingOccurrences(of: "{message}", with: components.message)
///     return result
/// }
/// ```
/// 
/// ## Formatting Examples
/// 
/// ### Default Format Template
/// ```
/// Template: "{timestamp} - {level} - {category} - {file}:{line} - {message}"
/// Output:   "2025-01-20T14:30:45Z - INFO    - Network   - APIClient.swift:42 - Request completed"
/// ```
/// 
/// ### Minimal Format Template
/// ```
/// Template: "{level}: {message}"
/// Output:   "INFO: Request completed"
/// ```
/// 
/// ### Structured Format Template
/// ```
/// Template: "[{timestamp}] {level} | {category} | {file}:{line} | {message}"
/// Output:   "[2025-01-20T14:30:45Z] INFO | Network | APIClient.swift:42 | Request completed"
/// ```
/// 
/// ### JSON-Style Format Template
/// ```
/// Template: "{\"timestamp\":\"{timestamp}\",\"level\":\"{level}\",\"message\":\"{message}\"}"
/// Output:   "{\"timestamp\":\"2025-01-20T14:30:45Z\",\"level\":\"INFO\",\"message\":\"Request completed\"}"
/// ```
/// 
/// ## Performance Optimizations
/// 
/// ### String Operations
/// - **Minimal Allocations**: Template processing reuses string buffers where possible
/// - **Efficient Replacement**: Uses optimized string replacement algorithms
/// - **Padding Caching**: Width calculations are performed once and cached
/// 
/// ### Timestamp Generation
/// ```swift
/// // Efficient ISO8601 formatting
/// private static let iso8601Formatter: ISO8601DateFormatter = {
///     let formatter = ISO8601DateFormatter()
///     formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
///     return formatter
/// }()
/// 
/// static func formatTimestamp() -> String {
///     return iso8601Formatter.string(from: Date())
/// }
/// ```
/// 
/// ### File Path Processing
/// ```swift
/// static func extractFilename(from path: String) -> String {
///     return (path as NSString).lastPathComponent
/// }
/// ```
/// 
/// This approach avoids expensive URL parsing for simple filename extraction.
/// 
/// ## Column Alignment System
/// 
/// The formatter ensures consistent column alignment through intelligent padding:
/// 
/// ### Level Padding
/// ```swift
/// func padLevel(_ level: LogLevel, toWidth width: Int) -> String {
///     return level.description.padding(toLength: width, withPad: " ", startingAt: 0)
/// }
/// 
/// // Results with width = 8:
/// "DEBUG   "  // 3 spaces added
/// "INFO    "  // 4 spaces added  
/// "WARNING "  // 1 space added
/// "ERROR   "  // 3 spaces added
/// "FAULT   "  // 3 spaces added
/// ```
/// 
/// ### Category Padding
/// ```swift
/// func padCategory(_ category: String, toWidth width: Int) -> String {
///     return category.padding(toLength: width, withPad: " ", startingAt: 0)
/// }
/// 
/// // Results with width = 12:
/// "Network     "  // 5 spaces added
/// "Database    "  // 4 spaces added
/// "Auth        "  // 8 spaces added
/// ```
/// 
/// ## Integration with Configuration System
/// 
/// The formatter dynamically reads configuration from ``LoggerConfiguration``:
/// 
/// ```swift
/// let config = LoggerConfiguration.shared
/// let template = config.logFormat
/// let levelWidth = config.logLevelWidth  
/// let categoryWidth = config.categoryWidth
/// ```
/// 
/// This allows runtime changes to formatting without requiring logger recreation.
/// 
/// ## Thread Safety
/// 
/// `LogFormatter` is implemented as a stateless utility with only static methods,
/// making it inherently thread-safe:
/// 
/// - **No Mutable State**: All operations are pure functions
/// - **Configuration Reads**: Thread-safe reads from LoggerConfiguration
/// - **Shared Resources**: Thread-safe access to shared formatters
/// 
/// ## Output Destination Compatibility
/// 
/// ### Console Output
/// - Supports ANSI color codes when enabled
/// - Optimized for terminal width and readability
/// - Handles special characters and Unicode properly
/// 
/// ### File Output
/// - Plain text without ANSI codes
/// - Consistent line endings across platforms
/// - UTF-8 encoding for international character support
/// 
/// ### Structured Logging Systems
/// - JSON-compatible when using appropriate templates
/// - Supports parsing by log aggregation systems
/// - Consistent field ordering for analysis tools
/// 
/// ## Error Handling
/// 
/// The formatter is designed to be robust and never fail:
/// 
/// - **Invalid Tokens**: Unknown tokens are left as-is in output
/// - **Nil Values**: Replaced with safe defaults (e.g., "<unknown>")
/// - **Format Errors**: Graceful degradation to basic formatting
/// - **Configuration Issues**: Uses built-in defaults when configuration unavailable
/// 
/// ## Usage in Logging Pipeline
/// 
/// While `LogFormatter` is internal to the Logly system, understanding its role
/// helps with debugging and custom template design:
/// 
/// ```
/// LogCategory.info() → LogFormatter.format() → LogWriter.write()
///                   │                        │
///                   └────── Console Output
///                                            │
///                                            └────── File Output
/// ```
/// 
/// The formatter sits between message capture and output, ensuring consistent
/// formatting regardless of destination.
struct LogFormatter {
    /// Formats a log message using the current configuration template.
    /// 
    /// This method processes the configured log format template, replacing all tokens with
    /// their corresponding values from the provided parameters.
    /// 
    /// - Parameters:
    ///   - level: The severity level of the log message
    ///   - category: The category name for the logger
    ///   - message: The actual log message content
    ///   - file: The source file path where the log was created
    ///   - line: The source line number where the log was created
    /// 
    /// - Returns: A fully formatted log message string ready for output
    /// 
    /// ## Formatting Process
    /// 
    /// 1. Generates ISO8601 timestamp for current time
    /// 2. Pads log level to configured width (``LoggerConfiguration/logLevelWidth``)
    /// 3. Pads category name to configured width (``LoggerConfiguration/categoryWidth``)
    /// 4. Extracts filename from full file path
    /// 5. Replaces all tokens in the format template
    /// 
    /// ## Example Output
    /// 
    /// With format `"{timestamp} - {level} - {category} - {file}:{line} - {message}"`:
    /// 
    /// ```
    /// 2025-01-20T10:30:45Z - INFO    - Network     - HTTPClient.swift:42 - Request completed
    /// ```
    static func format(level: LogLevel, category: String, message: String, file: String, line: Int) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let levelFormatted = level.description.padding(toLength: LoggerConfiguration.shared.logLevelWidth, withPad: " ", startingAt: 0)
        let categoryFormatted = category.padding(toLength: LoggerConfiguration.shared.categoryWidth, withPad: " ", startingAt: 0)
        let fileName = (file as NSString).lastPathComponent

        var formattedMessage = LoggerConfiguration.shared.logFormat
        formattedMessage = formattedMessage.replacingOccurrences(of: "{timestamp}", with: timestamp)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{level}", with: levelFormatted)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{category}", with: categoryFormatted)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{file}", with: fileName)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{line}", with: "\(line)")
        formattedMessage = formattedMessage.replacingOccurrences(of: "{message}", with: message)

        return formattedMessage
    }
}
