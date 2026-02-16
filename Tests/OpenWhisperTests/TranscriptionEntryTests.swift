import Testing
import Foundation
@testable import OpenWhisper

@Suite("TranscriptionEntry")
struct TranscriptionEntryTests {

    @Test("Default initializer generates unique IDs")
    func defaultInit() {
        let a = TranscriptionEntry(text: "Hello")
        let b = TranscriptionEntry(text: "Hello")
        #expect(a.id != b.id)
        #expect(a.text == "Hello")
        #expect(a.durationSeconds == nil)
        #expect(a.targetAppName == nil)
    }

    @Test("Full initializer stores all fields")
    func fullInit() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1000)
        let entry = TranscriptionEntry(id: id, text: "Test", createdAt: date, durationSeconds: 5.5, targetAppName: "Safari")
        #expect(entry.id == id)
        #expect(entry.text == "Test")
        #expect(entry.createdAt == date)
        #expect(entry.durationSeconds == 5.5)
        #expect(entry.targetAppName == "Safari")
    }

    @Test("Identifiable conformance uses id")
    func identifiable() {
        let entry = TranscriptionEntry(text: "A")
        let _: any Identifiable = entry
        #expect(entry.id == entry.id) // compiles = conforms
    }

    @Test("Hashable conformance")
    func hashable() {
        let id = UUID()
        let date = Date()
        let a = TranscriptionEntry(id: id, text: "Same", createdAt: date)
        let b = TranscriptionEntry(id: id, text: "Same", createdAt: date)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let entry = TranscriptionEntry(text: "Codable test", durationSeconds: 3.14, targetAppName: "Notes")
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.id == entry.id)
        #expect(decoded.text == entry.text)
        #expect(decoded.durationSeconds == entry.durationSeconds)
        #expect(decoded.targetAppName == entry.targetAppName)
    }

    @Test("Codable round-trip with nil optionals")
    func codableNilOptionals() throws {
        let entry = TranscriptionEntry(text: "Minimal")
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptionEntry.self, from: data)
        #expect(decoded.durationSeconds == nil)
        #expect(decoded.targetAppName == nil)
    }

    @Test("Inequality for different entries")
    func inequality() {
        let a = TranscriptionEntry(text: "A")
        let b = TranscriptionEntry(text: "B")
        #expect(a != b)
    }

    @Test("Empty text is allowed")
    func emptyText() {
        let entry = TranscriptionEntry(text: "")
        #expect(entry.text == "")
    }
}
