//
//  SettingsView.swift
//  DriveSync
//
//  Created by saihgupr on 2024-12-11.
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
                Spacer()
            }
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)

            Divider()

            // Content
            ZStack {
                (colorScheme == .dark ? Color.dsBackgroundDark : Color.dsBackgroundLight)
                    .ignoresSafeArea()

                FoldersSettingsView()
                    .environmentObject(syncManager)
                    .opacity(selectedTab == .folders ? 1 : 0)
                    .zIndex(selectedTab == .folders ? 1 : 0)

                AccountsSettingsView()
                    .environmentObject(syncManager)
                    .opacity(selectedTab == .accounts ? 1 : 0)
                    .zIndex(selectedTab == .accounts ? 1 : 0)

                GeneralSettingsView()
                    .environmentObject(syncManager)
                    .opacity(selectedTab == .general ? 1 : 0)
                    .zIndex(selectedTab == .general ? 1 : 0)
            }
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Folders Tab

struct FoldersSettingsView: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var showingAddSheet = false
    @State private var showingAddAccountSheet = false
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
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)

                        Text("No accounts connected")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Connect your Google Drive account in the Accounts tab to start syncing folders.")
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
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)

                        Text("No Folders")
                            .font(.title3)
                            .foregroundStyle(Color.dsTextPrimary)

                        Text("Add a folder to start syncing to Google Drive")
                            .font(.body)
                            .foregroundStyle(Color.dsTextSecondary)

                        Button {
                            showingAddSheet = true
                        } label: {
                            Text("Add Folder")
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
                    statusText: syncManager.isSyncing ? "Syncing..." : "All synced",
                    statusColor: syncManager.isSyncing ? .orange : .green,
                    lastSyncText: lastSyncText
                )
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFolderSheet()
                .environmentObject(syncManager)
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            AddAccountSheet()
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
            return "Never synced"
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "Last sync: just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Last sync: \(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Last sync: \(hours) hr ago"
        } else {
            let days = Int(interval / 86400)
            return "Last sync: \(days) day\(days > 1 ? "s" : "") ago"
        }
    }
}

struct FolderSettingsRow: View {
    let folder: SyncFolder
    let onEdit: () -> Void
    @EnvironmentObject var syncManager: SyncManager

    @State private var showingErrorPopover = false

    private var statusIcon: String {
        folder.lastSyncStatus == .success ? "checkmark.circle.fill" : "circle"
    }

