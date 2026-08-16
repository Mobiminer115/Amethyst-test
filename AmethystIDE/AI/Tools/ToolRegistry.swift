import Foundation

public struct ToolRegistry: Sendable {
    private let tools: [String: any AgentTool]

    public init(tools: [any AgentTool] = []) {
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    }

    public func tool(named name: String) -> (any AgentTool)? {
        tools[name]
    }

    public func allTools() -> [any AgentTool] {
        Array(tools.values)
    }

    public func openAICompatibleSchemas() throws -> [Data] {
        try tools.values.map { tool in
            let schema: [String: JSONValue] = [
                "type": .string("function"),
                "function": .object([
                    "name": .string(tool.name),
                    "description": .string(tool.description),
                    "parameters": .object(tool.parametersSchema)
                ])
            ]
            return try JSONEncoder().encode(schema)
        }
    }
}
