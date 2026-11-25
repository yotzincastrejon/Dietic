import SwiftUI
import Vision
import AVFoundation
import PhotosUI
import ImageIO

/// A US Nutrition Facts panel gives these values per serving. Missing values stay blank.
struct NutritionLabelReading {
    var calories: String?
    var carbs: String?
    var protein: String?
    var fat: String?
    var otherNutrients: [Int: String] = [:]
    var serving: String?
    var metricSize: String?
    var metricUnit = "g"

    enum ReadError: LocalizedError {
        case unreadable, multipleColumns, ambiguous
        var errorDescription: String? {
            switch self {
            case .unreadable: return "No readable Nutrition Facts panel found. Try a closer, well-lit photo or enter the values below."
            case .multipleColumns: return "This label lists multiple portions. Enter the values from the per-serving column below."
            case .ambiguous: return "Some values on this photo conflict. Photograph one Nutrition Facts panel or enter its values below."
            }
        }
    }

    static func recognize(_ image: CGImage) async throws -> Self {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image).perform([request])
        try Task.checkCancellation()
        let boxes = (request.results ?? []).compactMap { observation -> (String, CGRect)? in
            guard let match = observation.topCandidates(1).first, match.confidence >= 0.5 else { return nil }
            return (match.string, observation.boundingBox)
        }
        return try parse(rows: rows(from: boxes))
    }

    /// Vision often returns the label and number separately; reconstruct visual lines first.
    static func rows(from boxes: [(String, CGRect)]) -> [String] {
        var lines: [[(String, CGRect)]] = []
        for box in boxes.sorted(by: { $0.1.midY > $1.1.midY }) {
            if let last = lines.last, let anchor = last.first,
               abs(box.1.midY - anchor.1.midY) <= max(box.1.height, anchor.1.height) * 0.48 {
                lines[lines.count - 1].append(box)
            } else { lines.append([box]) }
        }
        return lines.map { line in line.sorted { $0.1.minX < $1.1.minX }.map(\.0).joined(separator: " ") }
    }

    static func parse(rows: [String]) throws -> Self {
        let rows = rows.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let whole = rows.joined(separator: " ").lowercased()
        let headings = rows.filter { $0.localizedCaseInsensitiveContains("nutrition facts") }
        guard headings.count <= 1 else { throw ReadError.ambiguous }
        guard !headings.isEmpty || whole.contains("serving size") else { throw ReadError.unreadable }
        // "Servings per container" is a count, while "per container" over a numeric column is another basis.
        let columnText = whole.replacingOccurrences(of: #"servings?\s+per\s+container"#, with: "", options: .regularExpression)
        if columnText.range(of: #"\bper\s+(container|package|bottle|box|bag|100\s*(g|ml))\b|\bas\s+(prepared|packaged)\b"#,
                            options: .regularExpression) != nil { throw ReadError.multipleColumns }

        func capture(_ pattern: String, _ text: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
            return (1..<match.numberOfRanges).map { index in
                Range(match.range(at: index), in: text).map { String(text[$0]) } ?? ""
            }
        }

        var result = Self()
        let fields: [(name: String, unit: String, id: Int)] = [
            (#"total\s+fat"#, "g", 204), (#"total\s+carbohydrates?"#, "g", 205), ("protein", "g", 203),
            (#"dietary\s+fiber"#, "g", 291), (#"total\s+sugars?"#, "g", 269), (#"saturated\s+fat"#, "g", 606),
            ("sodium", "mg", 307), ("cholesterol", "mg", 601)
        ]
        var gramsOrMilligrams: [Int: String] = [:]
        for (index, row) in rows.enumerated() {
            let next = index + 1 < rows.count ? rows[index + 1] : ""
            let rowWithNext = row + " " + next
            if capture(#"^(calories)(?:\s+per\s+serving)?\s*:?\s*\d+\s+\d+\s*$"#, row) != nil { throw ReadError.multipleColumns }
            let caloriePattern = #"^calories(?:\s+per\s+serving)?\s*:?\s*(\d+(?:\.\d+)?)\s*(?:kcal)?\s*$"#
            let calories = capture(caloriePattern, row) ?? capture(caloriePattern, rowWithNext)
            if let value = calories?.first {
                guard result.calories == nil || result.calories == value else { throw ReadError.ambiguous }
                result.calories = value
            }
            for (name, unit, id) in fields {
                let twoAmounts = "^" + name + #"\s*:?.*?\b\d+(?:\.\d+)?\s*"# + unit
                    + #"\b.*?\b(\d+(?:\.\d+)?)\s*"# + unit + #"\b"#
                if capture(twoAmounts, row) != nil {
                    throw ReadError.multipleColumns
                }
                let pattern = "^" + name + #"\s*:?\s*(\d+(?:\.\d+)?)\s*"# + unit + #"(?:\s*\d+(?:\.\d+)?\s*%)?\s*$"#
                if let value = (capture(pattern, row) ?? capture(pattern, rowWithNext))?.first {
                    guard gramsOrMilligrams[id] == nil || gramsOrMilligrams[id] == value else { throw ReadError.ambiguous }
                    gramsOrMilligrams[id] = value
                }
            }
            if let match = capture(#"^serving\s+size\s*:?\s*(.*)$"#, row) {
                let value = match[0].isEmpty ? next : match[0]
                let metric = capture(#"^(.*?)\(?\s*(\d+(?:\.\d+)?)\s*(g|grams?|ml)\s*\)?\s*$"#, value)
                if let metric {
                    let description = metric[0].trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "(")))
                    result.serving = description.isEmpty ? nil : description
                    result.metricSize = metric[1]
                    result.metricUnit = metric[2].lowercased() == "ml" ? "mL" : "g"
                } else if value.first?.isNumber == true { result.serving = value }
            }
        }
        result.fat = gramsOrMilligrams.removeValue(forKey: 204)
        result.carbs = gramsOrMilligrams.removeValue(forKey: 205)
        result.protein = gramsOrMilligrams.removeValue(forKey: 203)
        result.otherNutrients = gramsOrMilligrams
        guard [result.calories, result.fat, result.carbs, result.protein].contains(where: { $0 != nil }) else {
            throw ReadError.unreadable
        }
        return result
    }
}

struct NutritionLabelCapture: View {
    @Binding var reading: Bool
    let apply: (NutritionLabelReading) -> Void
    @State private var selection: PhotosPickerItem?
    @State private var camera = false
    @State private var photo: CGImage?
    @State private var recognitionID: UUID?
    @State private var hasAppliedPhoto = false
    @State private var message = ""

    var body: some View {
        Section("Scan Nutrition Facts") {
            HStack {
                Button { Task { await openCamera() } } label: { Label("Take photo", systemImage: "camera") }
                Spacer()
                PhotosPicker(selection: $selection, matching: .images) { Label("Choose photo", systemImage: "photo") }
            }.buttonStyle(.borderless)
            if let photo {
                Image(decorative: photo, scale: 1).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 240)
            }
            if reading { ProgressView("Reading label…") }
            if !message.isEmpty { Text(message).font(.footnote) }
        }
        .fullScreenCover(isPresented: $camera) {
            CameraPhotoPicker { data in
                camera = false
                if let data { receive(data) }
            }.ignoresSafeArea()
        }
        .task(id: selection) {
            guard let selection else { return }
            recognitionID = nil
            reading = true
            message = ""
            do {
                guard let data = try await selection.loadTransferable(type: Data.self) else { throw NutritionLabelReading.ReadError.unreadable }
                try Task.checkCancellation()
                receive(data)
            } catch { if !Task.isCancelled { reportFailure(error.localizedDescription) } }
        }
        .task(id: recognitionID) {
            guard recognitionID != nil, let photo else { return }
            reading = true
            message = ""
            do {
                let result = try await NutritionLabelReading.recognize(photo)
                try Task.checkCancellation()
                apply(result)
                hasAppliedPhoto = true
                message = "Review the values below against your label."
            } catch { if !Task.isCancelled { reportFailure(error.localizedDescription) } }
            if !Task.isCancelled { reading = false }
        }
    }

    private func receive(_ data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2200
              ] as CFDictionary) else {
            reportFailure("This photo could not be opened.")
            return
        }
        photo = image
        reading = true
        recognitionID = UUID()
    }

    private func reportFailure(_ reason: String) {
        reading = false
        message = hasAppliedPhoto ? reason + " The fields still show your previous entries." : reason
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            message = "The camera is unavailable. Choose a photo from your library."
            return
        }
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            message = "Allow camera access for Dietic in Settings, or choose a label photo."
            return
        }
        camera = true
    }
}
