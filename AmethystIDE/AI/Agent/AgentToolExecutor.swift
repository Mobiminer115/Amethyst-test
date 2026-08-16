import Foundation

public struct AgentToolExecutor: Sendable {
    private let registry: ToolRegistry

    public init(registry: ToolRegistry) {
        self.registry = registry
    }

    public func execute(_ call: AgentToolCall) async throws -> ToolResult {
        guard let tool = registry.tool(named: call.name) else {
            throw ToolExecutionError.unsupportedTool(call.name)
        }
        do {
            return try await tool.execute(arguments: call.arguments)
        } catch {
            return ToolResult(success: false, message: error.localizedDescription, path: nil, content: nil)
        }
    }
}
