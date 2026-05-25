import Foundation

public struct ProcessRunner: Sendable {
    public init() {}

    public func run(
        _ executable: String,
        arguments: [String],
        timeout: TimeInterval = 8
    ) -> CommandResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        let output = LockedDataBuffer()
        let error = LockedDataBuffer()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            output.append(data)
        }

        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            error.append(data)
        }

        do {
            try process.run()
        } catch {
            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
            return CommandResult(exitCode: 126, stdout: "", stderr: error.localizedDescription)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
            return CommandResult(exitCode: 124, stdout: output.stringValue, stderr: "Command timed out: \(executable)")
        }

        process.waitUntilExit()
        Thread.sleep(forTimeInterval: 0.02)
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil

        return CommandResult(
            exitCode: process.terminationStatus,
            stdout: output.stringValue,
            stderr: error.stringValue
        )
    }
}

private final class LockedDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ newData: Data) {
        lock.lock()
        data.append(newData)
        lock.unlock()
    }

    var stringValue: String {
        lock.lock()
        let copy = data
        lock.unlock()
        return String(data: copy, encoding: .utf8) ?? ""
    }
}
