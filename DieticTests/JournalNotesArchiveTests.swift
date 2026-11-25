import XCTest
@testable import Dietic

final class JournalNotesArchiveTests: XCTestCase {
    @MainActor func testNotesRoundTripConflictPreservationAndInvalidArchives() throws {
        let domain = "Dietic.Notes.QA." + UUID().uuidString
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set("Café 🥑\nSupper", forKey: "journal.note.2026-4-2")
        defaults.set("A different day", forKey: "journal.note.2026-12-31")
        defaults.set("other prefs", forKey: "some.settings.key")
        defaults.set(" \n ", forKey: "journal.note.2026-3-14")
        let local = JournalNoteRecord.local(from: defaults)
        XCTAssertTrue(local.map(\.day) == ["2026-12-31", "2026-04-02"])
        let snapshot = JournalNotesArchive(notes: local)
        let bytes = try snapshot.encoded()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let read = try JournalNotesArchive.read(url)
        XCTAssertTrue(local == read.notes)
        let none = try read.importMissing(into: defaults)
        XCTAssertTrue(none == 0)
        defaults.removeObject(forKey: "journal.note.2026-4-2")
        defaults.set("My updated note", forKey: "journal.note.2026-12-31")
        XCTAssertTrue(read.notes.map { read.disposition($0, defaults: defaults) } == [.conflict, .add])
        let inserted = try read.importMissing(into: defaults)
        XCTAssertTrue(inserted == 1)
        XCTAssertTrue(defaults.string(forKey: "journal.note.2026-4-2") == "Café 🥑\nSupper")
        XCTAssertTrue(defaults.string(forKey: "journal.note.2026-12-31") == "My updated note")
        XCTAssertTrue(defaults.string(forKey: "some.settings.key") == "other prefs")
        let again = try read.importMissing(into: defaults)
        XCTAssertTrue(again == 0)
        var malformed = try JSONSerialization.jsonObject(with: bytes) as! [String: Any]
        for (field, replacement) in [("version", 2 as Any), ("format", "random" as Any),
                                     ("notes", [["day":"2026-02-29","text":"leap day"]] as Any),
                                     ("notes", [["day":"2026-00-01","text":"invalid"]] as Any),
                                     ("notes", [["day":"2026-2-3","text":"ambiguous"]] as Any),
                                     ("notes", [["day":"2024-02-29","text":""]] as Any),
                                     ("notes", [["day":"2024-02-29","text":"A"], ["day":"2024-02-29","text":"B"]] as Any)] {
            let original = malformed[field]
            malformed[field] = replacement
            let corrupt = try JSONSerialization.data(withJSONObject: malformed)
            XCTAssertTrue((try? JournalNotesArchive.decode(corrupt)) == nil)
            malformed[field] = original
        }
        let sizeTest = Data(repeating: 0, count: JournalNotesArchive.maxBytes + 1)
        XCTAssertTrue((try? JournalNotesArchive.decode(sizeTest)) == nil)
        XCTAssertTrue(JournalNoteRecord.date("2024-02-29", iso:true) != nil)
    }
}
