import Foundation

public enum WarpStatusParser {
    public static func parseJSONStatus(_ text: String) -> WarpStatus {
        guard
            let data = text.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return parsePlainStatus(text)
        }

        let fields = flatten(object)
        let statusText = fields["status"] ?? fields["state"] ?? fields["connection_status"] ?? text
        let reason = fields["reason"] ?? fields["connection_reason"] ?? fields["details"]
        let mode = fields["mode"] ?? fields["operation_mode"]
        return WarpStatus.from(statusText: statusText, reason: reason, mode: mode)
    }

    public static func parsePlainStatus(_ text: String) -> WarpStatus {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        let statusLine = lines.first { $0.localizedCaseInsensitiveContains("status") } ?? lines.first ?? text
        let reasonLine = lines.first { $0.localizedCaseInsensitiveContains("reason") }
        let modeLine = lines.first { $0.localizedCaseInsensitiveContains("mode") }

        return WarpStatus.from(
            statusText: value(afterColonIn: statusLine),
            reason: reasonLine.map(value(afterColonIn:)),
            mode: modeLine.map(value(afterColonIn:))
        )
    }

    private static func flatten(_ object: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]

        func visit(_ value: Any, prefix: String?) {
            if let dictionary = value as? [String: Any] {
                for (key, nestedValue) in dictionary {
                    visit(nestedValue, prefix: key)
                }
                return
            }

            guard let prefix else { return }
            result[prefix.lowercased()] = String(describing: value)
        }

        visit(object, prefix: nil)
        return result
    }

    private static func value(afterColonIn text: String) -> String {
        guard let colon = text.firstIndex(of: ":") else { return text }
        return String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
