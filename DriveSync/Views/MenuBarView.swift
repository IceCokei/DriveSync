//
//  MenuBarView.swift
//  DriveSync
//
//  Created by saihgupr on 2024-12-11.
//  Modified by IceCokei on 2026.
//  Copyright (c) 2026 IceCokei. Licensed under GPL v3.0.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.openWindow) private var openWindow
    @State private var expandedFolderID: UUID? = nil

    // Computed color scheme based on user settings
    private var effectiveColorScheme: ColorScheme {
        switch syncManager.settings.appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return systemColorScheme
        }
    }

    // Helper to close menu bar popover
    private func closeMenuBar() {
        // This will close the menu bar popover
        NSApp.keyWindow?.close()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Progress (only shows when syncing)
            if syncManager.isSyncing {
                progressSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()
                    .padding(.horizontal, 16)
            }

            // Main content
            if !syncManager.isRcloneInstalled {
                rcloneNotInstalledSection
                    .padding(16)
            } else {
                let enabledFolders = syncManager.folders.filter { $0.isEnabled }
                if enabledFolders.isEmpty {
                    emptyFoldersSection
                        .padding(.vertical, 32)
                } else {
                    foldersSection
                        .padding(.vertical, 8)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Actions
                actionsSection
                    .padding(.vertical, 6)
            }

            Divider()
                .padding(.horizontal, 16)

            // Footer
            footerSection
                .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
        .preferredColorScheme(syncManager.settings.appearanceMode == .auto ? nil : (syncManager.settings.appearanceMode == .dark ? .dark : .light))
        .frame(width: 300)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DriveSync")
                    .font(.custom(DSTypography.fontFamily, size: 15).weight(.bold))
                    .foregroundColor(.primary)

                Text(syncManager.statusText)
                    .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image("CloudSyncIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.blue)

                if let folder = syncManager.currentSyncFolder {
                    Text("menu.syncing_folder".localized(with: folder.displayName))
                        .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                        .foregroundColor(.primary)
                } else {
                    Text("menu.syncing".localized)
                        .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button {
                    syncManager.cancelSync()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let percent = syncManager.syncProgressPercent {
                    ProgressView(value: percent)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }

                HStack(spacing: 6) {
                    if let percent = syncManager.syncProgressPercent {
                        Text("\(Int(percent * 100))%")
                            .font(.custom(DSTypography.fontFamily, size: 11).weight(.medium))
                            .foregroundColor(.secondary)
                    }

                    Text(syncManager.syncProgress.isEmpty ? "menu.preparing".localized : syncManager.syncProgress)
                        .font(.custom(DSTypography.fontFamily, size: 10).weight(.medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()
                }
            }
        }
    }

    private var rcloneNotInstalledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("menu.rclone_not_installed".localized)
                .font(.custom(DSTypography.fontFamily, size: 13).weight(.semibold))
                .foregroundColor(.red)

            Text("menu.install_homebrew".localized)
                .font(.custom(DSTypography.fontFamily, size: 11).weight(.medium))
                .foregroundColor(.secondary)

            HStack {
                Text("brew install rclone")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("brew install rclone", forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("menu.check_again".localized) {
                Task {
                    await syncManager.checkRcloneInstallation()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var emptyFoldersSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text("menu.no_folders".localized)
                .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                .foregroundColor(.secondary)

            Button {
                openSettings()
            } label: {
                Text("menu.add_folder".localized)
                    .font(.custom(DSTypography.fontFamily, size: 13).weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
    }

    private var foldersSection: some View {
        let enabledFolders = syncManager.folders.filter { $0.isEnabled }

        return VStack(alignment: .leading, spacing: 0) {
            Text("menu.folders".localized)
                .font(.custom(DSTypography.fontFamily, size: 11).weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 4) {
                ForEach(enabledFolders) { folder in
                    FolderCardView(folder: folder)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 0) {
            Button {
                closeMenuBar()
                Task {
                    await syncManager.syncAll()
                }
            } label: {
                Label("menu.sync_all".localized, systemImage: "arrow.triangle.2.circlepath")
                    .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(MenuActionButtonStyle())
            .disabled(syncManager.isSyncing || syncManager.folders.isEmpty)

            Button {
                closeMenuBar()
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Label("menu.settings".localized, systemImage: "gear")
                    .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(MenuActionButtonStyle())
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    private var footerSection: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("menu.quit".localized, systemImage: "power")
                .font(.custom(DSTypography.fontFamily, size: 13).weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(MenuActionButtonStyle())
        .keyboardShortcut("q", modifiers: .command)
    }
}

// MARK: - Menu Action Button Style

struct MenuActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                configuration.isPressed ? Color.accentColor : Color.clear
            )
            .foregroundColor(
                configuration.isPressed ? .white : .primary
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Folder Card View

struct FolderCardView: View {
    let folder: SyncFolder
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(.custom(DSTypography.fontFamily, size: 13).weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(folder.remoteName)
                    .font(.custom(DSTypography.fontFamily, size: 11).weight(.medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(colorScheme == .dark ? 0.5 : 1.0))
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                Task {
                    await syncManager.syncFolder(folder)
                }
            } label: {
                Label("menu.sync_now".localized, systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(syncManager.isSyncing)

            Divider()

            Button(role: .destructive) {
                syncManager.removeFolder(folder)
            } label: {
                Label("common.remove".localized, systemImage: "trash")
            }
        }
    }

    private var statusIndicator: some View {
        Group {
            switch folder.lastSyncStatus {
            case .idle:
                Circle()
                    .stroke(Color.secondary, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            case .syncing:
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: 16, height: 16)
            case .success:
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
            case .error:
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)
            }
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(SyncManager())
}
