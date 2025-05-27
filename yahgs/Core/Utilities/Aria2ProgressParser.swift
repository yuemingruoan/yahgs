//
//  Aria2ProgressParser.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//

import Foundation

struct Aria2ProgressInfo {
    let percent: Double   // 0.0 - 1.0
    let downloadedBytes: Int64
    let totalBytes: Int64
    let speedBytesPerSec: Int64
}

class Aria2ProgressParser {
    /// Parse a single line of aria2c output, returns progress info if matched.
    /// Example matched line:
    /// [#399677 26MiB/174MiB(15%) CN:4 DL:3.9MiB ETA:37s]
    static func parseProgress(from line: String) -> Aria2ProgressInfo? {
        // Regex to extract downloaded size, total size, percentage, and speed
        // Pattern groups:
        // 1: downloaded size (number + unit)
        // 2: total size (number + unit)
        // 3: percentage (number)
        // 4: download speed (number + unit)
        
        // Example line to parse:
        // [#399677 26MiB/174MiB(15%) CN:4 DL:3.9MiB ETA:37s]
        
        let pattern = #"\[#\w+\s+([\d\.]+)([KMG]?i?B)/([\d\.]+)([KMG]?i?B)\(\d+%\)\s+CN:\d+\s+DL:([\d\.]+)([KMG]?i?B)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range), match.numberOfRanges == 7 else {
            return nil
        }
        
        func parseSize(_ numberRange: NSRange, _ unitRange: NSRange) -> Int64? {
            guard let numberStr = Range(numberRange, in: line),
                  let unitStr = Range(unitRange, in: line) else {
                return nil
            }
            let number = Double(line[numberStr]) ?? 0
            let unit = String(line[unitStr]).lowercased()
            
            let multiplier: Double
            switch unit {
            case "b": multiplier = 1
            case "kb", "kib": multiplier = 1024
            case "mb", "mib": multiplier = 1024 * 1024
            case "gb", "gib": multiplier = 1024 * 1024 * 1024
            default: multiplier = 1
            }
            return Int64(number * multiplier)
        }
        
        let downloadedBytes = parseSize(match.range(at: 1), match.range(at: 2)) ?? 0
        let totalBytes = parseSize(match.range(at: 3), match.range(at: 4)) ?? 0
        let speedBytes = parseSize(match.range(at: 5), match.range(at: 6)) ?? 0
        
        // Parse percent from the string inside parentheses
        // Since regex does not capture percentage number, extract manually
        // Example: "...174MiB(15%) ..."
        let percentPattern = #"\((\d+)%\)"#
        var percent: Double = 0
        if let percentRegex = try? NSRegularExpression(pattern: percentPattern, options: []),
           let percentMatch = percentRegex.firstMatch(in: line, options: [], range: range),
           percentMatch.numberOfRanges == 2,
           let percentRange = Range(percentMatch.range(at: 1), in: line),
           let percentVal = Double(line[percentRange]) {
            percent = percentVal / 100.0
        }
        
        return Aria2ProgressInfo(percent: percent,
                                 downloadedBytes: downloadedBytes,
                                 totalBytes: totalBytes,
                                 speedBytesPerSec: speedBytes)
    }
}
