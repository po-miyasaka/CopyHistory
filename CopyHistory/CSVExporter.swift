import Foundation

struct CSVExportRow: Equatable {
    let name: String
    let contentType: String
    let text: String
    let memo: String
    let isFavorite: Bool
    let binarySize: Int64
    let createdDate: Date?
    let updateDate: Date?
    let reminderDate: Date?
    let ocrText: String
    /// Only written by the AI filter export: true when the model could not judge the item.
    var isUnjudged = false
}

extension CSVExportRow {
    init(item: CopiedItem) {
        self.init(
            name: item.name ?? "",
            contentType: item.contentTypeString ?? "",
            text: item.rawString ?? "",
            memo: item.memo ?? "",
            isFavorite: item.favorite,
            binarySize: item.binarySize,
            createdDate: item.createdDate,
            updateDate: item.updateDate,
            reminderDate: item.reminderDate,
            ocrText: item.ocrText ?? ""
        )
    }
}

enum CSVExporter {
    static let header = ["name", "content_type", "text", "memo", "favorite", "size_bytes", "saved_at", "updated_at", "reminder_at", "ocr_text"]

    /// RFC 4180 CSV with a UTF-8 BOM so spreadsheet apps detect the encoding.
    static let unjudgedHeader = "could_not_judge"
    static let unjudgedMark = "×"

    /// With `includesUnjudged`, an extra last column holds × for items the AI filter could not judge and stays empty otherwise.
    static func makeCSV(rows: [CSVExportRow], includesUnjudged: Bool = false, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let lines = [header + (includesUnjudged ? [unjudgedHeader] : [])] + rows.map { row in
            [
                row.name,
                row.contentType,
                row.text,
                row.memo,
                row.isFavorite ? "true" : "false",
                String(row.binarySize),
                row.createdDate.map(formatter.string(from:)) ?? "",
                row.updateDate.map(formatter.string(from:)) ?? "",
                row.reminderDate.map(formatter.string(from:)) ?? "",
                row.ocrText
            ] + (includesUnjudged ? [row.isUnjudged ? unjudgedMark : ""] : [])
        }
        return "\u{FEFF}" + lines.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
