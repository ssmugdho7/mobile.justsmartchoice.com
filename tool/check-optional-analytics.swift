import Foundation
import WebKit

// Validate the actual Dart URL filter with the native WebKit rule compiler.
let source = try String(contentsOfFile: "lib/optional_analytics.dart", encoding: .utf8)
let expression = try NSRegularExpression(pattern: "r'([^']+)'")
let range = NSRange(source.startIndex..<source.endIndex, in: source)
let patterns = expression.matches(in: source, range: range).compactMap { match -> String? in
    guard let matchRange = Range(match.range(at: 1), in: source) else { return nil }
    return String(source[matchRange])
}
guard patterns.count == 3 else { fatalError("Cannot identify the production analytics filters") }
let rules: [[String: Any]] = patterns.map { ["trigger": ["url-filter": $0], "action": ["type": "block"]] }
let encoded = String(data: try JSONSerialization.data(withJSONObject: rules), encoding: .utf8)!
let identifier = "smart-choice-check-" + UUID().uuidString
var complete = false
var failed = false
WKContentRuleListStore.default().compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: encoded) { list, error in
    if error != nil || list == nil {
        fputs("Production analytics rule failed native WebKit compilation\n", stderr)
        failed = true
        complete = true
        return
    }
    WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier) { removalError in
        failed = removalError != nil
        complete = true
    }
}
let deadline = Date().addingTimeInterval(30)
while !complete && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
}
guard complete && !failed else { exit(1) }
print("Production analytics rule compiled and removed in native macOS WebKit")
