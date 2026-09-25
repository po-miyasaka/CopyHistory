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
            reminderDate: item.reminderDate
        )
    }
}

enum CSVExporter {
    static let header = ["name", "content_type", "text", "memo", "favorite", "size_bytes", "saved_at", "updated_at", "reminder_at"]

    /// RFC 4180 CSV with a UTF-8 BOM so spreadsheet apps detect the encoding.
    static func makeCSV(rows: [CSVExportRow], timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let lines = [header] + rows.map { row in
            [
                row.name,
                row.contentType,
                row.text,
                row.memo,
                row.isFavorite ? "true" : "false",
                String(row.binarySize),
                row.createdDate.map(formatter.string(from:)) ?? "",
                row.updateDate.map(formatter.string(from:)) ?? "",
                row.reminderDate.map(formatter.string(from:)) ?? ""
            ]
        }
        return "\u{FEFF}" + lines.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