    private var statusColor: Color {
        folder.lastSyncStatus == .success ? .green : Color.dsTextTertiary
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Large folder icon
            Image(systemName: "folder.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            // Folder info
            VStack(alignment: .leading, spacing: 4) {
                // Name + Status
                HStack(spacing: 6) {
                    Text(folder.displayName)
                        .font(DSTypography.body.font)
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

            Spacer()

            // Timestamp
            if let lastSync = folder.lastSyncDate {
                Text(lastSync, style: .relative)
                    .font(DSTypography.caption.font)
                    .foregroundStyle(Color.dsTextTertiary)
            } else {
                Text("Never")
                    .font(DSTypography.caption.font)
                    .foregroundStyle(Color.dsTextTertiary)
            }
        }
        .padding(DesignTokens.spacingM)
        .dsCard()
        .contextMenu {
            Button {
                Task {
                    await syncManager.syncFolder(folder)
                }
            } label: {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
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
                Label("Enabled", systemImage: "checkmark.circle")
            }

            Divider()

            Button {
                onEdit()
            } label: {
                Label("Edit...", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                syncManager.removeFolder(folder)
            } label: {
                Label("Remove", systemImage: "trash")
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
                Text("Add Sync Folder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dsTextPrimary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Local Folder Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Local Folder")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            HStack {
                                TextField("Select folder...", text: $localPath)
                                    .textFieldStyle(.roundedBorder)

                                Button("Browse...") {
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
                            Text("Google Drive Account")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Picker("", selection: $selectedRemote) {
                                Text("Select...").tag(nil as RcloneRemote?)
                                ForEach(syncManager.availableRemotes) { remote in
                                    Text(remote.displayName).tag(remote as RcloneRemote?)
                                }
                            }
                            .labelsHidden()

                            Text("Destination Folder (optional)")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            TextField("Leave empty for root", text: $remotePath)
                                .textFieldStyle(.roundedBorder)

                            Text("Leave empty to sync to the root of your Drive.\nOr type a folder path (e.g. 'Backups/MyMac').")
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }

                        Divider()

                        // Exclude Patterns Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exclude Patterns")
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

                            Text("Exclude files or folders from sync (e.g., 'node_modules', '.git', '*.tmp').")
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                    }
                    .padding(20)
                }

                Divider()

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Add") {
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
                Text("Edit Sync Folder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dsTextPrimary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Local Folder Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Local Folder")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            HStack {
                                TextField("Select folder...", text: $localPath)
                                    .textFieldStyle(.roundedBorder)

                                Button("Browse...") {
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
                            Text("Google Drive Account")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Picker("", selection: $selectedRemote) {
                                Text("Select...").tag(nil as RcloneRemote?)
                                ForEach(syncManager.availableRemotes) { remote in
                                    Text(remote.displayName).tag(remote as RcloneRemote?)
                                }
                            }
                            .labelsHidden()

                            Text("Destination Folder")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            TextField("Remote path", text: $remotePath)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        // Exclude Patterns Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exclude Patterns")
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

                            Text("Exclude files or folders from sync (e.g., 'node_modules', '.git', '*.tmp').")
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                    }
                    .padding(20)
                }

                Divider()

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Save") {
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
            Text("Connecting to Google Drive...")
                .font(.headline)
            
            ProgressView()
                .controlSize(.regular)
            
            Text("Complete the sign-in in your browser, then return here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Cancel") {
                dismiss()
            }
            .padding(.top, 8)
        }
    }
    
    private var namingView: some View {
        VStack(spacing: 16) {
            Text("Account Connected!")
                .font(.headline)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Give this account a name:")
                    .font(.subheadline)
                
                TextField("e.g., Work, Personal, john@gmail.com", text: $accountName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                
                Text("This helps you identify which Google account this is.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack(spacing: 16) {
                Button("Skip") {
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
                        Text("Save")
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
                errorMessage = "Failed to rename. The account is still connected as '\(tempRemoteName)'."
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
    @State private var showingRenameSheet = false
    @State private var accountToRename: RcloneRemote?

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

                    Text("Connect to Google Drive")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Sign in with your Google account to start syncing folders.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        showingAddAccountSheet = true
                    } label: {
                        Label("Connect Google Drive", systemImage: "link")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dsPrimary)
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusL))

                    Text("This will open your browser to sign in.")
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

                                    Text("Google Drive")
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

                                    Text("Connected")
                                        .font(DSTypography.caption.font)
                                        .foregroundStyle(Color.dsTextSecondary)
                                }
                            }
                            .padding(DesignTokens.spacingM)
                            .dsCard()
                            .contextMenu {
                                Button {
                                    accountToRename = remote
                                    showingRenameSheet = true
                                } label: {
                                    Label("Rename...", systemImage: "pencil")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    Task {
                                        await syncManager.deleteRemote(name: remote.name)
                                    }
                                } label: {
                                    Label("Remove Account", systemImage: "trash")
                                }
                            }
                        }

                        // Add Another Account button (dashed border)
                        Button {
                            showingAddAccountSheet = true
                        } label: {
                            HStack {
                                Spacer()

                                Image("PlusIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)

                                Text("Add Another Account")
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

                        // Refresh button
                        Button {
                            Task {
                                await syncManager.refreshRemotes()
                            }
                        } label: {
                            HStack {
                                Spacer()

                                Image("RefreshIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)

                                Text("Refresh")
                                    .font(DSTypography.body.font)

                                Spacer()
                            }
                            .padding(DesignTokens.spacingM)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.dsPrimary)
                        .dsCard()
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
                    statusText: syncManager.isSyncing ? "Syncing..." : "All synced",
                    statusColor: syncManager.isSyncing ? .orange : .green,
                    lastSyncText: lastSyncText
                )
            }
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            AddAccountSheet()
                .environmentObject(syncManager)
        }
        .sheet(isPresented: $showingRenameSheet) {
            if let remote = accountToRename {
                RenameAccountSheet(currentName: remote.name)
                    .environmentObject(syncManager)
            }
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
            return "Never synced"
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "Last sync: just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Last sync: \(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Last sync: \(hours) hr ago"
        } else {
            let days = Int(interval / 86400)
            return "Last sync: \(days) day\(days > 1 ? "s" : "") ago"
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
            Text("Rename Account")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Current name: \(currentName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("New name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack(spacing: 16) {
                Button("Cancel") {
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
                        Text("Rename")
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
                errorMessage = "Failed to rename account"
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
                    DSSectionHeader(title: "Theme")

                    VStack(spacing: 0) {
                        HStack {
                            Text("Appearance")
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
                        }
                        .padding(DesignTokens.spacingM)
                    }
                    .dsCard()
                }

                // Sync Schedule Section
                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    DSSectionHeader(title: "Sync Schedule")

                    VStack(spacing: 0) {
                        HStack {
                            Text("Sync Interval")
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
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("Sync when app launches")
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
                    DSSectionHeader(title: "App Behavior")

                    VStack(spacing: 0) {
                        HStack {
                            Text("Show notifications after sync")
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
                            Text("Notify on Error")
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
                            Text("Launch at login")
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
                    DSSectionHeader(title: "About")

                    VStack(spacing: 0) {
                        HStack {
                            Text("Automatically check for updates")
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
                            Text("Check for Updates")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            if isCheckingForUpdates {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button("Check") {
                                    checkForUpdates()
                                }
                                .buttonStyle(.plain)
                                .font(DSTypography.caption.font)
                                .foregroundStyle(Color.dsPrimary)
                            }
                        }
                        .padding(DesignTokens.spacingM)

                        Divider()

                        HStack {
                            Text("Version")
                                .font(DSTypography.body.font)
                                .foregroundStyle(Color.dsTextPrimary)

                            Spacer()

                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                                .font(.system(size: 11, design: .monospaced))
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
                statusText: syncManager.isSyncing ? "Syncing..." : "All synced",
                statusColor: syncManager.isSyncing ? .orange : .green,
                lastSyncText: lastSyncText
            )
        }
        .alert(updateAlertTitle, isPresented: $showingUpdateAlert) {
            if let url = updateURL {
                Button("Get Update") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(updateAlertMessage)
        }
        .onChange(of: syncManager.settings) { _, _ in
            syncManager.saveSettings()
        }
        .onChange(of: syncManager.settings.rclonePath) { _, _ in
            // When path changes, save and re-check
            syncManager.saveSettings()
            Task {
                await syncManager.checkRcloneInstallation()
            }
        }
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Everything", role: .destructive) {
                syncManager.resetAllSettings()
            }
        } message: {
            Text("This will remove all sync folders and Google Drive account connections from the app. This cannot be undone.")
        }
    }
    
    private func checkForUpdates() {
        isCheckingForUpdates = true
        Task {
            do {
                let (isAvailable, latestVersion, url) = try await syncManager.checkForUpdates()
                if isAvailable {
                    updateAlertTitle = "Update Available"
                    updateAlertMessage = "A new version (\(latestVersion)) is available."
                    updateURL = url
                } else {
                    updateAlertTitle = "Up to Date"
                    updateAlertMessage = "You are running the latest version."
                    updateURL = nil
                }
            } catch {
                updateAlertTitle = "Error"
                updateAlertMessage = "Failed to check for updates. Please try again later."
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
            return "Never synced"
        }

        let interval = Date().timeIntervalSince(mostRecentSync)
        if interval < 60 {
            return "Last sync: just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Last sync: \(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Last sync: \(hours) hr ago"
        } else {
            let days = Int(interval / 86400)
            return "Last sync: \(days) day\(days > 1 ? "s" : "") ago"
        }
    }
}



#Preview {
    SettingsView()
        .environmentObject(SyncManager())
}
