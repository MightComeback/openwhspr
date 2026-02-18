import Testing
import Foundation
@testable import OpenWhisper

@Suite("ViewHelpers.activeLanguageLabel")
struct ViewHelpersActiveLanguageLabelTests {

    @Test("auto code returns auto label")
    func autoCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "auto")
        #expect(result == "auto")
    }

    @Test("en code returns english")
    func englishCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "en")
        #expect(result == "english")
    }

    @Test("de code returns german")
    func germanCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "de")
        #expect(result == "german")
    }

    @Test("ja code returns japanese")
    func japaneseCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "ja")
        #expect(result == "japanese")
    }

    @Test("uk code returns ukrainian")
    func ukrainianCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "uk")
        #expect(result == "ukrainian")
    }

    @Test("unknown code falls back to auto")
    func unknownCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "zzz_nonexistent")
        #expect(result == "auto")
    }

    @Test("empty string falls back to auto")
    func emptyString() {
        let result = ViewHelpers.activeLanguageLabel(for: "")
        #expect(result == "auto")
    }

    @Test("fr code returns french")
    func frenchCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "fr")
        #expect(result == "french")
    }

    @Test("es code returns spanish")
    func spanishCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "es")
        #expect(result == "spanish")
    }

    @Test("zh code returns chinese")
    func chineseCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "zh")
        #expect(result == "chinese")
    }

    @Test("ru code returns russian")
    func russianCode() {
        let result = ViewHelpers.activeLanguageLabel(for: "ru")
        #expect(result == "russian")
    }

    @Test("case sensitive - EN is unknown, falls back to auto")
    func caseSensitive() {
        let result = ViewHelpers.activeLanguageLabel(for: "EN")
        #expect(result == "auto")
    }
}
