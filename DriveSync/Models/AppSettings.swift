//
//  AppSettings.swift
//  DriveSync
//
//  Created by saihgupr on 2024-12-11.
//  Modified by IceCokei on 2026.
//  Copyright (c) 2026 IceCokei. Licensed under GPL v3.0.
//

import Foundation
import SwiftUI

enum AppearanceMode: String, Codable, Equatable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"

    var displayName: String {
        switch self {
        case .light: return "enum.appearance.light".localized
        case .dark: return "enum.appearance.dark".localized
        case .auto: return "enum.appearance.auto".localized
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil  // System default
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

enum SyncInterval: Codable, Equatable, Hashable, CaseIterable {
    case manual
    case minutes15
    case minutes30
    case hourly
    case daily
    case custom(minutes: Int)
    
    static var allCases: [SyncInterval] {
        [.manual, .minutes15, .minutes30, .hourly, .daily]
    }
    
    var displayName: String {
        switch self {
        case .manual: return "enum.interval.manual".localized
        case .minutes15: return "enum.interval.15min".localized
        case .minutes30: return "enum.interval.30min".localized
        case .hourly: return "enum.interval.hourly".localized
        case .daily: return "enum.interval.daily".localized
        case .custom(let minutes): return "enum.interval.custom".localized(with: minutes)
        }
    }
    
    var intervalSeconds: TimeInterval? {
        switch self {
        case .manual: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hourly: return 60 * 60
        case .daily: return 24 * 60 * 60
        case .custom(let minutes): return TimeInterval(minutes * 60)
        }
    }
}

struct AppSettings: Codable, Equatable {
    var syncInterval: SyncInterval
    var rclonePath: String
    var showNotifications: Bool
    var notifyOnError: Bool
    var launchAtLogin: Bool
    var syncOnLaunch: Bool
    var dailySyncTime: Date  // Time of day for daily syncs (only hour/minute matter)
    var checkUpdatesAutomatically: Bool
    var appearanceMode: AppearanceMode
    var language: AppLanguage

    static var defaultRclonePath: String {
        return detectRclonePath() ?? "/opt/homebrew/bin/rclone"
    }
    static let intelRclonePath = "/usr/local/bin/rclone"

    /// Default sync time: 9:00 AM
    static var defaultDailySyncTime: Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    init(
        syncInterval: SyncInterval = .hourly,
        rclonePath: String = AppSettings.defaultRclonePath,
        showNotifications: Bool = true,
        notifyOnError: Bool = true,
        launchAtLogin: Bool = false,
        syncOnLaunch: Bool = true,
        dailySyncTime: Date? = nil,
        checkUpdatesAutomatically: Bool = true,
        appearanceMode: AppearanceMode = .auto,
        language: AppLanguage = .system
    ) {
        self.syncInterval = syncInterval
        self.rclonePath = rclonePath
        self.showNotifications = showNotifications
        self.notifyOnError = notifyOnError
        self.launchAtLogin = launchAtLogin
        self.syncOnLaunch = syncOnLaunch
        self.dailySyncTime = dailySyncTime ?? AppSettings.defaultDailySyncTime
        self.checkUpdatesAutomatically = checkUpdatesAutomatically
        self.appearanceMode = appearanceMode
        self.language = language
    }

    // Custom Codable: backward-compatible with saved data that lacks the "language" key
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        syncInterval = try container.decode(SyncInterval.self, forKey: .syncInterval)
        rclonePath = try container.decode(String.self, forKey: .rclonePath)
        showNotifications = try container.decode(Bool.self, forKey: .showNotifications)
        notifyOnError = try container.decode(Bool.self, forKey: .notifyOnError)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        syncOnLaunch = try container.decode(Bool.self, forKey: .syncOnLaunch)
        dailySyncTime = try container.decode(Date.self, forKey: .dailySyncTime)
        checkUpdatesAutomatically = try container.decode(Bool.self, forKey: .checkUpdatesAutomatically)
        appearanceMode = try container.decode(AppearanceMode.self, forKey: .appearanceMode)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
    }
    
    static func detectRclonePath() -> String? {
        // 1. Check for bundled rclone (Preferred)
        if let bundledPath = Bundle.main.path(forResource: "rclone", ofType: nil) {
            return bundledPath
        }
        
        // 2. Check common system locations
        let paths = [
            intelRclonePath,        // Intel Homebrew
            "/usr/bin/rclone",      // System
            "/opt/local/bin/rclone" // MacPorts
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try which command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["rclone"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            // Ignore
        }
        
        return nil
    }
}
