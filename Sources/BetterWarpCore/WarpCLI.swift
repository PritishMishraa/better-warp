import Foundation

public struct WarpCLI: Sendable {
    private let candidates: [String]
    private let runner: ProcessRunner

    public init(
        candidates: [String] = [
            "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli",
            "/usr/local/bin/warp-cli",
            "/opt/homebrew/bin/warp-cli"
        ],
        runner: ProcessRunner = ProcessRunner()
    ) {
        self.candidates = candidates
        self.runner = runner
    }

    public func status(fallbackError: String? = nil) -> WarpStatus {
        let result = run(["--json", "status"])
        if result.exitCode == 0 {
            return WarpStatusParser.parseJSONStatus(result.stdout)
        }

        let plain = run(["status"])
        if plain.exitCode == 0 {
            return WarpStatusParser.parsePlainStatus(plain.stdout)
        }

        return .unavailable(fallbackError ?? result.errorText ?? plain.errorText ?? "Unable to reach WARP")
    }

    public func connect() -> CommandResult {
        run(["--accept-tos", "connect"])
    }

    public func disconnect() -> CommandResult {
        run(["disconnect"])
    }

    private func run(_ arguments: [String]) -> CommandResult {
        guard let executable = locateCLI() else {
            return CommandResult(exitCode: 127, stdout: "", stderr: "warp-cli was not found")
        }

        return runner.run(executable, arguments: arguments)
    }

    private func locateCLI() -> String? {
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }

        let result = runner.run("/usr/bin/which", arguments: ["warp-cli"], timeout: 2)
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.exitCode == 0 && !path.isEmpty ? path : nil
    }
}
