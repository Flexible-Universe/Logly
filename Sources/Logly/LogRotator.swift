//
//  LogRotator.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// Internal utility responsible for automatic log file rotation and cleanup.
/// 
/// `LogRotator` monitors log files and automatically rotates them based on size and age
/// constraints configured in ``LoggerConfiguration``. It also manages cleanup of old
/// rotated files to prevent unlimited disk usage.
/// 
/// ## Rotation Triggers
/// 
/// Log rotation occurs when either condition is met:
/// - File size exceeds ``LoggerConfiguration/maxFileSizeInBytes``
/// - File age exceeds ``LoggerConfiguration/maxLogAge``
/// 
/// ## Rotation Process
/// 
/// 1. Current log file is renamed with ISO8601 timestamp suffix
/// 2. New log file is created at the original location
/// 3. Old rotated files beyond ``LoggerConfiguration/maxRotatedFiles`` limit are deleted
/// 
/// ## Naming Convention
/// 
/// Rotated files follow the pattern: `{original_name}_{timestamp}.log`
/// 
/// Example: `app.log` → `app_2025-01-20T10-30-45Z.log`
/// 
/// ## Thread Safety
/// 
/// The rotator is designed to be called from serialized logging queues to prevent
/// race conditions during file operations.
/// 
/// ## Usage
/// 
/// This struct is used internally by ``LogWriter`` and is not intended for direct use.
/// Rotation is automatically triggered before each log write operation.
struct LogRotator {
    /// Checks if log rotation is needed and performs rotation if necessary.
    /// 
    /// This method examines the specified log file against configured size and age
    /// limits, performing rotation and cleanup when thresholds are exceeded.
    /// 
    /// - Parameter url: The URL of the log file to check for rotation
    /// 
    /// ## Rotation Criteria
    /// 
    /// Rotation occurs when either condition is met:
    /// - File size ≥ ``LoggerConfiguration/maxFileSizeInBytes``
    /// - File age ≥ ``LoggerConfiguration/maxLogAge``
    /// 
    /// ## Process Flow
    /// 
    /// 1. Check if file exists (exit early if not)
    /// 2. Evaluate size-based rotation criteria
    /// 3. Evaluate age-based rotation criteria  
    /// 4. If rotation needed, rename current file with timestamp
    /// 5. Clean up excess rotated files
    /// 
    /// ## Error Handling
    /// 
    /// File operation errors are logged to console and don't interrupt the logging process.
    /// The system gracefully continues even if rotation fails.
    /// 
    /// ## Example
    /// 
    /// ```
    /// // Before rotation
    /// app.log (5.2 MB, created 2 days ago)
    /// 
    /// // After rotation  
    /// app.log (0 bytes, just created)
    /// app_2025-01-20T10-30-45Z.log (5.2 MB, archived)
    /// ```
    static func rotateIfNeeded(at url: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return }

        var shouldRotate = false

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            let maxFileSize = LoggerConfiguration.shared.maxFileSizeInBytes
            if fileSize >= maxFileSize {
                shouldRotate = true
            }
        }

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let creationDate = attributes[.creationDate] as? Date {
            let age = Date().timeIntervalSince(creationDate)
            let maxLogAge = LoggerConfiguration.shared.maxLogAge
            if age >= maxLogAge {
                shouldRotate = true
            }
        }

        if shouldRotate {
            let dateString = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let rotatedURL = url.deletingLastPathComponent().appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)_\(dateString).log")
            do {
                try fileManager.moveItem(at: url, to: rotatedURL)
                cleanUpOldLogFiles(directory: url.deletingLastPathComponent(), baseName: url.deletingPathExtension().lastPathComponent)
            } catch {
                print("[Logger] Failed to rotate log file: \(error)")
            }
        }
    }

    /// Removes excess rotated log files beyond the configured retention limit.
    /// 
    /// This method scans the log directory for rotated files matching the base name pattern,
    /// sorts them by creation date, and removes the oldest files that exceed the
    /// ``LoggerConfiguration/maxRotatedFiles`` limit.
    /// 
    /// - Parameters:
    ///   - directory: The directory containing log files
    ///   - baseName: The base name of the log file (without extension or timestamp)
    /// 
    /// ## Cleanup Process
    /// 
    /// 1. Scan directory for files matching `{baseName}_{timestamp}.log` pattern
    /// 2. Sort files by creation date (oldest first)
    /// 3. Calculate excess file count beyond retention limit
    /// 4. Remove oldest excess files
    /// 
    /// ## File Selection
    /// 
    /// Only files that:
    /// - Have names starting with the base name followed by underscore
    /// - Have `.log` extension
    /// - Can be identified as rotated files (contain timestamp)
    /// 
    /// ## Error Handling
    /// 
    /// Individual file deletion failures are silently ignored to prevent
    /// interrupting the logging process. Permissions or file system issues
    /// won't crash the application.
    /// 
    /// ## Example
    /// 
    /// With `maxRotatedFiles = 3` and files:
    /// ```
    /// app_2025-01-18T08-00-00Z.log  ← Will be deleted (oldest)
    /// app_2025-01-19T08-00-00Z.log  ← Will be deleted (old)
    /// app_2025-01-20T08-00-00Z.log  ← Kept
    /// app_2025-01-21T08-00-00Z.log  ← Kept
    /// app_2025-01-22T08-00-00Z.log  ← Kept (newest)
    /// ```
    private static func cleanUpOldLogFiles(directory: URL, baseName: String) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: []) else { return }

        let rotatedFiles = files.filter { $0.lastPathComponent.hasPrefix("\(baseName)_") && $0.pathExtension == "log" }

        let sortedFiles = rotatedFiles.sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 < date2
        }

        let maxRotatedFiles = LoggerConfiguration.shared.maxRotatedFiles
        let excessCount = sortedFiles.count - maxRotatedFiles
        guard excessCount > 0 else { return }

        for file in sortedFiles.prefix(excessCount) {
            try? fileManager.removeItem(at: file)
        }
    }
}
