//
//  LogRotator.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

struct LogRotator {
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
