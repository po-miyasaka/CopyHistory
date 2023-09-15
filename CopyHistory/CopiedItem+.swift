//
//  CopiedItem+.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/26.
//

import Foundation

extension CopiedItem {
    static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()

    var binarySizeString: String {
        if binarySize == 0 { return "-" }
        return Self.formatter.string(fromByteCount: binarySize)
    }

    var attributeString: NSAttributedString? {
        if let att = rtfStringCached {
            return att
        }
        guard contentTypeString?.contains("rtf") == true, let content = content else { return nil }

        let attributeString = (try? NSAttributedString(data: content, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))
        rtfStringCached = attributeString
        return attributeString
    }

    var htmlString: NSAttributedString? {
        if let att = htmlStringCached {
            return att
        }
        guard contentTypeString?.contains("html") == true, let content = content else { return nil }

        let attributeString = (try? NSAttributedString(data: content, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil))
        htmlStringCached = attributeString
        return attributeString
    }

    var fileURL: URL? {
        guard contentTypeString?.contains("file-url") == true,
            let content = content,
            let path = String(data: content, encoding: .utf8),
            let url = URL(string: path) else {

            return nil
        }
//                    url.startAccessingSecurityScopedResource()
        return url
    }
}
