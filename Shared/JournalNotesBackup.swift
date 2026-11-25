import Foundation

struct JournalNoteRecord: Codable, Hashable, Identifiable {
    let day: String
    let text: String
    var id: String { day }

    static let keyPrefix = "journal.note."

    static func key(for date: Date) -> String {
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        return keyPrefix + "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    // Parse calendar components without a time-zone conversion or accepting rolled-over dates.
    static func date(_ value: String, iso: Bool) -> Date? {
        let pieces = value.split(separator: "-", omittingEmptySubsequences: false)
        guard pieces.count == 3, pieces[0].count == 4, pieces.allSatisfy({
            !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) }
        }), !iso || (pieces[1].count == 2 && pieces[2].count == 2),
              let year = Int(pieces[0]), (1...9999).contains(year),
              let month = Int(pieces[1]), (1...12).contains(month),
              let day = Int(pieces[2]), (1...31).contains(day) else { return nil }
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: .init(year: year, month: month, day: day, hour: 12)),
              cal.component(.year, from: date) == year, cal.component(.month, from: date) == month,
              cal.component(.day, from: date) == day else { return nil }
        return date
    }

    var date: Date? { Self.date(day, iso: true) }
    var title: String { date?.formatted(date: .long, time: .omitted) ?? day }

    static func local(from defaults: UserDefaults = .standard) -> [Self] {
        defaults.dictionaryRepresentation().compactMap { pair -> Self? in
            guard pair.key.hasPrefix(keyPrefix), let text = pair.value as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let date = date(String(pair.key.dropFirst(keyPrefix.count)), iso: false),
                  key(for: date) == pair.key else { return nil }
            let calendar = Calendar(identifier: .gregorian)
            let canonical = String(format: "%04d-%02d-%02d", calendar.component(.year, from: date),
                                   calendar.component(.month, from: date), calendar.component(.day, from: date))
            return Self(day: canonical, text: text)
        }.sorted { $0.day > $1.day }
    }
}

struct JournalNotesArchive: Codable {
    private let format: String
    private let version: Int
    let notes: [JournalNoteRecord]
    static let maxBytes = 8 * 1024 * 1024

    init(notes: [JournalNoteRecord]) {
        self.notes = notes
        format = "dietic.journal-notes"
        version = 1
    }

    enum Issue: LocalizedError {
        case invalid, version, size
        var errorDescription: String? {
            switch self {
            case .invalid: return "Choose a Dietic notes backup with valid, unique dates."
            case .version: return "This notes backup uses an unsupported file version."
            case .size: return "The notes backup must be 8 MB or smaller."
            }
        }
    }

    private func validate() throws {
        guard format == "dietic.journal-notes" else { throw Issue.invalid }
        guard version == 1 else { throw Issue.version }
        var seen = Set<String>()
        guard notes.allSatisfy({ $0.date != nil && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                  seen.insert($0.day).inserted }) else { throw Issue.invalid }
    }

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= Self.maxBytes else { throw Issue.size }
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= maxBytes else { throw Issue.size }
        guard let archive = try? JSONDecoder().decode(Self.self, from: data) else { throw Issue.invalid }
        try archive.validate()
        return archive
    }

    static func read(_ url: URL) throws -> Self {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        guard let data = try file.read(upToCount: maxBytes + 1) else { throw Issue.invalid }
        return try decode(data)
    }

    enum Disposition: String {
        case add = "Ready to add", same = "Already saved", conflict = "Existing note kept"
    }

    func disposition(_ note: JournalNoteRecord, defaults: UserDefaults = .standard) -> Disposition {
        guard let date = note.date else { return .conflict }
        let key = JournalNoteRecord.key(for: date)
        guard let value = defaults.object(forKey: key) else { return .add }
        guard let text = value as? String else { return .conflict }
        if text == note.text { return .same }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .add : .conflict
    }

    @MainActor func importMissing(into defaults: UserDefaults = .standard) throws -> Int {
        try validate()
        var added = 0
        for note in notes where disposition(note, defaults: defaults) == .add {
            guard let date = note.date else { continue }
            defaults.set(note.text, forKey: JournalNoteRecord.key(for: date))
            added += 1
        }
        return added
    }
}

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

