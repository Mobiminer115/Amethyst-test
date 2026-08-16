import Foundation

public actor VirtualFileSystem {
    private var files: [String: String] = [:]

    public init(initialFiles: [String: String] = [:]) {
        self.files = initialFiles.reduce(into: [:]) { result, item in
            result[Self.normalize(item.key)] = item.value
        }
    }

    public func createFile(path: String, content: String) throws {
        let normalized = Self.normalize(path)
        guard !normalized.isEmpty else { throw FileSystemError.invalidPath }
        guard files[normalized] == nil else { throw FileSystemError.fileAlreadyExists(normalized) }
        files[normalized] = content
    }

    public func readFile(path: String) throws -> String {
        let normalized = Self.normalize(path)
        guard let content = files[normalized] else { throw FileSystemError.fileNotFound(normalized) }
        return content
    }

    public func replaceFile(path: String, content: String) throws {
        let normalized = Self.normalize(path)
        guard files[normalized] != nil else { throw FileSystemError.fileNotFound(normalized) }
        files[normalized] = content
    }

    public func exists(path: String) -> Bool {
        files[Self.normalize(path)] != nil
    }

    public func allFiles() -> [String] {
        files.keys.sorted()
    }

    private static func normalize(_ path: String) -> String {
        path.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "//", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

public enum FileSystemError: LocalizedError, Sendable {
    case invalidPath
    case fileAlreadyExists(String)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPath: return "Invalid file path."
        case .fileAlreadyExists(let path): return "File already exists: \(path)"
        case .fileNotFound(let path): return "File not found: \(path)"
        }
    }
}
