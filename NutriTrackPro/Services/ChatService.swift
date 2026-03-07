import Foundation

// MARK: – Data types

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: String   // "user" | "assistant"
    var content: String
    var timestamp: Date = .now

    var isUser: Bool { role == "user" }
}

// MARK: – Service

/// Actor responsável pelas mensagens GPT-4o via proxy AWS Lambda.
/// O proxy não suporta SSE, então usamos resposta completa (sem stream).
actor ChatService {
    static let shared = ChatService()
    private init() {}

    /// Envia mensagens ao proxy e retorna o conteúdo via AsyncThrowingStream
    /// (compatível com o caller existente no ChatView).
    func sendStream(
        messages: [ChatMessage],
        systemPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let content = try await self.send(messages: messages, systemPrompt: systemPrompt)
                    continuation.yield(content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: – Private

    private func send(messages: [ChatMessage], systemPrompt: String) async throws -> String {
        var payload: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for m in messages {
            payload.append(["role": m.role, "content": m.content])
        }

        let body: [String: Any] = [
            "model": AppConstants.chatModel,
            "max_tokens": 800,
            "messages": payload
        ]

        var request = URLRequest(url: URL(string: AppConstants.openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChatError.invalidResponse
        }

        guard let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.invalidResponse
        }
        return content
    }
}

// MARK: – Errors

enum ChatError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Resposta inválida do servidor de chat."
    }
}