private struct JournalNotesDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw JournalNotesArchive.Issue.invalid }
        _ = try JournalNotesArchive.decode(data)
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct JournalNotesView: View {
    @State private var notes: [JournalNoteRecord] = []
    @State private var document: JournalNotesDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var reading = false
    @State private var preview: JournalNotesArchive?
    @State private var presentingPreview = false
    @State private var message: String?

    var body: some View {
        List {
            Section {
                Button { export() } label: { Label("Export notes", systemImage: "square.and.arrow.up") }
                    .disabled(notes.isEmpty || reading)
                Button { importing = true } label: { Label("Import notes", systemImage: "square.and.arrow.down") }
                    .disabled(reading)
                if reading { ProgressView("Opening backup…") }
                if let message { Text(message).font(.footnote) }
            } footer: { Text("Back up your dated journal notes to Files.") }
            Section("Your notes") {
                if notes.isEmpty { Text("Your daily notes will appear here.").foregroundStyle(.secondary) }
                ForEach(notes) { note in
                    if let date = note.date {
                        NavigationLink {
                            JournalNoteEditor(date: date)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title).font(.headline)
                                Text(note.text).lineLimit(2).font(.subheadline).foregroundStyle(WarmInk.muted)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Journal notes").scrollContentBackground(.hidden).background(WarmInk.paper)
        .onAppear { notes = JournalNoteRecord.local() }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Dietic Journal Notes") { result in
            do { _ = try result.get(); message = "Notes exported." } catch { report(error) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                reading = true
                Task {
                    defer { reading = false }
                    do {
                        preview = try await Task.detached { try JournalNotesArchive.read(url) }.value
                        presentingPreview = true
                    } catch { report(error) }
                }
            } catch { report(error) }
        }
        .sheet(isPresented: $presentingPreview) {
            if let preview {
                NotesImportPreview(archive: preview) { count in
                    notes = JournalNoteRecord.local()
                    message = count == 1 ? "1 note imported." : "\(count) notes imported."
                }
            }
        }
    }

    private func export() {
        do {
            document = JournalNotesDocument(data: try JournalNotesArchive(notes: JournalNoteRecord.local()).encoded())
            exporting = true
        } catch { report(error) }
    }

    private func report(_ error: Error) {
        if (error as NSError).domain == NSCocoaErrorDomain, (error as NSError).code == NSUserCancelledError { return }
        message = error.localizedDescription
    }
}

private struct NotesImportPreview: View {
    let archive: JournalNotesArchive
    let applied: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?

    var body: some View {
        let addCount = archive.notes.filter { archive.disposition($0) == .add }.count
        NavigationStack {
            List {
                Section {
                    ForEach(archive.notes.sorted { $0.day > $1.day }) { note in
                        DisclosureGroup {
                            Text(note.text)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(note.title)
                                Text(archive.disposition(note).rawValue).font(.caption).foregroundStyle(WarmInk.muted)
                            }
                        }
                    }
                    if archive.notes.isEmpty { Text("This backup has no notes.") }
                } footer: { Text("Only dates without a saved note will be added.") }
                if let message { Text(message) }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Import preview")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Button(addCount == 1 ? "Import 1 note" : "Import \(addCount) notes") {
                    do { applied(try archive.importMissing()); dismiss() }
                    catch { message = error.localizedDescription }
                }.buttonStyle(JournalActionStyle()).disabled(addCount == 0).padding().background(WarmInk.paper)
            }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }
}

private struct JournalNoteEditor: View {
    let date: Date
    @AppStorage private var note: String
    init(date: Date) {
        self.date = date
        _note = AppStorage(wrappedValue: "", JournalNoteRecord.key(for: date))
    }
    var body: some View {
        Form {
            TextField("Journal note", text: $note, axis: .vertical).lineLimit(5...16)
        }.navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .scrollContentBackground(.hidden).background(WarmInk.paper)
    }
}
#endif
