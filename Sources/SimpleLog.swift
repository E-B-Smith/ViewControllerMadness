/**
 @file          SimpleLog.swift
 @package       IsCute?
 @brief         Simple logging for debugging.

 @author        Edward Smith
 @date          September 2020
 @copyright     -©- Copyright © 2020 Affirm, Inc. All rights reserved. -©-
*/

import Foundation

enum LogLevel: Int, Comparable {
    case debug
    case warning
    case error
    case log

    static func < (lhs: Self, rhs: Self) -> Bool {
       return lhs.rawValue < rhs.rawValue
    }

    var description: String {
        let values = [
            "  Debug",
            "Warning",
            "  Error",
            "   Info",
        ]
        return values[self.rawValue]
   }
}

func VersionString(bundle: Bundle) -> String {
    return
        String(describing:  bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString"))
        + " (" +
        String(describing:  bundle.object(forInfoDictionaryKey: "CFBundleVersion"))
        + ")"
}

class SimpleLog {
    var logLevel: LogLevel = .debug
    var excludedFiles = Set<String>()

    func callAsFunction(
        _ level: LogLevel,
        _ message: String,
        file: String = #file,
        line: UInt = #line
    ) {
        if level >= logLevel {
            let file = (file as NSString).lastPathComponent
            if level >= .error || !excludedFiles.contains(file) {
                print("[NoteSpy] \(level.description) \(file):\(line): \(message)")
            }
        }
    }
}

let Log = SimpleLog()
