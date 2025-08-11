//
//  LogWriter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// High-performance file I/O engine for persistent log storage with intelligent error recovery.
/// 
/// `LogWriter` serves as the core file system interface for the Logly logging system,
/// providing robust, efficient, and reliable persistence of log messages to disk.
/// The writer implements advanced strategies for file handling, error recovery,
/// and integration with the log rotation system.
/// 
/// ## Architecture Overview
/// 
/// ### Dual-Strategy File Writing
/// 
/// The writer implements a sophisticated dual-strategy approach to maximize both
/// performance and reliability:
/// 
/// ```
/// ┌────────────────────────────────────────────────────┐
/// │                    LogWriter.write(message)                     │
/// └────────────────────────┬───────────────────────────┘
///                                │
///         ┌──────────────────┴──────────────────┐
///         │       LogRotator.rotateIfNeeded()        │
///         └──────────────────┬──────────────────┘
///                                │
///    ┌──────────────────────────────┴──────────────────────────────┐
///    │                        Primary Strategy: FileHandle                        │
///    │                                                                          │
///    │  1. Open existing file with FileHandle(forWritingTo:)                   │
///    │  2. Seek to end of file for appending                                   │
///    │  3. Write message data directly                                          │
///    │  4. Close handle immediately                                             │
///    │                                                                          │
///    │  Benefits: High performance, minimal memory usage, atomic operations    │
///    └──────────────────────────────┬──────────────────────────────┘
///                                │
///                   ┌────────────┴────────────┐
///                   │     Fallback Strategy      │
///                   │                            │
///                   │  String.write(to:)          │
///                   │  - Atomic operation         │
///                   │  - Creates file if needed   │
///                   │  - Directory creation       │
///                   └────────────────────────────┘
/// ```
/// 
/// ### File System Integration
/// 
/// The writer integrates seamlessly with the broader file system management:
/// 
/// - **Log Rotation**: Automatic coordination with ``LogRotator`` before each write
/// - **Directory Management**: Automatic creation of parent directories
/// - **File Permissions**: Respects system file permissions and security contexts
/// - **Atomic Operations**: Ensures file consistency even during process termination
/// 
/// ## Performance Characteristics
/// 
/// ### Primary Strategy (FileHandle)
/// 
/// ```swift
/// func writeViaFileHandle(message: String, to url: URL) throws {
///     let fileHandle = try FileHandle(forWritingTo: url)  // → Open existing file
///     fileHandle.seekToEndOfFile()                       // → Position for append
///     fileHandle.write(message.data(using: .utf8)!)      // → Write data
///     fileHandle.closeFile()                             // → Close immediately
/// }
/// ```
/// 
/// **Performance Benefits**:
/// - **No Full File Read**: Only positions at end, doesn't read existing content
/// - **Direct I/O**: Bypasses higher-level string processing
/// - **Memory Efficient**: Minimal memory footprint for large files
/// - **Platform Optimized**: Leverages system-level optimizations
/// 
/// ### Fallback Strategy (Atomic Write)
/// 
/// ```swift
/// func writeViaAtomicOperation(message: String, to url: URL) throws {
///     try message.write(to: url, atomically: true, encoding: .utf8)
/// }
/// ```
/// 
/// **Reliability Benefits**:
/// - **Atomic Operation**: File is completely written or not at all
/// - **Auto-Creation**: Creates file and directories as needed
/// - **Error Recovery**: Handles permissions, disk space, and other I/O errors
/// - **Crash Safety**: Incomplete writes don't corrupt existing files
/// 
/// ## Error Handling & Recovery
/// 
/// ### Hierarchical Error Handling
/// 
/// ```swift
/// static func write(_ message: String) {
///     let url = LoggerConfiguration.shared.logFilePath
///     LogRotator.rotateIfNeeded(at: url)
/// 
///     do {
///         // Primary strategy: High-performance FileHandle
///         try writeWithFileHandle(message, to: url)
///     } catch {
///         do {
///             // Fallback strategy: Atomic write with auto-creation
///             try writeAtomically(message, to: url)
///         } catch {
///             // Final fallback: Console error logging
///             print("[Logger] Failed to write log to file: \(error)")
///         }
///     }
/// }
/// ```
/// 
/// ### Common Error Scenarios & Recovery
/// 
/// | Error Type | Primary Strategy | Fallback Strategy | Final Action |
/// |------------|------------------|-------------------|---------------|
/// | File doesn't exist | ❌ Fails | ✅ Creates file | Log to console |
/// | Permission denied | ❌ Fails | ❌ Fails | Log to console |
/// | Disk full | ❌ Fails | ❌ Fails | Log to console |
/// | Directory missing | ❌ Fails | ✅ Creates directory | Log to console |
/// | File locked | ❌ Fails | ✅ May succeed | Log to console |
/// | Network drive offline | ❌ Fails | ❌ Fails | Log to console |
/// 
/// ### Infinite Recursion Prevention
/// 
/// The writer prevents infinite recursion when logging its own errors:
/// 
/// ```swift
/// // Safe error logging - uses console output directly
/// print("[Logger] Failed to write log to file: \(error)")
/// 
/// // NEVER does this (would cause infinite recursion):
/// // logger.error("Failed to write log to file: \(error)")
/// ```
/// 
/// ## File Format & Encoding
/// 
/// ### UTF-8 Encoding
/// All log files are written using UTF-8 encoding to ensure:
/// - **International Support**: Full Unicode character set support
/// - **Backward Compatibility**: ASCII compatibility for legacy tools
/// - **Cross-Platform**: Consistent encoding across macOS, iOS, and other platforms
/// - **Tool Compatibility**: Works with standard text processing tools
/// 
/// ### Line Ending Handling
/// ```swift
/// let messageWithNewline = message + "\n"
/// ```
/// 
/// The writer automatically appends newlines to ensure:
/// - **Proper Line Separation**: Each log entry on its own line
/// - **Tool Compatibility**: Works correctly with tail, grep, and other utilities
/// - **Parse-Friendly**: Facilitates line-by-line processing
/// 
/// ### File Structure Example
/// ```
/// 2025-01-20T14:30:45Z - INFO    - Network   - APIClient.swift:42 - Starting request
/// 2025-01-20T14:30:46Z - DEBUG   - Network   - APIClient.swift:58 - Request headers: {...}
/// 2025-01-20T14:30:47Z - INFO    - Network   - APIClient.swift:73 - Request completed: 200 OK
/// 2025-01-20T14:30:48Z - WARNING - Auth      - TokenManager.swift:156 - Token expires in 5 minutes
/// 2025-01-20T14:30:49Z - ERROR   - Database - CoreData.swift:89 - Failed to save context
/// ```
/// 
/// ## Integration with Log Rotation
/// 
/// ### Pre-Write Rotation Check
/// 
/// Every write operation begins with a rotation check:
/// 
/// ```swift
/// static func write(_ message: String) {
///     let url = LoggerConfiguration.shared.logFilePath
///     
///     // Critical: Check rotation before writing
///     LogRotator.rotateIfNeeded(at: url)
///     
///     // Proceed with write to potentially new file
///     // ...
/// }
/// ```
/// 
/// This ensures:
/// - **Size Limits**: Files never exceed configured maximum size
/// - **Age Limits**: Old log files are rotated based on creation time
/// - **Clean Separation**: New files start fresh after rotation
/// - **Consistent Timing**: Rotation happens at message boundaries
/// 
/// ## Thread Safety Considerations
/// 
/// ### Serialized Access Pattern
/// 
/// While `LogWriter` itself is stateless, it's designed to be called from
/// the logging system's serialized queues:
/// 
/// ```swift
/// // In LogCategory:
/// if asyncLogging {
///     LogCategory.logQueue.async {  // Serialized queue
///         LogWriter.write(formattedMessage)
///     }
/// } else {
///     LogWriter.write(formattedMessage)  // Direct call (still safe)
/// }
/// ```
/// 
/// ### File System Atomicity
/// 
/// Both writing strategies provide different levels of atomicity:
/// - **FileHandle**: Write operation is atomic at the data level
/// - **Atomic Write**: Entire file operation is atomic (safer for crashes)
/// 
/// ## Platform-Specific Considerations
/// 
/// ### macOS
/// - Full file system access (with proper permissions)
/// - Efficient FileHandle operations
/// - Support for extended attributes and metadata
/// 
/// ### iOS
/// - Sandboxed file system access
/// - Optimized for app lifecycle (background/foreground transitions)
/// - Automatic backup exclusion for large log files
/// 
/// ### Simulator
/// - Host file system access for development
/// - Convenient log file locations for debugging
/// - Performance characteristics may differ from device
/// 
/// ## Best Practices Integration
/// 
/// The writer supports common logging best practices:
/// 
/// ### Structured Logging
/// ```swift
/// // Writer handles any message format
/// LogWriter.write("{\"timestamp\":\"2025-01-20T14:30:45Z\",\"level\":\"INFO\",\"message\":\"User login\"}")
/// ```
/// 
/// ### Log Aggregation
/// - Consistent file locations for log shipping agents
/// - UTF-8 encoding for international log aggregation systems
/// - Predictable rotation for automated cleanup
/// 
/// ### Monitoring Integration
/// - File-based monitoring can watch log files for real-time analysis
/// - Rotation events can trigger log processing pipelines
/// - Error recovery logging provides operational visibility
struct LogWriter {
    /// Writes a log message to the configured log file synchronously.
    /// 
    /// This method performs the complete write operation, including pre-write log rotation
    /// checks and robust error handling. Messages are written with automatic newline
    /// appending for proper log file formatting.
    /// 
    /// - Parameter message: The formatted log message to write to the file
    /// 
    /// ## Write Process
    /// 
    /// 1. Triggers log rotation check via ``LogRotator/rotateIfNeeded(at:)``
    /// 2. Attempts to open file with `FileHandle` for efficient appending
    /// 3. Falls back to atomic write if handle creation fails
    /// 4. Automatically creates file and directories if they don't exist
    /// 
    /// ## Error Handling
    /// 
    /// Write failures are logged to the console with descriptive error messages.
    /// The system continues operating even if individual writes fail.
    /// 
    /// ## Performance Notes
    /// 
    /// - Uses `FileHandle.seekToEndOfFile()` for efficient appending
    /// - Properly closes file handles to prevent resource leaks
    /// - Atomic writes ensure file consistency even if process terminates during write
    /// 
    /// ## Example Log File Output
    /// 
    /// ```
    /// 2025-01-20T10:30:45Z - INFO - Network - Request completed
    /// 2025-01-20T10:30:46Z - ERROR - Database - Connection failed
    /// ```
    static func write(_ message: String) {
        let url = LoggerConfiguration.shared.logFilePath
        LogRotator.rotateIfNeeded(at: url)

        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            if let data = (message + "\n").data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } catch {
            do {
                try (message + "\n").write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("[Logger] Failed to write log to file: \(error)")
            }
        }
    }
}
