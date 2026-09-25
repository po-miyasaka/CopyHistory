import Foundation

enum CSVImportError: LocalizedError, Equatable {
    case missingRequiredColumns
    case unterminatedQuote

    var errorDescription: String? {
        switch self {
        case .missingRequiredColumns:
            return String(localized: "The CSV must have \"name\" and \"text\" columns.")
        case .unterminatedQuote:
            return String(localized: "The CSV is malformed (unclosed quote).")
        }
    }
}

/// Reads CSV produced by `CSVExporter` (RFC 4180, optional UTF-8 BOM).
enum CSVImporter {
    static func parse(_ csv: String, timeZone: TimeZone = .current) -> Result<[CSVExportRow], CSVImportError> {
        let records: [[String]]
        switch tokenize(csv) {
        case .success(let value): records = value
        case .failure(let error): return .failure(error)
        }

        guard let headerRecord = records.first else { return .success([]) }
        let columns = Dictionary(headerRecord.enumerated().map { ($1.trimmingCharacters(in: .whitespaces), $0) },
                                 uniquingKeysWith: { first, _ in first })
        guard columns["name"] != nil, columns["text"] != nil else { return .failure(.missingRequiredColumns) }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let rows = records.dropFirst().map { record -> CSVExportRow in
            func value(_ key: String) -> String {
                guard let index = columns[key], index < record.count else { return "" }
                return record[index]
            }
            return CSVExportRow(
                name: value("name"),
                contentType: value("content_type"),
                text: value("text"),
                memo: value("memo"),
                isFavorite: value("favorite").lowercased() == "true",
                binarySize: Int64(value("size_bytes")) ?? 0,
                createdDate: formatter.date(from: value("saved_at")),
                updateDate: formatter.date(from: value("updated_at")),
                reminderDate: formatter.date(from: value("reminder_at")),
                ocrText: value("ocr_text"),
                imageCaption: value("image_caption")
            )
        }
        return .success(rows)
    }

    private static func tokenize(_ csv: String) -> Result<[[String]], CSVImportError> {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var hasContent = false

        var characters = csv.unicodeScalars.makeIterator()
        var pending: Unicode.Scalar? = characters.next()
        if pending == "\u{FEFF}" { pending = characters.next() }

        func endRecord() {
            if hasContent || !record.isEmpty {
                record.append(field)
                records.append(record)
            }
            record = []
            field = ""
            hasContent = false
        }

        while let scalar = pending {
            pending = characters.next()
            if inQuotes {
                if scalar == "\"" {
                    if pending == "\"" {
                        field.unicodeScalars.append("\"")
                        pending = characters.next()
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(scalar)
                }
                continue
            }
            switch scalar {
            case "\"":
                inQuotes = true
                hasContent = true
            case ",":
                record.append(field)
                field = ""
                hasContent = true
            case "\r":
                if pending == "\n" { pending = characters.next() }
                endRecord()
            case "\n":
                endRecord()
            default:
                field.unicodeScalars.append(scalar)
                hasContent = true
            }
        }
        if inQuotes { return .failure(.unterminatedQuote) }
        endRecord()
        return .success(records)
    }
}
