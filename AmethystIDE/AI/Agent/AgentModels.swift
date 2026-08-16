import Foundation

public struct AgentMessage: Codable, Sendable {
    public enum Role: String, Codable, Sendable { case system, user, assistant, tool }
    public let role: Role
    public let content: String?
    public let toolCallID: String?
    public let toolCalls: [AgentToolCall]?

    public init(role: Role, content: String? = nil, toolCallID: String? = nil, toolCalls: [AgentToolCall]? = nil) {
        self.role = role
        self.content = content
        self.toolCallID = toolCallID
        self.toolCalls = toolCalls
    }
}

public struct AgentToolCall: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let arguments: [String: JSONValue]

    public init(id: String, name: String, arguments: [String: JSONValue]) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

public struct AgentResponse: Codable, Sendable {
    public let message: AgentMessage
    public init(message: AgentMessage) { self.message = message }
}

public enum AgentError: LocalizedError, Sendable {
    case invalidResponse
    case requestFailed(String)
    case maximumIterationsReached

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The AI provider returned an invalid response."
        case .requestFailed(let message): return message
        case .maximumIterationsReached: return "The agent reached its maximum tool iterations."
        }
    }
}
