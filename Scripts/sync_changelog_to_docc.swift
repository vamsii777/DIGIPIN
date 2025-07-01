#!/usr/bin/env swift
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let mainChangelog = root.appendingPathComponent("CHANGELOG.md")
let doccMain = root.appendingPathComponent("Sources/DIGIPIN/DIGIPIN.docc/DIGIPIN.md")

guard let changelogText = try? String(contentsOf: mainChangelog, encoding: .utf8) else {
    print("Main changelog not found: \(mainChangelog.path)")
    exit(1)
}

guard var doccText = try? String(contentsOf: doccMain, encoding: .utf8) else {
    print("DIGIPIN.md not found: \(doccMain.path)")
    exit(1)
}

// Remove any existing '## Changelog' section and everything after it
if let changelogRange = doccText.range(of: "## Changelog") {
    doccText = String(doccText[..<changelogRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
}

// style: '### Version x.y.z (YYYY-MM-DD)', no horizontal rules, no '# Changelog', only one '## Changelog'
let versionPattern = "## \\[(.*?)\\] - (.*?)\\n"
let regex = try! NSRegularExpression(pattern: versionPattern, options: [])
let nsChangelog = changelogText as NSString
var formattedChangelog = ""
var lastRangeEnd = 0
let matches = regex.matches(in: changelogText, options: [], range: NSRange(location: 0, length: nsChangelog.length))
for (i, match) in matches.enumerated() {
    let version = nsChangelog.substring(with: match.range(at: 1))
    let date = nsChangelog.substring(with: match.range(at: 2))
    let start = match.range.location + match.range.length
    let end: Int
    if i + 1 < matches.count {
        end = matches[i+1].range.location
    } else {
        end = nsChangelog.length
    }
    let body = nsChangelog.substring(with: NSRange(location: start, length: end - start)).trimmingCharacters(in: .whitespacesAndNewlines)
    formattedChangelog += "### Version \(version) (\(date))\n"
    // Group by section (Added, Changed, Fixed, etc.)
    let sectionRegex = try! NSRegularExpression(pattern: "^###? (Added|Changed|Fixed|Deprecated|Note|Breaking Change|Feature & Documentation Release)$", options: [.anchorsMatchLines, .caseInsensitive])
    let sectionMatches = sectionRegex.matches(in: body, options: [], range: NSRange(location: 0, length: (body as NSString).length))
    if sectionMatches.isEmpty {
        // No sections, just add as bullet points
        for line in body.components(separatedBy: "\n") where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formattedChangelog += "- " + line.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }
    } else {
        var lastSectionEnd = 0
        for (j, sectionMatch) in sectionMatches.enumerated() {
            let section = (body as NSString).substring(with: sectionMatch.range(at: 1)).capitalized
            let sectionStart = sectionMatch.range.location + sectionMatch.range.length
            let sectionEnd: Int
            if j + 1 < sectionMatches.count {
                sectionEnd = sectionMatches[j+1].range.location
            } else {
                sectionEnd = (body as NSString).length
            }
            let sectionBody = (body as NSString).substring(with: NSRange(location: sectionStart, length: sectionEnd - sectionStart)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sectionBody.isEmpty {
                formattedChangelog += "- \(section)\n"
                for line in sectionBody.components(separatedBy: "\n") where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanLine.hasPrefix("-") {
                        formattedChangelog += "    \(cleanLine)\n"
                    } else {
                        formattedChangelog += "    - \(cleanLine)\n"
                    }
                }
            }
            lastSectionEnd = sectionEnd
        }
    }
    formattedChangelog += "\n"
}

let newDoccText = doccText + "\n\n## Changelog\n\n" + formattedChangelog.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
try newDoccText.write(to: doccMain, atomically: true, encoding: .utf8)
print("DocC changelog appended to DIGIPIN.md: \(doccMain.path)") 