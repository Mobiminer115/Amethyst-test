import Foundation

public struct OpenAIResponsesProvider: Sendable {
    public let apiKey: String
    public let model: String
    public let endpoint: URL

    public init(apiKey: String, model: String = "gpt-5.6", endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
    }

    @available(macOS 12.0, iOS 15.0, *)
    public func respond(input: [JSONValue], registry: ToolRegistry) async throws -> AgentResponse {
        struct Request: Encodable {
            let model: String
            let input: [JSONValue]
            let tools: [JSONValue]
            let toolChoice: String
            enum CodingKeys: String, CodingKey { case model, input, tools; case toolChoice = "tool_choice" }
        }

        let tools = registry.allTools().map { tool -> JSONValue in
            .object([
                "type": .string("function"),
                "name": .string(tool.name),
                "description": .string(tool.description),
                "parameters": .object(tool.parametersSchema),
                "strict": .bool(true)
            ])
        }

        let body = Request(model: model, input: input, tools: tools, toolChoice: "auto")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AgentError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "OpenAI request failed."
            throw AgentError.requestFailed("HTTP \(http.statusCode): \(message)")
        }

        let root = try JSONDecoder().decode([String: JSONValue].self, from: data)
        guard let output = root["output"], case .array(let items) = output else { throw AgentError.invalidResponse }

        var calls: [AgentToolCall] = []
        var text: String?
        for item in items {
            guard case .object(let object) = item,
                  let type = object["type"]?.stringValue else { continue }
            if type == "function_call",
               let id = object["call_id"]?.stringValue,
               let name = object["name"]?.stringValue,
               let argumentString = object["arguments"]?.stringValue,
               let argumentData = argumentString.data(using: .utf8),
               case .object(let arguments) = try JSONDecoder().decode(JSONValue.self, from: argumentData) {
                calls.append(AgentToolCall(id: id, name: name, arguments: arguments))
            }
            if type == "message", let content = object["content"], case .array(let parts) = content {
                text = parts.compactMap { part -> String? in
                    guard case .object(let p) = part else { return nil }
                    return p["text"]?.stringValue
                }.joined()
            }
        }

        let message = AgentMessage(role: .assistant, content: text, toolCalls: calls.isEmpty ? nil : calls)
        return AgentResponse(message: message)
    }
}
