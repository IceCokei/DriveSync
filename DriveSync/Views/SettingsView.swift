//
//  SettingsView.swift
//  DriveSync
//
//  Created by saihgupr on 2024-12-11.
//  Modified by IceCokei on 2026.
//  Copyright (c) 2026 IceCokei. Licensed under GPL v3.0.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: SettingsTab = .folders

    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            HStack {
                Spacer()
                DSTabBar(selectedTab: $selectedTab)
                    .id(syncManager.settings.language)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)

            // Content
            ZStack {
                (colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)
                    .ignoresSafeArea()

                switch selectedTab {
                case .folders:
                    FoldersSettingsView()
                        .environmentObject(syncManager)
                case .accounts:
                    AccountsSettingsView()
                        .environmentObject(syncManager)
                case .general:
                    GeneralSettingsView()
                        .environmentObject(syncManager)
                }
            }
        }
        .navigationTitle("DriveSync")
        .frame(width: 500, height: 600)
    }
}

// MARK: - Folders Tab

struct FoldersSettingsView: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var showingAddSheet = false
    @State private var selectedFolder: SyncFolder?

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            VStack(alignment: .leading, spacing: 16) {
                if syncManager.folders.isEmpty {
                if syncManager.availableRemotes.isEmpty {
                    // No accounts configured yet - prompt to go to Accounts tab
                    VStack(spacing: 20) {
                        Spacer()

                        Image("CloudServerIcon")
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)

                        Text("settings.folders.no_accounts".localized)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("settings.folders.no_accounts_hint".localized)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Has accounts, no folders
                    VStack(spacing: 16) {
                        Spacer()

                        Image("FolderIcon")
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)

                        Text("settings.folders.no_folders".localized)
                            .font(.title3)
                            .foregroundStyle(Color.dsTextPrimary)

                        Text("settings.folders.no_folders_hint".localized)
                            .font(.body)
                            .foregroundStyle(Color.dsTextSecondary)

                        Button {
                            showingAddSheet = true
                        } label: {
                            Text("settings.folders.add_folder".localized)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.dsPrimary)
                        .cornerRadius(10)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(syncManager.folders) { folder in
                            FolderSettingsRow(folder: folder, onEdit: {
                                selectedFolder = folder
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            }

            Spacer()

            // Bottom status bar
            if !syncManager.folders.isEmpty {
                DSStatusBar(
                    statusText: syncManager.isSyncing ? "status.syncing".localized : "status.all_synced".localized,
                    statusColor: syncManager.isSyncing ? .orange : .green,
                    lastSyncText: lastSyncText,
                    accountCount: syncManager.availableRemotes.count
                )
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFolderSheet()
                .environmentObject(syncManager)
        }
        .sheet(item: $selectedFolder) { folder in
            EditFolderSheet(folder: folder)
                .environmentObject(syncManager)
        }
    }

    private var lastSyncText: String {
        guard let mostRecentSync = syncManager.folders
            .compactMap({ $0.lastSyncDate })
            .max() else {
            return "status.never_synced".localized
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "status.last_sync_now".localized
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "status.last_sync_min".localized(with: minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "status.last_sync_hr".localized(with: hours)
        } else {
            let days = Int(interval / 86400)
            if days > 1 {
                return "status.last_sync_days".localized(with: days)
            } else {
                return "status.last_sync_day".localized(with: days)
            }
        }
    }
}

struct FolderSettingsRow: View {
    let folder: SyncFolder
    let onEdit: () -> Void
    @EnvironmentObject var syncManager: SyncManager

    private var statusIcon: String {
        folder.lastSyncStatus == .success ? "checkmark.circle.fill" : "circle"
    }

    private var statusColor: Color {
        folder.lastSyncStatus == .success ? .green : Color.dsTextTertiary
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Large folder icon
            Image("FolderIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .frame(width: 44)

            // Folder info — takes all remaining space
            VStack(alignment: .leading, spacing: 4) {
                // Name + Status
                HStack(spacing: 6) {
                    Text(folder.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dsTextPrimary)

                    Image(systemName: statusIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(statusColor)
                }

                // Local path with folder icon
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsTextTertiary)

                    Text(folder.localPath)
                        .font(DSTypography.caption.font)
                        .foregroundStyle(Color.dsTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // Cloud path with cloud icon
                HStack(spacing: 4) {
                    Image(systemName: "cloud")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsTextTertiary)

                    Text(folder.fullRemotePath.trimmingCharacters(in: CharacterSet(charactersIn: ":")))
                        .font(DSTypography.caption.font)
                        .foregroundStyle(Color.dsTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Timestamp — fixed width to prevent layout jitter
            Group {
                if let lastSync = folder.lastSyncDate {
                    Text(lastSync, style: .relative)
                } else {
                    Text("settings.folders.never".localized)
                }
            }
            .font(DSTypography.caption.font)
            .foregroundStyle(Color.dsTextTertiary)
            .frame(width: 90, alignment: .trailing)
            .lineLimit(1)
        }
        .padding(DesignTokens.spacingM)
        .dsCard()
        .contextMenu {
            Button {
                Task {
                    await syncManager.syncFolder(folder)
                }
            } label: {
                Label("menu.sync_now".localized, systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(syncManager.isSyncing || !folder.isEnabled)

            Toggle(isOn: Binding(
                get: { folder.isEnabled },
                set: { newValue in
                    var updated = folder
                    updated.isEnabled = newValue
                    syncManager.updateFolder(updated)
                }
            )) {
                Label("settings.folders.enabled".localized, systemImage: "checkmark.circle")
            }

            Divider()

            Button {
                onEdit()
            } label: {
                Label("settings.folders.edit".localized, systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                syncManager.removeFolder(folder)
            } label: {
                Label("common.remove".localized, systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Folder Sheet

struct AddFolderSheet: View {
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var localPath: String = ""
    @State private var selectedRemote: RcloneRemote?
    @State private var remotePath: String = ""
    @State private var excludePatterns: [String] = []
    @State private var newPattern: String = ""

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("settings.folder.add_title".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dsTextPrimary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Local Folder Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("settings.folder.local_folder".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            HStack {
                                TextField("settings.folder.select_folder".localized, text: $localPath)
                                    .textFieldStyle(.roundedBorder)

                                Button("settings.folder.browse".localized) {
                                    selectFolder()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.dsPrimary)
                                .controlSize(.small)
                            }
                        }

                        Divider()

                        // Google Drive Account Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.folder.drive_account".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Picker("", selection: $selectedRemote) {
                                Text("settings.folder.select".localized).tag(nil as RcloneRemote?)
                                ForEach(syncManager.availableRemotes) { remote in
                                    Text(remote.displayName).tag(remote as RcloneRemote?)
                                }
                            }
                            .labelsHidden()

                            Text("settings.folder.dest_folder_optional".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            TextField("settings.folder.leave_empty".localized, text: $remotePath)
                                .textFieldStyle(.roundedBorder)

                            Text("settings.folder.dest_hint".localized)
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }

                        Divider()

                        // Exclude Patterns Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.folder.exclude_patterns".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            if !excludePatterns.isEmpty {
                                VStack(spacing: 6) {
                                    ForEach(Array(excludePatterns.enumerated()), id: \.offset) { index, pattern in
                                        HStack {
                                            Text(pattern)
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundStyle(Color.dsTextPrimary)

                                            Spacer()

                                            Button {
                                                excludePatterns.remove(at: index)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(Color.dsMuted.opacity(0.3))
                                        .cornerRadius(6)
                                    }
                                }
                            }

                            HStack(alignment: .center, spacing: 8) {
                                TextField("*.tmp", text: $newPattern)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        addPattern()
                                    }

                                Button {
                                    addPattern()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.dsPrimary)
                                }
                                .buttonStyle(.plain)
                                .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            Text("settings.folder.exclude_hint".localized)
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                    }
                    .padding(20)
                }

                Divider()

                HStack {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("common.add".localized) {
                        if let remote = selectedRemote {
                            let folder = SyncFolder(
                                localPath: localPath,
                                remoteName: remote.name,
                                remotePath: remotePath,
                                excludePatterns: excludePatterns
                            )
                            syncManager.folders.append(folder)
                            syncManager.saveFolders()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dsPrimary)
                    .keyboardShortcut(.defaultAction)
                    .disabled(localPath.isEmpty || selectedRemote == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 500, height: 550)
    }

    private func addPattern() {
        let trimmed = newPattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !excludePatterns.contains(trimmed) else { return }
        excludePatterns.append(trimmed)
        newPattern = ""
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            localPath = url.path
        }
    }
}

// MARK: - Edit Folder Sheet

struct EditFolderSheet: View {
    let folder: SyncFolder
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var localPath: String = ""
    @State private var selectedRemote: RcloneRemote?
    @State private var remotePath: String = ""
    @State private var excludePatterns: [String] = []
    @State private var newPattern: String = ""

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("settings.folder.edit_title".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dsTextPrimary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Local Folder Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("settings.folder.local_folder".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            HStack {
                                TextField("settings.folder.select_folder".localized, text: $localPath)
                                    .textFieldStyle(.roundedBorder)

                                Button("settings.folder.browse".localized) {
                                    selectFolder()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.dsPrimary)
                                .controlSize(.small)
                            }
                        }

                        Divider()

                        // Google Drive Account Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.folder.drive_account".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Picker("", selection: $selectedRemote) {
                                Text("settings.folder.select".localized).tag(nil as RcloneRemote?)
                                ForEach(syncManager.availableRemotes) { remote in
                                    Text(remote.displayName).tag(remote as RcloneRemote?)
                                }
                            }
                            .labelsHidden()

                            Text("settings.folder.dest_folder".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            TextField("settings.folder.remote_path".localized, text: $remotePath)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        // Exclude Patterns Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.folder.exclude_patterns".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            if !excludePatterns.isEmpty {
                                VStack(spacing: 6) {
                                    ForEach(Array(excludePatterns.enumerated()), id: \.offset) { index, pattern in
                                        HStack {
                                            Text(pattern)
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundStyle(Color.dsTextPrimary)

                                            Spacer()

                                            Button {
                                                excludePatterns.remove(at: index)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(Color.dsMuted.opacity(0.3))
                                        .cornerRadius(6)
                                    }
                                }
                            }

                            HStack(alignment: .center, spacing: 8) {
                                TextField("*.tmp", text: $newPattern)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        addPattern()
                                    }

                                Button {
                                    addPattern()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.dsPrimary)
                                }
                                .buttonStyle(.plain)
                                .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            Text("settings.folder.exclude_hint".localized)
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                    }
                    .padding(20)
                }

                Divider()

                HStack {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("common.save".localized) {
                        if let remote = selectedRemote {
                            var updated = folder
                            updated.localPath = localPath
                            updated.remoteName = remote.name
                            updated.remotePath = remotePath
                            updated.excludePatterns = excludePatterns
                            syncManager.updateFolder(updated)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dsPrimary)
                    .keyboardShortcut(.defaultAction)
                    .disabled(localPath.isEmpty || selectedRemote == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 500, height: 550)
        .onAppear {
            localPath = folder.localPath
            remotePath = folder.remotePath
            excludePatterns = folder.excludePatterns
            selectedRemote = syncManager.availableRemotes.first { $0.name == folder.remoteName }
        }
    }

    private func addPattern() {
        let trimmed = newPattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !excludePatterns.contains(trimmed) else { return }
        excludePatterns.append(trimmed)
        newPattern = ""
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            localPath = url.path
        }
    }
}

// MARK: - Add Account Sheet

struct AddAccountSheet: View {
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss

    enum SetupStep {
        case connecting
        case naming
    }

    @State private var step: SetupStep = .connecting
    @State private var tempRemoteName: String = ""
    @State private var accountName: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image("CloudServerIcon")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)

            switch step {
            case .connecting:
                connectingView
            case .naming:
                namingView
            }
        }
        .padding(30)
        .frame(width: 380)
        .onAppear {
            startConnection()
        }
    }

    private var connectingView: some View {
        VStack(spacing: 16) {
            Text("settings.accounts.connecting".localized)
                .font(.headline)

            ProgressView()
                .controlSize(.regular)

            Text("settings.accounts.complete_signin".localized)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("common.cancel".localized) {
                dismiss()
            }
            .padding(.top, 8)
        }
    }

    private var namingView: some View {
        VStack(spacing: 16) {
            Text("settings.accounts.connected_success".localized)
                .font(.headline)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 8) {
                Text("settings.accounts.name_prompt".localized)
                    .font(.subheadline)

                TextField("settings.accounts.name_placeholder".localized, text: $accountName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                Text("settings.accounts.name_hint".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 16) {
                Button("common.skip".localized) {
                    dismiss()
                }

                Button {
                    finishWithName()
                } label: {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal)
                    } else {
                        Text("common.save".localized)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(accountName.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func startConnection() {
        Task {
            if let tempName = await syncManager.quickSetupGoogleDrive() {
                tempRemoteName = tempName

                // Poll for the remote to appear (user completing OAuth)
                for _ in 0..<60 { // Wait up to 60 seconds
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await syncManager.refreshRemotes()

                    if syncManager.availableRemotes.contains(where: { $0.name == tempName }) {
                        step = .naming
                        return
                    }
                }
            }
            // If we get here, something went wrong
            dismiss()
        }
    }

    private func finishWithName() {
        let newName = sanitizedName
        guard !newName.isEmpty else { return }

        isProcessing = true
        errorMessage = nil

        Task {
            let success = await syncManager.renameRemote(from: tempRemoteName, to: newName)

            if success {
                dismiss()
            } else {
                errorMessage = "settings.accounts.rename_failed".localized(with: tempRemoteName)
                isProcessing = false
            }
        }
    }

    private var sanitizedName: String {
        let trimmed = accountName.trimmingCharacters(in: .whitespaces)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_@.-"))
        return String(trimmed.unicodeScalars.filter { allowed.contains($0) })
            .replacingOccurrences(of: " ", with: "_")
    }
}

// MARK: - Accounts Tab

struct AccountsSettingsView: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var showingAddAccountSheet = false
    @State private var accountToRename: RcloneRemote?
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                if syncManager.availableRemotes.isEmpty {
                VStack(spacing: 20) {
                    Spacer()

                    Image("CloudServerIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)

                    Text("settings.accounts.connect_title".localized)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("settings.accounts.connect_hint".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        showingAddAccountSheet = true
                    } label: {
                        Label("settings.accounts.connect_button".localized, systemImage: "link")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dsPrimary)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusL))

                    Text("settings.accounts.browser_hint".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Account cards
                        ForEach(syncManager.availableRemotes) { remote in
                            HStack(alignment: .center, spacing: 16) {
                                // Drive icon
                                Image("DriveIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)

                                // Account info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(remote.name)
                                        .font(DSTypography.body.font)
                                        .foregroundStyle(Color.dsTextPrimary)

                                    Text("settings.accounts.google_drive".localized)
                                        .font(DSTypography.caption.font)
                                        .foregroundStyle(Color.dsTextSecondary)
                                }

                                Spacer()

                                // Connected badge
                                HStack(spacing: 2) {
                                    Image("DotIcon")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(Color.green)

                                    Text("settings.accounts.connected".localized)
                                        .font(DSTypography.caption.font)
                                        .foregroundStyle(Color.dsTextSecondary)
                                }
                            }
                            .padding(DesignTokens.spacingM)
                            .dsCard()
                            .contextMenu {
                                Button {
                                    accountToRename = remote
                                } label: {
                                    Label("settings.accounts.rename".localized, systemImage: "pencil")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    Task {
                                        await syncManager.deleteRemote(name: remote.name)
                                    }
                                } label: {
                                    Label("settings.accounts.remove".localized, systemImage: "trash")
                                }
                            }
                        }

                        // Add Account + Refresh row
                        HStack(spacing: 10) {
                            Button {
                                showingAddAccountSheet = true
                            } label: {
                                HStack {
                                    Spacer()

                                    Image("PlusIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)

                                    Text("settings.accounts.add_another".localized)
                                        .font(DSTypography.body.font)

                                    Spacer()
                                }
                                .padding(DesignTokens.spacingM)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .foregroundStyle(Color.dsBorder)
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.dsTextPrimary)

                            Button {
                                guard !isRefreshing else { return }
                                isRefreshing = true
                                Task {
                                    await syncManager.refreshRemotes()
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    isRefreshing = false
                                }
                            } label: {
                                HStack {
                                    Spacer()

                                    if isRefreshing {
                                        ProgressView()
                                            .controlSize(.small)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image("RefreshIcon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 14, height: 14)
                                    }

                                    Text("common.refresh".localized)
                                        .font(DSTypography.body.font)

                                    Spacer()
                                }
                                .padding(DesignTokens.spacingM)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.dsTextPrimary)
                            .dsCard()
                            .disabled(isRefreshing)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            }

            Spacer()

            // Bottom status bar
            if !syncManager.availableRemotes.isEmpty {
                DSStatusBar(
                    statusText: syncManager.isSyncing ? "status.syncing".localized : "status.all_synced".localized,
                    statusColor: syncManager.isSyncing ? .orange : .green,
                    lastSyncText: lastSyncText,
                    accountCount: syncManager.availableRemotes.count
                )
            }
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            AddAccountSheet()
                .environmentObject(syncManager)
        }
        .sheet(item: $accountToRename) { remote in
            RenameAccountSheet(currentName: remote.name)
                .environmentObject(syncManager)
        }
        .onAppear {
            Task {
                await syncManager.refreshRemotes()
            }
        }
    }

    private var lastSyncText: String {
        guard let mostRecentSync = syncManager.folders
            .compactMap({ $0.lastSyncDate })
            .max() else {
            return "status.never_synced".localized
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "status.last_sync_now".localized
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "status.last_sync_min".localized(with: minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "status.last_sync_hr".localized(with: hours)
        } else {
            let days = Int(interval / 86400)
            if days > 1 {
                return "status.last_sync_days".localized(with: days)
            } else {
                return "status.last_sync_day".localized(with: days)
            }
        }
    }
}

// MARK: - Rename Account Sheet

struct RenameAccountSheet: View {
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss

    let currentName: String
    @State private var newName: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("settings.accounts.rename_title".localized)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("settings.accounts.current_name".localized(with: currentName))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("settings.accounts.new_name".localized, text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 16) {
                Button("common.cancel".localized) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    renameAccount()
                } label: {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal)
                    } else {
                        Text("common.rename".localized)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(sanitizedName.isEmpty || sanitizedName == currentName || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 350)
        .onAppear {
            newName = currentName
        }
    }

    private func renameAccount() {
        isProcessing = true
        errorMessage = nil

        Task {
            let success = await syncManager.renameRemote(from: currentName, to: sanitizedName)

            if success {
                dismiss()
            } else {
                errorMessage = "settings.accounts.rename_error".localized
                isProcessing = false
            }
        }
    }

    private var sanitizedName: String {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_@.-"))
        return String(trimmed.unicodeScalars.filter { allowed.contains($0) })
            .replacingOccurrences(of: " ", with: "_")
    }
}

// MARK: - General Tab

struct GeneralSettingsView: View {
    @EnvironmentObject var syncManager: SyncManager

    @State private var isCheckingForUpdates = false
    @State private var showingUpdateAlert = false
    @State private var updateAlertTitle = ""
    @State private var updateAlertMessage = ""
    @State private var updateURL: URL?

    // Advanced / Reset state
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Theme Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    DSSectionHeader(title: "settings.general.theme".localized)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.general.appearance".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Picker("", selection: $syncManager.settings.appearanceMode) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                            .id(syncManager.settings.language)
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        // Language Picker
                        HStack {
                            Text("settings.general.language".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Picker("", selection: $syncManager.settings.language) {
                                ForEach(AppLanguage.allCases, id: \.self) { lang in
                                    Text(lang.displayName).tag(lang)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 140)
                            .id(syncManager.settings.language)
                        }
                        .padding(DesignTokens.spacingM)
                    }
                    .dsCard()
                }

                // Sync Schedule Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    DSSectionHeader(title: "settings.general.sync_schedule".localized)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.general.sync_interval".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Picker("", selection: $syncManager.settings.syncInterval) {
                                ForEach(SyncInterval.allCases, id: \.self) { interval in
                                    Text(interval.displayName).tag(interval)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 140)
                            .id(syncManager.settings.language)
                        }
                        .padding(DesignTokens.spacingM)

                        // Show time picker when daily sync is selected
                        if case .daily = syncManager.settings.syncInterval {
                            Divider()

                            HStack {
                                Text("settings.general.sync_time".localized)
                                    .font(DSTypography.body.font)
                                    .foregroundStyle(Color.dsTextPrimary)

                                Spacer()

                                HStack(spacing: 2) {
                                    Picker("", selection: Binding(
                                        get: { Calendar.current.component(.hour, from: syncManager.settings.dailySyncTime) },
                                        set: { newHour in
                                            let minute = Calendar.current.component(.minute, from: syncManager.settings.dailySyncTime)
                                            let roundedMinute = (minute / 5) * 5
                                            var components = DateComponents()
                                            components.hour = newHour
                                            components.minute = roundedMinute
                                            if let date = Calendar.current.date(from: components) {
                                                syncManager.settings.dailySyncTime = date
                                            }
                                        }
                                    )) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 64)

                                    Text(":")
                                        .font(DSTypography.body.font)
                                        .foregroundStyle(Color.dsTextSecondary)

                                    Picker("", selection: Binding(
                                        get: {
                                            let minute = Calendar.current.component(.minute, from: syncManager.settings.dailySyncTime)
                                            return (minute / 5) * 5
                                        },
                                        set: { newMinute in
                                            let hour = Calendar.current.component(.hour, from: syncManager.settings.dailySyncTime)
                                            var components = DateComponents()
                                            components.hour = hour
                                            components.minute = newMinute
                                            if let date = Calendar.current.date(from: components) {
                                                syncManager.settings.dailySyncTime = date
                                            }
                                        }
                                    )) {
                                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 64)
                                }
                            }
                            .padding(DesignTokens.spacingM)
                        }

                        Divider()

                        HStack {
                            Text("settings.general.sync_on_launch".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Toggle("", isOn: $syncManager.settings.syncOnLaunch)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                        .padding(DesignTokens.spacingM)
                    }
                    .dsCard()
                }

                // App Behavior Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    DSSectionHeader(title: "settings.general.app_behavior".localized)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.general.show_notifications".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Toggle("", isOn: $syncManager.settings.showNotifications)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("settings.general.notify_error".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Toggle("", isOn: $syncManager.settings.notifyOnError)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("settings.general.launch_login".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Toggle("", isOn: $syncManager.settings.launchAtLogin)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                        .padding(DesignTokens.spacingM)
                    }
                    .dsCard()
                }

                // About Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    DSSectionHeader(title: "settings.general.about".localized)

                    VStack(spacing: 0) {
                        HStack {
                            Text("settings.general.auto_updates".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Toggle("", isOn: $syncManager.settings.checkUpdatesAutomatically)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.small)
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("settings.general.check_updates".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            if isCheckingForUpdates {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button("common.check".localized) {
                                    checkForUpdates()
                                }
                                .buttonStyle(.plain)
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextPrimary)
                            }
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("settings.general.version".localized)
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                                .font(.custom(DSTypography.fontFamily, size: 11))
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                        .padding(DesignTokens.spacingM)
                    }
                    .dsCard()
                }
            }
            .padding(20)
        }

        Spacer()

        // Bottom status bar
        DSStatusBar(
                statusText: syncManager.isSyncing ? "status.syncing".localized : "status.all_synced".localized,
                statusColor: syncManager.isSyncing ? .orange : .green,
                lastSyncText: lastSyncText,
                accountCount: syncManager.availableRemotes.count
            )
        }
        .alert(updateAlertTitle, isPresented: $showingUpdateAlert) {
            if let url = updateURL {
                Button("settings.general.get_update".localized) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(updateAlertMessage)
        }
        .onChange(of: syncManager.settings) { _, _ in
            syncManager.saveSettings()
        }
        .onChange(of: syncManager.settings.rclonePath) { _, _ in
            // saveSettings() already called by the .onChange(of: settings) above
            Task {
                await syncManager.checkRcloneInstallation()
            }
        }
        .alert("settings.general.reset_title".localized, isPresented: $showingResetConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("settings.general.reset_confirm".localized, role: .destructive) {
                syncManager.resetAllSettings()
            }
        } message: {
            Text("settings.general.reset_message".localized)
        }
    }

    private func checkForUpdates() {
        isCheckingForUpdates = true
        Task {
            do {
                let (isAvailable, latestVersion, url) = try await syncManager.checkForUpdates()
                if isAvailable {
                    updateAlertTitle = "settings.general.update_available".localized
                    updateAlertMessage = "settings.general.update_message".localized(with: latestVersion)
                    updateURL = url
                } else {
                    updateAlertTitle = "settings.general.up_to_date".localized
                    updateAlertMessage = "settings.general.up_to_date_message".localized
                    updateURL = nil
                }
            } catch {
                updateAlertTitle = "settings.general.update_error".localized
                updateAlertMessage = "settings.general.update_error_message".localized
                updateURL = nil
            }
            showingUpdateAlert = true
            isCheckingForUpdates = false
        }
    }

    /// Calculate when the next daily sync will occur
    private var nextSyncDescription: String {
        let calendar = Calendar.current
        let syncTimeComponents = calendar.dateComponents([.hour, .minute], from: syncManager.settings.dailySyncTime)

        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = syncTimeComponents.hour
        todayComponents.minute = syncTimeComponents.minute

        guard let todayAtSyncTime = calendar.date(from: todayComponents) else {
            return "Unknown"
        }

        let nextSync: Date
        if todayAtSyncTime > Date() {
            nextSync = todayAtSyncTime
        } else {
            nextSync = calendar.date(byAdding: .day, value: 1, to: todayAtSyncTime) ?? todayAtSyncTime
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextSync)
    }

    private var lastSyncText: String {
        guard let mostRecentSync = syncManager.folders
            .compactMap({ $0.lastSyncDate })
            .max() else {
            return "status.never_synced".localized
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "status.last_sync_now".localized
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "status.last_sync_min".localized(with: minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "status.last_sync_hr".localized(with: hours)
        } else {
            let days = Int(interval / 86400)
            if days > 1 {
                return "status.last_sync_days".localized(with: days)
            } else {
                return "status.last_sync_day".localized(with: days)
            }
        }
    }
}



#Preview {
    SettingsView()
        .environmentObject(SyncManager())
}
