//
//  DesignSystem.swift
//  DriveSync
//
//  Minimalist macOS Design System - Clean & Modern
//
//  Created by IceCokei on 2026.
//  Copyright (c) 2026 IceCokei. Licensed under GPL v3.0.
//

import SwiftUI

// MARK: - Color Palette (Neutral & Clean)

extension Color {
    // Backgrounds: Pure light/dark
    static let dsBackgroundLight = Color.white
    static let dsBackgroundDark = Color(red: 0.04, green: 0.04, blue: 0.04)  // HSL(0, 0%, 3.9%)

    // Cards
    static let dsCardLight = Color.white
    static let dsCardDark = Color(red: 0.04, green: 0.04, blue: 0.04)

    // Text: High contrast
    static let dsTextPrimary = Color(nsColor: .labelColor)
    static let dsTextSecondary = Color(nsColor: .secondaryLabelColor)
    static let dsTextTertiary = Color(nsColor: .tertiaryLabelColor)

    // Primary action color (blue)
    static let dsPrimary = Color.blue
    static let dsPrimaryLight = Color.blue.opacity(0.9)

    // Status colors
    static let dsSuccess = Color.green
    static let dsError = Color.red
    static let dsWarning = Color.orange
    static let dsSyncing = Color.blue

    // Borders: Subtle
    static let dsBorderLight = Color(red: 0.898, green: 0.898, blue: 0.898)  // HSL(0, 0%, 89.8%)
    static let dsBorderDark = Color(red: 0.149, green: 0.149, blue: 0.149)  // HSL(0, 0%, 14.9%)

    // Muted backgrounds
    static let dsMutedLight = Color(red: 0.961, green: 0.961, blue: 0.961)  // HSL(0, 0%, 96.1%)
    static let dsMutedDark = Color(red: 0.149, green: 0.149, blue: 0.149)   // HSL(0, 0%, 14.9%)

    static var dsBorder: Color {
        Color(nsColor: .separatorColor)
    }

    static var dsMuted: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.unemphasizedSelectedContentBackgroundColor)
        #else
        return Color.secondary.opacity(0.2)
        #endif
    }
}

// MARK: - Design Tokens

struct DesignTokens {
    // Spacing (Compact, macOS-like)
    static let spacingXS: CGFloat = 2
    static let spacingS: CGFloat = 6
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20

    // Corner Radius (Consistent rounded)
    static let radiusS: CGFloat = 4
    static let radiusM: CGFloat = 8
    static let radiusL: CGFloat = 12
    static let radiusXL: CGFloat = 16

    // Shadows (Minimal)
    static let shadowColor = Color.black.opacity(0.05)
    static let shadowRadius: CGFloat = 4
    static let shadowY: CGFloat = 2

    // Animation (Fast & responsive)
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
    static let transitionDuration: Double = 0.2
}

// MARK: - Typography (Small & Clean)

enum DSTypography {
    case title           // Section headers
    case body            // Main text
    case caption         // Secondary text
    case tiny            // Timestamps

    // Font family name must match the internal name in RomanticRounded.ttf
    static let fontFamily = "\u{6D6A}\u{6F2B}\u{96C5}\u{5706}_Sleek"

    var font: Font {
        switch self {
        case .title:
            return .custom(DSTypography.fontFamily, size: 11).weight(.bold)
        case .body:
            return .custom(DSTypography.fontFamily, size: 13).weight(.semibold)
        case .caption:
            return .custom(DSTypography.fontFamily, size: 11).weight(.medium)
        case .tiny:
            return .custom(DSTypography.fontFamily, size: 10).weight(.medium)
        }
    }
}

// MARK: - Card Style (Minimal border + hover)

struct DSCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.dsCardDark : Color.dsCardLight)
            .cornerRadius(DesignTokens.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                    .stroke(
                        isHovered ?
                            (colorScheme == .dark ? Color.dsBorderDark.opacity(0.8) : Color.dsBorderLight.opacity(0.8)) :
                            (colorScheme == .dark ? Color.dsBorderDark : Color.dsBorderLight),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: DesignTokens.transitionDuration), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func dsCard() -> some View {
        modifier(DSCardStyle())
    }
}

// MARK: - Status Indicator (Clean icons)

struct DSStatusIndicator: View {
    enum Status {
        case idle, syncing, success, error

        var color: Color {
            switch self {
            case .idle: return Color.dsTextTertiary
            case .syncing: return Color.dsSyncing
            case .success: return Color.dsSuccess
            case .error: return Color.dsError
            }
        }

        var icon: String {
            switch self {
            case .idle: return "circle"
            case .syncing: return "arrow.triangle.2.circlepath"
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    let status: Status
    let size: CGFloat

    init(status: Status, size: CGFloat = 14) {
        self.status = status
        self.size = size
    }

    @State private var isAnimating = false

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(status.color)
            .rotationEffect(.degrees(status == .syncing && isAnimating ? 360 : 0))
            .animation(
                status == .syncing ?
                    .linear(duration: 1.5).repeatForever(autoreverses: false) :
                    .default,
                value: isAnimating
            )
            .onAppear {
                if status == .syncing {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Progress Bar (Simple bar)

struct DSProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.dsMuted)
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.dsPrimary)
                    .frame(width: geometry.size.width * animatedProgress, height: 4)
            }
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Toggle Switch (macOS style)

struct DSToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
    }
}

// MARK: - Section Header

struct DSSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(DSTypography.title.font)
            .foregroundStyle(Color.dsTextSecondary)
            .tracking(0.5)
    }
}

// MARK: - Status Bar

struct DSStatusBar: View {
    let statusText: String
    let statusColor: Color
    let lastSyncText: String
    var accountCount: Int = 0
    var body: some View {
        HStack(spacing: 8) {
            // Left: Status
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(DSTypography.caption.font)
                    .foregroundStyle(Color.dsTextPrimary)
            }

            Spacer()

            // Center: Account count
            if accountCount > 0 {
                Text("\("settings.tab.accounts".localized)：\(accountCount)")
                    .font(DSTypography.caption.font)
                    .foregroundStyle(Color.dsTextPrimary)
            }

            Spacer()

            // Right: Last sync time
            Text(lastSyncText)
                .font(DSTypography.caption.font)
                .foregroundStyle(Color.dsTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.dsMuted.opacity(0.3))
    }
}

// MARK: - Custom Tab Bar

enum SettingsTab: String, CaseIterable {
    case folders = "Folders"
    case accounts = "Accounts"
    case general = "Settings"

    var localizedName: String {
        switch self {
        case .folders: return "settings.tab.folders".localized
        case .accounts: return "settings.tab.accounts".localized
        case .general: return "settings.tab.settings".localized
        }
    }

    var iconName: String {
        switch self {
        case .folders: return "FolderIcon"
        case .accounts: return "AccountIcon"
        case .general: return "SettingsIcon"
        }
    }
}

struct DSTabBar: View {
    @Binding var selectedTab: SettingsTab
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(tab.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundStyle(selectedTab == tab ? Color.dsTextPrimary : Color.dsTextSecondary)

                        Text(tab.localizedName)
                            .font(DSTypography.body.font)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.dsTextPrimary : Color.dsTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                            (colorScheme == .dark ? Color.dsCardDark : Color.dsCardLight) :
                            Color.clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.dsMuted.opacity(0.5))
        .cornerRadius(10)
    }
}
