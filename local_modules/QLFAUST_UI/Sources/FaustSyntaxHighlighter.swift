import AppKit

struct FaustSyntaxHighlighter {
    static func highlight(_ source: String) -> NSAttributedString {
        let fullRange = NSRange(location: 0, length: source.utf16.count)
        let attributed = NSMutableAttributedString(string: source)

        let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        attributed.addAttribute(.font, value: baseFont, range: fullRange)
        attributed.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        var excludedRanges: [NSRange] = []

        func add(_ pattern: String, color: NSColor, exclude: Bool = false, options: NSRegularExpression.Options = []) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            for match in regex.matches(in: source, options: [], range: fullRange) {
                // Skip overlapping ranges
                if excludedRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) {
                    continue
                }

                attributed.addAttribute(.foregroundColor, value: color, range: match.range)

                if exclude {
                    excludedRanges.append(match.range)
                }
            }
        }

        // 🧱 Comments FIRST — exclude from other highlighting
        add("/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/", color: .systemGray, exclude: true) // block comments (safe multiline)
        add("//.*", color: .systemGray, exclude: true) // line comments

        // 💬 Strings
        add("\"(\\\\.|[^\"])*\"", color: .systemGreen, exclude: true) // exclude to avoid nested highlights

        // 🔑 Keywords
        let keywords = [
            "with", "let", "import", "component", "where", "letrec",
            "library", "environment", "declare", "ffunction",
        ]
        let types = ["int", "float"]

        let extra = ["\\(", "\\)", "=", "\\,", "\\{", "\\}", ";", "\\."]
        let math = ["\\+", "\\-", "\\*", "\\/", "\\%", "\\^",
                    "\\>", "\\<", "\\>=", "\\<=", "==", "\\!=", "\\,"]
        let composition = ["<:", ":>", "\\~", "\\:"]

        add("\\b(process)\\b", color: .systemOrange)
        add("\\b(\(keywords.joined(separator: "|")))\\b", color: .systemBlue)
        add("\\b(\(types.joined(separator: "|")))\\b", color: .systemPurple)

        add("(\(extra.joined(separator: "|")))", color: .systemPurple)
        add("(\(math.joined(separator: "|")))", color: .systemBrown)

        add("\\!", color: .systemRed)
        add("\\_", color: .systemBlue)

        // 🔢 Numbers
        add("\\b[0-9]+\\.[0-9]+([eE][-+]?[0-9]+)?\\b", color: .systemPink) // Floats
        add("\\b[0-9]+\\b", color: .systemRed) // Ints

        // 🧩 Composition operators
        add("(\(composition.joined(separator: "|")))", color: .systemTeal)

        return attributed
    }
}
