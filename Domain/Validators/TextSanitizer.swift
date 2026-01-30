//
//  TextSanitizer.swift
//  MediScribe
//
//  Text normalization and forbidden phrase detection for safety validation
//

import Foundation

struct TextSanitizer {
    /// Normalizes text by converting to lowercase, removing diacritics, stripping non-alphanumeric characters
    /// Returns both spaced and collapsed forms to detect obfuscation attempts
    static func normalize(_ input: String) -> (spaced: String, collapsed: String) {
        var s = input.lowercased()
        s = s.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)

        let allowed = CharacterSet.alphanumerics
        s = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
            .reduce(into: "") { $0.append($1) }

        s = s.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).joined(separator: " ")
        let collapsed = s.replacingOccurrences(of: " ", with: "")
        return (spaced: s, collapsed: collapsed)
    }

    /// Searches for forbidden phrases in input text using normalized forms
    /// Returns the first forbidden phrase found, or nil if none detected
    static func findForbidden(in input: String, forbidden: [String]) -> String? {
        let norm = normalize(input)
        for rawPhrase in forbidden {
            let p = normalize(rawPhrase)
            if norm.spaced.contains(p.spaced) { return rawPhrase }
            if !p.collapsed.isEmpty && norm.collapsed.contains(p.collapsed) { return rawPhrase }
        }
        return nil
    }

    /// Searches for forbidden phrases in selected language
    /// Returns the first forbidden phrase found, or nil if none detected
    static func findForbiddenInLanguage(in input: String, language: Language) -> String? {
        return findForbidden(in: input, forbidden: language.forbiddenPhrases)
    }
}
