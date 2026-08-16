import Foundation

@available(macOS 12.0, iOS 15.0, *)
public actor AgentLoop {
    private let provider: OpenAIResponsesProvider
    private let executor: AgentToolExecutor
    private let registry: ToolRegistry
    private let maxIterations: Int

    public init(provider: OpenAIResponsesProvider, registry: ToolRegistry, maxIterations: Int = 12) {
        self.provider = provider
        self.registry = registry
        self.executor = AgentToolExecutor(registry: registry)
        self.maxIterations = maxIterations
    }

    public func run(userPrompt: String) async throws -> AgentResponse {
        var input: [JSONValue] = [
            .object([
                "role": .string("user"),
                "content": .string(userPrompt)
            ])
        ]

        for _ in 0..<maxIterations {
            let response = try await provider.respond(input: input, registry: registry)
            guard let calls = response.message.toolCalls, !calls.isEmpty else {
                return response
            }

            for call in calls {
                input.append(.object([
                    "type": .string("function_call"),
                    "call_id": .string(call.id),
                    "name": .string(call.name),
                    "arguments": .string((try? String(data: JSONEncoder().encode(call.arguments), encoding: .utf8)) ?? "{}")
                ]))

                let result = try await executor.execute(call)
                let output = try JSONEncoder().encode(result)
                input.append(.object([
                    "type": .string("function_call_output"),
                    "call_id": .string(call.id),
                    "output": .string(String(data: output, encoding: .utf8) ?? "{}")
                ]))
            }
        }

        throw AgentError.maximumIterationsReached
    }
}
