import Foundation

public protocol AgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parametersSchema: [String: JSONValue] { get }
    func execute(arguments: [String: JSONValue]) async throws -> ToolResult
}

public struct ToolResult: Codable, Sendable {
    public let success: Bool
    public let message: String
    public let path: String?
    public let content: String?

    public init(success: Bool, message: String, path: String? = nil, content: String? = nil) {
        self.success = success
        self.message = message
        self.path = path
        self.content = content
    }
}

public enum ToolExecutionError: LocalizedError, Sendable {
    case invalidArguments
    case textNotFound(String)
    case unsupportedTool(String)

    public var errorDescription: String? {
        switch self {
        case .invalidArguments: return "Invalid tool arguments."
        case .textNotFound(let path): return "The requested old_text was not found in \(path)."
        case .unsupportedTool(let name): return "Unsupported tool: \(name)"
        }
    }
}

public enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode(String.self) { self = .string(value); return }
        if let value = try? container.decode(Bool.self) { self = .bool(value); return }
        if let value = try? container.decode(Double.self) { self = .number(value); return }
        if let value = try? container.decode([String: JSONValue].self) { self = .object(value); return }
        self = .array(try container.decode([JSONValue].self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}
