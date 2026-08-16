import Foundation

public struct CreateFileTool: AgentTool {
    public let fileSystem: VirtualFileSystem
    public let name = "create_file"
    public let description = "Create a new file inside the current project."

    public var parametersSchema: [String: JSONValue] {
        [
            "type": .string("object"),
            "properties": .object([
                "path": .object(["type": .string("string"), "description": .string("Relative file path")]),
                "content": .object(["type": .string("string"), "description": .string("Complete UTF-8 file content")])
            ]),
            "required": .array([.string("path"), .string("content")]),
            "additionalProperties": .bool(false)
        ]
    }

    public init(fileSystem: VirtualFileSystem) { self.fileSystem = fileSystem }

    public func execute(arguments: [String: JSONValue]) async throws -> ToolResult {
        guard let path = arguments["path"]?.stringValue,
              let content = arguments["content"]?.stringValue else {
            throw ToolExecutionError.invalidArguments
        }
        try await fileSystem.createFile(path: path, content: content)
        return ToolResult(success: true, message: "Created \(path)", path: path, content: content)
    }
}

public struct ReadFileTool: AgentTool {
    public let fileSystem: VirtualFileSystem
    public let name = "read_file"
    public let description = "Read an existing project file."

    public var parametersSchema: [String: JSONValue] {
        [
            "type": .string("object"),
            "properties": .object(["path": .object(["type": .string("string"), "description": .string("Relative file path")])]),
            "required": .array([.string("path")]),
            "additionalProperties": .bool(false)
        ]
    }

    public init(fileSystem: VirtualFileSystem) { self.fileSystem = fileSystem }

    public func execute(arguments: [String: JSONValue]) async throws -> ToolResult {
        guard let path = arguments["path"]?.stringValue else { throw ToolExecutionError.invalidArguments }
        let content = try await fileSystem.readFile(path: path)
        return ToolResult(success: true, message: "Read \(path)", path: path, content: content)
    }
}

public struct EditFileProposal: Codable, Sendable, Identifiable {
    public let id: UUID
    public let path: String
    public let oldText: String
    public let newText: String

    public init(path: String, oldText: String, newText: String) {
        self.id = UUID()
        self.path = path
        self.oldText = oldText
        self.newText = newText
    }
}

public struct EditFileTool: AgentTool {
    public let fileSystem: VirtualFileSystem
    public let proposalSink: EditProposalSink
    public let name = "edit_file"
    public let description = "Propose an exact text replacement. The app must show a diff and wait for user approval before changing the file."

    public var parametersSchema: [String: JSONValue] {
        [
            "type": .string("object"),
            "properties": .object([
                "path": .object(["type": .string("string")]),
                "old_text": .object(["type": .string("string")]),
                "new_text": .object(["type": .string("string")])
            ]),
            "required": .array([.string("path"), .string("old_text"), .string("new_text")]),
            "additionalProperties": .bool(false)
        ]
    }

    public init(fileSystem: VirtualFileSystem, proposalSink: EditProposalSink) {
        self.fileSystem = fileSystem
        self.proposalSink = proposalSink
    }

    public func execute(arguments: [String: JSONValue]) async throws -> ToolResult {
        guard let path = arguments["path"]?.stringValue,
              let oldText = arguments["old_text"]?.stringValue,
              let newText = arguments["new_text"]?.stringValue else {
            throw ToolExecutionError.invalidArguments
        }

        let current = try await fileSystem.readFile(path: path)
        guard current.contains(oldText) else { throw ToolExecutionError.textNotFound(path) }

        let proposal = EditFileProposal(path: path, oldText: oldText, newText: newText)
        await proposalSink.propose(proposal)

        return ToolResult(success: true, message: "Edit proposal created; waiting for user approval.", path: path)
    }
}

public actor EditProposalSink {
    private var proposals: [UUID: EditFileProposal] = [:]

    public init() {}

    public func propose(_ proposal: EditFileProposal) {
        proposals[proposal.id] = proposal
    }

    public func proposal(id: UUID) -> EditFileProposal? {
        proposals[id]
    }

    public func reject(id: UUID) {
        proposals.removeValue(forKey: id)
    }

    public func accept(id: UUID, in fileSystem: VirtualFileSystem) async throws {
        guard let proposal = proposals[id] else { return }
        let current = try await fileSystem.readFile(path: proposal.path)
        guard current.contains(proposal.oldText) else { throw ToolExecutionError.textNotFound(proposal.path) }
        let updated = current.replacingOccurrences(of: proposal.oldText, with: proposal.newText, options: [], range: nil)
        try await fileSystem.replaceFile(path: proposal.path, content: updated)
        proposals.removeValue(forKey: id)
    }
}
