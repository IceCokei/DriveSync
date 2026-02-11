//
//  LocalizationManager.swift
//  DriveSync
//
//  Manages app language switching with custom Bundle support.
//
//  Created by IceCokei on 2026.
//  Copyright (c) 2026 IceCokei. Licensed under GPL v3.0.
//

import Foundation

// MARK: - AppLanguage Enum

enum AppLanguage: String, Codable, CaseIterable, Equatable {
    case system
    case en
    case zhHans = "zh-Hans"

    var displayName: String {
        switch self {
        case .system: return "enum.language.system".localized
        case .en: return "enum.language.en".localized
        case .zhHans: return "enum.language.zhHans".localized
        }
    }

    /// Resolve to a concrete language code (never "system")
    var resolvedCode: String {
        switch self {
        case .system:
            return AppLanguage.detectSystemLanguage().rawValue
        case .en, .zhHans:
            return self.rawValue
        }
    }

    /// Detect the system's preferred language, mapping to a supported language
    static func detectSystemLanguage() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            let lower = preferred.lowercased()
            if lower.hasPrefix("zh") {
                return .zhHans
            }
            if lower.hasPrefix("en") {
                return .en
            }
        }
        return .en
    }
}

// MARK: - LocalizationManager

final class LocalizationManager {
    static let shared = LocalizationManager()

    private(set) var bundle: Bundle = .main

    private init() {
        // Default to system language detection
        update(language: .system)
    }

    func update(language: AppLanguage) {
        let code = language.resolvedCode

        // Try to find the .lproj bundle for the resolved language
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let enBundle = Bundle(path: path) {
            // Fallback to English
            bundle = enBundle
        } else {
            bundle = .main
        }
    }
}

// MARK: - String Extension

extension String {
    /// Returns the localized version of this string key using LocalizationManager's current bundle
    var localized: String {
        NSLocalizedString(self, tableName: nil, bundle: LocalizationManager.shared.bundle, comment: "")
    }

    /// Returns the localized version with format arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
