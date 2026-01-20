//
//  TextSanitizerTests.swift
//  MediScribeTests
//
//  Tests for text normalization and forbidden phrase detection
//

import XCTest
@testable import MediScribe

final class TextSanitizerTests: XCTestCase {

    // MARK: - Basic Normalization Tests

    func testConvertsToLowercase() {
        let input = "UPPERCASE TEXT"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.collapsed, "uppercasetext")
    }

    func testRemovesDiacritics() {
        let input = "café naïve"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.collapsed, "cafenaive")
    }

    func testRemovesNonAlphanumeric() {
        let input = "hello, world! 123"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.collapsed, "helloworld123")
    }

    func testReturnsSpacedAndCollapsedForms() {
        let input = "hello world"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.spaced, "hello world")
        XCTAssertEqual(result.collapsed, "helloworld")
    }

    // MARK: - Obfuscation Detection Tests

    func testDetectsPhraseWithExtraSpaces() {
        let obfuscated = "p n e u m o n i a"
        let result = TextSanitizer.normalize(obfuscated)
        XCTAssertEqual(result.collapsed, "pneumonia")
    }

    func testNormalizesSpecialCharacters() {
        let input = "dia-gnosis!"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.collapsed, "diagnosis")
    }

    func testHandlesEmptyString() {
        let input = ""
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.spaced, "")
        XCTAssertEqual(result.collapsed, "")
    }

    func testHandlesWhitespaceOnly() {
        let input = "   \t\n   "
        let result = TextSanitizer.normalize(input)
        XCTAssertTrue(result.collapsed.isEmpty)
    }

    // MARK: - Medical Term Normalization Tests

    func testNormalizesMedicalTerms() {
        let terms = [
            ("Pnéumônia", "pneumonia"),
            ("DiagNOSIS", "diagnosis"),
            ("reçommend", "recommend"),
            ("liKEly", "likely")
        ]

        for (input, expected) in terms {
            let result = TextSanitizer.normalize(input)
            XCTAssertEqual(result.collapsed, expected, "Failed to normalize '\(input)' to '\(expected)'")
        }
    }

    // MARK: - Forbidden Phrase Detection Tests

    func testFindsForbiddenPhraseInText() {
        let text = "This shows signs of pneumonia"
        let forbidden = ["pneumonia", "tuberculosis"]
        let found = TextSanitizer.findForbidden(in: text, forbidden: forbidden)
        XCTAssertEqual(found, "pneumonia")
    }

    func testFindsForbiddenPhraseWithObfuscation() {
        let text = "This shows p n e u m o n i a pattern"
        let forbidden = ["pneumonia"]
        let found = TextSanitizer.findForbidden(in: text, forbidden: forbidden)
        XCTAssertEqual(found, "pneumonia")
    }

    func testReturnsNilWhenNoForbiddenPhrases() {
        let text = "Visible lung fields bilaterally"
        let forbidden = ["pneumonia", "tuberculosis"]
        let found = TextSanitizer.findForbidden(in: text, forbidden: forbidden)
        XCTAssertNil(found)
    }

    func testFindsForbiddenPhraseWithDiacritics() {
        let text = "This shows pnéumònia"
        let forbidden = ["pneumonia"]
        let found = TextSanitizer.findForbidden(in: text, forbidden: forbidden)
        XCTAssertEqual(found, "pneumonia")
    }

    // MARK: - Complex Input Tests

    func testHandlesMultilineText() {
        let input = """
        Line 1
        Line 2
        Line 3
        """
        let result = TextSanitizer.normalize(input)
        XCTAssertTrue(result.collapsed.contains("line1"))
        XCTAssertTrue(result.collapsed.contains("line2"))
        XCTAssertTrue(result.collapsed.contains("line3"))
    }

    func testHandlesMixedLanguageCharacters() {
        let input = "English français español"
        let result = TextSanitizer.normalize(input)
        XCTAssertEqual(result.collapsed, "englishfrancaisespanol")
    }

    func testPreservesNumbers() {
        let input = "Test123Value456"
        let result = TextSanitizer.normalize(input)
        XCTAssertTrue(result.collapsed.contains("123"))
        XCTAssertTrue(result.collapsed.contains("456"))
    }

    // MARK: - Edge Cases

    func testHandlesVeryLongStrings() {
        let longString = String(repeating: "test ", count: 1000)
        let result = TextSanitizer.normalize(longString)
        XCTAssertFalse(result.collapsed.isEmpty)
    }

    func testHandlesUnicodeEmojis() {
        let input = "test 😀 text"
        let result = TextSanitizer.normalize(input)
        // Emojis are removed (non-alphanumeric)
        XCTAssertTrue(result.collapsed.contains("test"))
        XCTAssertTrue(result.collapsed.contains("text"))
        XCTAssertFalse(result.collapsed.contains("😀"))
    }

    func testHandlesTabsAndNewlines() {
        let input = "text\twith\ttabs\nand\nnewlines"
        let result = TextSanitizer.normalize(input)
        XCTAssertTrue(result.collapsed.contains("text"))
        XCTAssertTrue(result.collapsed.contains("with"))
        XCTAssertTrue(result.collapsed.contains("tabs"))
    }

    // MARK: - Consistency Tests

    func testConsistentResults() {
        let input = "Test Input! 123"
        let result1 = TextSanitizer.normalize(input)
        let result2 = TextSanitizer.normalize(input)
        XCTAssertEqual(result1.spaced, result2.spaced)
        XCTAssertEqual(result1.collapsed, result2.collapsed)
    }

    func testIdempotency() {
        let input = "Test Input"
        let once = TextSanitizer.normalize(input)
        let twice = TextSanitizer.normalize(once.spaced)
        XCTAssertEqual(once.spaced, twice.spaced)
        XCTAssertEqual(once.collapsed, twice.collapsed)
    }
}
