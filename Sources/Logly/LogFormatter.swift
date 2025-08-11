//
//  LogFormatter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// Internal utility for formatting log messages according to the configured template.
/// 
/// `LogFormatter` handles the conversion of log message components (level, category, timestamp, etc.)
/// into formatted strings using the template pattern specified in ``LoggerConfiguration/logFormat``.
/// 
/// ## Template Processing
/// 
/// The formatter processes templates containing tokens that are replaced with actual values:
/// 
/// - `{timestamp}`: Current time in ISO8601 format
/// - `{level}`: Log level name, padded to configured width
/// - `{category}`: Logger category name, padded to configured width  
/// - `{file}`: Source filename (without directory path)
/// - `{line}`: Source line number
/// - `{message}`: The actual log message content
/// 
/// ## Usage
/// 
/// This struct is used internally by the logging system and is not intended for direct use.
/// Message formatting is automatically handled when logging through ``LogCategory`` methods.
/// 
/// ## Performance Considerations
/// 
/// - Timestamp formatting uses a shared `ISO8601DateFormatter` instance
/// - String padding operations are optimized for consistent column alignment
/// - Template token replacement is performed efficiently using string substitution
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
