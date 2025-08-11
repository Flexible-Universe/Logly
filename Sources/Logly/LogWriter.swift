//
//  LogWriter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// Internal utility responsible for writing log messages to the file system.
/// 
/// `LogWriter` handles the low-level file I/O operations for persistent log storage.
/// It coordinates with ``LogRotator`` to ensure log rotation occurs before writing,
/// and provides robust error handling for file system operations.
/// 
/// ## File Handling Strategy
/// 
/// The writer attempts to use `FileHandle` for efficient appending to existing files,
/// falling back to atomic file writing if the handle approach fails. This provides
/// both performance and reliability.
/// 
/// ## Error Recovery
/// 
/// When file operations fail, errors are logged to the console with the prefix "[Logger]"
/// to avoid infinite recursion in the logging system.
/// 
/// ## Thread Safety
/// 
/// While the writer itself doesn't provide thread safety, it's designed to be called
/// from the logging system's serialized queues to ensure proper ordering of writes.
/// 
/// ## Usage
/// 
/// This struct is used internally by ``LogCategory`` and is not intended for direct use.
/// All file writing is automatically handled when ``LoggerConfiguration/logToFile`` is enabled.
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
