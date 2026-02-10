//
//  ProcessRunner.swift
//  DriveSync
//
//  Created by saihgupr on 2024-12-11.
//

import Foundation

struct ProcessResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    let wasCancelled: Bool

    var isSuccess: Bool { exitCode == 0 && !wasCancelled }

    init(stdout: String, stderr: String, exitCode: Int32, wasCancelled: Bool = false) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.wasCancelled = wasCancelled
    }
}

actor ProcessRunner {
    static let shared = ProcessRunner()

    private var currentProcess: Process?

    private init() {}

    /// Terminate the currently running process
    func terminateCurrentProcess() {
        if let process = currentProcess, process.isRunning {
            process.terminate()
        }
    }

    func run(
        _ executablePath: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectory: String? = nil
    ) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = arguments

                if let env = environment {
                    var processEnv = ProcessInfo.processInfo.environment
                    for (key, value) in env {
                        processEnv[key] = value
                    }
                    process.environment = processEnv
                }

                if let dir = currentDirectory {
                    process.currentDirectoryURL = URL(fileURLWithPath: dir)
                }

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()

                    // Read both pipes concurrently to avoid deadlock
                    // when output exceeds the pipe buffer size (~64KB).
                    // If we waitUntilExit() first, a full pipe blocks the
                    // child process write, causing mutual wait.
                    var stdoutData = Data()
                    var stderrData = Data()
                    let group = DispatchGroup()

                    group.enter()
                    DispatchQueue.global().async {
                        stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        group.leave()
                    }

                    group.enter()
                    DispatchQueue.global().async {
                        stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        group.leave()
                    }

                    group.wait()
                    process.waitUntilExit()

                    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                    let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                    let result = ProcessResult(
                        stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                        stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                        exitCode: process.terminationStatus
                    )

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Run a command with real-time output streaming (cancellable)
    /// Uses terminationHandler + EOF detection to avoid data loss race conditions
    func runWithProgress(
        _ executablePath: String,
        arguments: [String] = [],
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        // Store reference for cancellation
        currentProcess = process

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            // Thread-safe state for collecting output and tracking completion
            let lock = NSLock()
            var allStdout = ""
            var allStderr = ""
            var stdoutDone = false
            var stderrDone = false
            var processExited = false
            var hasResumed = false

            func tryComplete() {
                lock.lock()
                guard stdoutDone && stderrDone && processExited && !hasResumed else {
                    lock.unlock()
                    return
                }
                hasResumed = true
                let stdout = allStdout
                let stderr = allStderr
                lock.unlock()

                let wasCancelled = process.terminationReason == .uncaughtSignal
                let result = ProcessResult(
                    stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                    stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                    exitCode: process.terminationStatus,
                    wasCancelled: wasCancelled
                )

                Task { await self?.clearCurrentProcess() }
                continuation.resume(returning: result)
            }

            // Read stdout with real-time callback
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    // EOF — pipe closed
                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    lock.lock()
                    stdoutDone = true
                    lock.unlock()
                    tryComplete()
                    return
                }
                if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                    lock.lock()
                    allStdout += str
                    lock.unlock()
                    onOutput(str)
                }
            }

            // Read stderr with real-time callback (rclone sends progress here)
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    // EOF — pipe closed
                    stderrPipe.fileHandleForReading.readabilityHandler = nil
                    lock.lock()
                    stderrDone = true
                    lock.unlock()
                    tryComplete()
                    return
                }
                if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                    lock.lock()
                    allStderr += str
                    lock.unlock()
                    onOutput(str)
                }
            }

            // Process exit callback (non-blocking, no waitUntilExit)
            process.terminationHandler = { _ in
                lock.lock()
                processExited = true
                lock.unlock()
                tryComplete()
            }

            do {
                try process.run()
            } catch {
                // Clean up handlers on launch failure
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                Task { await self?.clearCurrentProcess() }
                continuation.resume(throwing: error)
            }
        }
    }

    private func clearCurrentProcess() {
        currentProcess = nil
    }
}
