import Foundation
import BetterWarpCore

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

private func testParsesConnectedJSONStatus() throws {
    let status = WarpStatusParser.parseJSONStatus("""
    {
      "status": "Connected",
      "reason": "NetworkHealthy",
      "operation_mode": "warp"
    }
    """)

    try expect(status == .connected(reason: "NetworkHealthy", mode: "warp"), "connected JSON status parsed incorrectly")
}

private func testParsesNestedJSONStatusFields() throws {
    let status = WarpStatusParser.parseJSONStatus("""
    {
      "connection": {
        "state": "Disconnected",
        "details": "ManualOverride"
      },
      "settings": {
        "mode": "warp+doh"
      }
    }
    """)

    try expect(status == .disconnected(reason: "ManualOverride", mode: "warp+doh"), "nested JSON status parsed incorrectly")
}

private func testParsesPlainStatusFallback() throws {
    let status = WarpStatusParser.parsePlainStatus("""
    Status: Connected
    Reason: NetworkHealthy
    Mode: warp
    """)

    try expect(status == .connected(reason: "NetworkHealthy", mode: "warp"), "plain status parsed incorrectly")
}

private func testRecognizesTransitionalStatesBeforeConnectedSubstring() throws {
    try expect(WarpStatus.from(statusText: "Disconnecting", reason: nil, mode: nil) == .disconnecting, "disconnecting parsed incorrectly")
    try expect(WarpStatus.from(statusText: "Reconnecting", reason: nil, mode: nil) == .connecting, "reconnecting parsed incorrectly")
}

private func testOnlyStableKnownStatesCanToggle() throws {
    try expect(WarpStatus.connected(reason: nil, mode: nil).canToggle, "connected should be toggleable")
    try expect(WarpStatus.disconnected(reason: nil, mode: nil).canToggle, "disconnected should be toggleable")
    try expect(!WarpStatus.connecting.canToggle, "connecting should not be toggleable")
    try expect(!WarpStatus.disconnecting.canToggle, "disconnecting should not be toggleable")
    try expect(!WarpStatus.unknown("mystery").canToggle, "unknown should not be toggleable")
    try expect(!WarpStatus.unavailable("warp-cli was not found").canToggle, "unavailable should not be toggleable")
}

private func testCapturesLargeOutputWithoutBlocking() throws {
    let result = ProcessRunner().run(
        "/usr/bin/yes",
        arguments: ["x"],
        timeout: 0.2
    )

    try expect(result.exitCode == 124, "large-output command should time out")
    try expect(result.stdout.count > 8_192, "large-output command did not drain stdout")
    try expect(result.stderr.contains("Command timed out"), "timeout did not report an error")
}

private func testCapturesStdoutAndStderr() throws {
    let result = ProcessRunner().run(
        "/bin/sh",
        arguments: ["-c", "printf out; printf err >&2"],
        timeout: 2
    )

    try expect(result.exitCode == 0, "shell command failed")
    try expect(result.stdout == "out", "stdout captured incorrectly")
    try expect(result.stderr == "err", "stderr captured incorrectly")
}

let tests: [(String, () throws -> Void)] = [
    ("parses connected JSON status", testParsesConnectedJSONStatus),
    ("parses nested JSON status fields", testParsesNestedJSONStatusFields),
    ("parses plain status fallback", testParsesPlainStatusFallback),
    ("recognizes transitional states before connected substring", testRecognizesTransitionalStatesBeforeConnectedSubstring),
    ("only stable known states can toggle", testOnlyStableKnownStatesCanToggle),
    ("captures large output without blocking", testCapturesLargeOutputWithoutBlocking),
    ("captures stdout and stderr", testCapturesStdoutAndStderr)
]

for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        fputs("FAIL \(name): \(error)\n", stderr)
        exit(1)
    }
}

print("All BetterWarpCore tests passed")
