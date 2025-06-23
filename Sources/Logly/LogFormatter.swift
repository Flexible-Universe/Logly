//
//  LogFormatter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

struct LogFormatter {
    static func format(level: LogLevel, category: String, message: String, file: String, line: Int) async -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let levelFormatted = level.description.padding(toLength: await LoggerConfiguration.shared.getLogLevelWidth(), withPad: " ", startingAt: 0)
        let categoryFormatted = category.padding(toLength: await LoggerConfiguration.shared.getCategoryWidth(), withPad: " ", startingAt: 0)
        let fileName = (file as NSString).lastPathComponent

        var formattedMessage = await LoggerConfiguration.shared.getLogFormat()
        formattedMessage = formattedMessage.replacingOccurrences(of: "{timestamp}", with: timestamp)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{level}", with: levelFormatted)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{category}", with: categoryFormatted)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{file}", with: fileName)
        formattedMessage = formattedMessage.replacingOccurrences(of: "{line}", with: "\(line)")
        formattedMessage = formattedMessage.replacingOccurrences(of: "{message}", with: message)

        return formattedMessage
    }
}
